# Application Shell 最小装配契约

> Owner A；2026-09-17 Issue #31；实现重构完成，本轮证据与未交付边界见执行检查。

职责仅应用装配、SDK 登录入口、首页／地图双 Tab、普通 Flutter 路由和语言接线。
唯一公开 app 入口 `lib/app/app.dart`；main 调用 startLocateMy。
LocateMyApp 消费 AuthenticationViewModel；signedInBuilder 为生产页面与已有 Widget harness 的页面入口。
MaterialApp 以 account id 为 key 建立唯一普通路由栈；成功退出或换号替换普通页面树与其路由／对话框。
失败保留登录状态及普通反馈，不出现 closing/opening/recovery gate 或清理恢复页。
首页 onExploreMap 切 Tab，地图回调携带合法地点直接 Navigator.push；返回使用 Navigator.pop。
语言由 LanguageController／shared_preferences 保存，重启与退出保留。
移除 ApplicationShell.submit/publish、通用 intent、binding、贡献／组合槽位与多层结果包装。
地图 provider 图层接口仍属必要业务接口，不用于通用页面组合。

验收由 A 负责：注册／登录／退出／换号、结束旧路由、首页地图返回、地点分析 A/B、语言保留与普通网络失败。
页面测试为主要证据，实际 SDK、KV／SQLite smoke 和设备旅程辅助。
证据见 [执行检查](../system/issue-31-validation.md)；不自动批准 Integrated。
