#!/usr/bin/env python3
"""Build on a Mac and capture the actual Simulator screens for the submission."""

import json
import os
import plistlib
import shutil
import signal
import subprocess
import sys
import tempfile
import time
from pathlib import Path


PROJECT = Path(__file__).resolve().parents[1]
DEVICES = (
    ("iPhone SE (3rd generation)", "iphone-se-3"),
    ("iPhone 16 Pro Max", "iphone-16-pro-max"),
)
MEDIA_START = "<!-- screenshots:start -->"
MEDIA_END = "<!-- screenshots:end -->"


def simctl(*arguments, **options):
    return subprocess.run(["xcrun", "simctl", *arguments], check=True, **options)


def find_simulator(name, inventory):
    device_type = next((value for value in inventory["devicetypes"] if value["name"] == name), None)
    if device_type is None:
        raise RuntimeError(f"This Xcode installation does not contain the {name} device type.")

    runtimes = [
        runtime for runtime in inventory["runtimes"]
        if runtime["isAvailable"]
        and runtime["identifier"].startswith("com.apple.CoreSimulator.SimRuntime.iOS-")
        and int(runtime["version"].split(".")[0]) >= 15
    ]
    runtimes.sort(key=lambda runtime: tuple(map(int, runtime["version"].split("."))), reverse=True)

    for runtime in runtimes:
        matches = [
            device for device in inventory["devices"].get(runtime["identifier"], [])
            if device.get("isAvailable", False)
            and (device.get("deviceTypeIdentifier") == device_type["identifier"]
                 or ("deviceTypeIdentifier" not in device and device["name"] == name))
        ]
        if matches:
            return next((device["udid"] for device in matches if device["state"] == "Booted"),
                        matches[0]["udid"])

    for runtime in runtimes:
        result = subprocess.run(
            ["xcrun", "simctl", "create", name, device_type["identifier"], runtime["identifier"]],
            capture_output=True, text=True,
        )
        if result.returncode == 0:
            return result.stdout.strip()

    raise RuntimeError(f"Install an iOS Simulator runtime supporting {name} in Xcode Settings, then retry.")


def build_application(folder, device_id):
    subprocess.run(
        ["xcodebuild", "-project", str(PROJECT / "FavoritesNavigator.xcodeproj"),
         "-scheme", "FavoritesNavigator", "-configuration", "Debug",
         "-destination", f"platform=iOS Simulator,id={device_id}",
         "-derivedDataPath", str(folder), "CODE_SIGNING_ALLOWED=NO", "build"],
        cwd=PROJECT, check=True,
    )
    return folder / "Build" / "Products" / "Debug-iphonesimulator" / "FavoritesNavigator.app"


def terminate_application(device_id, bundle_id):
    subprocess.run(["xcrun", "simctl", "terminate", device_id, bundle_id],
                   capture_output=True, timeout=20)


def screenshot(device_id, destination):
    simctl("io", device_id, "screenshot", str(destination))
    if not destination.read_bytes().startswith(b"\x89PNG\r\n\x1a\n"):
        raise RuntimeError(f"Simulator did not save a valid PNG for {destination.name}.")


def capture_launch_screen(device_id, bundle_id, destination):
    terminate_application(device_id, bundle_id)
    result = subprocess.run(
        ["xcrun", "simctl", "launch", "--wait-for-debugger", device_id, bundle_id],
        capture_output=True, text=True,
    )
    try:
        if result.returncode == 0:
            time.sleep(1)
            answer = input(
                "Inspect this Simulator. If it shows the centered film logo on the launch background, "
                "type yes to capture it. Otherwise press Enter to supply an Xcode launch-screen screenshot. "
            ).strip().lower()
            if answer == "yes":
                screenshot(device_id, destination)
                return

        print("Open LaunchScreen.storyboard in Xcode. Preview this device and appearance, then save a PNG screenshot.")
        supplied = input("Drag that PNG into Terminal and press Enter, or leave empty to stop. ").strip()
        if not supplied:
            raise RuntimeError("Launch Screen capture is still required. Run the script again when it is available.")
        supplied = supplied.strip("'\"").replace("\\ ", " ")
        path = Path(supplied).expanduser()
        if not path.read_bytes().startswith(b"\x89PNG\r\n\x1a\n"):
            raise RuntimeError("The supplied Launch Screen image must be a PNG screenshot.")
        shutil.copyfile(path, destination)
    finally:
        # A launch paused for debugging can be stopped, then started normally.
        if result.returncode == 0:
            process = result.stdout.strip().rsplit(":", 1)[-1].strip()
            if process.isdigit():
                try:
                    os.kill(int(process), signal.SIGKILL)
                except ProcessLookupError:
                    pass


def capture_device(device_id, name, prefix, app, bundle_id, folder):
    print(f"\nCapturing {name}", flush=True)
    simctl("bootstatus", device_id, "-b")
    subprocess.run(["open", "-a", "Simulator", "--args", "-CurrentDeviceUDID", device_id], check=True)
    appearance_output = simctl("ui", device_id, "appearance", capture_output=True, text=True).stdout.split()
    original_appearance = appearance_output[-1].lower() if appearance_output else None
    try:
        simctl("ui", device_id, "appearance", "light")
        terminate_application(device_id, bundle_id)
        simctl("install", device_id, str(app))
        simctl("launch", device_id, bundle_id)
        time.sleep(2)
        input(f"Show {name} in Simulator and check that My Movies is at the top of the list. Press Enter to capture. ")
        screenshot(device_id, folder / f"{prefix}-list.png")

        input("Tap a film in this Simulator and check its title, image, rating and description. Press Enter to capture Detail. ")
        screenshot(device_id, folder / f"{prefix}-detail.png")

        for appearance in ["light", "dark"]:
            simctl("ui", device_id, "appearance", appearance)
            capture_launch_screen(device_id, bundle_id, folder / f"{prefix}-launch-{appearance}.png")

        simctl("ui", device_id, "appearance", "light")
        input("Show the Home Screen with the Movie Navigator app icon visible. Use Shift+Cmd+H in Simulator, then press Enter here. ")
        screenshot(device_id, folder / f"{prefix}-home.png")
    finally:
        if original_appearance in ("light", "dark"):
            simctl("ui", device_id, "appearance", original_appearance)


def save_screenshots(folder, readme):
    names = [f"{prefix}-{kind}.png" for _, prefix in DEVICES
             for kind in ["list", "detail", "launch-light", "launch-dark", "home"]]
    if not all((folder / name).is_file() for name in names):
        raise RuntimeError("A required screenshot is missing.")
    destination = PROJECT / "Screenshots"
    destination.mkdir(exist_ok=True)
    for name in names:
        shutil.copyfile(folder / name, destination / name)

    rows = [
        "| Screen | iPhone SE (3rd generation) | iPhone 16 Pro Max |",
        "| --- | --- | --- |",
    ]
    for kind, label in [("list", "List"), ("detail", "Detail"), ("launch-light", "Launch Screen, light"),
                        ("launch-dark", "Launch Screen, dark"), ("home", "App Icon on the Home Screen")]:
        cells = [f'<img src="Screenshots/{prefix}-{kind}.png" alt="{label} on {name}" width="245">'
                 for name, prefix in DEVICES]
        rows.append(f"| {label} | {cells[0]} | {cells[1]} |")
    before, remainder = readme.split(MEDIA_START, 1)
    _, after = remainder.split(MEDIA_END, 1)
    text = before + MEDIA_START + "\n\n" + "\n".join(rows) + "\n\n" + MEDIA_END + after
    temporary_readme = PROJECT / "README.capture.tmp"
    temporary_readme.write_text(text, encoding="utf-8")
    os.replace(temporary_readme, PROJECT / "README.md")


def main():
    if sys.platform != "darwin":
        raise RuntimeError("Run this command on a Mac with Xcode and iOS Simulator installed.")
    if not sys.stdin.isatty():
        raise RuntimeError("Run this command in Terminal to answer the screenshot prompts.")

    readme = (PROJECT / "README.md").read_text(encoding="utf-8")
    if MEDIA_START not in readme or MEDIA_END not in readme:
        raise RuntimeError("The README screenshot markers are missing.")
    inventory = json.loads(simctl("list", "-j", capture_output=True, text=True).stdout)
    devices = [find_simulator(name, inventory) for name, _ in DEVICES]

    with tempfile.TemporaryDirectory(prefix="favorites-navigator-") as temp:
        folder = Path(temp)
        app = build_application(folder / "BuildData", devices[0])
        with (app / "Info.plist").open("rb") as file:
            bundle_id = plistlib.load(file)["CFBundleIdentifier"]
        for device_id, (name, prefix) in zip(devices, DEVICES):
            capture_device(device_id, name, prefix, app, bundle_id, folder)
        save_screenshots(folder, readme)

    print("\nSaved ten real screenshots in Screenshots/ and inserted them into README.md.")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, subprocess.SubprocessError, OSError, KeyboardInterrupt) as error:
        sys.exit(f"Capture stopped. {error}")
