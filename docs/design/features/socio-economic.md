# Socio-economic 开发契约

> Owner：B；依赖顺序参考 Wave 6；2026-09-17 Issue #31 修订。
> 状态：实现完成，等待 GPT‑5.6 Luna High 最终验收；Integrated 未批准。

本契约按 [Issue #31](https://github.com/chewjs-wm25/LocateMY/issues/31) 与
[ADR 0017](../../adr/0017-minimal-account-and-online-user-records.md) 修订。
产品事实和公式以知识库为准；字段、权限和 migration 只在
[Schema Catalog](../data/schema-catalog.md) 定义。普通页面传参与具名服务替代通用导航／贡献框架。

产品事实源：[socio_economic](../../knowledge_base/locatemy_product/features/socio_economic.md)。

## 本轮分析页面精简（2026-09-17）

界面按 [UI 精简边界](../../knowledge_base/locatemy_product/ui_design_spec.md#分析页面精简边界2026-09-17) 调整；该节取代本契约中冲突的来源／时间／较旧提示展示要求。
指标、公式、输入、缓存时效和服务可用性不变。保留内部来源与日期用于取数／校验，取消用户页面技术明细，保留简短错误与重试。
验收沿用页面和公开服务边界，核对单点与 A/B 均无技术元数据／重复提示，并回归现有缓存、公式、失败恢复与账户行为。本次已实现并验证对应页面、公式、缓存、公开服务与只读 Adapter；证据见下方本次验收分配。

## 生产行为

行政区家庭收入中位数、州级 P1–P100 分布、收入结构和基尼保留。
SOCIO-02 用户收入位置仅读取当前预算预案的家庭月度总收入；月净收入不能替代。
行政区缺失时只按事实源展示允许的州级参考，ambiguity 不选择默认候选。
A/B 不同年份／版本／缺失状态明确不可比；单位和调查年份可见。
唯一入口 `lib/features/socio_economic/socio_economic.dart`，页面显式地点参数，
具名服务消费 Geo 与预算 current，不消费 Privacy、Shell 或 Suitability。

## 服务与后续联合验收

B 已交付真实分析服务、数据映射与只读 RPC；预算 current 仅读公开 CurrentBudgetReader。完整预算变更页面的联合验收仍待上游实现。
本模块：分位组、单位／年份／缺失、收入位置边界、A/B；联合：Geo 与预算切换后更新，
B 主责、A 页面接线；最迟 Wave 6。在线预案失败不能制造成功的收入位置。

## 生命周期与验收责任

页面只在登录后的业务树内建立；退出成功或换账号后结束旧业务页面，新页面按当前 SDK 用户读取记录。
Widget／ViewModel 在 dispose 后忽略晚到结果。账号记录只在线保存，网络失败显示未保存并允许用户重试；
不建立自动同步、清理屏障或离线队列。公共分析内部保留真实来源、日期与可用性，不以零替代缺失；呈现按本轮 UI 精简边界。

主要验收 seam 为应用页面入口；使用可见内容、动作、导航与保存／读取结果断言。
复用仍有效的公式、地理、Adapter 与存储测试，完成格式、分析、测试、debug APK 构建。
本次重构的统一证据见 [Issue #31 执行检查](../system/issue-31-validation.md)；
设备、真实外部服务证据缺失时不得宣称新版本 `Implemented` 或 `Integrated`。

## 本次开发固定范围与验收分配

测试边界已由项目负责人于 2026-09-17 确认：单点/A-B 页面入口、唯一公开分析服务、真实外部 Adapter。
公开入口为 `socio_economic.dart`；`SocioEconomic.analyse(location, refresh: false)` 返回独立收入、基尼、结构、分布及收入位置；`compare(a,b)` 保留两端并给出逐指标可比性。
`SocioInputsReader.read(state,district)` 是只读 RPC Adapter 边界。预算 current 仅读 Cost 的公开 current 服务，不读私有表；预案 CRUD 不属于本模块。

| 场景 ID / 可观察结果 | 验证归属 | 依赖及用途 | 证据要求 | Owner | 最迟 Wave | 本模块状态 | 联合状态 |
| --- | --- | --- | --- | --- | --- | --- | --- |
| SOCIO-01 行政区收入/基尼、同年优先、独立缺失与州回退 | 两者 | 真实 Geo/RPC；测试 fake 故障 | 服务、页面、live | B；A 接线 | 6 | 已通过；公开服务/页面/live/设备 | 已通过：真实 Geo/Auth/Map 接线 |
| SOCIO-02 完整州分布、插值/精确命中/范围外、current 缺失与失败 | 两者 | 测试预算 current；真实只读 current；完整预算切换后续 | 服务、页面、live 私有读取 | B；A 接线 | 6 | 已通过；边界/插值/真实已保存字段读取 | 完整预算切换待接入，B 主责、A 接线 |
| SOCIO-03 组均值/份额/P40/P80、真实曲线/P50、不补零 | 本模块 | 真实 RPC；独立 worked fixture | 服务、页面 | B | 6 | 已通过；公式/页面/工程检查 | 不适用 |
| SOCIO-04 A/B 年份/边界版本/缺失不可比、保留可用端 | 两者 | 真实 Geo；Map 传参 | 服务、应用路由 | B；A 接线 | 6 | 已通过；公开服务/页面/live/设备 | 已通过：真实 Geo/Auth/Map 接线 |
| SOCIO-05 离线/权限/重试、缓存过期、晚到/dispose/换号 | 两者 | SQLite/SDK/登录页面树 | 服务、页面、真实权限 | B；A 登录树 | 6 | 已通过；公开服务/页面/live/设备 | 已通过：真实 Geo/Auth/Map 接线 |
| SOCIO-06 中英文/读屏/小屏/放大字体/Penpot 风格、工程门槛 | 本模块 | 实际页面与 Android | widget/device、格式、分析、全测试（275 通过，11 个 live gate 跳过）、APK | B | 6 | 已通过；公式/页面/工程检查 | 不适用 |


## 本次验收证据（2026-09-17）

- 测试按已确认边界逐片 red → green；服务覆盖 independent worked fixture、共同年份、州回退、逐项缺失、无月净收入替代、P1/P100/插值/精确命中、部分曲线、A/B 不可比、三天缓存、离线精确坐标回退、失败刷新不延长缓存、过期响应不覆盖缓存。
- 页面与应用路由覆盖单点/A-B、读取变化、短错误/重试、保留官方结果但撤回未确认个人位置、晚到/dispose、小屏/双语/200% 字体/读屏语义。
- 真实 Supabase 验证 Geo→官方 RPC→当前家庭收入；无 current 时临时 provision 仅本账号记录，验证字段 null/恢复后按 id 清理。匿名 RPC deny、镜像写入 deny；五个镜像的 SELECT allow / INSERT UPDATE DELETE deny / anon all deny 已核对。SQL 事务内真实临时记录已验证 authenticated owner allow / other owner deny，事务回滚无残留。
- 独立 DOSM CSV 与真实 RPC 对照已通过五个投影；州收入旧镜像历史 null 中位数行未收录，对照仅有效中位数读数，不补零。本次未修改既有镜像业务数据。
- Penpot board `08 · 社会与经济`（`f8bc3597-5a95-809e-8008-a3fa931ecc50`）已读结构/样式并导出目视核对；使用其 #F5F7FA / #172033 / #667085 / #155EEF / #148F83 / #B76E00 / #D9E0EA、16px 卡片圆角与 Source Sans Pro。官方/估算分组保留，原型示例数字替换为真实读数，按事实源补图与组均值/门槛；A/B 免责声明仅一处。
- 工程与真实设备证据保存在 `build/socio-wave6-evidence/`（忽略凭据与构建物）：format-check.log、analyze.log、all-tests.log、live-test.log/source.json、official-source-verification.json、production-build.log/source.json、device-build.source.json、owner-b-emulator-*.xml/png/verification.json。
- `tool/verify_socio_live.py`、`verify_socio_source.py`、`verify_socio_build.py`、`verify_socio_devices.py --devices <adb serial>` 可复跑；私有凭据仅读本地文件，构建仅 allowlist 公共配置，APK secret scan 已通过。当前设备目标为 Android 36 x86_64 模拟器；不声称额外真机验证。
- 生产源码 SHA-256：`ace7b8e21576ef7ca47d596c962c99414b8fa81cf2158cffd6e5f55dbb068596`；独立 worktree 与 APK 来源匹配。最终 Luna High 审查结果另记；不据本模块验收宣告整个 Wave 6 已完成。

本期集成：真实 Auth/Geo/Map 与只读 current 读取通过。后续集成：完整预算编辑/删除/选择成功的页面通知与 Socio 更新，由 B 主责、A 接线，最迟 Wave 6；上游尚未实现，Wave 6 联合完成不得提前宣告。
