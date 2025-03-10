#!/bin/bash

# 错误则终止构建
set -e
# 读取用户传入的版本参数
TORCH_VERSION=${VERSION:-"cu126"}
PYTHON_PATH_FILES=$(ls "${PYTHON_PATH}")
# remoteUser自动注入
USERNAME="${USERNAME:-"${_REMOTE_USER:-"automatic"}"}"
echo "USERNAME is '$USERNAME'"

# Bring in ID, ID_LIKE, VERSION_ID, VERSION_CODENAME
. /etc/os-release
# Get an adjusted ID independent of distro variants
MAJOR_VERSION_ID=$(echo ${VERSION_ID} | cut -d . -f 1)
if [ "${ID}" = "debian" ] || [ "${ID_LIKE}" = "debian" ]; then
    ADJUSTED_ID="debian"
elif [[ "${ID}" = "rhel" || "${ID}" = "fedora" || "${ID}" = "mariner" || "${ID_LIKE}" = *"rhel"* || "${ID_LIKE}" = *"fedora"* || "${ID_LIKE}" = *"mariner"* ]]; then
    ADJUSTED_ID="rhel"
    if [[ "${ID}" = "rhel" ]] || [[ "${ID}" = *"alma"* ]] || [[ "${ID}" = *"rocky"* ]]; then
        VERSION_CODENAME="rhel${MAJOR_VERSION_ID}"
    else
        VERSION_CODENAME="${ID}${MAJOR_VERSION_ID}"
    fi
else
    echo "Linux distro ${ID} not supported."
    exit 1
fi


# 读取 PYthon 解释器路径 验证Python可执行文件存在
PYTHON_SRC="${PYTHON_PATH}/python3"
if ! type pip >/dev/null 2>&1 && type pip3 >/dev/null 2>&1; then
    ln -s /usr/bin/pip3 /usr/bin/pip
else
    PYTHON_SRC=$(which python)
    if [ ! -f "${PYTHON_SRC}" ]; then
        echo "错误：未找到 ${PYTHON_PATH}/python3"
        exit 1
    fi
fi
PYTHON_PREFIX=$(dirname "$(dirname "$PYTHON_SRC")")
echo "Python in '$PYTHON_SRC'"
echo "Python_path in '$PYTHON_PREFIX'"


# Determine the appropriate non-root user
if [ "${USERNAME}" = "auto" ] || [ "${USERNAME}" = "automatic" ]; then
    USERNAME=""
    POSSIBLE_USERS=("vscode" "node" "codespace" "$(awk -v val=1000 -F ":" '$3==val{print $1}' /etc/passwd)")
    for CURRENT_USER in "${POSSIBLE_USERS[@]}"; do
        if id -u ${CURRENT_USER} > /dev/null 2>&1; then
            USERNAME=${CURRENT_USER}
            break
        fi
    done
    if [ "${USERNAME}" = "" ]; then
        USERNAME=root
    fi
elif [ "${USERNAME}" = "none" ] || ! id -u ${USERNAME} > /dev/null 2>&1; then
    USERNAME=root
fi
# 是否以root 身份运行
INSTALL_UNDER_ROOT=true
if [ "$(id -u)" -eq 0 ] && [ "$USERNAME" != "root" ]; then
    INSTALL_UNDER_ROOT=false
fi
echo "user is ${USRNAME} "
# 根据用户选择sudo / su
sudo_if() {
    COMMAND="$*"
    if [ "$(id -u)" -eq 0 ] && [ "$USERNAME" != "root" ]; then
        su - "$USERNAME" -c "$COMMAND"
    else
        $COMMAND
    fi
}
# 安装Python包,root 或 user  动态参数捕获
install_user_package() {
    INSTALL_UNDER_ROOT="$1"
    shift  # 移除首个参数，剩余参数作为安装包和选项
    PACKAGES_AND_OPTIONS=("$@")

    if [ "$INSTALL_UNDER_ROOT" = true ]; then
        sudo_if "${PYTHON_SRC}" -m pip install --upgrade --no-cache-dir --prefix=$PYTHON_PREFIX "${PACKAGES_AND_OPTIONS[@]}"
    else
        sudo_if "${PYTHON_SRC}" -m pip install  --upgrade --no-cache-dir --prefix=$PYTHON_PREFIX "${PACKAGES_AND_OPTIONS[@]}"
    fi
}
echo "Installing PyTorch with version ${TORCH_VERSION} with in ${PYTHON_SRC}"
# 安装PyTorch及相关库
install_user_package $INSTALL_UNDER_ROOT torch torchvision torchaudio --default-timeout=600 --index-url "https://download.pytorch.org/whl/${TORCH_VERSION}"



# Clean up 清理不同 Linux 发行版的软件包管理器缓存文件
clean_up() {
    case ${ADJUSTED_ID} in
        debian)
            rm -rf /var/lib/apt/lists/*
            ;;
        rhel)
            rm -rf /var/cache/dnf/* /var/cache/yum/*
            rm -rf /tmp/yum.log
            rm -rf ${GPG_INSTALL_PATH}
            ;;
    esac
}
# Clean up
clean_up

echo "Done!"
