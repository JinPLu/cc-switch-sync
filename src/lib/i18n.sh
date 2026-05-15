#!/usr/bin/env bash
# lib/i18n.sh — zh-CN / en strings. Detected from CCR_LANGUAGE or LANG.

_ccr_detect_lang() {
    case "${CCR_LANGUAGE:-auto}" in
        zh|zh-CN|zh_CN) printf 'zh' ;;
        en|en-US|en_US) printf 'en' ;;
        *) case "${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}" in
               zh*|*ZH*) printf 'zh' ;;
               *)        printf 'en' ;;
           esac ;;
    esac
}
CCR_LANG="$(_ccr_detect_lang)"

t() {
    local key="$1" msg
    if [ "$CCR_LANG" = "zh" ]; then
        case "$key" in
            menu_title)       msg="CC Switch Remote Kit" ;;
            menu_connect)     msg="连接服务器" ;;
            menu_sync)        msg="同步 Provider 配置" ;;
            menu_history)     msg="下载会话历史" ;;
            menu_add)         msg="添加服务器" ;;
            menu_list)        msg="服务器列表" ;;
            menu_doctor)      msg="环境检查" ;;
            menu_settings)    msg="设置" ;;
            menu_exit)        msg="退出" ;;
            select_prompt)    msg="请选择" ;;
            invalid_choice)   msg="无效选择。" ;;
            press_enter)      msg="按回车继续" ;;
            cancelled)        msg="已取消。" ;;
            no_servers)       msg="还没有配置服务器，我们现在添加一个。" ;;
            servers_header)   msg="可用服务器" ;;
            add_server_title) msg="添加服务器" ;;
            sync_starting)    msg="开始同步" ;;
            sync_done)        msg="同步完成" ;;
            connect_target)   msg="连接" ;;
            *)                msg="$key" ;;
        esac
    else
        case "$key" in
            menu_title)       msg="CC Switch Remote Kit" ;;
            menu_connect)     msg="Connect to server" ;;
            menu_sync)        msg="Sync provider config" ;;
            menu_history)     msg="Download history" ;;
            menu_add)         msg="Add server" ;;
            menu_list)        msg="List servers" ;;
            menu_doctor)      msg="Check environment" ;;
            menu_settings)    msg="Settings" ;;
            menu_exit)        msg="Exit" ;;
            select_prompt)    msg="Select" ;;
            invalid_choice)   msg="Invalid selection." ;;
            press_enter)      msg="Press Enter to continue" ;;
            cancelled)        msg="Cancelled." ;;
            no_servers)       msg="No servers yet. Let's add one." ;;
            servers_header)   msg="Available servers" ;;
            add_server_title) msg="Add Server" ;;
            sync_starting)    msg="Start sync" ;;
            sync_done)        msg="Sync complete" ;;
            connect_target)   msg="Connecting" ;;
            *)                msg="$key" ;;
        esac
    fi
    printf '%s' "$msg"
}
