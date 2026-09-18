# Issue #31 实现与验收记录

2026-09-17；本地工作区执行。追踪：[Issue #31](https://github.com/chewjs-wm25/LocateMY/issues/31)。
此次保留开始前的未提交修改；没有重置工作区、提交或推送，也没有关闭 Issue。

## 已调整范围

- Auth 直接消费 SDK currentSession／onAuthStateChange，基础注册、登录、当前设备退出；移除验证页、自建过期管理与远端身份复核。退出时也接受 SDK 身份事件；身份已清除即完成当前设备退出，远端请求失败不恢复假身份，新 SDK 身份则不误报退出成功。
- 删除 Account Privacy 模块及其状态机、participant、屏障、证明和专属测试。
- App 改为首页／地图 Tab、普通 Navigator 与地点回调。MaterialApp 普通路由栈按账号重新创建，换号／成功退出结束旧页面和根弹窗；失败保留当前身份与普通反馈。
- 地图收藏只在线保存、读取和删除；失败不会缓存待写记录或在恢复网络时重放。保留地图 provider、分类图标、A/B、合法地点验证与公共分析。
- 首页、设施、交通和隐患使用原有业务服务与页面，通过普通生命周期忽略晚到结果；保留来源口径、公式、公共缓存和读写归属。
- 已同步系统设计、owning 契约、Schema Catalog 和 16 份 HTML。预算 JSON v1、房产在线照片／回收站／风险快照等尚未实现的 Feature 只修订后续设计，未标记完成。

## 验证证据

| 检查 | 结果／实际边界 |
| --- | --- |
| Flutter 静态分析 | 无问题（最终认证修正后再次通过） |
| 原有业务与 Widget 测试 | 保留有效公式／地理／数据质量测试；新增登录门控、换号结束页面与根弹窗、退出失败保留页面、单点／A/B 路由输入与返回、断网收藏不重放测试。最终全量 206 项通过、9 项 opt-in live 跳过；opt-in 测试另行注入本地凭据执行，真实测试用例共 8 个通过（每个用例可包含多个用户动作） |
| 真实 Supabase 只读与账号 | 5 个测试用例通过：SDK 无邮箱确认注册／直接进入已登录状态、登录／cached identity／当前设备退出、首页真实 RPC 与 SQLite 公共缓存保留、交通 RPC 与只读权限、Geo 候选与权限 |
| 真实在线收藏与隐患 | 3 个测试用例通过：收藏在线保存／重开读取／删除及另一账号读写拒绝；五类隐患、作者修改限制、投票／撤回、2 km 包含边界与排除已处理。隔离临时测试账号已清理；只清理本轮测试记录 |
| Android 模拟器 | 生产 debug APK 成功构建／安装／启动；双语切换、凭据登录、首页→地图、地图工具栏与隐患图层、强制停止后重新启动仍进入已登录页面。账号与密码不保存在截图和报告中；最终 APK 额外通过合法坐标→分析目录→交通页、系统返回交通→目录→地图、重启保持登录、设备退出返回登录；已确认地图无取消的适配度提示 |
| 新 migration | 本地 PostgreSQL 成功应用；事务测试后 rollback：不完整 available 快照被拒、完整快照可保存、普通字段编辑保留、实际坐标变化清空旧快照并设 unavailable、旧偏好表 authenticated 权限撤销 |
| HTML | 由权威 Markdown 生成，标题数量与 fenced code 数量核对；移动端样式支持表格／代码横向滚动 |
| GPT‑5.6 Luna | 最终复查通过，无阻断／高优先问题。旧本地化残留已清理；正常退出仍有新 SDK 身份时误报成功的问题已修正，相关测试覆盖 SDK 事件与等待期间换号 |

## 数据部署与后续范围

新增 `20260917085335_simplify_online_records.sql` 是前向 migration，保留历史数据与旧文件；没有向远端部署 schema migration。开发项目认证配置仅按本 Issue 要求设置 `mailer_autoconfirm=true`（关闭邮箱确认），Management API 与公共 Auth settings 的 readback 均为 true；随后真实 SDK 注册测试通过。
本地 `migration up` 遇到既有 GTFS 表已存在的历史登记差异，未重置或删表；在该失败后单独应用并登记本轮 migration，单独验证其约束。
本地在线业务测试的边界数据不完整，因此上述在线业务证据来自现有真实开发 Supabase；本地 SQL 测试覆盖新 migration。

SQLite 删除的仅废弃 `map_saved_records` 私有收藏缓存；保留原库内公共设施缓存、首页公共库和语言 KV。
预算 Datafile 与房产完整业务、真实照片 Storage／回收站联合验收属于后续 Feature，不以本次 SQL 约束测试冒充已实现。
注册要求目标 Supabase 关闭邮箱确认；本次已同步现有开发项目。客户端无 session 时显示普通注册失败，不展示验证流程。
当前不自动宣称 Integrated；审批状态由项目负责人决定。

认证配置使用 [Supabase 官方 Management API](https://supabase.com/docs/reference/api/v1-update-auth-service-config)；仅调整邮箱自动确认，不更改历史账号或远端 schema。

## 后续 Wave 5 Crime & Security（2026-09-17）

治安模块本期责任按 Issue #25 达到 Implemented；真实 Geo/地图/Auth/只读 RPC 联合路径、Owner A Android 和 Owner B 模拟器均通过，GPT‑5.6 Luna High 规格/规范审查无生产阻断。详见[owning contract](../features/crime-and-security.md)及[独立验收报告](../../human/crime-and-security-wave5-acceptance-2026-09-17.md)。这是后续新增模块证据，不替换本页此前 Issue #31 执行记录。房产消费 B / Wave 6 待接入，Integrated 未自动批准。

## 全模块集成（2026-09-18）

此前未实现／后续描述保留为当时记录；当前 Cost/Budget、Socio、Infrastructure、Property 与 Account/Map/Crime/Hazard 均已真实装配。地图五项摘要替换永久不可用占位；Budget/Socio/Cost 成功切换联合 live、Property 风险／照片／回收站、Infrastructure canonical Transit 验证通过。当前证据与 GPT‑5.6 Luna High 双轴结论见[全模块报告](../../human/integration-2026-09-18.md)，不自动授予 Integrated。
