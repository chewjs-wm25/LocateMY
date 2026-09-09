# 登录页与注册页

代码：`lib/modules/module_b/views/auth/login_view.dart`、`register_view.dart`、
`lib/modules/module_b/view_models/auth/auth_view_model.dart`、`lib/modules/module_b/repositories/auth/auth_repository.dart`

## 已完成

- 邮箱 + 密码登录、注册、表单校验、密码复杂度与确认密码校验。
- Supabase Auth 会话监听、错误本地化、登录/注册加载状态。
- 注册时写入用户名元数据；登录后确保 `profiles` 记录存在。
- 登录/注册页均可切换语言；账户页可退出登录。

## 未完成/差异

- 旧文档描述的 Magic Link 登录未实现，当前是密码认证。
- “游客身份继续”、忘记密码 UI、注销账户未实现；Repository 虽有
  `resetPassword`，但没有页面入口。
- 偏好设置写穿透缓存、游客数据备份、头像编辑未实现。

