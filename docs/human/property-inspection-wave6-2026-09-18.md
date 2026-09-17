# Property Inspection Wave 6

当前状态：生产实现及必要边界测试已完成，最终设备必要证据已完成，等待 Luna High 最终审查；未授予 Implemented 或 Integrated。

最高公开验收 seam：PropertyInspectionService 与应用页面。Supabase、Storage、相机/系统相册为系统边界。Issue #25 Q2 与本次自主决策授权固定测试范围。Penpot MCP 已读取并 export 档案屏；五屏使用 #F6F8FB 底色、白圆角卡、蓝主按钮与左侧照片封面，当前契约取消历史草稿/待同步/风险刷新行为。

| 场景 | 归属、依赖、责任与期限 | 当前证据 |
| --- | --- | --- |
| 在线新建/编辑/档案/详情与四评分平均 | 本模块B；Supabase真实；Wave6 | 服务测试及live真实CRUD通过；设备在线新增、四评分平均与档案成功 |
| 合法地图返回保留表单 | 本模块+联合；A Map/B Property真实；Wave6 | 真实 Navigator 地图返回保留名称/价格/地址已通过 |
| 创建/实际坐标变化请求完整风险，失败unavailable与旧组清除 | 本模块+联合；B Geo/Crime与A Hazard真实；Wave6 | live完整风险已保存；同点时间不变；服务失败及错坐标red→green通过 |
| 查看/档案/重启不重算与晚到dispose | 本模块B；测试fake系统边界；Wave6 | 无刷新入口；同点/读取与晚到 dispose 测试通过；模拟器重启后读取同一持久风险通过 |
| 相机/相册压缩真实上传、权限、限20/封面/说明/单删 | 本模块B；真实平台/Storage/metadata；Wave6 | 真实相机拍摄、系统相册选择、压缩 JPEG 上传、权限拒绝再授权通过；真实 Storage/metadata 验证、单封面回退/说明通过；20上限服务/RPC边界通过 |
| 部分上传失败当前页重试/路径保留 | 本模块B；系统失败fake；Wave6 | upload/finish保路径测试通过；reserve失败保bytes公开页面真实red→green通过；最终设备离线系统相册选择、原页中英重试状态、在线同页补传与真实Storage/metadata两份JPEG通过 |
| 软删保照片/恢复/确认取消无副作用/永久清空逐份失败恢复 | 本模块B；Supabase/Storage真实；Wave6 | live软删/恢复/永久清空；失败保留path/parent与在线重试、purge并发restore拒绝测试通过；设备确认取消无副作用、软删照片保留、恢复与最终自动返回档案通过 |
| 本人2–3活动记录比较/Account档案/Crime消费 | 本模块+联合；A Account/Crime与B Property；Wave6 | Account真实档案接线及2项真实持久记录比较、中英320dp200%完整列通过；2–3唯一本人活动记录边界测试通过 |

数据库：两份 forward migration 已部署开发项目。风险组完整性约束、坐标变更触发清空、auth.users归属、父实勘owner Storage/metadata RLS、照片不可变路径、父行锁20张限制、原子封面设置、删除封面最早剩余回退。旧nullable-location历史记录保留且新写入必须合法地点；未导入政府数据/改镜像业务列。

命令证据：`flutter analyze` 无问题；全量测试此前323 passed/14 skipped；最终相关17 tests通过，后续locale notice页面7 tests通过（包含真实red→green）；无变化全量不重复；`python3 tool/verify_property_live.py` live通过；`python3 tool/verify_property_build.py` debug APK构建和敏感扫描通过。构建/live source manifest记录代码摘要及基线SHA，见本次[evidence](evidence/property-inspection-wave6-2026-09-18)。

Storage下载CDN短时可返回先前缓存；永久删除以Storage list为空及真实storage.objects缺失作为实际删除证据，不能据短时缓存误报云对象仍存在。

1. 模块实现：既定实现及验收证据完成，Implemented候选。最终等待Luna High审查。
2. 本期集成：当前Wave6真实Map/Account/Crime/风险调用已接线；真实设备联合路径证据见本次evidence。
3. 后续集成：本模块当前无未来槽位；Integrated由项目负责人批准。
4. 当前阻塞：Luna最终gate待授予，无实现或既定证据缺口。最终设备编辑保存成功notice即时中英切换已通过。原生读屏树来自UiAutomation可访问性服务，与中英320dp200%截图一并交付；未启用TalkBack音频。
