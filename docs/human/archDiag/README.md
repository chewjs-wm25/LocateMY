# LocateMY Architecture Diagrams

本目录提供可独立渲染的 PlantUML 架构图。

- `architecture-overview.puml`：整个项目的简化架构图。
- Feature：`authentication-and-session.puml`、`home-and-relocation-outlook.puml`、`map-and-location.puml`、`cost-of-living-and-budget.puml`、`crime-and-security.puml`、`nearby-facilities.puml`、`public-transportation.puml`、`hazard-reporting.puml`、`socio-economic.puml`、`infrastructure-coverage.puml`、`property-inspection.puml`、`account-center.puml`、`personalized-location-suitability.puml`。
- Shared module：`application-shell.puml`、`account-privacy.puml`、`geographic-context.puml`。
- `theme.puml`：所有图共用的视觉主题；渲染时需与图文件放在同一目录。

每张分层图固定使用以下逻辑层：Presentation、Application、Domain、Data / Integration。组件是设计层面的职责边界，不是对 Dart 文件、类或状态管理方案的强制拆分；实际内部结构仍由各 Owner 决定。跨模块箭头只表示已登记的公开 Interface 或外部 seam，不允许导入其他 Feature 的内部实现。

可使用任意 PlantUML 渲染器打开单个 `.puml` 文件。例如：

```bash
plantuml architecture-overview.puml
```

图的事实来源为 `docs/design/system/architecture.md`、`feature-map.md`、`interfaces.md` 与对应 Feature 开发协作契约。
