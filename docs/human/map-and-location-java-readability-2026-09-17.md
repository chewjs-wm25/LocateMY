# Map / Location Java 可读性重构验收记录

日期：2026-09-17  
范围：`lib/features/map_location/` 及 `test/features/map_location/` 的手写 Dart。  
依据：[Map / Location Development Contract](../design/features/map-and-location.md)、[开发规范第 7 节](../design/development-standard.md#7-java-阅读习惯与-dart-可读性约束)与 Issue #25。

## 重构结果

完成。公开入口 `package:locatemy/features/map_location/map_location.dart`、冻结的 `LOCATION-001` / `LOCATION-002` declaration、调用方式、结果类型、异步顺序及账户/同步语义均未改变。

已盘点的生产文件包括公开入口、`src/domain/` 的 2 个文件、`src/application/` 的 5 个文件、`src/data/` 的 2 个文件与 `src/presentation/` 的 4 个文件；已盘点的专属测试包括 coordinator、adapter、layer、storage、remote adapter、diagnostics、page 与公开类型测试。模型、接口和多数 Widget 声明原本已经符合规范；本次的安全改写集中在：

- Geoapify 与 SQLite/Supabase Adapter：将多步 `map` / ternary / switch expression 处理改为具名局部变量、普通循环和 `switch`；远端错误分类、序列化字段和返回值保持不变。
- `LocationService`：为比较角色、客户端幂等键和本地记录移除建立具名 helper；将队列筛选、隐藏图层结果和离线删除错误转换改为顺序清晰的控制流。串行 Future 链保留，并在代码旁说明其确保持久化操作逐个执行的必要性。
- `MapViewModel` 与输入对话框：拆分合并状态字段与局部变量；以穷尽普通 `switch` 取代结果赋值的 switch expression；将坐标和名称校验提取为具名步骤。保留 Flutter Widget 树、`Timer`、`Stream.listen`、`setState` 与 Navigator 的简短框架回调，因为它们是声明式 UI / 生命周期所必需的写法。

## 兼容性与验证

修改前基线：`flutter test test/features/map_location`，37 项测试通过。

修改后，在当前工作区执行：

```text
dart format lib/features/map_location test/features/map_location
flutter analyze lib/features/map_location test/features/map_location
flutter test test/features/map_location
flutter build apk --debug
git diff --check
```

结果：Map 目标范围静态分析无问题；Map 专属测试 37/37 通过；debug APK 已生成；diff 检查无空白错误。全仓 `flutter analyze` 另报告 21 条既有 `prefer_initializing_formals` 信息，均位于 Account Privacy、其测试或设备工具，未涉及本次范围。构建仅出现 Gradle 对未来 Java native-access 要求的非失败警告。

本任务是等价可读性重构，不重新执行真实 Supabase、设备或跨 Feature 联合验收；本次 Widget 测试覆盖地图、坐标输入、收藏、搜索、图层、隐私 Navigator 与中英文 200% 字体路径。既有 Contract 记录 Map / Location 为 `Implemented`，本报告不重复判定该状态，也不授予 `Integrated`。

## 集成与协调

本期集成：不适用；没有变更共享 `lib/app/`、公共 Interface declaration、Schema、迁移、依赖或其他 Feature。

后续集成：不适用；本次没有新增待接线项。既有 Wave 5–7 分析和图层提供方联合接入仍按 Map / Location Contract 的责任表执行。

## 当前阻塞

无。工作区存在其他任务的既有修改与未跟踪文件，均未恢复、删除或混入本次 Feature 范围。
