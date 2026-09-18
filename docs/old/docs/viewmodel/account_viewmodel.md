# 视图模型层：账户组件

## 状态定义
- `user`：当前 `User` 对象（游客模式下为 null）。
- `authStatus`：未验证、验证中、已验证。
- `preferences`：`UserPreferences` 对象。
- `errorMessage`：用于 UI 错误处理。

## 命令 / 方法
- `signInWithMagicLink(String email)`：触发 Supabase 身份验证。
- `signOut()`：清除会话和本地状态。
- `updatePreferences(UserPreferences newPrefs)`：将更改持久化到 Supabase。
- `backupGuestData()`：（内部方法）处理非登录用户的本地存储。

## 数据转换
- 将 Supabase `User` 元数据映射到领域层 `User` 模型。
- 在触发 API 调用前验证邮箱格式。
