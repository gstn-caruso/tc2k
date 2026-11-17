import hashlib
import os
import tempfile
import unittest
import zipfile
from pathlib import Path

from build_release import zip_folder


class PortablePackageTests(unittest.TestCase):
    def test_zip_is_stable_and_preserves_executable_permissions(self):
        with tempfile.TemporaryDirectory(prefix="godot-zip-test-") as temporary:
            root = Path(temporary)
            folder = root / "game-0.1.0-linux-x86_64"
            folder.mkdir()
            executable = folder / "game.x86_64"
            executable.write_bytes(b"game executable")
            executable.chmod(0o755)
            (folder / "LICENSE").write_text("Project license")
            first, second = root / "first.zip", root / "second.zip"
            zip_folder(folder, first, 1730000000)
            os.utime(executable, (1800000000, 1800000000))
            zip_folder(folder, second, 1730000000)
            self.assertEqual(hashlib.sha256(first.read_bytes()).digest(), hashlib.sha256(second.read_bytes()).digest())
            with zipfile.ZipFile(first) as archive:
                mode = archive.getinfo(folder.name + "/game.x86_64").external_attr >> 16
            self.assertEqual(mode & 0o777, 0o755)


if __name__ == "__main__":
    unittest.main()
