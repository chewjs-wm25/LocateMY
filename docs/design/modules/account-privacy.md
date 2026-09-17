# Account Privacy（已取消）

> Retired — 2026-09-17；Issue #31 / ADR 0017。

独立模块、PRIVACY-001/002、participant、AccountScope 状态机、逐 Owner 清理、证明及持久化屏障已取消。
生产代码、fake 和协议专用测试移除；没有替代安全协调模块。业务页面按普通 Flutter 生命周期结束。
退出执行 SDK 当前设备 signOut，成功回登录，失败普通重试；不删除云端记录、公共缓存或预算 JSON。
参见 [当前架构](../system/architecture.md) 与 [ADR 0017](../../adr/0017-minimal-account-and-online-user-records.md)。
