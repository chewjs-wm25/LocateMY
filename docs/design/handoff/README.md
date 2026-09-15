# Development Contract 人类交接

实现者以 owning Feature/shared-module Markdown 为唯一 Development Contract。`docs/human/` 中同 basename HTML 是方便顺序阅读的语义等价导出，不是第二套设计、独立工作包或批准状态。

## 导出规则

1. 仅从对应 Markdown 生成 HTML；不得在 HTML 中引入新决定或手工修正语义。
2. 保持标题顺序、表格、代码 declaration、链接目标和 Ready Gate 等价。
3. 导出后比较 Markdown 与 HTML 的标题及所有 Dart fenced blocks，并抽查链接和移动端可读性。
4. Markdown 发生实质变化时，同一 PR 更新 HTML；只改变格式时不得改变契约语义。

## 实现者阅读顺序

1. 阅读成果、范围、依赖和文件责任。
2. 理解唯一公开入口及完整 declarations；实现体仍由 Owner 自己设计。
3. 阅读数据/公式的唯一事实源、权限与失败边界。
4. 先写 fake 或 Adapter 测试场景，再实现和完成联合验收。

遇到规格缺口时记录 contract、Interface、期望行为、实际阻碍、是否阻塞和受影响消费者；停止受影响部分并交由项目负责人决策。不得用私有实现约定替代公开契约变更。
