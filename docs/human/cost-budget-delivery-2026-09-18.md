# Cost of Living & Budget 本期交付

基线：`32be4bac5c6d68d0e86428c57c58bed3a7e2b89e`。仅实现本 Feature 及必要应用、预算 current 共享接线；等待独立 Luna 审查 Implemented Gate，不宣称 Integrated。

## 本模块

生产入口使用真实 GeographicContext、认证 Supabase RPC、owner-only 在线预算和可选三天 SQLite 公共输入缓存。固定11项篮子按逐月商户双中位数、有效月份平均以及6个月/80%门槛计算；个人净收入与家庭总收入保持独立。不可比较结果、失败重试、临时 CPI、预算 CRUD/current 原子唯一、删除不自动选、真实预算 JSON 文件列表/只读打开均已实现。所有公开集合防御性复制，dispose 忽略晚响应。

验收 seam 固定于公开服务和应用页面，Issue #25 Q2 与本次自主决策授权支持此选择。逐片 TDD 包含生产服务、真实 HTTP Adapter、真目录文件及页面；导出反馈回归使用360px多预案页面，旧尾部反馈不可见 red，顶部成功提示及立即打开 green。

## 真实数据边界

实际 public schema 完整核查发现 cpi_core/index、cpi_state/index 及 inflation 表；没有全国 Headline/Overall 表/RPC，cpi_state 无 Malaysia 全国行。不能把 core 作为 headline。真实临时换算返回 typed unavailable，可修正输入后重试，不写预算。独立成功用例 `1000 × (120 / 100) = 1200` 验证正确公式。

固定篮子 item272、1541、1645 的整个原始 pricecatcher 均无有效观测（不是日期窗口、单位或 premise/lookup 连接过滤导致）；其全国基准缺失。盐 `+-350g` 归一为 `±350g` 后匹配。全国权重不能冻结完整，因此真实覆盖率未知，指数/压力不可用，保留已观察部分金额，不补零或替代价格。完整公式用固定 literal 测试：本地430、全国215、指数200，住房100交通0、净收入1000得到个人53%压力。

已部署前向非破坏 migration：预算 FK 改 auth.users、owner RLS/列级权限、原子 current RPC、只读冻结全国篮子、真实取数 RPC及必要索引。镜像业务列未改写，未导入新数据。真实 RPC 从约20秒优化至207ms（本机一次观测，不承诺所有请求）。权限验收覆盖 owner 成功、另一用户与匿名拒绝、归属不可改写、负数拒绝；QA清理并恢复原current。

## 本期联合与后续

Account 与 Socio 消费同一个 CurrentBudgetReader/store；成功保存立即通知，失败保留选择，轮询相同current版本不打断页面滚动或输入。Account 可进入真实预算管理；Socio 使用家庭总收入，不冒用净收入。真实联合live断言验证家庭总收入8000而净收入3500，切换空家庭收入后Socio位置缺失；Account设备XML验证同一current。联合证据与设备结果列在证据目录。

Home 六类摘要消费由 A 主责、B 参与，最迟 Wave 6；不以当前独立 Cost 页面替代未来 Home 验收。Account/Socio 完整 Wave 6 联验仍按原责任分配执行。本期没有需要用户决策的阻塞；全国 headline 与完整篮子缺失属于如实表达的数据结果。

## 验证

- `dart format ...`；`flutter analyze`：No issues found。
- `flutter test --reporter expanded`：312 PASS，13个需显式凭据的 live 默认跳过；本期live另行执行。
- `python3 tool/verify_cost_budget_live.py`：真实读数/owner allow-deny/current通知/恢复 PASS。
- `python3 tool/verify_cost_budget_build.py`：真实生产 debug APK成功，账号密码与secret key扫描PASS，APK不包含本地测试凭据。
- `python3 tool/verify_cost_budget_devices.py --devices emulator-5554 --resume-files --files-only`：exit0，精确JSON文件/列表/打开、重启可达、退出保留、重新登录同副本打开、Account current PASS。

设备证据为分段运行：首轮CRUD、第二轮A/B/中英文200%与离线恢复、最后文件生命周期。第二轮末尾因driver错误的`adb shell sh -c find ...`列出整个应用目录，错误比较prefs/db变化而失败；已改直接`run-as find budget_exports`并只重跑上述JSON短路径。没有把第二轮整体exit1写成PASS，也没有重复无变化的完整流程。可访问性通过UI语义树/读数与无Flutter异常日志核查，未宣称完成TalkBack实机体验。

Penpot 实际读取 Mobile UI 的05生活成本与UI Foundations，并导出截图核对。使用 SourceSansPro、canvas #F6F8FB、ink #172033、primary #155EEF、hero #0B1F44、16px边距/圆角；按知识库修正原型fixture单位和压力读数，按精简边界不显示技术来源元数据。

[证据目录](evidence/cost-budget-2026-09-18/)。source JSON将代码摘要与构建/设备/live结果关联，最终提交由交付消息提供。
