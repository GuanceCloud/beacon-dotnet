# 同步 OpenTelemetry .NET Automatic Instrumentation

命令均从仓库根目录执行。`main` 是 Beacon 下游主线；官方 `main` 仅用于发现
更新，不直接替换 Beacon 自有提交。当前采用的正式标签和提交记录在
[`upstream.lock.json`](upstream.lock.json)。

## Remote 配置

目标仓库建立后，`origin` 应指向
`https://github.com/GuanceCloud/beacon-dotnet.git`。官方仓库只配置为
`upstream`：

```bash
git remote add upstream https://github.com/open-telemetry/opentelemetry-dotnet-instrumentation.git
git remote set-url --push upstream DISABLED
git config remote.pushDefault origin
```

若 remote 已存在，先核对地址，不要覆盖。不得向官方 `upstream` 推送。

## 固定并采用正式基线

1. 审查官方 Release，核对签名标签对象、标签解析后的完整提交以及 Release
   制品；不要只从官方当前 `main` 推断基线。
2. 将目标标签抓取到本地并分别核对标签对象和提交：

   ```bash
   git fetch --no-tags upstream refs/tags/v1.17.0:refs/tags/v1.17.0
   git rev-parse refs/tags/v1.17.0
   git rev-parse refs/tags/v1.17.0^{commit}
   ```

3. 从干净的 `main` 新建同步分支，合并目标提交并保留合并提交。解决冲突时保留
   Beacon 产品目录、制品身份和受控 CI；不要用新的上游目录覆盖整个工作树。
4. 复核 `.NET SDK`、OpenTelemetry Core、instrumentation 包、原生工具链及
   NuGet 依赖。依赖组合以采用的上游发行和实际测试为准，不盲目升级到最新版。
5. 运行 Beacon 检查、受影响的上游测试和目标平台构建；按拟发行范围完成归档、
   干净环境启动及 DataKit 链路验证。通过后更新基线文件并确认目标提交已进入
   下游主线：

   ```bash
   git merge-base --is-ancestor <上游提交SHA> HEAD
   ```

抓取、合并、构建、打包和发行是不同状态。每次同步后检查新出现的工作流；继承的
上游发布、机器人、定时任务和第三方凭证流程不能直接成为 Beacon 自动入口。
