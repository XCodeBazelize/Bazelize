import os
from pathlib import Path
import subprocess
import tempfile
import unittest


SCRIPT = Path(__file__).with_name("compare-generated-workspaces.py")


class CompareGeneratedWorkspacesTests(unittest.TestCase):
    def setUp(self):
        self.temporary = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary.name)
        self.reference = self.root / "App-pbxproj"
        self.generated = self.root / "App"
        for workspace in (self.reference, self.generated):
            workspace.mkdir()
            (workspace / "BUILD").write_text('objc_library(name = "Probe")\n')
            (workspace / ".build").mkdir()
            (workspace / ".build/state").write_text(workspace.name)
            (workspace / "Source").symlink_to(workspace / ".build/checkouts/Dependency")

    def tearDown(self):
        self.temporary.cleanup()

    def compare(self):
        return subprocess.run(
            [str(SCRIPT), str(self.reference), str(self.generated)],
            capture_output=True, text=True,
        )

    def test_relocates_workspace_links_and_excludes_swiftpm_state(self):
        result = self.compare()
        self.assertEqual(result.returncode, 0, result.stdout + result.stderr)
        self.assertEqual(os.readlink(self.reference / "Source"),
                         str(self.reference / ".build/checkouts/Dependency"))

    def test_reports_changed_generated_rule(self):
        (self.generated / "BUILD").write_text('objc_library(name = "Other")\n')
        result = self.compare()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn('objc_library(name = "Other")', result.stdout)

    def test_reports_missing_generated_file(self):
        (self.generated / "BUILD").unlink()
        result = self.compare()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("BUILD", result.stdout)

    def test_reports_changed_workspace_relative_link(self):
        (self.generated / "Source").unlink()
        (self.generated / "Source").symlink_to(self.generated / ".build/checkouts/Other")
        result = self.compare()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn(".build/checkouts/Other", result.stdout)

    def test_preserves_external_absolute_link_differences(self):
        for workspace in (self.reference, self.generated):
            (workspace / "Source").unlink()
            (workspace / "Source").symlink_to(self.root / (workspace.name + "-external"))
        result = self.compare()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("-external", result.stdout)

    def test_reports_file_replaced_by_link(self):
        (self.generated / "BUILD").unlink()
        (self.generated / "BUILD").symlink_to(self.reference / "BUILD")
        self.assertNotEqual(self.compare().returncode, 0)

    def test_reports_executable_bit_change(self):
        (self.generated / "BUILD").chmod(0o755)
        result = self.compare()
        self.assertNotEqual(result.returncode, 0)
        self.assertIn("mode", result.stdout)

    def test_rejects_missing_workspace(self):
        (self.generated / "BUILD").unlink()
        (self.generated / "Source").unlink()
        (self.generated / ".build/state").unlink()
        (self.generated / ".build").rmdir()
        self.generated.rmdir()
        self.assertNotEqual(self.compare().returncode, 0)


if __name__ == "__main__":
    unittest.main()
