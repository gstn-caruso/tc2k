#!/usr/bin/env python3
"""Conventional Commits -> SemVer and release notes, without package dependencies."""
import argparse
import json
import re
import subprocess
from pathlib import Path

HEADER = re.compile(r"^(feat|fix|perf|refactor|docs|test|build|ci|chore|style|revert)(?:\([^\r\n()]+\))?(!)?: (\S[^\r\n]*)$")
TAG = re.compile(r"^v(0|[1-9]\d*)\.(0|[1-9]\d*)\.(0|[1-9]\d*)$")


def change_type(message):
    header = HEADER.fullmatch(message.splitlines()[0]) if message else None
    if not header:
        return None
    if header[2] or re.search(r"^BREAKING[ -]CHANGE: \S", message, re.MULTILINE):
        return "major"
    if header[1] == "feat":
        return "minor"
    return "patch"


def next_version(previous, messages, initial="0.1.0"):
    changes = [change_type(message) for message in messages]
    if not messages:
        return ""
    if not previous:
        return initial
    major, minor, patch = map(int, previous.lstrip("v").split("."))
    if "major" in changes:
        return f"{major + 1}.0.0"
    if "minor" in changes:
        return f"{major}.{minor + 1}.0"
    return f"{major}.{minor}.{patch + 1}"


def git(*args):
    return subprocess.check_output(["git", *args], text=True).strip()


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("command", choices=["plan", "check-title"])
    parser.add_argument("--title", default="")
    parser.add_argument("--github-output", type=Path)
    args = parser.parse_args()
    if args.command == "check-title":
        if not HEADER.fullmatch(args.title):
            parser.error("Use a Conventional Commit PR title, for example feat(menu): add character creation")
        return
    config = json.loads(Path("release-config.json").read_text())
    tags = [tag for tag in git("tag", "--merged", "HEAD").splitlines() if TAG.fullmatch(tag)]
    previous = max(tags, key=lambda tag: tuple(map(int, TAG.fullmatch(tag).groups())), default="")
    # An existing tag on this exact commit identifies a rerun, not a new version.
    tagged_head = bool(previous and git("rev-parse", previous + "^{commit}") == git("rev-parse", "HEAD"))
    earlier = [tag for tag in tags if tag != previous]
    notes_base = max(earlier, key=lambda tag: tuple(map(int, TAG.fullmatch(tag).groups())), default="") if tagged_head else previous
    revision = f"{notes_base}..HEAD" if notes_base else "HEAD"
    messages = [message.strip() for message in git("log", "--format=%B%x00", revision).split("\x00") if message.strip()]
    version = previous.removeprefix("v") if tagged_head else next_version(previous, messages, config["initial_version"])
    build = Path("build")
    build.mkdir(exist_ok=True)
    lines = [f"# {config['title']} v{version}", "", "## Changes", ""]
    lines.extend(f"- {message.splitlines()[0]}" for message in reversed(messages))
    lines += ["", "## Download", "", "Linux x86_64: install the .deb or extract the portable ZIP.", "Windows x86_64: run the .exe; the Windows ZIP also includes third-party notices.", "No Godot installation is needed. Verify downloads with SHA256SUMS.txt.", "", config.get("summary", "See the changes above for the features included in this release."), ""]
    (build / "release-notes.md").write_text("\n".join(lines))
    print(f"Release version: {version or 'none (no releasable changes)'}")
    if args.github_output:
        with args.github_output.open("a") as output:
            output.write(f"version={version}\n")


if __name__ == "__main__":
    main()
