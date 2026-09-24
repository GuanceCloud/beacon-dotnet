# Beacon .NET

Beacon .NET 是 GuanceCloud 基于 OpenTelemetry .NET Automatic Instrumentation
维护的 .NET 自动插桩探针。本仓库采用完整源码下游方式维护，不是 GitHub Fork。

当前代码基于官方 `v1.17.0` 建立工程。Beacon `0.1.0` 的首版支持范围为 Linux
glibc x64 上的 .NET 8 应用，发布归档经过真实应用的 OTLP Trace、Metric、Log
功能验证。其他平台、架构、NuGet 部署模式和 DataKit 接收链路不在首版已验证
支持范围内。

开发、上游同步、制品和发行准备入口见 [Beacon 开发说明](beacon/README.md)。
继承的 OpenTelemetry 使用与实现文档见
[OpenTelemetry .NET Automatic Instrumentation](docs/README.md)。

## Beacon Contributors

<table>
  <tr>
    <td align="center">
      <a href="https://github.com/lrwh"><img src="https://github.com/lrwh.png?size=80" width="80" height="80" alt="lrwh"><br><sub>lrwh</sub></a>
    </td>
  </tr>
</table>
