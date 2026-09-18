[简体中文](./README.zh-CN.md)

# LocateMY

LocateMY is being rebuilt as an Android-only Flutter application. The active rewrite lives on the `Rework` branch; the legacy implementation remains on `main` for history only.

## Requirements

- Flutter 3.47.2 (stable)
- Dart 3.13.2 (included with Flutter)
- Android Studio with the Flutter plugin, or VS Code with the Flutter and Remote - SSH extensions
- Android SDK and Platform Tools
- An Android emulator or a paired physical Android device

Flutter and the Android SDK are machine-level prerequisites. They are not stored in this repository. Android Studio can restore the project's Dart packages and Gradle dependencies after the SDKs and Flutter plugin are installed.

## Clone and install dependencies

```bash
git clone https://github.com/chewjs-wm25/LocateMY.git
cd LocateMY
git switch Rework
flutter pub get
flutter doctor -v
```

Confirm that `flutter --version` reports Flutter 3.47.2 before developing or building.

## Android Studio

1. Clone the repository and switch to `Rework`.
2. In Android Studio, select **Open** and choose the repository root, not the `android` directory.
3. Allow Pub Get and Gradle Sync to finish.
4. Select an emulator or connected Android device and click **Run**.

No project-specific SDK path or IDE configuration is committed. Android Studio uses the Flutter and Android SDKs configured for that workstation.

## VS Code over Remote SSH

1. Connect to the Arch Linux host with Remote - SSH and open the repository root.
2. Install the recommended Flutter extension on the SSH host when VS Code prompts you.
3. Run `flutter devices` in the remote terminal and select the Android device shown in the VS Code status bar.
4. Press `F5` to build, install, and start a debug session using `.vscode/launch.json`.

All Flutter and ADB commands in a Remote SSH window run on the remote host. The phone must therefore be paired with that host.

## Build and run on a wireless Android device

Check the connection and copy the current Flutter device ID:

```bash
adb devices
flutter devices
```

Build, install, and attach the debugger in one command:

```bash
flutter run --debug -d <device-id>
```

For the currently paired test phone, the command may be:

```bash
flutter run --debug -d 'adb-R5CRA19F7ZY-U61Nug._adb-tls-connect._tcp'
```

The mDNS device ID can change, so always prefer the latest value from `flutter devices`.

To build an APK without installing it:

```bash
flutter build apk --debug
```

The output is `build/app/outputs/flutter-apk/app-debug.apk`.

## Hot Reload

While `flutter run` is active:

- Press `r` for Hot Reload.
- Press `R` for Hot Restart.
- Press `q` to stop the application.

In VS Code, start the application with `F5`, then use **Flutter: Hot Reload** from the Command Palette or the Hot Reload button in the debug toolbar. Hot Reload preserves app state; use Hot Restart when a change cannot be applied while preserving state.

## Troubleshooting wireless debugging

If the device is missing or offline:

```bash
adb kill-server
adb start-server
adb devices
flutter devices
```

If necessary, pair and connect again using the pairing and debugging ports displayed by Android's **Developer options > Wireless debugging** screen:

```bash
adb pair <phone-ip>:<pairing-port>
adb connect <phone-ip>:<debug-port>
```

ADB pairing is granted per development machine and cannot be shared through GitHub. A teammate who wants to use the same phone must pair it separately from their workstation.

If dependency or build behavior differs between machines, first verify `flutter --version`, then run:

```bash
flutter clean
flutter pub get
flutter doctor -v
```

## Quality checks

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

The same checks run on GitHub Actions for pushes and pull requests targeting `Rework`.
