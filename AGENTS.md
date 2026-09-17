# 项目文档约定

- 涉及产品术语、地点分析范围或领域关系时，先读 [CONTEXT.md](./CONTEXT.md)；具体功能、公式和数据边界再读 `docs/knowledge_base/` 中对应的事实源。

## `docs/knowledge_base/`

- 认为成果值得长期入库时，先读 `docs/knowledge_base/README.md`；仅按其收录边界更新。

## `docs/my_knowledge.md`

- 该文件描述用户当前对 Flutter 和 Supabase 的知识范围。
- 只有当用户明确确认自己已经学会某项知识时，才将该知识加入或更新到此文件。

## `docs/human/`

- 这是存放展示给用户阅读的文档的目录。
- 需要向用户交付文档时，将文档存放于此。
- 仅在用户明确要求时读取此目录中的文件。

## `docs/old/`

- 这是存放过时或历史文档的目录。
- 执行项目任务时忽略此目录，不读取或引用其中的文件。

## Agent skills

### Issue tracker

Issues and specs are tracked in GitHub Issues. See `docs/agents/issue-tracker.md`.

### Triage labels

Use the default five triage labels. See `docs/agents/triage-labels.md`.

### Domain docs

This is a single-context repo. See `docs/agents/domain.md`.

### Design docs

涉及系统设计、Development Contract、跨 Owner Interface、设计审查或 HTML 交接时，先读 `docs/design/README.md`。

开发 Feature/shared module、审查实现完成度或验收 Wave 时，先读 `docs/design/development-standard.md`。

编写、修改或审查手写 Dart 代码，以及设计新的公开 Dart declaration 时，先读 `docs/design/development-standard.md` 第 7 节的 Java 阅读习惯约束。

## 本地真实测试凭据

- 需要登录的真实、live 或设备测试开始前，读取根目录的 `test_credentials.local.md`，并按其中的变量名注入测试环境。
- 该文件只存在于本地，内容按敏感信息处理；不要在回复、日志、截图、提交或其他版本控制内容中暴露账号和密码。
