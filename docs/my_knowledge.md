# Flutter 课程知识范围

> 本文档用于让 AI 了解我目前学习过的 Flutter / Dart 技术范围。

当需要使用本文档以外的技术时，AI 可以使用，但应考虑我可能尚未学习过，并在必要时优先解释相关概念或选择较容易理解的实现方式。

## Dart

我已学习：

* 基本类型：`int`、`double`、`bool`、`String`
* `var`、`final`、`const`
* Null Safety：`?`、`!`、`??`
* 函数、参数、返回值、Named Parameters、`required`
* `List<T>`、`Map<K, V>` 及基本操作
* `map()`、`List.generate()`、`indexWhere()` 等常见 Collection 操作
* `if / else`、三元运算符、`switch`
* `try / catch / finally`、`throw`
* 字符串处理与基本数值转换
* Class、Field、Constructor、Getter、`factory`、`@override`
* `fromJson()`、`toMap()`
* `Future`、`async / await`
* `StreamSubscription`、`listen()`、`cancel()`
* `RegExp`
* 基础 Debug：`print()`、`log()`

## Flutter 基础

我已学习：

* `runApp()`
* `StatelessWidget`
* `StatefulWidget`
* `State<T>`
* `build()`
* `setState()`
* `initState()`
* `dispose()`
* Widget Constructor 传值
* `MaterialApp`
* `ThemeData`
* `Scaffold`
* `AppBar`

### 常用 Widgets

布局与显示：

* `Text`
* `Icon`
* `Image`
* `Center`
* `Padding`
* `Align`
* `SizedBox`
* `Expanded`
* `Row`
* `Column`
* `Stack`
* `Container`
* `Card`
* `Divider`
* `CircleAvatar`
* `ListTile`
* `Table`

列表与滚动：

* `SingleChildScrollView`
* `ListView.builder`
* `ListView.separated`

输入与表单：

* `TextField`
* `TextFormField`
* `TextEditingController`
* `FocusNode`
* `DropdownButton`
* `CheckboxListTile`
* `RadioListTile`
* `Form`
* `GlobalKey<FormState>`
* Validator
* Input Formatter

按钮与反馈：

* `ElevatedButton`
* `TextButton`
* `IconButton`
* `FloatingActionButton`
* `SnackBar`
* `AlertDialog`
* `showDialog()`
* `showModalBottomSheet()`

异步 UI：

* `FutureBuilder`
* `CircularProgressIndicator`

## Navigation

我熟悉基础 Navigator：

```dart
Navigator.push()
MaterialPageRoute()
Navigator.pop()
```

也了解通过 Widget Constructor 在页面之间传递数据。

## State Management

我学习过：

### StatefulWidget

```dart
setState()
```

### Provider

```text
ChangeNotifier
notifyListeners()
ChangeNotifierProvider
Consumer<T>
Provider.of<T>()
```

## Local Storage

### Shared Preferences

学习过：

```text
shared_preferences
SharedPreferences.getInstance()
getString()
setString()
```

主要用于简单 Key-Value 数据。

### Local File

学习过：

```text
dart:io File
image_picker
path_provider
```

包括：

* 从 Gallery 选择图片
* 获取 Application Documents Directory
* 保存/复制文件
* 检查文件是否存在
* 显示本地图片

## SQLite

使用过：

```text
sqflite
path_provider
```

了解：

* 建立 SQLite Database
* `openDatabase()`
* `onCreate`
* `CREATE TABLE`
* 基础 CRUD
* `query`
* `rawInsert`
* `update`
* `delete`
* 简单 Database Service

## Network & JSON

使用过：

```text
http
dart:convert
intl
```

了解：

* `Uri.parse()`
* `http.get()`
* HTTP Status Code
* `response.body`
* `jsonDecode()`
* JSON List / Map 转换成 Model
* `FutureBuilder`
* Network Error Handling
* `NumberFormat`
* `DateFormat`

## Supabase

使用过：

```text
supabase_flutter
```

了解：

```dart
Supabase.initialize()
Supabase.instance.client
```

以及基本 Database CRUD：

```text
select
insert
update
delete
eq
```

## Map

使用过：

```text
flutter_map
latlong2
```

了解：

```text
FlutterMap
MapOptions
LatLng
TileLayer
MarkerLayer
Marker
```

以及使用 OpenStreetMap Tile 显示地图与 Marker。

## Location

使用过：

```text
location
permission_handler
```

了解：

* Location Permission
* GPS Service 检查与请求
* 前台 Location Tracking
* `onLocationChanged`
* `LocationData`

## 已接触的 Flutter Packages

```text
provider
flutter_localizations
intl
shared_preferences
image_picker
path_provider
sqflite
http
supabase_flutter
flutter_map
latlong2
location
permission_handler
```

## Android 基础权限

接触过：

```text
android.permission.INTERNET
android.permission.WRITE_EXTERNAL_STORAGE
android.permission.ACCESS_FINE_LOCATION
android.permission.ACCESS_COARSE_LOCATION
```

## AI 使用本文档时的理解方式

本文档只表示：

**“这些技术属于我目前已经学习或接触过的知识。”**

它不代表：

* 项目只能使用这些技术
* 未列出的技术不能使用
* AI 必须严格按照这些 API 编写代码
* 项目 Architecture 必须局限于课程示例

如果解决问题需要本文档之外的技术，AI 应根据项目需求正常考虑使用，只需要意识到我可能尚未学习该技术，并在需要时提供相应解释。
