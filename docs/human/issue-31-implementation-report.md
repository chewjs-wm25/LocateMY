# GitHub Issue #31 实施结果

已完成现有 Auth、App 装配、地图收藏、首页、设施、交通和隐患的精简重构，并同步设计 Markdown 与 16 份 HTML。

- 使用 SDK 登录身份与持久会话，保留注册、登录、当前设备退出；开发 Supabase 已关闭邮箱确认，真实注册直接进入应用。
- 删除 Account Privacy、安全清理协调、自建验证／过期管理、通用 Shell 导航／组合框架，以及收藏离线缓存与同步队列。
- 普通 Flutter 路由保留首页／地图、单点与 A/B、分类图层和在线业务；换号结束旧页面与弹窗，系统返回正常工作。
- 保留公共 SQLite 缓存与语言 KV。预算 JSON v1、房产照片／回收站／风险快照等尚未实现能力已修订设计，按后续 Feature 开发。

验证：最终静态分析无问题；全量 206 项测试通过，9 项 opt-in live 跳过并另行执行8 个真实测试用例通过（含多项用户动作）；格式与 diff 检查通过；debug APK 构建成功。设备检查覆盖语言、登录、首页／地图、重启保持登录、合法选点、交通入口、系统返回和当前设备退出回登录。GPT‑5.6 Luna 最终复查通过，发现的问题已修正并补回归测试。

[当前设计 HTML](index.html) · [完整执行检查](../design/system/issue-31-validation.md) · [前向 migration](../../supabase/migrations/20260917085335_simplify_online_records.sql)

SQL migration 已在本地验证，尚未部署到远端。变更保留于当前工作区，没有提交／推送或关闭 Issue。
