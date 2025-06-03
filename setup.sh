#!/usr/bin/env bash

NORMAL=$(tput sgr0)
RED=$(tput setaf 1)
GREEN=$(tput setaf 2)
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

prompt_parameter() {
    local __parameter_name=$1
    shift
    local __dependencies="$@"

    if [ -v "__setup_${__parameter_name}" ]; then
        # Already defined
        return
    fi

    if [ -n "${__dependencies}" ]; then
        prompt "Setup ${__parameter_name} (depends on ${__dependencies})"
    else
        prompt "Setup ${__parameter_name}"
    fi
    local __result="$?"

    if [ "$__result" -ne "0" ]; then
        return
    fi

    eval "__setup_${__parameter_name}"=true

    for dep in "${__dependencies[@]}"; do
        if ! [ -n "${dep}" ]; then
            continue
        fi

        eval "__setup_${dep}"=true
    done
}

run_setup() {
    local __parameter_name=$1
    local __setup_name="__setup_${__parameter_name}"

    if [ "${!__setup_name}" != "true" ]; then
        # Skip
        echo "${RED}Skipping ${SMUL}${__parameter_name}${NORMAL}"
        return
    fi

    echo "${BLUE}Setting up ${SMUL}${__parameter_name}${NORMAL}"

    local __function_name="setup_${__parameter_name}"
    $__function_name
}

print_selected() {
    local __parameter_name=$1
    local __setup_name="__setup_${__parameter_name}"

    if [ "${!__setup_name}" != "true" ]; then
        echo -e "${__parameter_name}:\t${RED}NO${NORMAL}"
        return
    fi

    echo -e "${__parameter_name}:\t${GREEN}YES${NORMAL}"
}

contains_element () {
  local e match="$1"
  shift
  for e; do [[ "$e" == "$match" ]] && return 0; done
  return 1
}

setup_fish() {
    sudo apt-get update
    sudo apt-get install -y \
        curl \
        software-properties-common

    yes | sudo add-apt-repository ppa:fish-shell/release-4
    sudo apt-get update
    sudo apt-get install -y \
        fish

    mkdir -p $HOME/.config/fish/
    ln -s -f $SCRIPTPATH/config.fish $HOME/.config/fish/config.fish

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
    sudo apt-get install -y \
        ca-certificates curl \
        curl
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

    sudo groupadd docker || true
    sudo usermod -aG docker $USER || true
    newgrp docker || true
}

setup_rust() {
    sudo apt-get update
    sudo apt-get install -y \
        build-essential \
        curl \
        make

    curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y

    . "$HOME/.cargo/env"
    echo '. "$HOME/.cargo/env"' >> ~/.bashrc
}

setup_fzf() {
    git clone --depth 1 https://github.com/junegunn/fzf.git $HOME/.fzf
    $HOME/.fzf/install --no-fish --bin

    if [ "$__setup_fish" == "true" ]; then
        fish -c "fish_add_path $HOME/.fzf/bin"
        fish -c "yes | fisher install PatrickF1/fzf.fish"
    fi

    if [ "$__setup_rust" == "true" ]; then
        cargo install \
            bat \
            fd-find \
            ripgrep
    fi
}

setup_zoxide() {
    cargo install zoxide

    echo 'eval "$(zoxide init bash)"' >> ~/.bashrc
}

declare -a utilities; declare -A dependencies;

utilities+=("fish");   dependencies["fish"]=""
utilities+=("tmux");   dependencies["tmux"]=""
utilities+=("docker"); dependencies["docker"]=""
utilities+=("rust");   dependencies["rust"]=""
utilities+=("fzf");    dependencies["fzf"]=""
utilities+=("zoxide"); dependencies["zoxide"]="rust"

while [ $# -gt 0 ]; do
  case $1 in
    --no-*)
      utility="${1#--no-}"

      if contains_element "$utility" "${utilities[@]}"; then
        eval "__setup_${utility}"=false
      else
        echo "Unknown utility: '$utility'"
        exit 1
      fi
      shift
      ;;
    --*)
      utility="${1#--}"

      if contains_element "$utility" "${utilities[@]}"; then
        eval "__setup_${utility}"=true
      else
        echo "Unknown utility: '$utility'"
        exit 1
      fi
      shift
      ;;
    *)
      echo "Unknown option: '$1'"
      exit 1
      ;;
  esac
done

for utility in "${utilities[@]}"; do
    prompt_parameter $utility "${dependencies[$utility]}"
done

set -e

for utility in "${utilities[@]}"; do
    print_selected $utility
done

echo "Starting setup, get a cup of coffee"

for utility in "${utilities[@]}"; do
    run_setup $utility
done
