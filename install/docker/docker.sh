#!/bin/bash

set -e
OS=${OS:-linux}

# Check if Docker is already installed
if command -v docker &> /dev/null; then
    echo "Docker is already installed."
    exit 0
fi

install_on_linux() {
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do sudo apt-get remove $pkg; done

    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo \
    "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] https://download.docker.com/linux/ubuntu \
    $(. /etc/os-release && echo "${UBUNTU_CODENAME:-$VERSION_CODENAME}") stable" | \
    sudo tee /etc/apt/sources.list.d/docker.list > /dev/null
    sudo apt-get update

    sudo apt-get install docker-ce docker-ce-cli containerd.io docker-buildx-plugin docker-compose-plugin

}

install_on_mac() {
    echo "Currently, Docker installation on Mac is not supported in this script."
    exit 1
}

install_on_windows() {
    echo "Currently, Docker installation on Windows is not supported in this script."
    exit 1
}

install_on_freebsd() {
    echo "Currently, Docker installation on FreeBSD is not supported in this script."
    exit 1
}

install_on_darwin() {
    echo "Currently, Docker installation on Darwin is not supported in this script."
    exit 1
}

verify_installation() {
    # Verify that Docker is installed correctly by running the hello-world image
    sudo docker run hello-world
}

# -- Main script starts here --
if [[ "$OS" == "linux" ]]; then
    install_on_linux
elif [[ "$OS" == "mac" ]]; then
    install_on_mac
elif [[ "$OS" == "windows" ]]; then
    install_on_windows
elif [[ "$OS" == "freebsd" ]]; then
    install_on_freebsd
elif [[ "$OS" == "darwin" ]]; then
    install_on_darwin
else
    echo "Unsupported OS: $OS"
    exit 1
fi

verify_installation
echo "Docker installed successfully."

