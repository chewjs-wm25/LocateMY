# 文档
- supabase table sql structure: docs/real_supabase_tables

# 备注
- 本应用仅设计给 Android/iOS，用 SM A528B 运行

# 运行（环境坑：/home 只读，仅工作区可写、可持久）
- SDK 副本在 `.flutter-sdk`（fvm 原件只读不可用）
- 可写 Android SDK 在 `.android-sdk`（sdkmanager 已装 platform-36/build-tools/NDK）
- flutter 覆盖 local.properties：先 `flutter config --android-sdk $PWD/.android-sdk`（配置存 `.xdg-config`，需 XDG_CONFIG_HOME）
- 运行命令：
```sh
export HOME=$PWD/.fakehome GRADLE_USER_HOME=$PWD/.gradle XDG_CONFIG_HOME=$PWD/.xdg-config FLUTTER_SUPPRESS_ANALYTICS=true ANDROID_HOME=$PWD/.android-sdk
$PWD/.flutter-sdk/bin/flutter run -d adb-R5CRA19F7ZY-U61Nug._adb-tls-connect._tcp
```
- 签名冲突时先 `adb uninstall com.locatemy.assignment.app`
