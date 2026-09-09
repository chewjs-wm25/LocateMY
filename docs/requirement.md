# LocateMY 项目依赖环境

本文档记录 LocateMY 的开发、构建和运行依赖。版本信息以项目当前的
`pubspec.yaml`、`pubspec.lock`、Android Gradle 配置和 iOS 工程配置为准。

## 1. 项目基本信息

- 应用类型：Flutter Android/iOS 移动应用
- 包名：`com.locatemy.assignment.app`
- 当前应用版本：`1.0.0+1`
- Flutter 入口：`lib/main.dart`
- 数据库及后端结构说明：`docs/real_supabase_tables.md`
- 目标设备：Android/iOS；Android 测试设备为 Samsung SM-A528B

## 2. 必需开发环境

| 依赖 | 要求 | 当前检查结果 |
| --- | --- | --- |
| Flutter SDK | `3.47.2` stable，项目内置路径为 `.flutter-sdk` | 已具备 |
| Dart SDK | `>=3.12.2 <4.0.0`（来自 `pubspec.yaml` 的 `^3.12.2`） | 当前为 `3.13.2`，满足要求 |
| Android SDK | API 36（compile/target SDK） | `.android-sdk/platforms/android-36` 已具备 |
| Android Build Tools | `36.0.0` | 已具备 |
| Android NDK | `28.2.13676358` | 已具备 |
| Java/JDK | JDK 17 语言目标（Java/Kotlin 编译配置） | Android Studio bundled JDK 可用；建议使用 JDK 17 |
| Gradle | `9.1.0` | 由 `android/gradle/wrapper/gradle-wrapper.properties` 固定 |
| Android Gradle Plugin | `9.0.1` | 由 `android/settings.gradle.kts` 固定 |
| Kotlin Gradle Plugin | `2.3.20` | 由 `android/settings.gradle.kts` 固定 |
| iOS Deployment Target | iOS 13.0 | 由 iOS Xcode 工程固定 |
| Swift | 5.0 | 由 iOS Xcode 工程固定 |

Android 的 `minSdk`、`compileSdk`、`targetSdk` 使用 Flutter SDK 默认值：

- `minSdk`: 24
- `compileSdk`: 36
- `targetSdk`: 36
- `ndkVersion`: `28.2.13676358`

构建 iOS 版本还需要 macOS、Xcode（支持 iOS 13.0 及以上）和 CocoaPods。
当前仓库没有额外的 CocoaPods 依赖声明；Flutter 插件依赖会在执行
`pod install` 或 `flutter build ios` 时生成/解析。

## 3. Dart/Flutter 直接依赖

以下是 `pubspec.yaml` 中声明的直接依赖。括号内为当前
`pubspec.lock` 解析出的实际版本。

### 运行时依赖

| 包 | 声明版本 | 当前解析版本 | 用途 |
| --- | --- | --- | --- |
| `flutter` | SDK | SDK | Flutter UI 与应用运行时 |
| `flutter_localizations` | SDK | SDK | 中英文国际化 |
| `cupertino_icons` | `^1.0.8` | `1.0.9` | iOS 风格图标 |
| `flutter_map` | `^8.3.2` | `8.3.2` | 地图显示及图层 |
| `latlong2` | `^0.10.1` | `0.10.1` | 经纬度数据结构与计算 |
| `fl_chart` | `^1.2.0` | `1.2.0` | 图表展示 |
| `intl` | `^0.20.2` | `0.20.3` | 日期、数字和本地化格式化 |
| `provider` | `^6.1.2` | `6.1.5+1` | 状态管理与依赖注入 |
| `http` | `^1.6.0` | `1.6.0` | HTTP API 请求 |
| `flutter_typeahead` | `^6.0.0` | `6.0.0` | 地点搜索自动补全 |
| `supabase_flutter` | `^2.6.0` | `2.17.2` | Supabase 认证、数据库和 RPC |
| `sqflite` | `^2.3.3+2` | `2.4.3` | 本地 SQLite 存储 |
| `path` | `^1.9.0` | `1.9.1` | 文件路径处理 |

### 开发依赖

| 包 | 声明版本 | 当前解析版本 | 用途 |
| --- | --- | --- | --- |
| `flutter_test` | SDK | SDK | 单元测试和 Widget 测试 |
| `flutter_lints` | `^6.0.0` | `6.0.0` | Dart/Flutter 静态检查规则 |

`pubspec.lock` 应保留在仓库中，以便在不同环境中获得一致的依赖解析结果。

## 4. 外部服务和运行时依赖

应用运行时会访问以下服务，这些不是通过 pub 包安装的依赖：

- Supabase：用户认证、业务数据、数据库查询及 RPC。连接配置目前位于
  `lib/core/api_keys.dart`，数据库表和 RPC 需要按 `docs/real_supabase_tables.md`
  及 `docs/supabase_rpc_setup.md` 配置。
- Geoapify Geocoding API：地点搜索和自动补全。调用代码位于
  `lib/modules/module_a/repositories/map/geoapify_repository.dart`。
- OpenStreetMap Overpass API：周边设施查询，调用代码位于
  `lib/modules/module_a/repositories/infrastructure/facility_repository.dart`。
- 网络连接：地图瓦片、Supabase、Geoapify 和 Overpass 请求均需要可用网络。

不要把生产环境密钥提交到版本库；建议后续将 `lib/core/api_keys.dart` 中的
配置迁移到构建时注入的环境变量或安全配置中。

## 5. 初始化和验证

在项目根目录执行：

```sh
export HOME=$PWD/.fakehome
export GRADLE_USER_HOME=$PWD/.gradle
export XDG_CONFIG_HOME=$PWD/.xdg-config
export FLUTTER_SUPPRESS_ANALYTICS=true
export ANDROID_HOME=$PWD/.android-sdk

$PWD/.flutter-sdk/bin/flutter config --android-sdk $PWD/.android-sdk
$PWD/.flutter-sdk/bin/flutter pub get
$PWD/.flutter-sdk/bin/flutter analyze
$PWD/.flutter-sdk/bin/flutter test
```

运行 Android：

```sh
$PWD/.flutter-sdk/bin/flutter run -d adb-R5CRA19F7ZY-U61Nug._adb-tls-connect._tcp
```

如遇 Android 签名冲突，可先卸载旧包：

```sh
adb uninstall com.locatemy.assignment.app
```

## 6. 当前环境检查备注

- Android SDK、API 36、Build Tools 36.0.0、NDK 28.2.13676358 和 Flutter/Dart
  版本均已在当前工作区检查到。
- 当前环境的 `flutter doctor` 无法启动 ADB daemon（受当前执行环境权限限制），
  不代表项目依赖缺失；连接真机时应确保只有一个可用的 `adb` 服务。
- Chrome、Linux desktop 工具链不是本项目的目标平台依赖；本项目按 Android/iOS
  移动端设计。
