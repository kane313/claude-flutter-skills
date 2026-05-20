# Patrol screenshot driver

## Prerequisites

- `dev_dependencies: patrol: ^X.Y.Z` and `patrol_cli` installed (`dart pub global activate patrol_cli`).
- Device or simulator running.

## Test scaffolding

Write `integration_test/<page>_shot_test.dart`:

```dart
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:patrol/patrol.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  patrolTest('shot_<page>', ($) async {
    await $.pumpWidget(const MyApp(initialRoute: '<route>'));
    await $.pumpAndSettle(timeout: const Duration(seconds: 8));
    // Preload fonts so first paint matches expected:
    await Future.delayed(const Duration(milliseconds: 500));
    await IntegrationTestWidgetsFlutterBinding.instance.takeScreenshot(
      'shot_<page>',
    );
  });
}
```

## Capture invocation

```
patrol test --target integration_test/<page>_shot_test.dart \
  -d <deviceId> \
  --tag screenshot
```

Then collect the screenshot from `build/screenshots/shot_<page>.png` (or platform-specific path) and copy to `.flutter-html-reproduce/<page>/flutter-shot.png`.

## Stability tricks

- Stop animations: insert `WidgetsBinding.instance.disableShader Warmup()` before pump if test is too jittery (advanced; usually unnecessary).
- Preload images: use `precacheImage` for known asset paths before pump.
- Fixed clock: set `WidgetsBinding.instance.platformDispatcher.locale` etc., if locale-dependent layout suspected.

## Failure modes

- Patrol fails to find an iOS simulator → suggest `xcrun simctl list` and pass explicit `-d`.
- App boots but screenshot is blank → likely `pumpAndSettle` returned too early; raise timeout to 12s.
- Multiple Flutter screenshot frameworks compete → ensure only `patrol` is used (not `flutter test` integration).
