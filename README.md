# cc-switch-sync

用本地 [CC Switch](https://github.com/farion1231/cc-switch) 一键把 Provider 配置推送到远程 Linux 服务器。

**一句话**：本地 CC Switch 里切好 Provider → 跑一下 `sync-to-server` → 远程的 `claude` / `codex` 立刻生效。

## 解决什么问题

你在本地用 CC Switch 管理 API Provider 很方便，但远程服务器是无头 Linux，每次换 Provider 都得 ssh 上去手改配置文件。这个脚本把它变成一条命令。

## 工作原理

```
本地 CC Switch                           远程 Linux
┌──────────────┐     scp DB             ┌──────────────────┐
│ cc-switch.db │ ────────────────────►  │ cc-switch.db     │
└──────────────┘                        │      ↓           │
                     ssh Xvfb+cc-switch │ 写入配置文件      │
                    ────────────────►   │      ↓           │
                                        │ settings.json    │
                     ssh verify         │ config.toml      │
                    ◄────────────────   │ auth.json        │
                                        └──────────────────┘
```

1. `scp` 把本地 CC Switch 数据库复制到远程
2. 远程用 Xvfb 后台启动 CC Switch 几秒，让它把当前 Provider 写入配置文件
3. 校验关键字段并打印

## 快速开始

### 1. 远程服务器准备（每台只做一次）

```bash
# ssh 到远程，安装依赖
sudo apt install -y xvfb dbus-x11

# 安装 CC Switch（选你的架构）
wget https://github.com/farion1231/cc-switch/releases/download/v3.14.1/CC-Switch-v3.14.1-Linux-x86_64.deb
sudo dpkg -i CC-Switch-v3.14.1-Linux-x86_64.deb
sudo apt install -f -y
```

### 2. 本地配置

把 `sync-to-server.bat` 放到任意位置（比如 `~/.cc-switch/scripts/`）。

创建服务器列表 `%USERPROFILE%\.cc-switch-sync\servers.json`：

```json
{
  "servers": [
    { "name": "lab-181", "host": "10.40.1.181", "port": 6339, "user": "root" },
    { "name": "dev-box", "host": "192.168.1.10", "port": 22, "user": "ubuntu" }
  ]
}
```

### 3. 使用

```
sync-to-server              # 交互式选服务器
sync-to-server lab-181      # 直接指定
sync-to-server --all        # 推送到所有服务器
```

输出示例：

```
=============================================
  CC Switch Sync - Push config to server
=============================================

  Servers:
  1. lab-181  (root@10.40.1.181:6339)
  2. dev-box  (ubuntu@192.168.1.10:22)

  Select [1-2]: 1

  --- lab-181 (root@10.40.1.181:6339) ---

  [1/3] Copying DB...
  OK

  [2/3] Applying config on server (wait 7s)...
  OK

  [3/3] Verifying...
  -- Claude --
  "ANTHROPIC_BASE_URL": "https://api.example.com"
  -- Codex --
  base_url = "https://api.example.com/v1"
  model = "gpt-5.5"

  [DONE] lab-181 synced.
  claude: immediate / codex: restart terminal
```

## 重要提示

- **CC Switch 里必须关掉 `enableLocalProxy`**，否则远程 Codex 的 base_url 会被写成 `http://127.0.0.1:15721/v1`（远程根本访问不到）
- Claude Code 切换后**立即生效**，Codex 需要**重启终端**
- Windows 用户如果 scp 报 `Bad permissions`，修复 SSH 权限：
  ```powershell
  icacls $env:USERPROFILE\.ssh\config /inheritance:r /grant:r "$($env:USERNAME):F"
  icacls $env:USERPROFILE\.ssh\id_rsa /inheritance:r /grant:r "$($env:USERNAME):F"
  ```

## 前置要求

| 本地 | 远程 |
|------|------|
| Windows 10+ | Ubuntu 20.04+ |
| [CC Switch](https://github.com/farion1231/cc-switch/releases) v3.14.1+ | CC Switch (deb) |
| SSH 免密登录（推荐） | xvfb, dbus-x11 |

## License

[MIT](LICENSE)

## 致谢

[farion1231/cc-switch](https://github.com/farion1231/cc-switch)
