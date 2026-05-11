# cc-switch-sync

在 Windows 本地用 [CC Switch](https://github.com/farion1231/cc-switch) 统一管理远程 Linux 服务器上的 Claude Code / Codex 等 AI 工具配置。

[English README](README_EN.md)

## 脚本说明

双击任意脚本即可运行。

1. **`1. SSH Connect.bat`** — 从 `servers.conf` 选择服务器，直接打开 SSH 连接。
2. **`2. Sync Config.bat`** — 把本地 CC Switch 的 Provider 数据库（`~/.cc-switch/cc-switch.db`）复制到远程服务器，禁用本地路由，然后无头启动 CC Switch，让它自动生成 Claude 的 `settings.json` 和 Codex 的 `config.toml`。
3. **`3. Add Server.bat`** — 交互式添加新服务器到 `servers.conf`，可选择立即初始化（安装 Xvfb + CC Switch、写入代理/工作目录到 `.bashrc`、同步 DB）。

`_select-server.bat` 是上面脚本共用的服务器选择器，不需要单独运行。

## `servers.conf` 格式

SSH config 风格。把 `servers.conf.example` 复制为 `servers.conf` 后填入你自己的值。

```
Host lab-gpu
  HostName 10.x.x.x
  Port 22
  User root
  WorkDir /home/user/projects/
  Proxy http://10.x.x.x:18000
```

| 字段 | 必填 | 说明 |
|------|------|------|
| `Host` | 是 | 服务器昵称，显示在选择菜单里 |
| `HostName` | 是 | IP 地址或主机名 |
| `Port` | 否 | SSH 端口（默认 22） |
| `User` | 否 | SSH 用户（默认 root） |
| `WorkDir` | 否 | 登录后自动 `cd` 到这个目录 |
| `Proxy` | 否 | 该服务器对外访问时使用的 HTTP 代理 |

`servers.conf` 已加入 `.gitignore`，不会被提交到 git。

## 远程服务器一次性初始化

`3. Add Server.bat` 会自动完成初始化，如果你想手动操作：

```bash
# 安装 Xvfb（无头运行 CC Switch 必需）
apt-get install -y xvfb

# 下载并安装 CC Switch
wget https://github.com/farion1231/cc-switch/releases/download/v3.14.1/CC-Switch-v3.14.1-Linux-amd64.deb -O /tmp/cc-switch.deb
apt install -y /tmp/cc-switch.deb
```

## 重要：关闭本地代理路由

同步前，在 **Windows 本地**打开 CC Switch → **Settings**，确认：

```
enableLocalProxy = off
```

如果开着本地代理，CC Switch 会把 `localhost:…` 写进生成的配置文件，远程服务器根本访问不到这个地址，导致 Claude / Codex 连不上。

同步脚本也会在复制数据库后自动执行以下 SQL 来强制关闭：

```sql
UPDATE proxy_config SET is_enabled = 0
```

## SSH 密钥权限问题（Windows）

如果 SSH 报权限错误，用 `icacls` 修复：

```cmd
icacls "C:\Users\你的用户名\.ssh\id_rsa" /inheritance:r /grant:r "%USERNAME%:R"
```

## License

MIT
