#!/bin/bash

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# 路径配置
XRAY_DIR="/usr/local/xray"
XRAY_BIN="/usr/local/bin/xray"
CONFIG_FILE="/etc/xray/config.json"
SERVICE_FILE="/etc/systemd/system/xray.service"
CLASH_SUB_URL="${CLASH_SUB_URL:-}"  # 从环境变量读取Clash订阅链接

# 检查 root 权限
check_root() {
    if [ "$(id -u)" != "0" ]; then
        echo -e "${RED}错误：此脚本需要 root 权限！${NC}" >&2
        exit 1
    fi
}

# 解析 Clash 订阅并生成 Xray 配置
generate_config() {
    if [ -z "$CLASH_SUB_URL" ]; then
        echo -e "${YELLOW}未提供 CLASH_SUB_URL 环境变量，使用默认配置${NC}"
        return
    fi

    echo -e "${GREEN}正在从 Clash 订阅生成 Xray 配置...${NC}"
    TEMP_YAML="/tmp/clash_temp.yaml"
    
    # 下载订阅并解码 Base64
    wget -qO- "$CLASH_SUB_URL" | base64 -d > "$TEMP_YAML" 2>/dev/null || {
        echo -e "${RED}错误：Clash 订阅链接解码失败！${NC}"
        return
    }

    # 提取第一个 vmess/trojan 节点（示例逻辑，需根据实际情况调整）
    NODE=$(grep -A 10 "type: vmess" "$TEMP_YAML" | head -10 || grep -A 10 "type: trojan" "$TEMP_YAML" | head -10)
    if [ -z "$NODE" ]; then
        echo -e "${RED}错误：未找到支持的节点类型！${NC}"
        return
    fi

    # 提取关键参数（简化版，实际需要更复杂的解析）
    SERVER=$(echo "$NODE" | grep "server:" | awk '{print $2}')
    PORT=$(echo "$NODE" | grep "port:" | awk '{print $2}')
    UUID=$(echo "$NODE" | grep "uuid:" | awk '{print $2}')
    NETWORK=$(echo "$NODE" | grep "network:" | awk '{print $2}' || echo "tcp")

    # 生成 Xray 配置
    cat > "$CONFIG_FILE" <<EOF
{
  "inbounds": [{
    "port": 10808,
    "protocol": "socks",
    "settings": {
      "auth": "noauth"
    }
  }],
  "outbounds": [{
    "protocol": "vmess",
    "settings": {
      "vnext": [{
        "address": "$SERVER",
        "port": $PORT,
        "users": [{"id": "$UUID"}]
      }]
    },
    "streamSettings": {
      "network": "$NETWORK"
    }
  }]
}
EOF
    echo -e "${GREEN}已从 Clash 订阅生成 Xray 配置！${NC}"
}

# 安装 Xray
install_xray() {
    echo -e "${GREEN}正在安装 Xray...${NC}"
    
    mkdir -p "$XRAY_DIR" /etc/xray
    
    # 下载最新版 Xray
    LATEST_VERSION=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    DOWNLOAD_URL="https://github.com/XTLS/Xray-core/releases/download/${LATEST_VERSION}/Xray-linux-64.zip"
    
    echo -e "${YELLOW}下载 Xray ${LATEST_VERSION}...${NC}"
    wget -qO /tmp/xray.zip "$DOWNLOAD_URL"
    unzip -q /tmp/xray.zip -d "$XRAY_DIR"
    ln -sf "$XRAY_DIR/xray" "$XRAY_BIN"
    
    # 生成配置（优先使用 Clash 订阅）
    generate_config
    
    # 创建 systemd 服务
    cat > "$SERVICE_FILE" <<EOF
[Unit]
Description=Xray Service
After=network.target

[Service]
ExecStart=$XRAY_BIN -config $CONFIG_FILE
Restart=on-failure

[Install]
WantedBy=multi-user.target
EOF
    
    systemctl daemon-reload
    echo -e "${GREEN}Xray 安装完成！${NC}"
    echo -e "${CYAN}配置文件路径：$CONFIG_FILE${NC}"
}

# 卸载 Xray
uninstall_xray() {
    echo -e "${RED}正在卸载 Xray...${NC}"
    
    systemctl stop xray 2>/dev/null
    systemctl disable xray 2>/dev/null
    rm -rf "$XRAY_DIR" "$XRAY_BIN" "$CONFIG_FILE" "$SERVICE_FILE"
    systemctl daemon-reload
    
    echo -e "${GREEN}Xray 已彻底卸载！${NC}"
}

# 查看配置
show_config() {
    echo -e "${CYAN}配置文件路径：$CONFIG_FILE${NC}"
    if [ -f "$CONFIG_FILE" ]; then
        echo -e "${YELLOW}当前配置文件地址：${NC}"
        echo -e "${GREEN}$CONFIG_FILE${NC}"
    else
        echo -e "${RED}错误：配置文件不存在！${NC}"
    fi
}

# 升级 Xray
upgrade_xray() {
    echo -e "${GREEN}正在检查 Xray 更新...${NC}"
    
    LATEST_VERSION=$(curl -s https://api.github.com/repos/XTLS/Xray-core/releases/latest | grep '"tag_name":' | sed -E 's/.*"([^"]+)".*/\1/')
    CURRENT_VERSION=$("$XRAY_BIN" -version | head -n1 | awk '{print $2}')
    
    if [ "$LATEST_VERSION" = "$CURRENT_VERSION" ]; then
        echo -e "${YELLOW}当前已是最新版本：$CURRENT_VERSION${NC}"
    else
        echo -e "${YELLOW}发现新版本：$LATEST_VERSION（当前：$CURRENT_VERSION）${NC}"
        install_xray
        systemctl restart xray
        echo -e "${GREEN}Xray 已升级到最新版本！${NC}"
    fi
}

# 管理开机启动
manage_service() {
    echo -e "${YELLOW}请选择操作：${NC}"
    echo "1. 启用开机启动"
    echo "2. 禁用开机启动"
    echo "3. 重启 Xray 服务"
    read -p "请输入选项 [1-3]: " choice
    
    case "$choice" in
        1)
            systemctl enable xray
            systemctl start xray
            echo -e "${GREEN}已启用开机启动！${NC}"
            ;;
        2)
            systemctl disable xray
            systemctl stop xray
            echo -e "${RED}已禁用开机启动！${NC}"
            ;;
        3)
            systemctl restart xray
            echo -e "${GREEN}Xray 服务已重启！${NC}"
            ;;
        *)
            echo -e "${RED}无效选项！${NC}"
            ;;
    esac
}

# 主菜单
main_menu() {
    clear
    echo -e "${GREEN}Xray 客户端管理脚本${NC}"
    echo "------------------------"
    echo "1. 安装 Xray"
    echo "2. 卸载 Xray"
    echo "3. 查看配置"
    echo "4. 升级 Xray"
    echo "5. 管理开机启动"
    echo "6. 退出"
    echo "------------------------"
    
    read -p "请输入选项 [1-6]: " choice
    
    case "$choice" in
        1) check_root; install_xray ;;
        2) check_root; uninstall_xray ;;
        3) show_config ;;
        4) check_root; upgrade_xray ;;
        5) check_root; manage_service ;;
        6) exit 0 ;;
        *) echo -e "${RED}无效选项！${NC}" ;;
    esac
    
    read -p "按回车键返回主菜单..." -n 1 -r
    main_menu
}

# 启动脚本
main_menu
