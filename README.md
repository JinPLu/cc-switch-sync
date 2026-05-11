# cc-switch-sync

> 用本地 [CC Switch](https://github.com/farion1231/cc-switch) 一键管理远程服务器上的 Claude Code / Codex / Gemini CLI 配置

一个 CC Switch 的小型配套工具：在本地图形界面里维护一份 Provider 配置，一条命令就能把它推到任意一台 SSH 远程机器，让远程的 `claude`、`codex` 立刻用上新的 API Key / Base URL / 模型。

---

## 为什么要这个东西

CC Switch 是个**只能在自己机器上跑**的桌面 App。但很多人的实际场景是：

- 本地一台 Windows / Mac 写代码、调配置
- 远程几台 Linux 服务器跑训练、跑推理、跑 agent
- 每台机器都装了 `claude` / `codex` CLI
- 每次换 Provider（中转站挂了、Key 没额度了），要 ssh 到每一台分别改 `~/.claude/settings.json` 和 `~/.codex/config.toml`

`cc-switch-sync` 把这件事变成一条命令。

---

## 工作原理

```
本地 (Windows/macOS/Linux)              远程 Linux 服务器
┌─────────────────────────┐            ┌──────────────────────────┐
│  CC Switch GUI          │            │                          │
│  ┌──────────────────┐   │   1. scp   │  ~/.cc-switch/           │
│  │ providers DB     │───┼──────────► │     cc-switch.db         │
│  └──────────────────┘   │            │           ↓              │
│                         │   2. ssh   │  Xvfb + cc-switch (10s)  │
│                         │ ─────────► │           ↓              │
│                         │            │  ~/.claude/settings.json │
│                         │   3. ssh   │  ~/.codex/config.toml    │
│                         │ ◄───────── │  ~/.codex/auth.json      │
│                         │  (verify)  │                          │
└─────────────────────────┘            └──────────────────────────┘
```

1. **复制数据库**：把本地 `~/.cc-switch/cc-switch.db` 通过 `scp` 传到远程同样路径
2. **触发应用**：在远程用 `Xvfb`（虚拟显示）后台启动 CC Switch 几秒钟，让它把数据库里"当前 Provider"的配置写入 `~/.claude/settings.json` 和 `~/.codex/config.toml`
3. **校验**：远程 `cat` 一下这两个文件，把关键字段（`ANTHROPIC_BASE_URL`、`base_url`）打印出来确认成功

整个过程 **10 秒以内**完成。

---

## 适用场景

- ✅ 本地 GUI 调试、批量推到 N 台无图形界面服务器
- ✅ 团队里所有人共用一台中转站，本地改一次，全员服务器同步
- ✅ A/B 切换不同中转站，远程不用动手
- ❌ 不适合官方 ChatGPT/Claude OAuth 登录（那个需要交互式浏览器认证）
- ❌ 不适合远程 macOS / Windows（远程只支持 Linux）

---

## 前置要求

### 本地

| 项 | 要求 |
|---|---|
| OS | Windows 10+ / macOS / Linux |
| CC Switch | v3.14.1 或更新 — [下载](https://github.com/farion1231/cc-switch/releases) |
| SSH | 系统自带 `ssh` / `scp` 命令 |
| 免密登录 | 远程服务器配好 `~/.ssh/authorized_keys`（强烈推荐） |

### 远程（每台服务器）

| 项 | 安装命令 |
|---|---|
| Linux | Ubuntu 20.04+ 测试通过 |
| CC Switch | 见下方"远程一次性准备" |
| Xvfb + dbus | `apt-get install -y xvfb dbus-x11` |
| Python 3 | 校验阶段用，绝大多数发行版自带 |

---

## 安装

### 1. 克隆仓库

```bash
git clone https://github.com/<你的用户名>/cc-switch-sync.git
cd cc-switch-sync
```

### 2. 本地安装脚本

**Windows（PowerShell）：**
```powershell
.\install.ps1
```

**macOS / Linux：**
```bash
./install.sh
```

安装脚本会把 `sync-to-server` 放到 `~/.cc-switch/scripts/` 下，并把服务器列表模板写到 `~/.cc-switch-sync/servers.json`。

### 3. 远程一次性准备

每台远程服务器**只需要做一次**：

```bash
# 在远程执行
sudo apt-get install -y xvfb dbus-x11

# 下载并安装 CC Switch（按你的 CPU 架构选 x86_64 或 arm64）
wget https://github.com/farion1231/cc-switch/releases/download/v3.14.1/CC-Switch-v3.14.1-Linux-x86_64.deb
sudo dpkg -i CC-Switch-v3.14.1-Linux-x86_64.deb || sudo apt-get install -f -y
```

> ⚠️ 如果你的服务器在国内、`apt-get install -f` 走代理失败，参考下方 [Troubleshooting](#troubleshooting)。

### 4. 注册服务器

编辑 `~/.cc-switch-sync/servers.json`：

```json
{
  "servers": [
    {
      "name": "lab-181",
      "host": "10.40.1.181",
      "port": 6339,
      "user": "root"
    },
    {
      "name": "liu-desktop",
      "host": "100.67.102.69",
      "port": 22,
      "user": "liu"
    }
  ]
}
```

---

## 使用

### 第一步：在本地 CC Switch GUI 里切到目标 Provider

打开 CC Switch，在 **Claude** 和 **Codex** 标签下分别点击你要使用的 Provider，确认它显示为 **Current**（绿色高亮 / 打钩）。

> ⚠️ **关掉本地代理**：进入 Settings，确认 `enableLocalProxy = off`、`enableFailoverToggle = off`。开启会导致远程 Codex 的 `base_url` 被写成 `http://127.0.0.1:15721/v1`，远程根本访问不到。

### 第二步：跑 sync

**交互式**（从服务器列表挑一个）：

```bash
sync-to-server
```

```
=============================================
  Sync CC Switch Provider Config to Server
=============================================

  Available servers:
  -------------------
  1. lab-181        (root@10.40.1.181:6339)
  2. liu-desktop    (liu@100.67.102.69:22)
  3. [+ Add new server]

  Select [1-3]: 1

  Target: root@10.40.1.181:6339  [lab-181]

[1/3] Copying CC Switch DB to server...        DONE
[2/3] Starting CC Switch on server (Xvfb)...   DONE  (waited 7s)
[3/3] Verifying...
  ~/.claude/settings.json env:
    "ANTHROPIC_BASE_URL": "https://cialloapi.cn"
    "ANTHROPIC_AUTH_TOKEN": "sk-...XXXX"
  ~/.codex/config.toml:
    base_url = "https://cialloapi.cn/v1"

=============================================
  Done! Provider config synced.
  On server:
    - claude: takes effect immediately
    - codex:  Ctrl+C then restart terminal
=============================================
```

**指定服务器**（脚本/CI 友好）：

```bash
sync-to-server lab-181
```

**推送到所有服务器**：

```bash
sync-to-server --all
```

### 第三步：在远程使用

直接连上去用就行：

```bash
ssh root@10.40.1.181
claude              # 立即生效
# 或
codex               # 需要重开终端
```

---

## 常见问题（Troubleshooting）

### Q1. `Bad permissions on C:\Users\<you>\.ssh\config`（Windows）

Windows OpenSSH 要求 `.ssh/config` 和私钥只能由当前用户访问。修复：

```powershell
$f = "$env:USERPROFILE\.ssh\config"
icacls $f /inheritance:r
icacls $f /grant:r "$($env:USERNAME):F"

# 同样处理私钥
$k = "$env:USERPROFILE\.ssh\id_rsa"
icacls $k /inheritance:r
icacls $k /grant:r "$($env:USERNAME):F"
```

### Q2. 远程 CC Switch 报 `Failed to initialize GTK`

远程没有图形环境，必须先用 Xvfb 提供一个虚拟显示。sync 脚本会自动启动 Xvfb，如果你手动跑 cc-switch：

```bash
Xvfb :99 -screen 0 1024x768x24 &
export DISPLAY=:99
cc-switch
```

### Q3. 远程 Codex 报 `Codex Provider 缺少 base_url 配置`

说明本地 CC Switch 的"代理接管"模式被开启了。打开本地 CC Switch GUI → Settings → 把 `enableLocalProxy` 关掉 → 重新 sync。

### Q4. sync 显示成功但 Codex 用的还是旧配置

Codex CLI 只在启动时读 `config.toml` 一次。**ssh 重连或重开终端 `tmux` 窗口**即可。

### Q5. apt 装依赖时被中转站 403 拦截

走代理访问国内镜像源（如 `mirrors.baidubce.com`）经常被拦。让 apt 直连：

```bash
echo 'Acquire::http::Proxy "DIRECT";'  | sudo tee /etc/apt/apt.conf.d/99proxy
echo 'Acquire::https::Proxy "DIRECT";' | sudo tee -a /etc/apt/apt.conf.d/99proxy
sudo apt-get install -f -y
```

### Q6. 远程服务器 `.bashrc` 里残留 http_proxy 导致 127.0.0.1 也走代理

如果之前手动配过 HTTP 代理，会把所有出站流量（包括 localhost）都路由出去，Codex 连本机 CC Switch 代理被 403。修复：

```bash
sed -i '/export http_proxy=/d; /export https_proxy=/d' ~/.bashrc
# 重新登录或 source ~/.bashrc
```

---

## 安全提示

- `cc-switch.db` 里的 **API Key 是明文存储的**。本工具通过 `scp` 经过 SSH 加密传输，**不要**改用 HTTP 或共享存储传播。
- 远程 `~/.codex/auth.json` 也是明文 Key，sync 完后建议：
  ```bash
  ssh server "chmod 600 ~/.codex/auth.json ~/.claude/settings.json ~/.cc-switch/cc-switch.db"
  ```
- 不要把 `cc-switch.db` 提交到 git。本仓库的 `.gitignore` 已经过滤。

---

## 路线图（Roadmap）

- [ ] 支持 macOS 远程（目前只支持 Linux 远程）
- [ ] 支持 `--dry-run` 预览不实际修改
- [ ] 支持只同步指定工具（`--only claude` / `--only codex`）
- [ ] 集成到 CC Switch 主程序的 Plugin 系统

---

## License

MIT

---

## 致谢

- [farion1231/cc-switch](https://github.com/farion1231/cc-switch) — 本工具是它的远程扩展
