#!/usr/bin/env bash

NORMAL=$(tput sgr0)
RED=$(tput setaf 1)
BLUE=$(tput setaf 4)
SMUL=$(tput smul)
RMUL=$(tput rmul)

SCRIPTPATH="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

prompt() {
    while :; do
        read -p "$1 [Y/n] " yn

        case $yn in
        Y | y | yes | "") return 0 ;;
        N | n | no) return 1 ;;
        *) echo "Please select y/n or leave empty for yes." ;;
        esac
    done
}

setup_fish() {
    sudo apt-get update
    sudo apt-get install -y \
        curl \
        software-properties-common

    yes | sudo apt-add-repository ppa:fish-shell/release-3
    sudo apt-get update
    sudo apt-get install -y \
        fish

    fish -c \
        "curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish \
            | source \
            && fisher install jorgebucaran/fisher"

    fish -c "fisher install IlanCosman/tide@v6"
    fish -c "tide configure \
                --auto \
                --style=Rainbow \
                --prompt_colors='True color' \
                --show_time='24-hour format' \
                --rainbow_prompt_separators=Angled \
                --powerline_prompt_heads=Sharp \
                --powerline_prompt_tails=Sharp \
                --powerline_prompt_style='Two lines, character' \
                --prompt_connection=Dotted \
                --powerline_right_prompt_frame=No \
                --prompt_connection_andor_frame_color=Lightest \
                --prompt_spacing=Compact \
                --icons='Many icons' \
                --transient=Yes"

    echo "case \"\$TERM\" in
    xterm-256color) export COLORTERM=truecolor;;
esac" >>$HOME/.bashrc
    echo "Run ${BLUE}source \$HOME/.bashrc${NORMAL} before running fish to enable truecolor in current session"
    echo "Run ${BLUE}fish${NORMAL} to start fish"
}

setup_tmux() {
    sudo apt-get update
    sudo apt-get install -y \
        git \
        tmux \
        xclip

    git clone https://github.com/gpakosz/.tmux.git $HOME/.tmux
    ln -s -f .tmux/.tmux.conf $HOME/.tmux.conf
    ln -s -f $SCRIPTPATH/.tmux.conf.local $HOME/.tmux.conf.local
}

# Based on https://docs.docker.com/engine/install/ubuntu
setup_docker() {
    # Remove conflicting packages
    for pkg in docker.io docker-doc docker-compose docker-compose-v2 podman-docker containerd runc; do
        sudo apt-get remove $pkg
    done

    # Add Docker's official GPG key:
    sudo apt-get update
    sudo apt-get install -y ca-certificates curl
    sudo install -m 0755 -d /etc/apt/keyrings
    sudo curl -fsSL https://download.docker.com/linux/ubuntu/gpg -o /etc/apt/keyrings/docker.asc
    sudo chmod a+r /etc/apt/keyrings/docker.asc

    # Add the repository to Apt sources:
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/etc/apt/keyrings/docker.asc] \
          https://download.docker.com/linux/ubuntu $(. /etc/os-release && echo "$VERSION_CODENAME") stable" |
        sudo tee /etc/apt/sources.list.d/docker.list >/dev/null
    sudo apt-get update

    sudo apt-get install -y \
        containerd.io \
        docker-buildx-plugin \
        docker-ce \
        docker-ce-cli \
        docker-compose-plugin

    sudo groupadd docker
    sudo usermod -aG docker $USER
    newgrp docker
}

set -e

if prompt "Setup fish?"; then
    echo "Will setup fish"
    __setup_fish=true
fi

if prompt "Setup tmux?"; then
    echo "Will setup tmux"
    __setup_tmux=true
fi

if prompt "Setup docker?"; then
    echo "Will setup docker"
    __setup_docker=true
fi

echo "Starting setup, get a cup of coffee"

if [[ -v "__setup_fish" ]]; then
    echo "${BLUE}Setting up ${SMUL}fish${NORMAL}"
    setup_fish
else
    echo "${RED}Skipping ${SMUL}fish${NORMAL}"
fi

if [ -v "__setup_tmux" ]; then
    echo "${BLUE}Setting up ${SMUL}tmux${NORMAL}"
    setup_tmux
else
    echo "${RED}Skipping ${SMUL}tmux${NORMAL}"
fi

if [ -v "__setup_docker" ]; then
    echo "${BLUE}Setting up ${SMUL}docker${NORMAL}"
    setup_docker
else
    echo "${RED}Skipping ${SMUL}docker${NORMAL}"
fi
