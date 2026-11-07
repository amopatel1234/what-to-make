"""Exercise runner preflight decisions without requiring Apple tools."""

import importlib.util
import json
from pathlib import Path
import subprocess
import unittest
from unittest.mock import patch

spec = importlib.util.spec_from_file_location(
    "apple_toolchain", Path(__file__).resolve().parents[1] / "check-apple-toolchain.py"
)
toolchain = importlib.util.module_from_spec(spec)
spec.loader.exec_module(toolchain)


class AppleToolchainTests(unittest.TestCase):
    def run_check(self, *, xcode="27.0", sdk="27.0", os="27-0",
                  name="iPhone 17", available=True, simulator=True):
        devices = {"devices": {f"com.apple.CoreSimulator.SimRuntime.iOS-{os}": [
            {"name": name, "isAvailable": available, "udid": "test-device"}
        ]}}

        def command(*arguments):
            if arguments == ("xcodebuild", "-version"):
                return f"Xcode {xcode}\nBuild version test"
            if "--show-sdk-version" in arguments:
                return sdk
            if arguments == ("xcrun", "simctl", "list", "devices", "available", "--json"):
                return json.dumps(devices)
            raise AssertionError(arguments)

        with patch.object(toolchain, "command", side_effect=command), patch("builtins.print"):
            toolchain.check("iPhone 17" if simulator else None, "27.0" if simulator else None)

    def test_verified_runner_inventory_passes(self):
        self.run_check()

    def test_xcode_26_is_rejected_even_with_new_runtime(self):
        with self.assertRaisesRegex(ValueError, "Select Xcode 27"):
            self.run_check(xcode="26.6")

    def test_unreviewed_future_major_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "Select Xcode 27"):
            self.run_check(xcode="28.0")

    def test_wrong_sdk_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "SDK"):
            self.run_check(sdk="26.5")

    def test_matching_name_on_wrong_runtime_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "Missing available"):
            self.run_check(os="26-0")

    def test_different_device_does_not_silently_replace_snapshot_destination(self):
        with self.assertRaisesRegex(ValueError, "Missing available"):
            self.run_check(name="iPhone 18 Pro")

    def test_unavailable_device_is_rejected(self):
        with self.assertRaisesRegex(ValueError, "Missing available"):
            self.run_check(available=False)

    def test_deployment_does_not_require_a_simulator(self):
        self.run_check(name="no test simulator installed", simulator=False)

    def test_missing_xcode_reports_failure(self):
        with patch.object(toolchain, "command", side_effect=FileNotFoundError("xcodebuild")), \
                patch("sys.argv", ["check-apple-toolchain.py"]), patch("builtins.print"):
            self.assertEqual(toolchain.main(), 1)

    def test_failed_command_reports_failure(self):
        error = subprocess.CalledProcessError(1, "xcrun", output="Invalid developer directory")
        with patch.object(toolchain, "command", side_effect=error), \
                patch("sys.argv", ["check-apple-toolchain.py"]), patch("builtins.print"):
            self.assertEqual(toolchain.main(), 1)


if __name__ == "__main__":
    unittest.main()
