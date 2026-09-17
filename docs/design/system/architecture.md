# 技术架构（Issue #31）

> 2026-09-17；ADR 0017 优先于历史基线 5d11769。

应用仍要求登录，Supabase SDK 负责认证、默认持久化与身份变化；项目仅调用注册、登录、当前设备退出及当前用户。
不重复远端核验、不自建失效计时，不建立会话恢复状态机或 Account Privacy。
lib/app/app.dart 装配 SDK、公共缓存与具名业务服务；登录后创建普通页面树，首页／地图双 Tab。
Navigator.push/pop 及明确 location／id／A/B 参数承担页面往返，普通回调完成首页切 Tab、上报后返回与定位。
退出成功／换号结束原账号业务树，Widget／ViewModel dispose 忽略晚到结果；失败普通重试。
没有通用导航意图、binding、贡献发布、槽位或逐 Feature 清理证明。

保留 View → ViewModel → 具名 application service → Domain，外部 Adapter 实现必要 service seam。
跨 Feature 只从唯一公开入口读取必要业务对象；不为形式增加空层或多层结果包装。
地理语境服务仍保留完整候选和来源。地图专属图层接口及 viewport version 保留其真实业务作用。
公式和资料可用性结果保留；中性 A/B 与原有六类业务口径不改变。

账号业务记录在线保存 Supabase，owner-only RLS；公开隐患 authenticated 可读、作者管理、本人唯一票。
照片在线 Storage，权限按实勘 owner。公共政府镜像仍一次性受控导入，Flutter 只读 View/RPC。
SQLite 仅公共分析缓存，KV 语言／简单设置，预算 JSON 应用文件目录导出与读取。
无收藏私有缓存、离线创建／重放、照片待传或跨重启房产草稿。

国际化仍中英文，当前与失败状态均支持，小屏／放大文字／读屏保留。
验收使用应用页面入口外部行为及少量真实 SDK／存储／权限检查；新版本证据见执行检查。
