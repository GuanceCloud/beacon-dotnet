# Beacon .NET Changelog

本文件只记录 Beacon .NET 产品变化；继承的上游变化见根目录
[`CHANGELOG.md`](../CHANGELOG.md)。

## Unreleased

## 0.1.0 - 2026-09-24

- 基于 OpenTelemetry .NET Automatic Instrumentation `v1.17.0` 建立完整源码下游工程。
- 增加 Beacon 独立产品版本、来源检查和候选归档打包入口。
- 提供经过真实应用 OTLP Trace、Metric、Log 验证的 Linux glibc x64 自动插桩归档。
- 增加标签校验、制品校验和 GitHub Release 自动发布流程。
