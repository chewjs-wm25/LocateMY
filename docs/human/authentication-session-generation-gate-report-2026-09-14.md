# Authentication & Session — Generation Gate Report

> 报告 ID：`GGR-AUTH-2026-09-14-01`  
> 日期：2026-09-14  
> 请求：为 Authentication & Session 生成 Issue #22 定义的 Development Documentation Package PDF  
> Gate 结果：**拒绝（无 PDF 输出）**  
> 权威规范：[GitHub Issue #22](https://github.com/chewjs-wm25/LocateMY/issues/22)；[ADR 0014](../adr/0014-version-locked-pdf-development-documentation-packages.md)

## 结论

本次请求不能生成任何 PDF，包括评审、草稿或部分 PDF。Issue #22 明确规定：任一硬门禁失败时，唯一输出只能是本结构化 Generation Gate Report；PDF 不能被用作尚未派工的评审材料。

Authentication & Session 的 owning design 已是 `Ready for Development`，但实现者未分配；此外，包所需的锁定源集与适用数据契约投影尚未建立。这些问题均为 fatal，不能由生成器自行补全或选择处理方式。

## 已检查的输入

| 输入 | 观察结果 | 结论 |
| --- | --- | --- |
| System baseline | `5d11769`，系统设计为 `Baselined` | 通过 |
| Owning Feature design | `docs/design/features/authentication-and-session.md`，状态为 `Ready for Development` | 通过 |
| Capability 范围 | `AUTH-01`、`AUTH-02`、`AUTH-03`、`ACCOUNT-07` | 已识别 |
| Calculation Specification | Feature 明确写明“没有自定义指数或公式” | 可在未来锁定源集中按 `Not Applicable` 记录，不是当前阻塞 |
| Data dependencies | `auth.users`（外部身份库）与 `profiles`（项目表） | 适用，必须有各自的数据契约投影 |

## Fatal findings

| Gate ID | 严重性 | 受影响的来源 / 要求 | 观察到的事实 | 所需解除条件 | 决策 Owner | 不受影响的工作 |
| --- | --- | --- | --- | --- | --- | --- |
| `GATE-IMPLEMENTER-UNASSIGNED` | Fatal | Issue #22 User Story 25；`docs/design/features/authentication-and-session.md` | Feature Owner 为“待项目负责人分配”。 | 项目负责人为该实施任务指定学生实现者，并记录该分配。 | 项目负责人 | 继续维护权威 Feature 设计，不得开始人类派工。 |
| `GATE-SOURCE-SET-UNLOCKED` | Fatal | Issue #22 Implementation Decisions：Locked Source Set、Package Manifest | 不存在本包的 Manifest，也没有记录完整输入文件、不可变版本/commit、校验和与读取顺序。系统 baseline 本身不能锁定 Feature、产品事实、Schema Catalog 与接口来源。 | 建立并验证完整 Locked Source Set；Manifest 记录每项来源的 ID、版本或 commit、checksum 和阅读顺序。 | 项目负责人（锁定与发布）；文档生成流程 Owner（校验） | 可继续更新权威来源；不得人工拼接 PDF。 |
| `GATE-DATA-SPEC-MISSING-AUTH-USERS` | Fatal | Issue #22 User Stories 15–16、26；Authentication §5；Schema Catalog `auth.users` | `auth.users` 是本 Feature 的适用外部身份权威，但尚无独立、版本化的 Data & Dataset Contract Specification。 | 从锁定的 Schema Catalog、Feature design 与产品事实投影出 `auth.users` 数据契约；覆盖权威、身份/确认事实、访问边界、安全分类、禁止推断与消费 Capability，且不含凭据或 token。 | 文档生成流程 Owner；产品/架构冲突由项目负责人裁定 | 可继续维护 Schema Catalog；不得把 `profiles` 当作 Auth 的替代来源。 |
| `GATE-DATA-SPEC-MISSING-PROFILES` | Fatal | Issue #22 User Stories 15–16、26；Authentication §5；Schema Catalog `profiles` | `profiles` 是可选注册资料的适用项目表，但尚无独立、版本化的数据契约投影。 | 从锁定的 Schema Catalog 与 Feature design 投影出 `profiles` 数据契约；覆盖行粒度、`id` 与 Auth identity 的关系、owner-only CRUD/RLS、资料失败语义与真实邮箱/确认状态不得由其推导的限制。 | 文档生成流程 Owner；产品/架构冲突由项目负责人裁定 | 可继续维护现有 `profiles` 权威定义；不得把资料失败解释为认证失败。 |

## 生成器不得自行决定的事项

- 不能替项目负责人指定实现者或给予 Development Release 批准。
- 不能把当前工作树、系统基线或单一 Feature 文档擅自认定为完整锁定源集。
- 不能因为 Feature 没有公式就省略适用的数据契约；“不适用”与“尚未提供”不同。
- 不能生成“仅供检查”的 PDF；这会违反 Issue #22 的无草稿/无评审 PDF 规则。

## 重新执行 Gate 的最小前置条件

1. 项目负责人分配 Authentication & Session 的学生实现者。
2. 建立与锁定该包的 Source Set 和 Package Manifest。
3. 生成并通过审查 `auth.users`、`profiles` 两份适用的数据契约投影。
4. 对完整输入运行 Gate；仅全部通过后才可生成 Manifest 与 Feature Implementation Guide PDF。
5. PDF 生成成功仍不等于发布：项目负责人另行批准 Development Release 后，才可将批准的 PDF 放入 `docs/human/`。

## 来源

- [Issue #22](https://github.com/chewjs-wm25/LocateMY/issues/22)
- [Authentication & Session owning design](../design/features/authentication-and-session.md)
- [Schema Catalog](../design/data/schema-catalog.md)
- [设计入口](../design/README.md)
- [ADR 0014](../adr/0014-version-locked-pdf-development-documentation-packages.md)
