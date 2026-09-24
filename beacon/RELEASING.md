# Beacon .NET 发行准备

Beacon .NET 通过带版本的 GitHub Release 发布。每个 Release 必须由标签工作流从
固定提交重新构建，先生成草稿供人工核验，发布后再从公开 Release 重新下载安装。

## 版本与标签

- [`version.properties`](version.properties) 是 Beacon 产品版本的唯一手工入口。
- 开发候选版本使用 SemVer，例如 `0.2.0-alpha.1`、`0.2.0-rc.1`；正式版使用
  `X.Y.Z`。
- Beacon 标签使用 `beacon-v<版本>`，不复用上游 `v*` 标签。
- Beacon 产品版本与 [`upstream.lock.json`](upstream.lock.json) 中的上游基线
  分开维护；不全局替换上游程序集、NuGet 依赖或 instrumentation scope 版本。

## 发布制品

`0.1.1` 起，一个版本包含以下自定义 Release assets：

```text
beacon-dotnet-auto-<版本>-linux-glibc-x64.zip
beacon-dotnet-auto-<版本>-linux-glibc-arm64.zip
beacon-dotnet-auto-<版本>-linux-musl-x64.zip
beacon-dotnet-auto-<版本>-linux-musl-arm64.zip
beacon-dotnet-auto-<版本>-windows.zip
beacon-dotnet-auto-<版本>-macos.zip
beacon-dotnet-auto-<版本>-nuget-packages.zip
otel-dotnet-auto-install.sh
OpenTelemetry.DotNet.Auto.psm1
checksums.txt
sbom.spdx.json
```

GitHub 还会自动提供源码归档和 Release attestation。平台归档保留上游内部文件名，
并额外包含 `BEACON-METADATA.json`，记录 Beacon 版本、目标平台、源码提交以及
上游标签和提交。NuGet 聚合归档保留上游兼容包 ID。

本地为已经构建的目录写入元数据并打包时可执行：

```bash
bash beacon/scripts/check-version.sh
bash beacon/scripts/package.sh \
  --input bin/tracer-home \
  --target linux-glibc-x64 \
  --output bin/beacon-artifacts
```

这些脚本不代替构建、单元测试、功能测试或各平台验证。

## 发行与验收流程

1. 固定最终源码提交、上游基线、依赖和构建环境，确认许可证及第三方声明。
2. 让主分支 CI 与完整多平台专项 CI 通过。
3. 推送与 `version.properties` 一致的 `beacon-v<版本>` 标签。
4. 标签工作流构建全部平台及 NuGet 制品，生成安装脚本、校验和、SBOM 和证明，
   校验归档后创建草稿 Release。
5. 人工检查草稿中的文件数、名称、校验和、元数据和发布说明，再发布草稿。
6. 发布后工作流从公开 Release 下载安装，在 Windows、macOS、Linux glibc/musl
   的 x64 与 ARM64 运行 .NET 8 应用，并验证 GitHub Release 和构建证明。

所有验证成功后才可宣布版本可用。已发布标签和制品不可覆盖；失败后修复代码并
递增版本。DataKit 接收链路仍需独立端到端验收，不能由 OTLP 导出测试推断。
