#!/usr/bin/env bash

# 加载库脚本
# source ./library-scripts/common.sh
# source ./library-scripts/sdkman.sh
# --- 动态路径修复 ---
SCRIPT_DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
LIBRARY_SCRIPTS_DIR="${SCRIPT_DIR}/library-scripts"
# 修复1：使用 Dev Container 的固定源路径
# LIBRARY_SCRIPTS_DIR="/tmp/build-features-src/scala-skdman_0/library-scripts"

# 调试路径
# echo "=== DEBUG ==="
# echo "Library scripts directory: ${LIBRARY_SCRIPTS_DIR}"
# ls -l "${LIBRARY_SCRIPTS_DIR}" || true
# echo "LIBRARY_SCRIPTS_DIR_r: ${LIBRARY_SCRIPTS_DIR_r}"
# ls -l  "${LIBRARY_SCRIPTS_DIR_r}" || true
# echo "============="

source "${LIBRARY_SCRIPTS_DIR}/common.sh"
source "${LIBRARY_SCRIPTS_DIR}/sdkman.sh"

# 严格错误处理
set -eo pipefail

# 参数配置
JAVA_VERSION="${SPECIFICJAVAVERSION:-"21-amzn"}"
SCALA_VERSION="${SCALAVERSION:-"latest"}"
INSTALL_SBT="${INSTALLSBT:-"false"}"
SBT_VERSION="${SBTVERSION:-"latest"}"

export SDKMAN_DIR="${SDKMAN_DIR:-"/usr/local/sdkman"}"
UPDATE_RC="${UPDATE_RC:-"true"}"

# 清理旧缓存
rm -rf /var/lib/apt/lists/*
# 权限检查
if [ "$(id -u)" -ne 0 ]; then
    echo -e 'Script must be run as root. Use sudo, su or add "USER root" to your Dockerfile before running this script.'
    exit 1
fi
# 确定运行时用户
USERNAME="$(determine_user)"
# 调试用户
echo "=== DEBUG ==="
echo "Runtime UserName: ${USERNAME}"
echo "============="
# 重置环境变量 PATH ，防止重复扩展
reset_env_path
# 检查系统架构是否支持
check_architecture
# 安装通用工具
check_packages curl ca-certificates zip unzip sed
# 安装 SDKMAN
if [ ! -d "${SDKMAN_DIR}" ]; then
    install_sdkman "${SDKMAN_DIR}" "${USERNAME}" true
    updaterc "export SDKMAN_DIR=${SDKMAN_DIR}\n. ${SDKMAN_DIR}/bin/sdkman-init.sh"
fi
# 安装 JDK （如果不存在）
if ! command -v java &> /dev/null; then
    # 在安装 Java 前添加版本校验
    if ! su ${USERNAME} -c "umask 0002 && . ${SDKMAN_DIR}/bin/sdkman-init.sh && sdk list java" | grep -q "${JAVA_VERSION}"; then
        echo "ERROR: Java version ${JAVA_VERSION} is invalid or not available."
        echo "Try 'sdk list java' to see available versions"
        exit 1
    fi
    sdk_install "java" "${JAVA_VERSION}" "${SDKMAN_DIR}" "${USERNAME}"
fi
# 安装 Scala
sdk_install "scala" "${SCALA_VERSION}" "${SDKMAN_DIR}" "${USERNAME}"
# 可选安装 SBT 
# 命令存在性检查 command -v sbt
if [[ "${INSTALL_SBT,,}" = "true" ]] && ! command -v sbt &> /dev/null; then
    sdk_install "sbt" "${SBT_VERSION}" "${SDKMAN_DIR}" "${USERNAME}"
fi

# 最终清理
cleanup_apt
echo -e "\nDone! Scala environment ready."