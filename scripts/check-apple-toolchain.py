#!/usr/bin/env python3
"""Check the selected Apple toolchain before Fastlane tests or signing work."""

import argparse
import json
import re
import subprocess
import sys


def command(*arguments):
    return subprocess.check_output(arguments, text=True, stderr=subprocess.STDOUT).strip()


def check(simulator_name=None, simulator_os=None):
    version = command("xcodebuild", "-version")
    print(version)
    # Major-version upgrades are deliberate: SDK and snapshot changes need review.
    if not re.search(r"^Xcode 27(?:\.|$)", version, re.MULTILINE):
        raise ValueError("Select Xcode 27 with DEVELOPER_DIR or xcode-select; Xcode 26 cannot build this app.")
    for sdk in ("iphoneos", "iphonesimulator"):
        sdk_version = command("xcrun", "--sdk", sdk, "--show-sdk-version")
        if not re.fullmatch(r"27(?:\.\d+)+", sdk_version):
            raise ValueError(f"Expected an iOS 27 {sdk} SDK; found {sdk_version}.")
        print(f"{sdk}: {sdk_version}")

    if simulator_name:
        devices = json.loads(command("xcrun", "simctl", "list", "devices", "available", "--json"))["devices"]
        runtime = "com.apple.CoreSimulator.SimRuntime.iOS-" + simulator_os.replace(".", "-")
        matches = [device for device in devices.get(runtime, [])
                   if device.get("isAvailable") and device.get("name") == simulator_name]
        if not matches:
            raise ValueError(
                f"Missing available {simulator_name} simulator on iOS {simulator_os}. "
                "Check 'xcrun simctl list devices available' and install the pinned runtime/device. "
                "Do not silently substitute a different snapshot destination."
            )
        print(f"Simulator: {simulator_name}, iOS {simulator_os} ({matches[0]['udid']})")


def main():
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--simulator-name")
    parser.add_argument("--simulator-os")
    args = parser.parse_args()
    if bool(args.simulator_name) != bool(args.simulator_os):
        parser.error("--simulator-name and --simulator-os must be supplied together")
    try:
        check(args.simulator_name, args.simulator_os)
    except (OSError, subprocess.CalledProcessError, ValueError, KeyError) as error:
        print(f"Apple toolchain check failed: {error}", file=sys.stderr)
        if isinstance(error, subprocess.CalledProcessError):
            print(error.output, file=sys.stderr)
        return 1
    return 0


if __name__ == "__main__":
    sys.exit(main())
