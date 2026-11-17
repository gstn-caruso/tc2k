#!/usr/bin/env python3
"""Build Debian/portable Linux packages and a standalone Windows executable."""
import argparse
import configparser
import hashlib
import io
import json
import os
import re
import shutil
import struct
import subprocess
import tempfile
import time
import zipfile
from pathlib import Path

from check import run_godot
from release import TAG


def smoke_linux(executable):
    with tempfile.TemporaryDirectory(prefix="godot-export-smoke-") as user_data:
        env = {**os.environ, "XDG_DATA_HOME": user_data, "XDG_CONFIG_HOME": user_data}
        result = subprocess.run(
            [str(executable.resolve()), "--headless", "--fixed-fps", "60", "--quit-after", "300"],
            env=env, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT, timeout=45,
        )
        print(result.stdout, end="", flush=True)
        if result.returncode or re.search(r"^(?:SCRIPT )?ERROR:", result.stdout, re.MULTILINE):
            raise RuntimeError("Exported Linux startup failed")


def verify_windows(executable):
    with executable.open("rb") as source:
        header = source.read(64)
        if len(header) != 64 or header[:2] != b"MZ":
            raise RuntimeError("Windows export is not a PE executable")
        source.seek(struct.unpack_from("<I", header, 0x3C)[0])
        signature = source.read(6)
    if signature != b"PE\0\0\x64\x86":
        raise RuntimeError("Windows export is not an x86_64 PE executable")


def template_presets(original, config):
    presets = configparser.ConfigParser(interpolation=None)
    presets.read_string(original.decode())
    names = config["export_presets"]
    templates = {
        names["linux"]: os.environ.get("GODOT_LINUX_RELEASE_TEMPLATE", os.environ.get("GODOT_RELEASE_TEMPLATE")),
        names["windows"]: os.environ.get("GODOT_WINDOWS_RELEASE_TEMPLATE"),
    }
    found = set()
    for section in presets.sections():
        if not re.fullmatch(r"preset\.\d+", section):
            continue
        name = json.loads(presets.get(section, "name"))
        if name in templates:
            found.add(name)
            if templates[name]:
                presets.set(section + ".options", "custom_template/release", json.dumps(str(Path(templates[name]).resolve())))
    if found != set(templates):
        raise RuntimeError("Missing export presets: " + ", ".join(set(templates) - found))
    output = io.StringIO()
    presets.write(output)
    return output.getvalue()


def copy_notices(folder):
    for filename in ["LICENSE", "THIRD_PARTY_NOTICES.md"]:
        shutil.copy(filename, folder)
    shutil.copytree("licenses", folder / "licenses", dirs_exist_ok=True)
    for license_file in Path("assets").glob("*/License.txt"):
        shutil.copy(license_file, folder / "licenses" / (license_file.parent.name + "_LICENSE.txt"))


def zip_folder(folder, output, epoch):
    # Stable entry order, timestamps and permissions make repeated ZIP packaging reproducible.
    timestamp = time.gmtime(max(epoch, 315532800))[:6]
    with zipfile.ZipFile(output, "w", zipfile.ZIP_DEFLATED, compresslevel=9) as archive:
        for file in sorted(folder.rglob("*")):
            if not file.is_file():
                continue
            entry = zipfile.ZipInfo(str(file.relative_to(folder.parent)), timestamp)
            entry.create_system = 3
            mode = 0o755 if file.stat().st_mode & 0o111 else 0o644
            entry.external_attr = (0o100000 | mode) << 16
            entry.compress_type = zipfile.ZIP_DEFLATED
            archive.writestr(entry, file.read_bytes(), compresslevel=9)


def build_deb(config, version, linux_folder, output, staging, epoch):
    root = staging / "debian"
    slug = config["slug"]
    executable_name = slug + ".x86_64"
    program = root / "usr/lib" / slug
    program.mkdir(parents=True)
    shutil.copy2(linux_folder / executable_name, program / executable_name)
    launcher = root / "usr/games" / slug
    launcher.parent.mkdir(parents=True)
    launcher.write_text(f'#!/bin/sh\nexec /usr/lib/{slug}/{executable_name} "$@"\n')
    launcher.chmod(0o755)
    desktop = root / "usr/share/applications" / (slug + ".desktop")
    desktop.parent.mkdir(parents=True)
    desktop.write_text(
        f"[Desktop Entry]\nType=Application\nName={config['title']}\n"
        f"Exec=/usr/games/{slug}\nTerminal=false\nCategories=Game;\n"
    )
    docs = root / "usr/share/doc" / slug
    docs.mkdir(parents=True)
    copy_notices(docs)
    (docs / "copyright").write_text(
        (docs / "LICENSE").read_text() + "\n" + (docs / "THIRD_PARTY_NOTICES.md").read_text()
    )
    control = root / "DEBIAN/control"
    control.parent.mkdir()
    installed_kib = sum(path.stat().st_size for path in root.rglob("*") if path.is_file()) // 1024 + 1
    control.write_text(
        f"Package: {slug}\nVersion: {version}\nSection: games\nPriority: optional\n"
        f"Architecture: amd64\nMaintainer: {config['maintainer']}\nInstalled-Size: {installed_kib}\n"
        "Depends: libc6 (>= 2.28), libstdc++6, libgl1, libx11-6, libxcursor1, libxi6, libxinerama1, libxrandr2, libxkbcommon0, libasound2t64 | libasound2\n"
        f"Description: {config['title']}\n Built with Godot Engine.\n"
    )
    root.chmod(0o755)
    for path in root.rglob("*"):
        path.chmod(0o755 if path.is_dir() or path in [program / executable_name, launcher] else 0o644)
    env = {**os.environ, "SOURCE_DATE_EPOCH": str(epoch)}
    subprocess.run(["dpkg-deb", "--root-owner-group", "--build", str(root), str(output)], check=True, env=env)
    fields = subprocess.check_output(["dpkg-deb", "--field", str(output), "Package", "Version", "Architecture"], text=True)
    expected = {"Package": slug, "Version": version, "Architecture": "amd64"}
    actual = dict(line.split(": ", 1) for line in fields.splitlines() if ": " in line)
    if actual != expected:
        raise RuntimeError("Debian package metadata does not match the release")
    with tempfile.TemporaryDirectory(prefix="godot-deb-smoke-") as extracted:
        subprocess.run(["dpkg-deb", "--extract", str(output), extracted], check=True)
        smoke_linux(Path(extracted) / "usr/lib" / slug / executable_name)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True)
    args = parser.parse_args()
    if not TAG.fullmatch("v" + args.version):
        parser.error("Version must be a canonical MAJOR.MINOR.PATCH")
    config = json.loads(Path("release-config.json").read_text())
    slug = config["slug"]
    if not re.fullmatch(r"[a-z0-9][a-z0-9-]+", slug):
        parser.error("Use a Debian-compatible lowercase slug of at least two characters")
    for key in ["title", "maintainer"]:
        if not config.get(key) or any(character in config[key] for character in "\r\n\0"):
            parser.error(f"{key} must be a nonempty single line")
    if not shutil.which("dpkg-deb"):
        parser.error("dpkg-deb is required to build the Linux installer")
    build = Path("build")
    build.mkdir(exist_ok=True)
    (build / ".gdignore").touch()
    artifacts = build / "release"
    staging = build / "staging" / f"{slug}-{args.version}"
    for owned in [artifacts, staging]:
        if owned.exists():
            shutil.rmtree(owned)
        owned.mkdir(parents=True)
    try:
        epoch = int(subprocess.check_output(["git", "show", "-s", "--format=%ct", "HEAD"], text=True, stderr=subprocess.DEVNULL).strip())
    except (subprocess.CalledProcessError, ValueError):
        epoch = 0
    linux_folder = staging / f"{slug}-{args.version}-linux-x86_64"
    windows_folder = staging / f"{slug}-{args.version}-windows-x86_64"
    linux_folder.mkdir()
    windows_folder.mkdir()
    linux_executable = linux_folder / (slug + ".x86_64")
    windows_executable = windows_folder / (slug + ".exe")
    version_file = Path("version.txt")
    preset_file = Path("export_presets.cfg")
    original_version = version_file.read_bytes()
    original_presets = preset_file.read_bytes()
    try:
        version_file.write_text(args.version + "\n")
        preset_file.write_text(template_presets(original_presets, config))
        for platform, executable in [("linux", linux_executable), ("windows", windows_executable)]:
            run_godot(["--export-release", config["export_presets"][platform], str(executable.resolve())], timeout=300)
    finally:
        version_file.write_bytes(original_version)
        preset_file.write_bytes(original_presets)
    smoke_linux(linux_executable)
    verify_windows(windows_executable)
    for folder in [linux_folder, windows_folder]:
        copy_notices(folder)
        executable = slug + (".exe" if folder == windows_folder else ".x86_64")
        (folder / "RUN.txt").write_text(f"{config['title']} v{args.version}\n\nRun {executable}\n")
        zip_folder(folder, artifacts / (folder.name + ".zip"), epoch)
    shutil.copy2(windows_executable, artifacts / f"{slug}-{args.version}-windows-x86_64.exe")
    build_deb(config, args.version, linux_folder, artifacts / f"{slug}_{args.version}_amd64.deb", staging, epoch)
    checksums = []
    for file in sorted(artifacts.iterdir()):
        if file.is_file():
            with file.open("rb") as source:
                digest = hashlib.file_digest(source, "sha256").hexdigest()
            checksums.append(f"{digest}  {file.name}\n")
    (artifacts / "SHA256SUMS.txt").write_text("".join(checksums))
    print("Built verified desktop artifacts in", artifacts)


if __name__ == "__main__":
    main()
