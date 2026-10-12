import json
import os
import plistlib
import subprocess
import tempfile
import unittest
from pathlib import Path


SCRIPT = Path(__file__).with_name("compare-bundles.py")


class CompareBundlesTests(unittest.TestCase):
    def setUp(self):
        self.temporary_directory = tempfile.TemporaryDirectory()
        self.root = Path(self.temporary_directory.name)
        self.reference = self.root / "Example.bundle"
        self.generated = self.root / "generated" / "Example.bundle"
        self.reference.mkdir(parents=True)
        self.generated.mkdir(parents=True)

    def tearDown(self):
        self.temporary_directory.cleanup()

    def run_comparison(self, *arguments, env=None):
        return subprocess.run(
            [
                str(SCRIPT),
                "--reference",
                str(self.reference),
                "--generated",
                str(self.generated),
                *arguments,
            ],
            capture_output=True,
            check=False,
            env=env,
            text=True,
        )

    def test_reports_entries_from_either_bundle(self):
        (self.reference / "reference.txt").write_text("reference")
        (self.generated / "generated.txt").write_text("generated")

        result = self.run_comparison()

        self.assertNotEqual(result.returncode, 0)
        self.assertIn("missing:reference.txt", result.stdout)
        self.assertIn("extra:generated.txt", result.stdout)

    def test_normalizes_wrapped_swiftpm_resource_layout(self):
        resources = self.reference / "Contents" / "Resources"
        resources.mkdir(parents=True)
        (self.reference / "Contents" / "Info.plist").write_bytes(
            plistlib.dumps({"CFBundleName": "Example"})
        )
        (resources / "resource.txt").write_text("resource")
        (self.generated / "Info.plist").write_bytes(
            plistlib.dumps({"CFBundleName": "Example"}, fmt=plistlib.FMT_BINARY)
        )
        (self.generated / "resource.txt").write_text("resource")

        result = self.run_comparison("--swiftpm-resource")

        self.assertEqual(result.returncode, 0, result.stdout)
        self.assertIn("accepted SwiftPM resource layout difference", result.stdout)

    def test_compares_plists_by_value(self):
        value = {"Items": ["one", "two"], "Enabled": True}
        (self.reference / "Info.plist").write_bytes(plistlib.dumps(value))
        (self.generated / "Info.plist").write_bytes(
            plistlib.dumps(value, fmt=plistlib.FMT_BINARY)
        )

        result = self.run_comparison()

        self.assertEqual(result.returncode, 0, result.stdout)

    def test_ignores_asset_catalog_compiler_metadata(self):
        (self.reference / "Assets.car").write_bytes(b"reference")
        (self.generated / "Assets.car").write_bytes(b"generated")
        fake_bin = self.root / "bin"
        fake_bin.mkdir()
        xcrun = fake_bin / "xcrun"
        xcrun.write_text(
            """#!/bin/sh
case "$5" in
  *generated*)
    timestamp=315532800 identifier=2 digest=generated size=300 tool=generated
    ;;
  *)
    timestamp=1791770420 identifier=1 digest=reference size=260 tool=reference
    ;;
esac
printf '[{"Authoring Tool":"%s","StorageVersion":17,"Timestamp":%s},{"AssetType":"Color","Color components":[0.75,0.25,0.5,1],"Name":"Brand","NameIdentifier":%s,"SHA1Digest":"%s","SizeOnDisk":%s}]\\n' "$tool" "$timestamp" "$identifier" "$digest" "$size"
"""
        )
        xcrun.chmod(0o755)
        environment = os.environ.copy()
        environment["PATH"] = f"{fake_bin}:{environment['PATH']}"

        result = self.run_comparison(env=environment)

        self.assertEqual(result.returncode, 0, result.stdout)

    def test_accepts_only_observed_baseline_differences(self):
        (self.reference / "resource.txt").write_text("reference")
        (self.generated / "resource.txt").write_text("generated")

        unaccepted = self.run_comparison()
        self.assertNotEqual(unaccepted.returncode, 0)
        self.assertIn("content:resource.txt", unaccepted.stdout)
        baseline = self.root / "baseline.json"
        baseline.write_text(
            json.dumps(
                {
                    "bundles": {
                        "Example.bundle": {
                            "content:resource.txt": "known compiler output"
                        }
                    }
                }
            )
        )

        accepted = self.run_comparison("--baseline", str(baseline))
        self.assertEqual(accepted.returncode, 0, accepted.stdout)

        (self.generated / "resource.txt").write_text("reference")
        stale = self.run_comparison("--baseline", str(baseline))
        self.assertNotEqual(stale.returncode, 0)
        self.assertIn("baseline difference no longer occurs", stale.stdout)


if __name__ == "__main__":
    unittest.main()
