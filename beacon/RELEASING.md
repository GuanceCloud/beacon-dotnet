# Beacon .NET 发行准备

当前没有 Beacon .NET 正式发行，也没有已经批准的发布目标。本页定义候选制品，
不表示当前版本已经通过支持范围或 DataKit 验收。

## 版本与标签

- [`version.properties`](version.properties) 是 Beacon 产品版本的唯一手工入口。
- 开发候选版本使用 SemVer，例如 `0.1.0-alpha.1`、`0.1.0-rc.1`；正式版使用
  `X.Y.Z`。
- Beacon 标签使用 `beacon-v<版本>`，不复用上游 `v*` 标签。
- Beacon 产品版本与 [`upstream.lock.json`](upstream.lock.json) 中的上游基线
  分开维护；不全局替换上游程序集、NuGet 依赖或 instrumentation scope 版本。

## 首版制品

首版只准备从固定源码构建的自动插桩归档：

```text
beacon-dotnet-auto-<版本>-<平台标识>.zip
beacon-dotnet-auto-<版本>-<平台标识>.zip.sha256
```

归档保留上游内部文件名，并额外包含 `BEACON-METADATA.json`，记录 Beacon 版本、
平台标识、上游标签和提交。执行：

```bash
bash beacon/scripts/check-version.sh
bash beacon/scripts/package.sh \
  --input bin/tracer-home \
  --target linux-glibc-x64 \
  --output bin/beacon-artifacts
```

脚本只对已经构建的目录打包，不代替 `BuildTracer`、单元测试、集成测试或平台
验证。NuGet 包、安装脚本、容器镜像、系统包和独立 Profiling 制品都不在当前
首版范围内；确有需求时分别完成命名与依赖设计后增加。

## 首次发布前验收

1. 固定最终源码提交、上游基线、依赖和构建环境，确认许可证及第三方声明。
2. 至少在拟声明支持的 Windows、Linux glibc/musl、macOS 和架构上构建同一
   版本；不能用一个 Linux x64 归档推断其他平台可用。
3. 从候选归档在干净环境启动真实 ASP.NET Core 应用，验证 Trace、Metric、Log
   的实际声明范围以及目标 DataKit OTLP 接收链路。
4. 验证 .NET 与 .NET Framework 的实际范围、IIS/Windows Service、容器、
   self-contained、依赖冲突、升级及回退；未测试的场景写入限制。
5. 保存制品 SHA-256、测试证据、版本说明和回退方法。审批后只发布已经验证的
   同一份制品，不在打标签后重新构建替代品。

已发布标签和制品不可覆盖。失败后修复代码并递增版本。首次正式发行后，再更新
Beacon 产品仓库中的固定版本安装和 Release 入口。
