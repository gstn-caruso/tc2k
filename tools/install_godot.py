#!/usr/bin/env python3
"""Install the pinned Linux editor and official Linux/Windows export templates."""
import hashlib
import json
import os
import shutil
import urllib.request
import zipfile
from pathlib import Path


def main():
    version = json.loads(Path("release-config.json").read_text())["godot_version"]
    cache = Path.home() / ".cache/godot-release" / version
    cache.mkdir(parents=True, exist_ok=True)
    editor = cache / "godot"
    linux = cache / "linux_release.x86_64"
    windows = cache / "windows_release_x86_64.exe"
    downloads = {}
    if not editor.exists():
        downloads[f"Godot_v{version}-stable_linux.x86_64.zip"] = {
            f"Godot_v{version}-stable_linux.x86_64": editor,
        }
    missing_templates = {
        member: target for member, target in {
            "templates/linux_release.x86_64": linux,
            "templates/windows_release_x86_64.exe": windows,
        }.items() if not target.exists()
    }
    if missing_templates:
        downloads[f"Godot_v{version}-stable_export_templates.tpz"] = missing_templates
    base = f"https://github.com/godotengine/godot-builds/releases/download/{version}-stable/"
    if downloads:
        with urllib.request.urlopen(base + "SHA512-SUMS.txt", timeout=60) as response:
            lines = response.read().decode().splitlines()
        checksums = {fields[1].lstrip("*"): fields[0] for line in lines if len(fields := line.split()) == 2}
        for filename, members in downloads.items():
            archive = cache / (filename + ".part")
            try:
                print("Downloading", filename, flush=True)
                urllib.request.urlretrieve(base + filename, archive)
                with archive.open("rb") as source:
                    digest = hashlib.file_digest(source, "sha512").hexdigest()
                if digest != checksums[filename]:
                    raise RuntimeError("Official SHA-512 checksum mismatch: " + filename)
                with zipfile.ZipFile(archive) as zipped:
                    for member, target in members.items():
                        temporary = target.with_suffix(target.suffix + ".tmp")
                        try:
                            with zipped.open(member) as source, temporary.open("wb") as output:
                                shutil.copyfileobj(source, output)
                            temporary.chmod(0o755)
                            temporary.replace(target)
                        finally:
                            temporary.unlink(missing_ok=True)
            finally:
                archive.unlink(missing_ok=True)
    values = {
        "GODOT": editor,
        "GODOT_RELEASE_TEMPLATE": linux,
        "GODOT_LINUX_RELEASE_TEMPLATE": linux,
        "GODOT_WINDOWS_RELEASE_TEMPLATE": windows,
    }
    if os.environ.get("GITHUB_ENV"):
        with open(os.environ["GITHUB_ENV"], "a") as output:
            for key, value in values.items():
                output.write(f"{key}={value}\n")
    for key, value in values.items():
        print(f"{key}={value}")


if __name__ == "__main__":
    main()
