# Infrastructure Coverage Wave 6 实现验收

本期为 Issue #25 规范下的 Infrastructure Coverage Feature；Issue #31 精简设计优先。实现以公开页面、fetch/compare/summary、权重读取/保存验证。基线 `1e33cee47189f6475a62ed0891a8c22d26d654e2`；源码和 APK 指纹见同目录 JSON。Luna High 独立审查由主 Agent 随后执行，Integrated 仍待项目负责人批准。

## 实现与数据边界

坐标伪造分数原型已替换为真实 Geo → read_infrastructure_inputs 原始行政区输入 → 全国同年有效参照百分位；交通直接消费同一 PublicTransportation canonical 结果。供水/供电保留有效零，人口按同年或最近两年上一期，原始 population_district 单位千人转人数（[官方变量定义](https://data.gov.my/data-catalogue/population_district)）。缺失不补零；基础可用项少于3/5时 ICI 为 null，权重不能改变这个门槛。内部保留完整精度，末次显示四舍五入。

账号三权重为1–10整数，默认5；在线SDK owner-only存取。合法草稿只在页面即时预览，明确未保存；保存失败保留草稿，可重试/恢复。A/B与summary固定中性5，分项不受权重影响。SDK换号后旧权重store拒绝，新账号重新读取；业务树按现有账号登录导航门控建立。

SQLite仅保存原始公共输入与坐标行政语境，3日有效，无账户/权重/地点名称；刷新失败读取尚有效缓存，不延长期限；较旧请求不能覆盖新缓存。页面/VM dispose与位置变更忽略晚到结果。

开发Supabase真实现况：schools_district有3977行，并非目录旧称完全缺失。Petaling的hospital_beds无记录；schools最新2025，teachers/enrolment最新2022；医疗和教育当前按必要输入缺失处理，不猜测地区或组成。2026-09-17真实交通成功时可用供水/供电/交通构成ICI；设备实际当前日期不保证GTFS日期范围内，允许如实Unavailable，不回退分析日期。没有导入新政府资料。

## 验证

- `flutter test test/features/infrastructure_coverage --reporter expanded`：17项通过。覆盖公开公式/原始统计、缺失/零/60%、全国百分位、人口年份、教育both-sex、canonical交通请求、权重preview/save失败重试/恢复、旧请求/dispose、SQLite有效期、刷新失败不续期/过期响应不覆盖、Adapter无权限/格式/范围与恢复、320px小屏200%Widget。
- `flutter test --reporter expanded`：全仓290项通过，12项显式live opt-in跳过；随后新增验证仅针对本Feature重复（最终Feature17项）。
- `flutter analyze`：无问题；`dart format`与`git diff --check`通过。
- `python tool/verify_infrastructure_live.py`：真实登录账号+受控临时第二账号，真实Geo/RPC/Transit、三权重1/10边界保存读取、缺省5、跨号select空/写拒绝、匿名拒绝、非法范围拒绝、换号新读取/旧store拒绝及恢复原权重通过；临时账号finally删除。秘密仅在运行环境；证据日志已清洗；日志归档使用`.txt`（运行输出原`.log`保留在build目录）。
- `python tool/verify_infrastructure_devices.py --devices emulator-5554`：隔离application id的真实生产页面/服务/路由debug APK，APK秘密扫描通过；真实账号经loopback运行时注入，不在APK内。单点中文、页面内语言切换、离线公共缓存、恢复、中性A/B、英文、200%字体、读屏语义UI树、真实退出门控；图/XML/日志及版本指纹见同目录。
- Penpot MCP实际读取/导出 `09 · 基础设施`（f8bc3597-5a95-809e-8008-a3fa95046be3），校对#F6F8FB背景、#0B1F44 ICI卡、白色分项/#D9E0EA 1px边框/16圆角/右值、#FFF3DE权重卡及#B76E00缺失提示。分项缺失最后修正为“—”并集中列缺少资料项；对应最终APK只复验启动、中英文和缺失呈现，不重复无逻辑变化的全部设备流程。完整流程JSON保留原源码指纹，presentation JSON标记最终源码指纹。小屏放大字体允许垂直伸展。

TDD逐片记录：第一公开公式测试red为evaluate不存在，green真实公式使100/0/60得53；刷新缓存不续期red期望2次write实际4次，green仅真实取得写缓存；过期请求red新结果后仍4次write，green generation拒绝旧缓存覆盖；最新有效百分比red为Partial，green跳过无效新记录后保留有效旧零/百分比。其余确定性/Widget/live测试用于补齐验收和回归，并未声称每个已有行为均有新red。

## 分项状态

1. 模块实现：实现及本模块证据已交付，等待 Luna High 独立判定 Implemented；适用生产能力、公开行为、SDK/缓存/设备与质量证据已交付。
2. 本期集成：真实Geo/Transit/RPC/账号SDK/应用Infrastructure路由、A/B及退出门控通过。生产传入同一transportation实例，同坐标/日期live结果一致。
3. 后续集成：首页完整摘要消费者由A接入summary，中性结果由B提供，最迟Wave6；B提供方子项已验证。Integrated及完整Wave完成不自动宣告。
4. 当前阻塞：无实现验收阻塞；独立 Luna High 审查仍待主Agent执行。当前真实政府组成缺失是合法结果，不冒充服务覆盖或资料成功。

Java阅读习惯审查：本期手写Dart使用显式类型、完整函数体、if/for、构造注入与初始化列表，结果不可变。保留Flutter Widget条件集合、SDK callback、nullable访问及const Widget属于框架/空安全需要；必要UI文案条件表达式为单步选择，不是嵌套业务控制。生成代码未修改。Supabase security advisor无本期新增对象问题；既有PostGIS/维护表提示由现有风险登记处理，不扩张本Feature范围。

环境限制：当前仅可用Android模拟器；owning契约/标准未要求本Feature强制Owner A实机，主Agent确认按可用模拟器验收，没有自增不可用实机阻塞。
