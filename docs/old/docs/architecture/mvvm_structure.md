# LocateMY 双 Module MVVM 架构

LocateMY 使用 **Module-first MVVM**。业务代码先分配给两名协作者各自拥有的 Module，
再在 Module 内按 Model、Repository、ViewModel、View 分层；业务域子目录用于避免同层
文件过度集中。

## 目录与所有权

```text
lib/
├── main.dart
├── modules/
│   ├── module_a/                     # 协作者 A
│   │   ├── models/{map,home,infrastructure}/
│   │   ├── repositories/{map,home,infrastructure,transport}/
│   │   ├── view_models/{map,home,infrastructure,transport}/
│   │   ├── views/{map,home,infrastructure,transport}/
│   │   ├── location_api.dart
│   │   ├── hazard_api.dart
│   │   └── module_a_providers.dart
│   └── module_b/                     # 协作者 B
│       ├── models/{cost_of_living,property}/
│       ├── repositories/{cost_of_living,property,auth,security,socio_economic}/
│       ├── view_models/{cost_of_living,property,auth,security,socio_economic}/
│       ├── views/{cost_of_living,property,auth,security,socio_economic}/
│       └── module_b_providers.dart
├── app/                              # 应用壳、全局状态、跨模块命名路由
├── core/                             # 缓存、Supabase、主题与纯算法
├── shared/                           # 跨模块复用 Widget
├── l10n/                             # 翻译源文件
└── generated/                        # 自动生成代码
```

| Module | 业务归属 | 约占业务代码 |
| --- | --- | --- |
| A | 地图与灾害、首页、基础设施、周边设施、公共交通 | 48% |
| B | 生活开销与预算、房产检查、认证与账户、治安、社会经济 | 52% |

app、core、shared、generated 和 l10n 是公共区，修改前应由双方协调。

## 分层规则

| 层 | 职责 | 禁止 |
| --- | --- | --- |
| View | 渲染、输入、导航、调用 ViewModel | 直接查询 Supabase/SQLite |
| ViewModel | UI 状态、校验、流程编排、错误状态 | 构建 Widget、拼接数据库查询 |
| Repository | Supabase/HTTP/SQLite、缓存、序列化 | 页面状态与导航 |
| Model | 实体、值对象、纯转换或计算 | 网络、数据库、页面生命周期 |

主数据流固定为：

```text
View → ViewModel → Repository → Supabase / HTTP / SQLite
View ← 可观察状态 ← Model/结果 ← Repository
```

- Repository 不得依赖 ViewModel 或 View，Model 不得依赖 Repository/ViewModel。
- Module B 只能通过 module_a/location_api.dart 和 hazard_api.dart 使用 A 的选址与灾害
  公共类型，不得引用 A 的内部 Repository。
- Module A 不直接引用 Module B 的 View；跨模块页面跳转统一使用 app/navigation 中的
  命名路由。Module 内部页面跳转仍可直接构造同 Module 页面。
- 跨模块调用不得修改另一 Module ViewModel 的私有状态。

## 降低协作冲突的约定

- 新业务文件只能加入负责人的 Module；不得重新建立 lib/features 或全局
  models、repositories、view_models、views 目录。
- 每个 Module 在自己的 provider 注册文件增加 ViewModel；main.dart 只组合
  moduleAProviders、moduleBProviders 与两个应用级 ViewModel。
- 新增跨模块页面时由 app/navigation/app_route_names.dart 声明名称，并在
  app_router.dart 注册；业务 View 只调用 Navigator.pushNamed。
- 公共接口坚持最小导出；不得为方便而建立导出整个 Module 的 barrel 文件。
- 测试分别放在 test/module_a、test/module_b；纯算法与应用烟雾测试放 test/core。

## 文档约定

当前路径和数据流以本架构文档、[页面功能状态](../pages/README.md)及
[Data Flow](../data-flow/README.md)为准。docs/human 是重构前的作业回顾材料，为保持
交付原文未做修改，其中 lib/features 和旧测试路径属于历史路径。
