#!/usr/bin/env bash

# SDKMAN 管理函数
# if [ ! -d "${SDKMAN_DIR}" ]; then
#     if ! cat /etc/group | grep -e "^sdkman:" > /dev/null 2>&1; then
#         groupadd -r sdkman
#     fi

#     usermod -a -G sdkman ${USERNAME}
#     umask 0002

#     curl -sSL "https://get.sdkman.io" | bash
#     chown -R "${USERNAME}:sdkman" ${SDKMAN_DIR}
#     find ${SDKMAN_DIR} -type d -print0 | xargs -d '\n' -0 chmod g+s
#     updaterc "export SDKMAN_DIR=${SDKMAN_DIR}\n. \${SDKMAN_DIR}/bin/sdkman-init.sh"
# fi
install_sdkman() {
    local sdkman_dir="${1:-/usr/local/sdkman}"
    local username="${2:-vscode}"
    local update_rc="${3:-true}"

    if [ ! -d "${sdkman_dir}" ]; then
        echo "Installing SDKMAN..."

        if ! grep -q "^sdkman:" /etc/group; then
            groupadd -r sdkman
        fi

        usermod -a -G sdkman "${username}"

        # 设置临时环境变量以控制安装位置
        export SDKMAN_DIR="${sdkman_dir}"
        
        curl -sSL "https://get.sdkman.io" | bash
        chown -R "${username}:sdkman" "${sdkman_dir}"
        find "${sdkman_dir}" -type d -exec chmod g+s {} \;
    fi
}

# 安装 sdk
# sdk_install()
# {
#     local candidate=$1
#     local requested_version=$2

#     if [ "${requested_version}" = "none" ]; then return; fi

#     if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "lts" ] || [ "${requested_version}" = "default" ]; then
#         requested_version=""
#     fi

#     su ${USERNAME} -c "umask 0002 && . ${SDKMAN_DIR}/bin/sdkman-init.sh && sdk install ${candidate} ${requested_version} && sdk flush archives && sdk flush temp"
# }
sdk_install() {
    local candidate="$1"
    local requested_version="${2:-latest}"
    local sdkman_dir="${3:-/usr/local/sdkman}"
    local username="${4:-vscode}"

    if [ "${requested_version}" = "none" ]; then return; fi

    if [ "${requested_version}" = "latest" ] || [ "${requested_version}" = "lts" ] || [ "${requested_version}" = "default" ]; then
        requested_version=""
    fi

    su ${username} -c "umask 0002 && . ${sdkman_dir}/bin/sdkman-init.sh && sdk install ${candidate} ${requested_version} && sdk flush archives && sdk flush temp"
    # su - "${username}" -c "
    #     source \"${sdkman_dir}/bin/sdkman-init.sh\"
    #     sdk install ${candidate} ${version}
    #     sdk flush archives
    #     sdk flush temp
    # "
}