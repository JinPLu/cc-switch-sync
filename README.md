# cc-switch-sync

[CC Switch](https://github.com/farion1231/cc-switch) 的配套脚本，双击即可把本地的 AI Provider 配置推送到远程 Linux 服务器。

[English](README_EN.md)

## 快速开始

### 第一步：一次性准备

**本地（Windows）**

1. 安装 [CC Switch](https://github.com/farion1231/cc-switch/releases)，添加好 Provider（API Key + Base URL）
2. Settings → 关闭 `enableLocalProxy`（否则远程服务器收到的是 `localhost` 地址，连不上）

**远程服务器**（通过 `3. Add Server.bat` 可自动完成）

```bash
apt-get install -y xvfb
wget https://github.com/farion1231/cc-switch/releases/download/v3.14.1/CC-Switch-v3.14.1-Linux-amd64.deb -O /tmp/cc.deb
apt install -y /tmp/cc.deb
```

### 第二步：clone 并填写服务器列表

```bash
git clone https://github.com/JinPLu/cc-switch-sync.git
```

把 `servers.conf.example` 复制为 `servers.conf`，填入你的服务器信息。

## 使用

双击脚本运行：

| 脚本 | 用途 |
|------|------|
| `1. SSH Connect.bat` | SSH 连接到服务器 |
| `2. Sync Config.bat` | 把当前 Provider 配置推送到服务器 |
| `3. Add Server.bat` | 添加新服务器（含自动初始化） |

## `servers.conf` 格式

```
Host my-server
  HostName 10.0.0.1
  Port 22
  User root
  WorkDir /home/user/projects/
  Proxy http://10.0.0.2:18000
```

`WorkDir` 和 `Proxy` 为可选字段。`servers.conf` 已加入 `.gitignore`，不会被提交。

## License

MIT
