# Beacon .NET 发行准备

Beacon .NET 通过带版本的 GitHub Release 发布。每个 Release 必须由标签工作流从
固定提交重新构建，并在发布前对打包后的同一份归档完成功能验证。

## 版本与标签

- [`version.properties`](version.properties) 是 Beacon 产品版本的唯一手工入口。
- 开发候选版本使用 SemVer，例如 `0.1.0-alpha.1`、`0.1.0-rc.1`；正式版使用
  `X.Y.Z`。
- Beacon 标签使用 `beacon-v<版本>`，不复用上游 `v*` 标签。
- Beacon 产品版本与 [`upstream.lock.json`](upstream.lock.json) 中的上游基线
  分开维护；不全局替换上游程序集、NuGet 依赖或 instrumentation scope 版本。

## 首版制品与支持范围

`0.1.0` 首版只发布从固定源码构建的 Linux glibc x64 自动插桩归档，并仅声明
支持 .NET 8 应用和通用 ZIP 部署：

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

脚本只对已经构建的目录打包，不代替 `BuildTracer`、单元测试、功能测试或平台
验证。NuGet 包、安装脚本、容器镜像、系统包、独立 Profiling 制品、Windows、
macOS、Linux musl、ARM64、.NET Framework 和 DataKit 接收链路都不在 `0.1.0`
已验证支持范围内；确有需求时分别完成设计和验收后增加。

## 首次发布前验收

1. 固定最终源码提交、上游基线、依赖和构建环境，确认许可证及第三方声明。
2. 在所有拟声明支持的平台、架构和 .NET 版本上构建同一版本；不能从一个平台
   的结果推断其他平台可用。
3. 校验候选归档 SHA-256，并从归档重新安装到空目录。
4. 使用归档启动真实应用，验证已声明的 Trace、Metric、Log 导出能力。
5. 保存自动化测试结果、版本说明、已知限制和回退方法。工作流验证全部成功后，
   只把经过验证的同一份 ZIP 和 SHA-256 文件附加到 GitHub Release。

推送 `beacon-v<版本>` 标签会触发完整构建、核心测试、归档后功能验证和 GitHub
Release 创建。已发布标签和制品不可覆盖；失败后修复代码并递增版本。
