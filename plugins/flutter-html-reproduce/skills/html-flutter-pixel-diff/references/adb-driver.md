# adb screenshot driver (Android fallback)

## Prerequisites

- `adb` on PATH (part of Android SDK platform-tools).
- An attached device or running emulator (`adb devices` shows at least one `device`).
- App installed AND running (`flutter run` in another terminal, or pre-installed `adb install -r build/app/outputs/apk/debug/app-debug.apk`).

## Capture

```bash
# 1. Ensure the device is unlocked and on the target screen.
# 2. Wait briefly to settle animations.
sleep 1.5

# 3. Capture.
adb exec-out screencap -p > /tmp/flutter-shot.png

# 4. Crop status/nav bars (optional — match HTML screenshot framing).
# Use ImageMagick if available:
#   convert /tmp/flutter-shot.png -crop WxH+X+Y output.png
```

## Navigating to the target route

If the app uses named routes, push via:

```bash
adb shell am start -n com.example.flutterhtml/.MainActivity \
  -a android.intent.action.VIEW \
  -d "myapp://route/<page>"
```

Requires the app to declare a matching intent-filter for the deep link. Without one, the operator must navigate manually before triggering capture.

## Stability tricks

- Disable animations on the device:
  ```bash
  adb shell settings put global window_animation_scale 0.0
  adb shell settings put global transition_animation_scale 0.0
  adb shell settings put global animator_duration_scale 0.0
  ```
  Remember to restore (`1.0`) after the test session.
- Use `adb wait-for-device` if the emulator is still booting.

## Modifying capture flow via inputs

The skill should `adb shell input tap X Y` to drive minimal UI before capture (e.g., dismiss a launch modal). Coordinates derived from the rendered Flutter screen (best-effort; brittle).

## Failure modes

- `adb: no devices/emulators found` → ask user to start one; do not silently skip.
- `adb exec-out` returns 0 bytes → device may have a black screen; sleep + retry once; on retry failure, log and continue with empty image (diff will be 100% red, signaling the issue).
- App crashes during capture → flutter logs via `adb logcat -d | tail` for diagnostic.
