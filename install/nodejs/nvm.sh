#!/bin/bash

set -e

SHELL="zsh"
if [ -n "$NODE_VERSION" ]; then
    echo "NODE_VERSION is set to $NODE_VERSION"
else
    echo "NODE_VERSION is not set, defaulting to 18"
    NODE_VERSION="18"
fi

check_nvm_installed() {
    if command -v nvm &> /dev/null
    then
        echo "nvm is already installed"
        return 0
    else
        echo "nvm is not installed"
        return 1
    fi
}

get_shell() {
    if [ -n "$BASH_VERSION" ]; then
        SHELL="bash"
    elif [ -n "$ZSH_VERSION" ]; then
        SHELL="zsh"
    else
        echo "unknown shell"
        exit 1
    fi
}

install_dependencies() {
    sudo apt-get update
    sudo apt-get install -y curl git
}

get_latest_nvm_version() {
    curl -s https://api.github.com/repos/nvm-sh/nvm/releases/latest | grep -oP '"tag_name": "\K(.*)(?=")'
}

# check if nvm is installed using defined function
if check_nvm_installed; then
    exit 0
else
    echo "prepared to install nvm" 
fi

get_shell
install_dependencies

# install nvm
echo "Installing nvm..."
curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/$(get_latest_nvm_version)/install.sh | bash

# add nvm to shell configuration


# load nvm
export NVM_DIR="$HOME/.nvm"
[ -s "$NVM_DIR/nvm.sh" ] && \. "$NVM_DIR/nvm.sh"  # This loads nvm
[ -s "$NVM_DIR/bash_completion" ] && \. "$NVM_DIR/bash_completion"  # This loads nvm bash_completion


if check_nvm_installed; then
    echo "nvm installed successfully"
else
    echo "nvm installation failed"
    exit 1
fi