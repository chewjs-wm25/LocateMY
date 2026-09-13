# 应用壳层（AppShell）

代码：`lib/app/views/app_shell.dart`、`lib/main.dart`

## 已完成

- Supabase 初始化和全局 `MultiProvider` 注入。
- 根据 `AuthViewModel.isAuthenticated` 在登录页与主应用之间切换。
- 首页、地图两个底部导航 Tab，使用 `IndexedStack` 保留页面状态。
- 中英文切换；首页提供带 1 分钟冷却的手动刷新。
- 账户中心入口。

## 未完成/差异

- 没有声明命名路由或深链路，子页面均使用 `MaterialPageRoute`。
- 旧模块文档中的更多一级导航并不存在；分析页面实际从地图报告面板进入。
- 主题偏好没有用户级持久化，当前只使用应用固定浅色主题。

