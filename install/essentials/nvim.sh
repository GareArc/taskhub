#!/bin/bash

set -e

TMP_DIR=$(mktemp -d -t nvim-temp.XXXXXX)
SHELL="zsh"

# Cleanup trap
trap 'rm -rf "$TMP_DIR"' EXIT

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
    sudo apt-get install -y ripgrep xclip
}

# -- Main script starts here --

get_shell
install_dependencies

# Download Neovim to temp folder
pushd "$TMP_DIR" > /dev/null
curl -LO https://github.com/neovim/neovim/releases/latest/download/nvim-linux-x86_64.tar.gz
rm -rf $HOME/.local/nvim
mkdir -p $HOME/.local/nvim
tar xzf nvim-linux-x86_64.tar.gz --strip-components=1 -C "$HOME/.local/nvim"
popd > /dev/null

# update PATH
nvim_bin="$HOME/.local/nvim/bin"
shell_rc="$HOME/.${SHELL}rc"

if ! grep -q "$nvim_bin" "$shell_rc"; then
    echo "export PATH=\"\$PATH:$nvim_bin\"" >> "$shell_rc"
fi

# Install my nvim config
NVIM_CONFIG="$HOME/.config/nvim"
rm -rf "$NVIM_CONFIG"
mkdir -p "$NVIM_CONFIG"
git clone --depth=1 https://github.com/GareArc/nvchad-config "$NVIM_CONFIG"

echo "Neovim installed successfully"
source "$shell_rc"