#!bin/sh

OS="${OS:-$(uname -s)}"
ARCH="${ARCH:-$(uname -m)}"
ZSH_CUSTOM="${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}"

install_for_ubuntu() {
    # 1. 安装 Oh My Zsh（防止自动退出）
    RUNZSH=no CHSH=no sh -c "$(curl -fsSL https://raw.github.com/ohmyzsh/ohmyzsh/master/tools/install.sh)"
    
    # 2. 安装主题
    echo "安装 powerlevel10k 主题..."
    git clone --depth=1 https://github.com/romkatv/powerlevel10k.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/themes/powerlevel10k" || {
        echo "主题安装失败"
        return 1
    }
    
    # 3. 修改主题配置
    sed -i 's/ZSH_THEME=".*"/ZSH_THEME="powerlevel10k\/powerlevel10k"/' ~/.zshrc
    
    # 4. 安装插件
    echo "安装 zsh-autosuggestions 插件..."
    git clone https://github.com/zsh-users/zsh-autosuggestions "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-autosuggestions" || {
        echo "zsh-autosuggestions 安装失败"
        return 1
    }
    
    echo "安装 zsh-syntax-highlighting 插件..."
    git clone https://github.com/zsh-users/zsh-syntax-highlighting.git "${ZSH_CUSTOM:-$HOME/.oh-my-zsh/custom}/plugins/zsh-syntax-highlighting" || {
        echo "zsh-syntax-highlighting 安装失败"
        return 1
    }
    
    # 5. 修改插件配置（更安全的 sed 命令）
    sed -i 's/^plugins=(.*)/plugins=(git zsh-autosuggestions zsh-syntax-highlighting z)/' ~/.zshrc
    
    # 6. 提示用户手动 source 或重启终端
    echo -e "\n安装完成！请执行以下命令生效："
    echo "source ~/.zshrc"
    echo "或重新打开终端"
}

main() {
    case "$OS" in
        Linux)
            if [ "$ARCH" = "x86_64" ]; then
                install_for_ubuntu
            else
                echo "不支持的架构：$ARCH"
                return 1
            fi
            ;;
        Darwin)
            echo "macOS 系统不支持自动安装 Oh My Zsh"
            return 1
            ;;
        *)
            echo "不支持的操作系统：$OS"
            return 1
            ;;
    esac
}

main