# Beacon .NET 开发说明

本仓库维护完整
[OpenTelemetry .NET Automatic Instrumentation](https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation)
源码，并在其上准备 Beacon .NET 产品制品。产品总入口为
[GuanceCloud/beacon](https://github.com/GuanceCloud/beacon)。

## 当前状态

- 已从官方 `v1.17.0` 固定基线建立非 Fork 下游工程并保留上游历史。
- 已定义 Beacon 独立产品版本、来源检查和 Linux/macOS/Windows 通用 ZIP
  归档规则。
- 尚未实现 Beacon 自有运行时增强，尚未完成 Windows、macOS、Linux、不同
  架构、NuGet 部署模式及 DataKit 接收链路验收。
- 当前没有 Beacon .NET 正式发行或安装入口。

这些状态只描述工程准备情况，不把上游支持范围自动视为 Beacon 已验证范围。

## 工程布局

| 位置                 | 用途                                                |
| -------------------- | --------------------------------------------------- |
| [`src`](../src/)     | 托管自动插桩、启动 Hook、Loader 和原生 CLR Profiler |
| [`nuget`](../nuget/) | 上游 NuGet 包布局；当前不作为 Beacon 首版制品发布   |
| [`build`](../build/) | Nuke 构建与测试入口                                 |
| [`docs`](../docs/)   | 继承的 OpenTelemetry 使用和实现文档                 |
| [`beacon`](./)       | Beacon 版本、来源、打包、同步与发行说明             |

## 产品与制品边界

对外产品名称为 **Beacon .NET**。首版候选制品采用：

```text
beacon-dotnet-auto-<Beacon版本>-<平台标识>.zip
beacon-dotnet-auto-<Beacon版本>-<平台标识>.zip.sha256
```

平台标识示例包括 `linux-glibc-x64`、`linux-musl-arm64`、`macos-arm64` 和
`windows-x64`。归档内保留 `OpenTelemetry.AutoInstrumentation.*` 程序集、
原生库、环境变量和 instrumentation scope 名称，避免仅为品牌进行全仓重命名，
破坏插件、强名称、CLR Profiler 或上游生态兼容性。

官方 NuGet 部署不是一个单包改名问题：主包依赖 BuildTasks、Loader、
StartupHook、托管与原生 Runtime 等配套包。完成整套包图的命名、依赖、升级与
兼容性验证前，不发布 `Beacon.AutoInstrumentation`，也不把上游
`OpenTelemetry.AutoInstrumentation` 包冒充 Beacon 制品。

## 维护入口

- [固定来源与当前基线](upstream.lock.json)
- [上游同步流程](UPSTREAM.md)
- [产品版本](version.properties)
- [制品与发行准备](RELEASING.md)
- [Beacon Changelog](CHANGELOG.md)

日常自动 CI 只检查 Beacon 元数据、打包脚本并完成一个 Linux x64 构建入口；
上游完整多平台与集成测试保留为手动专项验证。具体支持范围只能由候选制品在目标
环境中的实际结果确定。
