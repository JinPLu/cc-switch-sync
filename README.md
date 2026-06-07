# CC Switch Remote

把本机 Claude Code / Codex 的 Provider 配置同步到远程 Linux 服务器。目标很简单：下载、双击安装、打开终端菜单、选择服务器、同步。

## 下载后点哪个

解压发布包后，在根目录双击：

- Windows：`安装 Windows.bat`
- macOS：`安装 macOS.command`

macOS 如果提示无法打开，右键 `安装 macOS.command`，选择“打开”。安装完成后会创建桌面入口 `CC Switch Remote.command`，也会把 `cc-remote` 加到常见 shell 的 PATH 中。打开一个新的终端即可运行：

```sh
cc-remote
```

## 常用命令

```sh
cc-remote setup          # 首次设置向导
cc-remote                # 打开交互菜单
cc-remote doctor         # 检查本机依赖、插件、服务器
cc-remote add            # 添加服务器
cc-remote test [name]    # 测试 SSH
cc-remote sync [name]    # 同步 Provider 配置
cc-remote connect [name] # SSH 登录服务器
cc-remote history [name] # 下载远程会话历史
```

## macOS 需要准备什么

本机需要系统自带或已安装的 `ssh`、`scp`、`tar`、`python3`。如果你用 Homebrew 装了 Git 或 Python，安装器会自动把 `/opt/homebrew/bin` 和 `/usr/local/bin` 放进启动入口的 PATH。

首次设置时准备：

- 服务器 Host / IP
- SSH 端口，通常是 `22`
- SSH 用户名
- 可用的 SSH 密钥或密码
- 远端工作目录，可直接填 `~`
- 如需代理，再填代理地址

## 一行安装

macOS / Linux：

```sh
curl -fsSL https://raw.githubusercontent.com/JinPLu/cc-switch-sync/main/src/install.sh | bash
```

Windows PowerShell：

```powershell
irm https://raw.githubusercontent.com/JinPLu/cc-switch-sync/main/src/install.ps1 | iex
```

## 简单插件原则

插件就是 `src/plugins/<name>.sh` 里的一个 shell 文件。插件只做三件事：

- `doctor`：检查本机配置是否存在。
- `sync`：把配置同步到当前服务器。
- `history_paths`：声明可下载的远程历史路径。

不需要服务端常驻进程，不需要复杂依赖，不自动覆盖远程密钥。Codex `auth.json` 默认会在上传前询问确认。

更多中文说明见 [使用说明.md](使用说明.md)，插件 API 见 [src/plugins/README.md](src/plugins/README.md)。
