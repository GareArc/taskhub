#!/bin/bash

# Clash 系统服务管理脚本
# 使用 systemd 服务管理，更稳定可靠

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 配置参数
LOCAL_INSTALL="${LOCAL_INSTALL:-false}" # 是否使用本地安装
CLASH_URL="https://github.com/DustinWin/proxy-tools/releases/download/Clash-Premium/clashpremium-release-linux-amd64.tar.gz"
CLASH_DIR="/usr/local/clash"
CLASH_BIN="$CLASH_DIR/clash"
CONFIG_FILE="$CLASH_DIR/config.yaml"
SERVICE_FILE="/etc/systemd/system/clash.service"
LOCAL_CLASH_ARCHIVE="${CLASH_LOCAL_ARCHIVE:-/tmp/clash.tar.gz}"

# 检查root权限
check_root() {
    if [ "$(id -u)" -ne 0 ]; then
        echo -e "${RED}请使用root用户或通过sudo运行此脚本${NC}"
        exit 1
    fi
}

# 安装Clash
install_clash() {
    echo -e "${BLUE}正在安装Clash...${NC}"
    mkdir -p "$CLASH_DIR"
    
    # 在线下载
    echo -e "${YELLOW}尝试在线下载Clash...${NC}"
    if [ "$LOCAL_INSTALL" = "false" ]; then
        curl -L "$CLASH_URL" -o "$LOCAL_CLASH_ARCHIVE" --progress-bar
        echo -e "${GREEN}下载成功，正在解压...${NC}"
        TEMP_DIR=$(mktemp -d)
        tar -xzf "$LOCAL_CLASH_ARCHIVE" -C "$TEMP_DIR"
        
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
            echo -e "${RED}错误：无法获取Clash安装包${NC}"
            return 1
        fi
    fi
    
    chmod +x "$CLASH_BIN"
    
    # 创建systemd服务
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Clash Proxy Service
After=network.target

[Service]
Type=simple
User=root
Group=root
ExecStart=$CLASH_BIN -d $CLASH_DIR
Restart=always
RestartSec=3
LimitNOFILE=65536

[Install]
WantedBy=multi-user.target
EOF

    # 验证服务文件创建
    if [ ! -f "$SERVICE_FILE" ]; then
        echo -e "${RED}错误：服务文件创建失败 $SERVICE_FILE${NC}"
        return 1
    fi

    echo -e "${GREEN}服务文件创建成功${NC}"
    chmod 644 "$SERVICE_FILE"
    
    # 重载systemd并验证
    echo -e "${YELLOW}重载systemd配置...${NC}"
    if ! systemctl daemon-reload; then
        echo -e "${RED}systemd重载失败！${NC}"
        return 1
    fi
    
    # 验证服务是否注册
    if ! systemctl list-unit-files | grep -q clash.service; then
        echo -e "${RED}错误：服务未正确注册！${NC}"
        echo -e "${YELLOW}尝试手动重载：${NC}"
        echo "1. sudo systemctl daemon-reload"
        echo "2. sudo systemctl reset-failed"
        return 1
    fi

    echo -e "${GREEN}Clash 已安装并配置为系统服务${NC}"
    echo -e "${YELLOW}使用以下命令控制：${NC}"
    echo "启动服务：sudo systemctl start clash"
    echo "开机启动：sudo systemctl enable clash"
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
        # 重启服务使配置生效
        systemctl restart clash
    else
        echo -e "${RED}下载配置文件失败!${NC}"
        return 1
    fi
}

# 服务状态检查
service_status() {
    # 先检查服务文件是否存在
    if [ ! -f "$SERVICE_FILE" ]; then
        echo -e "${RED}错误：服务文件不存在 (请先安装)${NC}"
        return 1
    fi
    
    # 检查服务是否加载
    if ! systemctl list-unit-files | grep -q clash.service; then
        echo -e "${RED}服务未加载，尝试执行：${NC}"
        echo -e "sudo systemctl daemon-reload"
        return 1
    fi
    
    # 检查服务状态
    echo -e "${CYAN}====== 服务状态 ======${NC}"
    systemctl status clash --no-pager -l || echo -e "${RED}获取状态失败${NC}"
    
    # 检查进程
    echo -e "\n${CYAN}====== 进程信息 ======${NC}"
    if pgrep -f "$CLASH_BIN" >/dev/null; then
        echo -e "${GREEN}Clash 进程正在运行${NC}"
        ps -fp $(pgrep -f "$CLASH_BIN")
    else
        echo -e "${RED}未找到运行中的Clash进程${NC}"
    fi
    
    # 检查端口
    local api_port=$(grep 'external-controller' "$CONFIG_FILE" | awk -F: '{print $NF}')
    if [ -n "$api_port" ]; then
        echo -e "\n${CYAN}====== 端口检查 ======${NC}"
        if ss -tulnp | grep -q ":$api_port"; then
            echo -e "${GREEN}API 端口 $api_port 正在监听${NC}"
        else
            echo -e "${RED}API 端口 $api_port 未监听${NC}"
        fi
    fi
}

# 显示配置信息
show_config() {
    if [ ! -f "$CONFIG_FILE" ]; then
        echo -e "${RED}配置文件不存在: $CONFIG_FILE${NC}"
        return 1
    fi

    echo -e "${CYAN}======= 基本配置信息 =======${NC}"
    grep -E '^(mixed-port|socks-port|port|redir-port|mode|log-level|allow-lan|external-controller|secret):' "$CONFIG_FILE"

    echo -e "\n${CYAN}======= 服务状态 =======${NC}"
    service_status
}

# 显示菜单
show_menu() {
    clear
    echo -e "${BLUE}==============================${NC}"
    echo -e "${GREEN}     Clash 系统服务管理脚本    ${NC}"
    echo -e "${BLUE}==============================${NC}"
    echo -e "1. 安装/更新 Clash"
    echo -e "2. 更新配置文件 (从订阅链接)"
    echo -e "3. 启动 Clash 服务"
    echo -e "4. 停止 Clash 服务"
    echo -e "5. 重启 Clash 服务"
    echo -e "6. 查看服务状态"
    echo -e "7. 查看配置信息"
    echo -e "8. 设置开机启动"
    echo -e "9. 禁用开机启动"
    echo -e "10. 一键安装+更新配置+启动"
    echo -e "0. 退出"
    echo -e "${BLUE}==============================${NC}"
}

# 主函数
main() {
    check_root
    
    while true; do
        show_menu
        read -p "请输入选项 [0-10]: " option
        case $option in
            1) install_clash ;;
            2) update_config ;;
            3) systemctl start clash ;;
            4) systemctl stop clash ;;
            5) systemctl restart clash ;;
            6) service_status ;;
            7) show_config ;;
            8) systemctl enable clash ;;
            9) systemctl disable clash ;;
            10) 
                install_clash && \
                update_config && \
                systemctl start clash
                ;;
            0) 
                echo -e "${GREEN}操作完成，再见!${NC}"
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
