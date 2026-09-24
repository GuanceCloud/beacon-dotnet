# Beacon .NET Changelog

本文件只记录 Beacon .NET 产品变化；继承的上游变化见根目录
[`CHANGELOG.md`](../CHANGELOG.md)。

## Unreleased

## 0.1.1 - 2026-09-24

- 增加 Linux glibc/musl x64 与 ARM64、Windows、macOS 和 NuGet 发布归档。
- 增加 Shell 与 PowerShell 安装脚本，以及发布后的跨平台安装和运行验证。
- 增加统一 SHA-256 清单、SPDX SBOM 和 GitHub 构建证明。
- 所有平台归档统一包含 Beacon 版本、目标平台和固定上游来源元数据。

## 0.1.0 - 2026-09-24

- 基于 OpenTelemetry .NET Automatic Instrumentation `v1.17.0` 建立完整源码下游工程。
- 增加 Beacon 独立产品版本、来源检查和候选归档打包入口。
- 提供经过真实应用 OTLP Trace、Metric、Log 验证的 Linux glibc x64 自动插桩归档。
- 增加标签校验、制品校验和 GitHub Release 自动发布流程。
