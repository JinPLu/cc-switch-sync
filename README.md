# cc-switch-sync

[CC Switch](https://github.com/farion1231/cc-switch) 的配套脚本，双击即可把本地 Claude 与 Codex 的 AI Provider 配置推送到远程 Linux 服务器。

[English](README_EN.md)

## 使用前（一次性）

1. 安装 [CC Switch](https://github.com/farion1231/cc-switch/releases)，在 GUI 里添加好 Provider（API Key + Base URL），并在 Settings 里关闭 `enableLocalProxy`
2. 如需同步 Codex，先在本机确认 `%USERPROFILE%\.codex\config.toml` 和 `%USERPROFILE%\.codex\auth.json` 可用
3. 把 `servers.conf.example` 复制为 `servers.conf`，填入服务器信息

## 使用

双击脚本运行：

| 脚本 | 用途 |
|------|------|
| `1. SSH Connect.bat` | 连接服务器。首次使用时选「+ Add new server」，脚本会自动初始化远程环境（代理、工作目录、Claude/Codex 配置），然后直接连入 |
| `2. Sync Config.bat` | 在 CC Switch 或 Codex 里切换 Provider 后，把新配置推送到服务器 |

同步 Codex 时会覆盖远端 `~/.codex/config.toml`，并在覆盖前保留 `config.toml.bak.<timestamp>`；如果本机存在 `auth.json`，也会同步到远端并保留备份。

## `servers.conf` 格式

```
Host my-server
  HostName 10.0.0.1
  Port 22
  User root
  WorkDir /home/user/projects/
  Proxy http://10.0.0.2:18000
```

| 字段 | 必填 | 说明 |
|------|------|------|
| `Host` | 是 | 服务器昵称 |
| `HostName` | 是 | IP 地址或主机名 |
| `Port` | 否 | SSH 端口（默认 22） |
| `User` | 否 | SSH 用户（默认 root） |
| `WorkDir` | 否 | 登录后自动 `cd` 到此目录 |
| `Proxy` | 否 | 服务器对外访问时使用的 HTTP 代理 |

`servers.conf` 已加入 `.gitignore`，不会被提交。

## License

MIT
