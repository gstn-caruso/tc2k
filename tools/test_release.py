import unittest
import json
import subprocess
import sys
import tempfile
from pathlib import Path
from release import HEADER, change_type, next_version


class ReleasePolicyTests(unittest.TestCase):
    def test_every_merge_has_a_release(self):
        self.assertEqual(next_version("", ["feat: initial game"]), "0.1.0")
        self.assertEqual(next_version("", ["chore: initialize project"]), "0.1.0")
        for kind in ["docs", "ci", "chore", "test", "build", "style", "refactor"]:
            with self.subTest(kind=kind):
                self.assertEqual(next_version("v0.1.0", [kind + ": update project"]), "0.1.1")
        self.assertEqual(next_version("v0.1.0", ["Update project without a conventional title"]), "0.1.1")
        self.assertEqual(next_version("v0.1.0", []), "")

    def test_semver_increments(self):
        self.assertEqual(next_version("v0.1.0", ["fix(menu): restore focus"]), "0.1.1")
        self.assertEqual(next_version("v0.1.1", ["fix: correct names", "feat: add combat"]), "0.2.0")
        self.assertEqual(next_version("v0.2.0", ["feat(save)!: replace save format"]), "1.0.0")
        self.assertEqual(next_version("v2.3.4", ["refactor: replace storage\n\nBREAKING CHANGE: old saves need conversion"]), "3.0.0")
        self.assertEqual(next_version("v1.2.3", ["perf: reduce allocations"]), "1.2.4")

    def test_headers_and_scopes(self):
        self.assertIsNotNone(HEADER.fullmatch("feat(character-creation): add a class"))
        self.assertIsNone(HEADER.fullmatch("add a menu"))
        self.assertIsNone(HEADER.fullmatch("feat: title\nfix: body"))
        self.assertIsNone(change_type("Merge pull request #1 from feature/menu"))
        self.assertEqual(change_type("fix!: change controls"), "major")


class ReleaseGitTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="godot-release-policy-")
        self.addCleanup(self.directory.cleanup)
        self.repository = Path(self.directory.name)
        self.script = Path(__file__).with_name("release.py").resolve()
        self.git("init", "-q", "-b", "main")
        self.git("config", "user.name", "Release Test")
        self.git("config", "user.email", "release@example.invalid")
        (self.repository / "release-config.json").write_text(json.dumps({"title": "Game", "initial_version": "0.1.0"}))

    def git(self, *args):
        return subprocess.check_output(["git", *args], cwd=self.repository, text=True).strip()

    def commit(self, message):
        self.git("add", "release-config.json")
        self.git("commit", "-q", "--allow-empty", "-m", message)

    def plan(self):
        output = self.repository / "github-output"
        output.unlink(missing_ok=True)
        subprocess.run([sys.executable, str(self.script), "plan", "--github-output", str(output)], cwd=self.repository, check=True, stdout=subprocess.PIPE, text=True)
        return output.read_text().strip().removeprefix("version=")

    def test_reruns_reuse_the_tag_and_release_notes(self):
        self.commit("feat: initial game")
        self.assertEqual(self.plan(), "0.1.0")
        first_notes = (self.repository / "build/release-notes.md").read_text()
        self.git("tag", "v0.1.0")
        self.assertEqual(self.plan(), "0.1.0")
        self.assertEqual((self.repository / "build/release-notes.md").read_text(), first_notes)
        self.commit("docs: document controls")
        self.assertEqual(self.plan(), "0.1.1")
        notes = (self.repository / "build/release-notes.md").read_text()
        self.assertIn("docs: document controls", notes)
        self.assertNotIn("feat: initial game", notes)
        self.git("tag", "v0.1.1")
        self.assertEqual(self.plan(), "0.1.1")
        self.assertEqual((self.repository / "build/release-notes.md").read_text(), notes)

    def test_unreachable_tags_do_not_change_main_version(self):
        self.commit("feat: initial game")
        self.git("tag", "v0.1.0")
        self.git("switch", "-q", "-c", "feature/future")
        self.commit("feat!: future incompatible change")
        self.git("tag", "v9.0.0")
        self.git("switch", "-q", "main")
        self.commit("ci: adjust runner")
        self.assertEqual(self.plan(), "0.1.1")


if __name__ == "__main__":
    unittest.main()
