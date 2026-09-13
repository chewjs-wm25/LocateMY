# 仓库层：账户组件

## 数据源
- **Supabase Auth**：魔术链接、会话管理。
- **Supabase Database**：`profiles` 表，`preferences` 表。

## 方法
- `login(String email)`：发送魔术链接。
- `fetchProfile(String userId)`：获取用户元数据。
- `savePreferences(String userId, UserPreferences prefs)`：更新或插入数据到数据库。

## 策略
- **离线同步**：为偏好设置实现写穿透式缓存 (Write-through cache)，以便更改在本地保存并在联网时同步。
