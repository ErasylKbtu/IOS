#!/usr/bin/env python3
"""Collect the required screenshots and scroll recording on a Mac with Xcode."""

import json
import plistlib
import shutil
import signal
import subprocess
import sys
import tempfile
import time
from pathlib import Path


PROJECT_DIR = Path(__file__).resolve().parents[1]
DEVICES = (
    ("iPhone SE (3rd generation)", "iphone-se-3.png"),
    ("iPhone 16 Pro Max", "iphone-16-pro-max.png"),
)
START = "<!-- submission-media:start -->"
END = "<!-- submission-media:end -->"


def simctl(*arguments, **options):
    return subprocess.run(["xcrun", "simctl", *arguments], check=True, **options)


def find_simulator(name, inventory):
    device_type = next((item for item in inventory["devicetypes"] if item["name"] == name), None)
    if device_type is None:
        raise RuntimeError(f"Xcode does not list the simulator model {name}.")

    runtimes = [
        runtime for runtime in inventory["runtimes"]
        if runtime["isAvailable"] and runtime["identifier"].startswith("com.apple.CoreSimulator.SimRuntime.iOS-")
    ]
    runtimes.sort(key=lambda runtime: tuple(map(int, runtime["version"].split("."))), reverse=True)

    candidates = []
    for runtime in runtimes:
        for device in inventory["devices"].get(runtime["identifier"], []):
            if device.get("isAvailable", False) and (
                device.get("deviceTypeIdentifier") == device_type["identifier"]
                or ("deviceTypeIdentifier" not in device and device["name"] == name)
            ):
                candidates.append(device)

    if candidates:
        return next((device["udid"] for device in candidates if device["state"] == "Booted"),
                    candidates[0]["udid"])

    for runtime in runtimes:
        result = subprocess.run(
            ["xcrun", "simctl", "create", name, device_type["identifier"], runtime["identifier"]],
            capture_output=True, text=True,
        )
        if result.returncode == 0:
            return result.stdout.strip()

    raise RuntimeError(
        f"Install an iOS Simulator runtime that supports {name} in Xcode Settings, then run this again."
    )


def build_application(build_folder, device_id):
    subprocess.run(
        ["xcodebuild", "-project", str(PROJECT_DIR / "FavoritesList.xcodeproj"),
         "-scheme", "FavoritesList", "-configuration", "Debug",
         "-destination", f"platform=iOS Simulator,id={device_id}",
         "-derivedDataPath", str(build_folder), "CODE_SIGNING_ALLOWED=NO", "build"],
        check=True, cwd=PROJECT_DIR,
    )
    return build_folder / "Build" / "Products" / "Debug-iphonesimulator" / "FavoritesList.app"


def capture_screenshot(device_id, app, bundle_id, output):
    simctl("bootstatus", device_id, "-b")
    subprocess.run(["xcrun", "simctl", "terminate", device_id, bundle_id], capture_output=True)
    simctl("install", device_id, str(app))
    simctl("launch", device_id, bundle_id)
    time.sleep(3)
    simctl("io", device_id, "screenshot", str(output))


def capture_video(device_id, output):
    subprocess.run(["open", "-a", "Simulator"], check=True)
    input("Show Favorite Films at the top of the list on iPhone 16 Pro Max, then press Enter here to start recording. ")
    simctl_path = subprocess.check_output(["xcrun", "--find", "simctl"], text=True).strip()
    recorder = subprocess.Popen(
        [simctl_path, "io", device_id, "recordVideo", "--codec=h264", str(output)],
        stdin=subprocess.DEVNULL, start_new_session=True,
    )
    try:
        time.sleep(1)
        if recorder.poll() is not None:
            raise RuntimeError("Simulator could not start the screen recording.")
        input("Scroll through all 20 films on iPhone 16 Pro Max. Return here and press Enter to finish. ")
    finally:
        if recorder.poll() is None:
            recorder.send_signal(signal.SIGINT)
        try:
            recorder.wait(timeout=20)
        except subprocess.TimeoutExpired:
            recorder.kill()
            recorder.wait()
            raise RuntimeError("Simulator did not finish saving the recording.")

    expected_exit_codes = (0, 128 + signal.SIGINT, -signal.SIGINT)
    if recorder.returncode not in expected_exit_codes or not output.is_file() or output.stat().st_size == 0:
        raise RuntimeError("Simulator did not save a recording.")


def write_submission(media_folder, readme_text):
    destination = PROJECT_DIR / "Submission"
    destination.mkdir(exist_ok=True)
    for filename in [filename for _, filename in DEVICES] + ["scroll-through.mp4"]:
        shutil.copyfile(media_folder / filename, destination / filename)

    media = (
        "| iPhone SE (3rd generation) | iPhone 16 Pro Max |\n"
        "| --- | --- |\n"
        '| <img src="Submission/iphone-se-3.png" alt="Favorite Films on iPhone SE" width="270"> '
        '| <img src="Submission/iphone-16-pro-max.png" alt="Favorite Films on iPhone 16 Pro Max" width="270"> |\n\n'
        "[Watch the full list scroll](Submission/scroll-through.mp4)"
    )
    before, remaining = readme_text.split(START, 1)
    _, after = remaining.split(END, 1)
    (PROJECT_DIR / "README.md").write_text(f"{before}{START}\n\n{media}\n\n{END}{after}", encoding="utf-8")


def main():
    if sys.platform != "darwin":
        raise RuntimeError("Run this script on a Mac with Xcode and an iOS Simulator runtime installed.")
    if not sys.stdin.isatty():
        raise RuntimeError("Run this script in Terminal so you can start and stop the recording.")

    readme = (PROJECT_DIR / "README.md").read_text(encoding="utf-8")
    if START not in readme or END not in readme:
        raise RuntimeError("The submission media section is missing from README.md.")

    inventory = json.loads(simctl("list", "-j", capture_output=True, text=True).stdout)
    simulators = [find_simulator(name, inventory) for name, _ in DEVICES]

    with tempfile.TemporaryDirectory(prefix="favorites-list-") as temp:
        folder = Path(temp)
        app = build_application(folder / "BuildData", simulators[0])
        with (app / "Info.plist").open("rb") as file:
            bundle_id = plistlib.load(file)["CFBundleIdentifier"]

        for device_id, (name, filename) in zip(simulators, DEVICES):
            print(f"Capturing {name}…", flush=True)
            capture_screenshot(device_id, app, bundle_id, folder / filename)

        capture_video(simulators[1], folder / "scroll-through.mp4")
        write_submission(folder, readme)

    print("Saved both screenshots and the recording to Submission/ and updated README.md.")


if __name__ == "__main__":
    try:
        main()
    except (RuntimeError, subprocess.CalledProcessError, OSError) as error:
        sys.exit(f"Capture failed: {error}")
