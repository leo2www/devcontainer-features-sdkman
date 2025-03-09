#!/usr/bin/env bash

# 检查系统架构是否支持
check_architecture() {
    export DEBIAN_FRONTEND=noninteractive
    
    architecture="$(uname -m)"
    
    if [ "${architecture}" != "amd64" ] && [ "${architecture}" != "x86_64" ] && [ "${architecture}" != "arm64" ] && [ "${architecture}" != "aarch64" ]; then
        echo "(!) Architecture $architecture unsupported"
        exit 1
    fi
}

# 通用工具函数
apt_get_update() {
    if [ "$(find /var/lib/apt/lists/* | wc -l)" = "0" ]; then
        echo "Running apt-get update..."
        apt-get update -y
    fi
}

# debian apt-get 安装
check_packages() {
    if ! dpkg -s "$@" > /dev/null 2>&1; then
        apt_get_update
        apt-get -y install --no-install-recommends "$@"
    fi
}

# 重置环境变量 PATH，防止重复扩展;新增PATH 调用updaterc()即可
reset_env_path() {
    rm -f /etc/profile.d/00-restore-env.sh
    echo "export PATH=${PATH//$(sh -lc 'echo $PATH')/\$PATH}" > /etc/profile.d/00-restore-env.sh
    chmod +x /etc/profile.d/00-restore-env.sh
}
# 环境配置函数
# updaterc()
# {
#     if [ "${UPDATE_RC}" = "true" ]; then
#         echo "Updating /etc/bash.bashrc and /etc/zsh/zshrc..."

#         if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
#             echo -e "$1" >> /etc/bash.bashrc
#         fi

#         if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh.zshrc)" != *"$1"* ]]; then
#             echo -e "$1" >> /etc/zsh/zshrc
#         fi
#     fi
# }
updaterc() {
    if [ "${UPDATE_RC}" = "true" ]; then
        echo "Updating shell profiles..."

        if [[ "$(cat /etc/bash.bashrc)" != *"$1"* ]]; then
            echo -e "$1" >> /etc/bash.bashrc
        fi

        if [ -f "/etc/zsh/zshrc" ] && [[ "$(cat /etc/zsh.zshrc)" != *"$1"* ]]; then
            echo -e "$1" >> /etc/zsh/zshrc
        fi
    fi
}

# 用户处理逻辑
# if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
#     USERNAME=""
#     POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")

#     for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
#         if id -u ${CURRENT_USER} > /dev/null 2>&1; then
#             USERNAME=${CURRENT_USER}
#             break
#         fi
#     done

#     if [ "${USERNAME}" = "" ]; then
#         USERNAME=root
#     fi
# elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
#     USERNAME=root
# fi
determine_user() {
    local user="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"

    if [ "${user}" = "auto" ] || [ "${user}" = "automatic" ]; then
        user=""
        POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")

        for current_user in "${POSSIBLE_USERS[@]}"; do
            if id -u "${current_user}" > /dev/null 2>&1; then
                user="${current_user}"
                break
            fi
        done

        [ -z "${user}" ] && user=root
    elif [ "${user}" = "none" ] || ! id -u "${user}" > /dev/null 2>&1; then
        user=root
    fi

    echo "${user}"
}

# 缓存清理
cleanup_apt() {
    apt-get autoremove -y
    apt-get clean -y
    rm -rf /var/lib/apt/lists/* /var/cache/apt/archives/*
}