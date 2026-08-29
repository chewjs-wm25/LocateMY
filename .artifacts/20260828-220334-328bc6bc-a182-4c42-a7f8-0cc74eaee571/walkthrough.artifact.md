# LocateMY 文档重组说明 (Walkthrough)

我已经成功地将 LocateMY 项目的文档重组为基于 MVVM 架构的组件化结构，并已将所有内容翻译为中文，确保了术语的一致性。

## 重组摘要
文档现在按照 MVVM 的四个核心层级进行划分，每个功能模块都被拆解到相应的层级中，以指导后续开发。

### 1. 架构概览
- [mvvm_structure.md](file:///D:/Work/Mobile Application/Assignment/docs/architecture/mvvm_structure.md): 定义了项目的整体结构、各层职责以及响应式数据流。

### 2. 视图层 (View Layer)
包含 UI 组件、布局结构以及每个模块的具体数据可视化要求。
- [cost_of_living_view.md](file:///D:/Work/Mobile Application/Assignment/docs/view/cost_of_living_view.md): 直方图与饼状图。
- [infrastructure_view.md](file:///D:/Work/Mobile Application/Assignment/docs/view/infrastructure_view.md): 用于 ICI 的雷达图。
- [crime_security_view.md](file:///D:/Work/Mobile Application/Assignment/docs/view/crime_security_view.md): 折线图与地图。
- 以及气候、交通、社会经济和账户模块的相关视图文档。

### 3. 视图模型层 (ViewModel Layer)
记录了业务逻辑、状态管理和数据转换流程。
- [infrastructure_viewmodel.md](file:///D:/Work/Mobile Application/Assignment/docs/viewmodel/infrastructure_viewmodel.md): 详细说明了 ICI 的归一化和加权逻辑。
- [account_viewmodel.md](file:///D:/Work/Mobile Application/Assignment/docs/viewmodel/account_viewmodel.md): 处理身份验证状态和偏好设置。

### 4. 模型层 (Model Layer) 与 仓库层 (Repository Layer)
定义了数据结构（实体/DTO）以及数据获取策略。
- [cost_of_living_repository.md](file:///D:/Work/Mobile Application/Assignment/docs/repository/cost_of_living_repository.md): PriceCatcher 数据的缓存策略。
- [account_repository.md](file:///D:/Work/Mobile Application/Assignment/docs/repository/account_repository.md): 与 Supabase Auth 和数据库的集成。

## 新增内容与改进
- **术语统一**：建立了[翻译术语表](file:///D:/Work/Mobile Application/Assignment/.artifacts/20260828-220334-328bc6bc-a182-4c42-a7f8-0cc74eaee571/translation_glossary.artifact.md)，确保了所有层级文档中“状态 (State)”、“命令 (Command)”、“数据转换 (Data Transformation)”等词汇的统一使用。
- **账户模块**：完整集成了游客模式、魔术链接登录以及基于 UID 的社交功能防刷机制。
- **数据可视化**：为每个视图组件明确了经过研究验证的可视化方案（如基尼系数使用仪表盘，交通密度使用热力图）。

## 验证结果
- **目录结构**：确认 `docs/` 下包含 `view/`, `viewmodel/`, `model/`, 和 `repository/` 子目录。
- **组件覆盖**：所有 7 个模块（包括账户模块）在每个层级都有对应的文档。
- **技术细节**：文档包含了状态定义、方法签名以及 API 映射策略。
