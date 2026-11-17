#!/usr/bin/env python3
"""Publish verified desktop artifacts as a draft, then expose the complete release."""
import argparse
import hashlib
import json
import re
import subprocess
from pathlib import Path

from release import TAG


def gh(repository, *arguments, check=True):
    return subprocess.run(
        ["gh", "release", *arguments, "--repo", repository],
        check=check, text=True, stdout=subprocess.PIPE, stderr=subprocess.PIPE,
    )


def publish(version, commit, repository, artifacts=Path("build/release"), notes=Path("build/release-notes.md")):
    if not TAG.fullmatch("v" + version) or not re.fullmatch(r"[0-9a-f]{40}", commit):
        raise ValueError("Use a canonical semantic version and a full commit SHA")
    manifest = artifacts / "SHA256SUMS.txt"
    expected_files = set()
    for line in manifest.read_text().splitlines():
        digest, filename = line.split("  ", 1)
        if Path(filename).name != filename or not re.fullmatch(r"[0-9a-f]{64}", digest):
            raise ValueError("Invalid checksum manifest")
        with (artifacts / filename).open("rb") as source:
            if hashlib.file_digest(source, "sha256").hexdigest() != digest:
                raise RuntimeError("Checksum mismatch: " + filename)
        expected_files.add(filename)
    actual_files = {file.name for file in artifacts.iterdir() if file.is_file()} - {"SHA256SUMS.txt"}
    if not expected_files or actual_files != expected_files:
        raise RuntimeError("Release directory and checksum manifest must contain exactly the same artifacts")
    expected_files.add("SHA256SUMS.txt")
    tag = "v" + version
    existing = gh(repository, "view", tag, "--json", "targetCommitish,isDraft,assets", check=False)
    if existing.returncode == 0:
        release = json.loads(existing.stdout)
        if release["targetCommitish"] != commit:
            raise RuntimeError(f"{tag} already belongs to another commit; refusing to replace it")
        if not release["isDraft"]:
            if not expected_files.issubset({asset["name"] for asset in release["assets"]}):
                raise RuntimeError("Published release has missing assets; refusing to modify an immutable release")
            print(tag, "is already published for this commit; leaving it unchanged")
            return
    else:
        if "release not found" not in existing.stderr.lower():
            raise RuntimeError(existing.stderr.strip() or "Could not read the existing release")
        gh(repository, "create", tag, "--target", commit, "--title", tag, "--notes-file", str(notes), "--draft")
    paths = [str(artifacts / name) for name in sorted(expected_files)]
    gh(repository, "upload", tag, *paths, "--clobber")
    gh(repository, "edit", tag, "--draft=false")
    print("Published", tag, "for", commit)


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--version", required=True)
    parser.add_argument("--commit", required=True)
    parser.add_argument("--repo", required=True)
    args = parser.parse_args()
    publish(args.version, args.commit, args.repo)


if __name__ == "__main__":
    main()
