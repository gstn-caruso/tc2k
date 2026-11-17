import hashlib
import json
import subprocess
import tempfile
import unittest
from pathlib import Path
from unittest.mock import patch

from publish_release import publish


class PublicationTests(unittest.TestCase):
    def setUp(self):
        self.directory = tempfile.TemporaryDirectory(prefix="godot-publish-test-")
        self.addCleanup(self.directory.cleanup)
        self.artifacts = Path(self.directory.name)
        (self.artifacts / "game.exe").write_bytes(b"verified game")
        checksum = hashlib.sha256(b"verified game").hexdigest()
        (self.artifacts / "SHA256SUMS.txt").write_text(f"{checksum}  game.exe\n")
        self.commit = "a" * 40

    def metadata(self, draft=False, commit=None):
        return subprocess.CompletedProcess([], 0, json.dumps({
            "targetCommitish": commit or self.commit,
            "isDraft": draft,
            "assets": [{"name": "game.exe"}, {"name": "SHA256SUMS.txt"}],
        }), "")

    def test_published_release_is_immutable_on_rerun(self):
        with patch("publish_release.gh", return_value=self.metadata()) as github:
            publish("0.1.0", self.commit, "owner/game", self.artifacts)
        self.assertEqual(github.call_count, 1)

    def test_existing_version_cannot_be_assigned_to_another_commit(self):
        with patch("publish_release.gh", return_value=self.metadata(commit="b" * 40)) as github:
            with self.assertRaisesRegex(RuntimeError, "another commit"):
                publish("0.1.0", self.commit, "owner/game", self.artifacts)
        self.assertEqual(github.call_count, 1)

    def test_checksum_failure_prevents_any_publication(self):
        (self.artifacts / "game.exe").write_bytes(b"corrupted artifact")
        with patch("publish_release.gh") as github:
            with self.assertRaisesRegex(RuntimeError, "Checksum mismatch"):
                publish("0.1.0", self.commit, "owner/game", self.artifacts)
        github.assert_not_called()

    def test_new_release_is_a_draft_until_assets_are_uploaded(self):
        absent = subprocess.CompletedProcess([], 1, "", "release not found")
        done = subprocess.CompletedProcess([], 0, "", "")
        with patch("publish_release.gh", side_effect=[absent, done, done, done]) as github:
            publish("0.1.0", self.commit, "owner/game", self.artifacts)
        calls = [call.args for call in github.call_args_list]
        self.assertEqual([args[1] for args in calls], ["view", "create", "upload", "edit"])
        self.assertIn("--draft", calls[1])
        self.assertIn("--draft=false", calls[-1])

    def test_authentication_failure_is_not_a_missing_release(self):
        denied = subprocess.CompletedProcess([], 1, "", "HTTP 401: authentication required")
        with patch("publish_release.gh", return_value=denied) as github:
            with self.assertRaisesRegex(RuntimeError, "401"):
                publish("0.1.0", self.commit, "owner/game", self.artifacts)
        self.assertEqual(github.call_count, 1)

    def test_draft_retry_finishes_without_creating_another_release(self):
        done = subprocess.CompletedProcess([], 0, "", "")
        with patch("publish_release.gh", side_effect=[self.metadata(draft=True), done, done]) as github:
            publish("0.1.0", self.commit, "owner/game", self.artifacts)
        self.assertEqual([call.args[1] for call in github.call_args_list], ["view", "upload", "edit"])


if __name__ == "__main__":
    unittest.main()
