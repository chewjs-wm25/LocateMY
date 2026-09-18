# 房产实勘 Penpot UI 调整（2026-09-18）

本次完成实勘详情、新增／编辑实勘及房产实勘对比的呈现调整。参考 Penpot MCP 当前文件中的 16、17、18 号画板；通过 MCP 导出查看原型，并读取卡片尺寸、文本、颜色及圆角。画板 id 和最终生产源码／APK 指纹见 [验证清单](evidence/property-ui-penpot-2026-09-18/validation.json)。

## 调整结果

- 详情：整幅封面、蓝色现场平均评分、相邻风险快照、两列现场记录，以及水灾／备注卡片；保留照片库及照片操作、编辑和回收站入口。
- 新增／编辑：圆角白色输入框、两列可编辑星级卡片、当前平均、相机／相册按钮及保存后上传提示。窄屏或大字体改为单列；当前页失败重试及地图往返保留输入继续使用原行为。
- 对比：A／B／C 封面与价格卡片、风险快照／现场记录分组和交替灰底指标。宽度不足时横向滚动，所有列共用同一滚动区域。快照不可用显示「—」，不会暴露不可用组中残留的数值；真实隐患数 0 仍显示 0。
- 价格显示千位分隔；快照时间按设备本地时区显示到分钟。实际快照、存储字段、四评分平均和风险请求时机均沿用既有业务逻辑。

## 验证与状态

1. **模块实现：Implemented（本次 UI 范围）**。格式、`flutter analyze`、房产 31 项测试和最终 `flutter test` 344 项通过。14 项需要 live 配置的测试跳过，不作为本次真实环境验证证据。最终生产 debug APK 构建通过，敏感值扫描通过，APK 的 lib 源码指纹与最终工作区一致。
2. **本期集成：本次页面导航与读取通过**。Samsung Android 真机安装最终生产 APK，沿普通登录后的账户 → 房产实勘入口，验证云端详情、编辑表单、新增表单和两份本人活动记录的对比。真实封面、州级安全指数、隐患数显示正常；中文常规／200% 字体截图已保留。设备原字体比例已恢复。本次不重新声明完整 Wave 6 验收或 Integrated。
3. **后续集成：本次 UI 无新增业务槽位**。模块整体 Integrated 仍沿用现有契约，由负责人另行确认。
4. **当前阻塞：无（本次 UI 范围）**。

页面测试另外覆盖三个页面 × 中英文 × 390dp 常规／320dp 200%，评分编辑与真实保存结果、云端失败保留输入、照片失败重试及销毁后迟到结果。截图生成开关为 `--dart-define=PROPERTY_UI_CAPTURE=true`；此组页面测试使用内存 fixture，和真机云端读取证据分别记录。相机、Storage、RLS 和永久删除未在本次 UI 任务重新操作；相关原行为通过现有房产回归测试。

证据：[房产测试](evidence/property-ui-penpot-2026-09-18/property-tests.log)、[静态分析](evidence/property-ui-penpot-2026-09-18/analyze.log)、[真机导航](evidence/property-ui-penpot-2026-09-18/device-navigation.log)、[生产 APK 指纹](evidence/property-ui-penpot-2026-09-18/production-build.source.json)。

## 画面

| 真机常规 | 真机 200% 字体 |
| --- | --- |
| [详情](evidence/property-ui-penpot-2026-09-18/device-detail-normal.png) | [详情](evidence/property-ui-penpot-2026-09-18/device-detail-large.png) |
| [编辑](evidence/property-ui-penpot-2026-09-18/device-edit-normal.png) | [编辑](evidence/property-ui-penpot-2026-09-18/device-edit-large.png) |
| [对比](evidence/property-ui-penpot-2026-09-18/device-comparison-normal.png) | [对比](evidence/property-ui-penpot-2026-09-18/device-comparison-large.png) |
| [新增](evidence/property-ui-penpot-2026-09-18/device-new-normal.png) | 三份记录另见 [fixture 画面](evidence/property-ui-penpot-2026-09-18/comparison-zh-normal.png) |

## Linux 永不息屏

当前电脑使用 XFCE。电源管理的电源／电池亮度闲置、自动休眠和 DPMS 都已禁用；屏幕保护、闲置激活和自动锁屏禁用。因屏保守护程序会将 X11 timeout 重设为 300 秒，已通过当前用户 autostart override 禁用其自动启动，并正常退出当前守护程序。另设当前用户 `keep-screen-on.desktop`，登录时执行 `xset s off`、`xset s noblank`、`xset -dpms`；最终检查 timeout 为 0，DPMS Disabled。系统设置存于用户配置，不属于 Git 项目。
