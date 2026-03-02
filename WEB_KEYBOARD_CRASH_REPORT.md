# Flutter Web Keyboard Crash Report (Caps Lock / KeyUp Assertion)

## Summary
When running the app on Flutter Web (Chrome, debug), the app crashes with keyboard assertions related to `HardwareKeyboard` and synthesized `KeyUpEvent` for Caps Lock.

Observed assertions include:
- `lastLogicalRecord == null is not true` (`engine/keyboard_binding.dart`)
- `A KeyUpEvent is dispatched, but the state shows that the physical key is not pressed` (`hardware_keyboard.dart`)

## Environment
- Flutter: `3.41.2` (stable)
- Framework: `90673a4eef`
- Engine: `6c0baaebf7`
- Dart: `3.11.0`
- OS: `macOS 26.3 (darwin-x64)`
- Browser: `Chrome 145.0.7632.117`

## App Context
- Project: `football_note`
- No app-level custom keyboard handling found (`RawKeyboard`, `HardwareKeyboard`, `onKey`, `KeyboardListener` not used in `lib/`).

## Reproduction Steps
1. Run app on web debug mode:
   ```bash
   flutter run -d chrome
   ```
2. Interact with the app normally.
3. Toggle/use Caps Lock (or trigger focus changes around keyboard state updates).
4. Observe assertion crash and Dart compiler exit / target crash.

## Expected Behavior
App should continue running without keyboard state assertion failures.

## Actual Behavior
App crashes due to keyboard state mismatch assertions in Flutter framework/engine.

## Stack Trace Snippet
```text
Assertion failed: .../engine/keyboard_binding.dart:502:16
lastLogicalRecord == null

Assertion failed: .../services/hardware_keyboard.dart:522:11
_pressedKeys.containsKey(event.physicalKey)
A KeyUpEvent is dispatched, but the state shows that the physical key is not pressed...
KeyUpEvent ... Caps Lock ... synthesized
```

## Temporary Workarounds
- Avoid using Caps Lock in web debug sessions.
- Prefer full restart over repeated hot reload when this starts occurring.
- Validate behavior in profile/release mode:
  ```bash
  flutter run -d chrome --profile
  ```

## Suggested Flutter Issue Template
Title:
`[web] HardwareKeyboard assertion crash with synthesized Caps Lock KeyUpEvent on Chrome (stable 3.41.2)`

Body:
- Include **Environment** section above.
- Include **Reproduction Steps** section above.
- Attach full stack trace.
- Mention that app does not use custom keyboard event APIs.

