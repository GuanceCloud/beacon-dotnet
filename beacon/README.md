# Beacon .NET 开发说明

本仓库维护完整
[OpenTelemetry .NET Automatic Instrumentation](https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation)
源码，并在其上准备 Beacon .NET 产品制品。产品总入口为
[GuanceCloud/beacon](https://github.com/GuanceCloud/beacon)。

## 当前状态

- 已从官方 `v1.17.0` 固定基线建立非 Fork 下游工程并保留上游历史。
- Beacon `0.1.1` 发布 Linux glibc/musl x64 与 ARM64、Windows、macOS 和
  NuGet 归档，并提供 Shell 与 PowerShell 安装脚本。
- 构建阶段使用真实控制台和 ASP.NET Core 应用验证 OTLP Trace、Metric、Log；
  发布后再次从 GitHub Release 下载安装并运行 .NET 8 应用。
- 发布附带统一 SHA-256 清单、SPDX SBOM 和 GitHub 构建证明。
- 尚未实现 Beacon 自有运行时增强；DataKit 接收链路尚未纳入已验证支持范围。

这些状态只描述工程准备情况，不把上游支持范围自动视为 Beacon 已验证范围。

## 工程布局

| 位置                 | 用途                                                |
| -------------------- | --------------------------------------------------- |
| [`src`](../src/)     | 托管自动插桩、启动 Hook、Loader 和原生 CLR Profiler |
| [`nuget`](../nuget/) | 上游兼容 NuGet 包布局；以聚合归档形式发布           |
| [`build`](../build/) | Nuke 构建与测试入口                                 |
| [`docs`](../docs/)   | 继承的 OpenTelemetry 使用和实现文档                 |
| [`beacon`](./)       | Beacon 版本、来源、打包、同步与发行说明             |

## 产品与制品边界

对外产品名称为 **Beacon .NET**。平台归档采用：

```text
beacon-dotnet-auto-<Beacon版本>-<平台标识>.zip
checksums.txt
```

平台标识示例包括 `linux-glibc-x64`、`linux-musl-arm64`、`macos-arm64` 和
`windows-x64`。归档内保留 `OpenTelemetry.AutoInstrumentation.*` 程序集、
原生库、环境变量和 instrumentation scope 名称，避免仅为品牌进行全仓重命名，
破坏插件、强名称、CLR Profiler 或上游生态兼容性。

NuGet 聚合归档保留上游包 ID，因为主包依赖 BuildTasks、Loader、StartupHook、
托管与原生 Runtime 等配套包。完成整套包图的命名、依赖、升级与兼容性验证前，
不发布虚假的 `Beacon.AutoInstrumentation` 包。

## 维护入口

- [固定来源与当前基线](upstream.lock.json)
- [上游同步流程](UPSTREAM.md)
- [产品版本](version.properties)
- [制品与发行准备](RELEASING.md)
- [Beacon Changelog](CHANGELOG.md)

日常自动 CI 检查 Beacon 元数据、打包脚本，完成 Linux x64 构建，并针对打包后
的同一份归档运行 .NET 8 OTLP Trace、Metric、Log 及 ASP.NET Core 客户端/服务端
自动插桩验证。标签工作流执行完整多平台构建并先创建草稿 Release；发布后工作流
再验证安装脚本、制品证明、元数据以及 Windows、macOS、Linux glibc/musl 上的
真实应用启动。
