# Home & Relocation Outlook：Wave 4 验收

> 2026-09-17；Owner A；Home Feature：**Implemented**；GPT‑5.6 Luna High Standards / Spec 复审均 PASS。

## 1. 模块实现

生产代码已接入真实 Supabase RPC、全国评分模型和 SQLite 公共缓存。首页提供五张卡、三个实际观测趋势图、中英文、来源/单位/观测日期、原因及读屏摘要。按钮与下拉共享刷新语义，成功后冷却 60 秒仅留在内存；账户关闭后忽略旧响应。

| 场景 | 验收证据 | 结果 |
| --- | --- | --- |
| HOME-W4-01 完整模型、原因、异频日期 | HOME-001 已知例、趋势页面、live RPC、两设备 | 通过 |
| HOME-W4-02 部分/缺失/schema/历史与权重 | 60% 门槛、收入独立、月/季历史回退、GDP 异常测试 | 通过 |
| HOME-W4-03 缓存、离线、恢复、并发 | SQLite 重启/stale、损坏拒绝、打开失败恢复、晚到写入不回退 | 通过 |
| HOME-W4-04 双入口、去重、冷却 | 公开 load、实际 Widget/两设备下拉、成功冷却和失败重试 | 通过 |
| HOME-W4-05 opened、关闭、无地点探索 | 真实 Shell 组合、真实 Auth/Privacy/Shell 设备流程 | Home/Shell 子项通过 |
| HOME-W4-06 双语、可访问性 | en/zh、360dp、200% 字号、趋势文字/读屏、两设备 | 通过 |
| HOME-W4-07 Adapter、权限 | 真实登录 RPC、匿名 RPC deny、五镜像 update deny、SQL CRUD grants | 通过 |

四个已确认边界均已开展：公开 HOME-001 load 26 项，公开页面 6 项，真实 Shell 组合 2 项，真实 Supabase live 1 项；另有真实 provider 趋势页面 2 项。诊断事件仅包含固定分类、耗时桶和生成 ID，敏感字段 deny-list 测试通过。

政府输入一次性导入，无自动同步。GDP 官方 CSV 目前只有 abs；有效空 growth_qoq 仍按其余 70% 权重归一化。字段或数据异常单独分类，不写缓存、不启动成功冷却。LFS 非破坏迁移保留 legacy 表并撤销客户端访问。

## 2. 本期集成

Home 与真实 Auth/Privacy/Shell 的门控、导航投影、关闭/重启和公共缓存保留通过；Home/Shell 当期子项有确定性、live 和设备证据。真实 Map 页面完整联验尚未完成，因此不宣告整个 Wave 4 完成。

## 3. 后续集成

Owner A 在 Wave 4 接入真实 Map 页面并完成 HOME-W4-05/探索地图完整联合场景；Integrated 仍须项目负责人批准。明确 Map Tab 槽位证据的范围，不能将其视为真实地图联验。

## 4. 当前阻塞

**无（Home 模块范围）。** Luna 发现的历史回退、GDP 异常成功冷却及缓存占位日期缺陷均已有失败测试、修复和复审；诊断及迁移/工具追踪缺口已关闭。

## 命令、环境与版本

- `flutter test --reporter expanded`：**145 通过，5 项 opt-in 跳过**；Home/Shell 定向 **36 通过**；Home live 单独启用 **1 通过**。
- `flutter analyze`：无问题；`dart format --output=none --set-exit-if-changed .`：77 文件，0 改动；`git diff --check` 通过；普通 debug APK 构建通过。
- `python3 tool/verify_home_devices.py --devices <physical-adb-id> emulator-5554`：真机与模拟器均通过双语、真实下拉/冷却、RPC 故障降级、时钟 +2 天过期、进程重启、恢复、探索/返回及关闭。使用临时账户和真实 RPC/TLS，只有 RPC 故障为可控注入；运行退出 0，账户清理及普通 APK 恢复完成。
- 构建时移除管理员配置，普通 APK 扫描不含管理员密钥、配置测试账户及临时账户；APK：`build/app/outputs/flutter-apk/app-debug.apk`。
- 基线 HEAD：`66f4ffc1e9392a1cdf9e01b054cbd81b713e82b9`；工作区未提交。App source SHA-256：`931fc6856e6301ea59975c2ca7ceee2ecf918c559d54f909ca8a8d449424ac1a`；测试、live、两设备和两种 APK 的 App 源码版本一致。五项 SQL 迁移和三项 Python runner 另有 revision 哈希，属于验收追踪。

[命令及版本](evidence/home-and-relocation-outlook-wave4-2026-09-17/checks.source.json) · [设备/清理汇总](evidence/home-and-relocation-outlook-wave4-2026-09-17/device-verification-summary.json) · [迁移/工具版本](evidence/home-and-relocation-outlook-wave4-2026-09-17/schema-and-tool-revision.json) · [最终权限审计](evidence/home-and-relocation-outlook-wave4-2026-09-17/grants-final-audit.json) · [Luna 两轴审查](home-and-relocation-outlook-wave4-review-2026-09-17.md)

设备截图、UI tree、分类结果及 red/green 证据保存在同一 evidence 目录；凭据未进入交付内容。
