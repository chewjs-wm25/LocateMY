# 房产新增/编辑页（AddPropertyScreen）

代码：`lib/modules/module_b/views/property/add_property_screen.dart`、
`lib/modules/module_b/view_models/property/property_view_model.dart`、`lib/modules/module_b/repositories/property/security_risk_repository.dart`

## 已完成

- 新增与编辑共用表单；支持名称、价格、评分、备注、水灾历史和季风检查项。
- 可选择已收藏地点，或保留草稿后返回主地图选点。
- 保存时按坐标调用警区匹配，并补充安全分数和附近隐患数量。
- 提交加载状态、基础表单校验和内存草稿恢复。

## 部分完成

- 模型含 `photos`、`mainPhotoIndex`，表单有相关展示结构，但没有完整的相机/相册文件选择与上传链路。
- 草稿和房产档案仅保存在 Provider 内存，应用重启即丢失。

## 未完成/差异

- 房产记录没有写入 Supabase 或 SQLite。
- 没有照片压缩、存储桶上传、权限处理和离线恢复。

