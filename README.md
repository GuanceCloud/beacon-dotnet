# Beacon .NET

Beacon .NET 是 GuanceCloud 基于 OpenTelemetry .NET Automatic Instrumentation
维护的 .NET 自动插桩探针。本仓库采用完整源码下游方式维护，不是 GitHub Fork。

当前代码基于官方 `v1.17.0` 建立工程。Beacon `0.1.2` 提供 Linux glibc、
Linux musl、Windows、macOS 和 NuGet 发布归档，覆盖 x64 与适用的 ARM64
平台，并附带 Shell/PowerShell 安装脚本、校验和、SPDX SBOM 和构建证明。
发布后会从 GitHub Release 重新下载安装并运行 .NET 8 应用；DataKit 接收链路
仍不在当前已验证支持范围内。

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
