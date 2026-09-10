[English](./README.md)

# LocateMY

LocateMY 正在被重建为仅支持 Android 的 Flutter 应用。新的实现位于 `Rework` 分支；旧的 `main` 分支仅保留作历史记录。

## 环境要求

- Flutter 3.47.2（stable）
- Dart 3.13.2（随 Flutter 提供）
- 安装了 Flutter 插件的 Android Studio，或安装了 Flutter 与 Remote - SSH 扩展的 VS Code
- Android SDK 与 Platform Tools
- Android 模拟器或已配对的 Android 真机

Flutter 和 Android SDK 属于每台开发机的全局前置环境，不会存放在仓库中。安装 SDK 和 Flutter 插件后，Android Studio 可以自动恢复项目的 Dart 包与 Gradle 依赖。

## 克隆并安装依赖

```bash
git clone https://github.com/chewjs-wm25/LocateMY.git
cd LocateMY
git switch Rework
flutter pub get
flutter doctor -v
```

开发或构建前，请确认 `flutter --version` 显示 Flutter 3.47.2。

## Android Studio

1. 克隆仓库并切换至 `Rework`。
2. 在 Android Studio 中选择 **Open**，打开仓库根目录，不要单独打开 `android` 目录。
3. 等待 Pub Get 和 Gradle Sync 完成。
4. 选择模拟器或已连接的 Android 设备，然后点击 **Run**。

仓库不会提交项目专属的 SDK 路径或 IDE 配置。Android Studio 会使用该开发机中已经配置好的 Flutter 与 Android SDK。

## 通过 VS Code Remote SSH 开发

1. 使用 Remote - SSH 连接 Arch Linux 主机并打开仓库根目录。
2. VS Code 提示时，在 SSH 主机端安装推荐的 Flutter 扩展。
3. 在远程终端运行 `flutter devices`，并在 VS Code 状态栏选择显示的 Android 设备。
4. 按 `F5`，通过 `.vscode/launch.json` 构建、安装并开始调试。

Remote SSH 窗口中的 Flutter 和 ADB 命令均在远程主机上运行，因此手机必须与远程主机完成配对。

## 编译并运行到无线 Android 真机

检查连接并复制当前 Flutter 设备 ID：

```bash
adb devices
flutter devices
```

用一条命令完成 Debug 编译、安装和调试器连接：

```bash
flutter run --debug -d <设备ID>
```

对于当前已经配对的测试手机，命令可能是：

```bash
flutter run --debug -d 'adb-R5CRA19F7ZY-U61Nug._adb-tls-connect._tcp'
```

mDNS 设备 ID 可能发生变化，因此应优先使用 `flutter devices` 最新显示的值。

只构建 APK 而不安装时执行：

```bash
flutter build apk --debug
```

产物位于 `build/app/outputs/flutter-apk/app-debug.apk`。

## Hot Reload

当 `flutter run` 正在运行时：

- 按 `r` 执行 Hot Reload。
- 按 `R` 执行 Hot Restart。
- 按 `q` 停止应用。

在 VS Code 中按 `F5` 启动应用后，可以从命令面板执行 **Flutter: Hot Reload**，或点击调试工具栏的 Hot Reload 按钮。Hot Reload 会保留应用状态；无法在保留状态的情况下应用改动时，请使用 Hot Restart。

## 无线调试故障排查

如果设备消失或显示 offline：

```bash
adb kill-server
adb start-server
adb devices
flutter devices
```

必要时，使用 Android **开发者选项 > 无线调试** 页面显示的配对端口和调试端口重新连接：

```bash
adb pair <手机IP>:<配对端口>
adb connect <手机IP>:<调试端口>
```

ADB 配对授权以开发机为单位，无法通过 GitHub 共享。队员若要使用同一手机，仍需从自己的电脑单独配对。

如果不同机器的依赖或构建行为不一致，请先检查 `flutter --version`，然后执行：

```bash
flutter clean
flutter pub get
flutter doctor -v
```

## 质量检查

```bash
dart format --output=none --set-exit-if-changed .
flutter analyze
flutter test
flutter build apk --debug
```

GitHub Actions 会对 `Rework` 分支的推送以及以该分支为目标的 Pull Request 执行相同检查。
