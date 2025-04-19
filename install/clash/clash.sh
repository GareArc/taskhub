#!/bin/bash

# Clash 简易管理脚本
# 功能：下载订阅配置并运行Clash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 配置参数
CLASH_URL="https://github.com/DustinWin/proxy-tools/releases/download/Clash-Premium/clashpremium-release-linux-amd64.tar.gz"
CLASH_DIR="/opt/clash"
CLASH_BIN="$CLASH_DIR/clash"
CONFIG_FILE="$CLASH_DIR/config.yaml"
LOCAL_CLASH_ARCHIVE="${CLASH_LOCAL_ARCHIVE}" # 环境变量指定本地包路径

# 检查root权限
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}请使用root用户或通过sudo运行此脚本${NC}"
        exit 1
    fi
}

# 安装Clash（修复文件名问题）
install_clash() {
    echo -e "${BLUE}正在安装Clash...${NC}"
    mkdir -p "$CLASH_DIR"
    
    # 在线下载
    echo -e "${YELLOW}尝试在线下载Clash...${NC}"
    if curl -L "$CLASH_URL" -o "$LOCAL_CLASH_ARCHIVE" --progress-bar; then
        echo -e "${GREEN}下载成功，正在解压...${NC}"
        # 解压到临时目录
        TEMP_DIR=$(mktemp -d)
        tar -xzf "$LOCAL_CLASH_ARCHIVE" -C "$TEMP_DIR"
        
        # 重命名CrashCore为clash
        if [ -f "$TEMP_DIR/CrashCore" ]; then
            mv "$TEMP_DIR/CrashCore" "$CLASH_BIN"
            echo -e "${GREEN}已重命名 CrashCore → clash${NC}"
        elif [ -f "$TEMP_DIR/clash" ]; then
            mv "$TEMP_DIR/clash" "$CLASH_BIN"
        else
            echo -e "${RED}错误：压缩包中未找到可执行文件${NC}"
            rm -rf "$TEMP_DIR"
            return 1
        fi
        
        rm -rf "$TEMP_DIR" "$LOCAL_CLASH_ARCHIVE"
    else
        echo -e "${YELLOW}在线下载失败，尝试使用本地文件: $LOCAL_CLASH_ARCHIVE${NC}"
        if [ -f "$LOCAL_CLASH_ARCHIVE" ]; then
            TEMP_DIR=$(mktemp -d)
            tar -xzf "$LOCAL_CLASH_ARCHIVE" -C "$TEMP_DIR"
            
            if [ -f "$TEMP_DIR/CrashCore" ]; then
                mv "$TEMP_DIR/CrashCore" "$CLASH_BIN"
                echo -e "${GREEN}已重命名 CrashCore → clash${NC}"
            elif [ -f "$TEMP_DIR/clash" ]; then
                mv "$TEMP_DIR/clash" "$CLASH_BIN"
            else
                echo -e "${RED}错误：本地压缩包中未找到可执行文件${NC}"
                rm -rf "$TEMP_DIR"
                return 1
            fi
            
            rm -rf "$TEMP_DIR"
            echo -e "${GREEN}使用本地文件安装成功${NC}"
        else
            echo -e "${RED}错误：无法获取Clash安装包，请检查网络或设置CLASH_LOCAL_ARCHIVE环境变量${NC}"
            return 1
        fi
    fi
    
    chmod +x "$CLASH_BIN"
    echo -e "${GREEN}Clash 已安装到 $CLASH_DIR${NC}"
}

# 从订阅链接更新配置
update_config() {
    if [ ! -f "$CLASH_BIN" ]; then
        echo -e "${RED}错误：请先安装Clash${NC}"
        return 1
    fi
    
    read -p "请输入Clash订阅链接: " sub_url
    if [ -z "$sub_url" ]; then
        echo -e "${RED}订阅链接不能为空!${NC}"
        return 1
    fi
    
    echo -e "${BLUE}正在下载配置文件...${NC}"
    if wget -q -O "$CONFIG_FILE" "$sub_url"; then
        echo -e "${GREEN}配置文件已更新: $CONFIG_FILE${NC}"
    else
        echo -e "${RED}下载配置文件失败!${NC}"
        return 1
    fi
}

# 运行Clash
run_clash() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}错误：配置文件不存在，请先更新配置!${NC}"
        return 1
    fi
    
    stop_clash 2>/dev/null
    
    echo -e "${BLUE}正在启动Clash...${NC}"
    nohup "$CLASH_BIN" -d "$CLASH_DIR" > "$CLASH_DIR/clash.log" 2>&1 &
    echo -e "${GREEN}Clash 已启动 (PID: $!)${NC}"
    echo -e "${YELLOW}日志文件: $CLASH_DIR/clash.log${NC}"

    # 提醒export环境变量
    echo -e "${YELLOW}请确保将以下环境变量添加到~/.bashrc或~/.bash_profile中:${NC}"
    echo -e "${YELLOW}export http_proxy=xxx:xxxx${NC}"
    echo -e "${YELLOW}export https_proxy=xxx:xxxx${NC}"
    
}

# 停止Clash
stop_clash() {
    if pgrep -f "$CLASH_BIN" >/dev/null; then
        pkill -f "$CLASH_BIN"
        echo -e "${GREEN}Clash 已停止${NC}"
    else
        echo -e "${YELLOW}Clash 未在运行${NC}"
    fi
}

# 重启Clash
restart_clash() {
    stop_clash
    run_clash
}

# 检查Clash状态
status_clash() {
    if pgrep -f "$CLASH_BIN" >/dev/null; then
        echo -e "${GREEN}Clash 正在运行${NC}"
    else
        echo -e "${RED}Clash 未运行${NC}"
    fi

    # 打开配置文件
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${BLUE}当前配置文件: ${NC}$CONFIG_FILE"
        vim "$CONFIG_FILE"
    else
        echo -e "${RED}配置文件不存在${NC}"
    fi
}

# 显示菜单
show_menu() {
    clear
    echo -e "${BLUE}==============================${NC}"
    echo -e "${GREEN}      Clash 简易管理脚本     ${NC}"
    echo -e "${BLUE}==============================${NC}"
    echo -e "1. 安装/更新 Clash"
    echo -e "2. 更新配置文件 (从订阅链接)"
    echo -e "3. 启动 Clash"
    echo -e "4. 停止 Clash"
    echo -e "5. 重启 Clash"
    echo -e "6. 查看 Clash 状态"
    echo -e "7. 一键安装+更新配置+启动"
    echo -e "0. 退出"
    echo -e "${BLUE}==============================${NC}"
    echo -e "${YELLOW}提示: 设置CLASH_LOCAL_ARCHIVE环境变量可指定本地安装包${NC}"
}

# 主函数
main() {
    check_root
    
    while true; do
        show_menu
        read -p "请输入选项 [0-7]: " option
        case $option in
            1) install_clash ;;
            2) update_config ;;
            3) run_clash ;;
            4) stop_clash ;;
            5) restart_clash ;;
            6) status_clash ;;
            7) 
                install_clash && \
                update_config && \
                run_clash
                ;;
            0) 
                echo -e "${GREEN}再见!${NC}"
                exit 0
                ;;
            *) 
                echo -e "${RED}无效选项，请重新输入${NC}" 
                ;;
        esac
        echo
        read -p "按回车键返回菜单..."
    done
}

main
