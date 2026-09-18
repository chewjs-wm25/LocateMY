# Wave 5 Crime & Security 证据

对应[验收报告](../../crime-and-security-wave5-acceptance-2026-09-17.md)。生产 lib SHA 摘要见 production-build.source.json / device-build.source.json；逐文件 SHA 见 source-files.json。真实数据审计只读，不替换镜像。live 与设备日志已删除本地凭据和 token。Owner 标签表示目标设备类型，不表示项目负责人授予 Integrated。APK 留在本地 build/crime-wave5-evidence，版本由 APK SHA256 登记；不入库二进制安装包。

TDD red01 是首个公开服务用例因尚无入口/声明而编译失败，red02 是只有一个类别时的行为失败，red17 是历史缺口回归失败，red18 是英文200%标题截断失败；最终全部检查通过，故这些 red 日志只记录实现前/修复前证据。
