#!/usr/bin/env python3
"""Release eligibility and previous-version selection are publishing boundaries."""

import importlib.util
from pathlib import Path
import unittest

spec = importlib.util.spec_from_file_location("release", Path(__file__).with_name("release.py"))
release = importlib.util.module_from_spec(spec)
spec.loader.exec_module(release)


def ci_run(identifier=1, **changes):
    result = dict(id=identifier, head_sha="commit", head_branch="0.2.0", event="push",
                  status="completed", conclusion="success", html_url="https://example.test/run")
    result.update(changes)
    return result


class ReleaseTests(unittest.TestCase):
    def test_only_matching_tag_push_can_qualify(self):
        unrelated = [ci_run(head_sha="other"), ci_run(head_branch="master"),
                     ci_run(event="pull_request"), ci_run(head_branch="v0.2.0")]
        self.assertIsNone(release.successful_run(unrelated, "0.2.0", "commit"))
        matching = ci_run(2)
        self.assertEqual(release.successful_run(unrelated + [matching], "0.2.0", "commit"), matching)

    def test_newer_pending_run_does_not_reuse_old_success(self):
        self.assertIsNone(release.successful_run(
            [ci_run(), ci_run(2, status="in_progress", conclusion=None)], "0.2.0", "commit"))

    def test_newer_failed_or_cancelled_run_blocks_publication(self):
        for conclusion in ["failure", "cancelled", "skipped", "timed_out"]:
            with self.subTest(conclusion=conclusion), self.assertRaises(ValueError):
                release.successful_run([ci_run(), ci_run(2, conclusion=conclusion)], "0.2.0", "commit")

    def test_previous_tag_is_numeric_and_older(self):
        self.assertEqual(release.previous_tag(
            ["temp", "0.0.4", "0.1.0", "v0.1.9", "0.1.10", "0.2.0", "1.0.0"], "v0.2.0"), "0.1.10")

    def test_initial_release_requires_explicit_setup(self):
        with self.assertRaises(ValueError):
            release.previous_tag(["temp", "0.2.0"], "0.2.0")

    def test_nonstable_tags_do_not_become_releases(self):
        for tag in ["temp", "01.2.3", "0.2.0-rc.1", "0.2.0/extra"]:
            with self.subTest(tag=tag), self.assertRaises(ValueError):
                release.version(tag)


if __name__ == "__main__":
    unittest.main()
