# Wave 2 开发准备（2026-09-16）

范围：Account Privacy，Owner A。设计状态为 Ready for Development，尚未实现；未授予 Integrated。

Wave 1 两份 owning contract 已记录 Implemented，验收分配没有截至 Wave 2 到期的联合事项。本次依据权威契约检查进入条件，没有重新执行 Wave 1 验收或读取既有人工报告。

已在 [Account Privacy 契约第 5.1/5.2 节](../design/modules/account-privacy.md#51-wave-2-验收分配2026-09-16) 固定全部验收场景、依赖分类、证据责任、后续 Owner 与期限，并同步 [HTML 阅读版](account-privacy.html)。

开发顺序：公开入口及 declarations/fake → 真实状态机和八项关闭协调 → 真实 AUTH-001 与 Auth participant → 公开调用 harness、真实调用和 Owner A 设备证据 → 格式、分析、测试、debug APK → 按规范报告完成状态。

本期只允许明确认证的同账户 opened；close 开始立即 closing，缺项、错身份或部分清理不能 closed，失败可恢复同一旧范围。未来模块 fake 仅用于测试，不得作为生产成功证明。

后续集成：Shell 门控、退出顺序及范围切换 Wave 3（A）；Map participant Wave 4（A）；Cost/Hazard Wave 5（B/A）；Infrastructure/Property/Account Center Wave 6（B/B/A）；全部八项清理及 A→B 隔离 Wave 7（A 主责、B 参与）。持久存储故障和进程重启证据在实际存储所属 Wave 补齐。

当前开发准备阻塞：无。所有 Wave 2 本模块验收证据仍待开发取得，不能据此宣告 Implemented 或 Wave 2 完成。此次只修改准备文档，未修改应用代码或执行真实登录测试。

验证：Markdown/新生成 HTML 标题数、全部 Dart declaration blocks 一致；链接按导出目录转换；git diff --check 通过。HTML 采用可横向滚动的表格/代码布局，未执行设备视觉验收。
