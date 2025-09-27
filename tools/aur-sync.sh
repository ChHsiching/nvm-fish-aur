#!/bin/bash

# AUR 同步脚本
# 自动将开发仓库的更改同步到 AUR 本地仓库

set -e  # 遇到错误立即退出

# 颜色定义
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# 脚本配置
DEV_REPO="/home/chhsich/Git/Mine/NVM-Fish/nvm-fish-aur"
AUR_REPO="/home/chhsich/Git/Mine/NVM-Fish/nvm-fish-aurpush"

# 打印带颜色的消息
print_message() {
    local color=$1
    local message=$2
    echo -e "${color}[$(date '+%Y-%m-%d %H:%M:%S')] ${message}${NC}"
}

# 检查仓库是否存在
check_repos() {
    print_message "$BLUE" "检查仓库状态..."

    if [ ! -d "$DEV_REPO" ]; then
        print_message "$RED" "错误: 开发仓库不存在: $DEV_REPO"
        exit 1
    fi

    if [ ! -d "$AUR_REPO" ]; then
        print_message "$RED" "错误: AUR 仓库不存在: $AUR_REPO"
        exit 1
    fi

    print_message "$GREEN" "仓库检查通过"
}

# 获取当前版本号
get_current_version() {
    local pkgbuild_path="$DEV_REPO/PKGBUILD"
    if [ ! -f "$pkgbuild_path" ]; then
        print_message "$RED" "错误: 找不到 PKGBUILD 文件: $pkgbuild_path"
        exit 1
    fi

    # 提取版本号
    local version=$(grep "^pkgver=" "$pkgbuild_path" | cut -d'=' -f2)
    echo "$version"
}

# 检查是否需要更新
check_if_update_needed() {
    local dev_version="$1"
    local aur_pkgbuild="$AUR_REPO/PKGBUILD"

    if [ ! -f "$aur_pkgbuild" ]; then
        print_message "$YELLOW" "AUR 仓库中找不到 PKGBUILD，需要更新"
        return 0
    fi

    local aur_version=$(grep "^pkgver=" "$aur_pkgbuild" | cut -d'=' -f2)

    if [ "$dev_version" = "$aur_version" ]; then
        print_message "$YELLOW" "版本号相同 (v$dev_version)，无需更新"
        return 1
    else
        print_message "$GREEN" "检测到版本更新: v$aur_version -> v$dev_version"
        return 0
    fi
}

# 复制文件到 AUR 仓库
copy_files_to_aur() {
    local version="$1"
    print_message "$BLUE" "复制文件到 AUR 仓库..."

    # 复制核心文件
    cp "$DEV_REPO/PKGBUILD" "$AUR_REPO/"
    cp "$DEV_REPO/nvm-fish.install" "$AUR_REPO/"

    # 复制 Fish 函数文件
    cp "$DEV_REPO/"*.fish "$AUR_REPO/"

    # 生成 .SRCINFO
    cd "$AUR_REPO"
    makepkg --printsrcinfo > .SRCINFO

    print_message "$GREEN" "文件复制完成"
}

# 显示更改摘要
show_changes_summary() {
    local version="$1"
    print_message "$BLUE" "=== 更改摘要 ==="
    print_message "$GREEN" "版本: v$version"
    print_message "$BLUE" "更新的文件:"

    cd "$AUR_REPO"
    git status --porcelain

    print_message "$BLUE" "=== 详细更改 ==="
    git diff --stat
}

# 显示下一步操作指南
show_next_steps() {
    local version="$1"
    cat << EOF

${GREEN}=== 同步完成！下一步操作指南 ===${NC}

${YELLOW}1. 检查更改:${NC}
   cd "$AUR_REPO"
   git status
   git diff

${YELLOW}2. 如果一切正常，提交更改:${NC}
   cd "$AUR_REPO"
   git add .
   git commit -m "Update nvm-fish to v$version"

${YELLOW}3. 推送到 AUR 远程仓库:${NC}
   git push origin master

${YELLOW}4. 验证 AUR 包:${NC}
   # 在本地测试构建
   makepkg --check

   # 检查 AUR 网站
   # https://aur.archlinux.org/packages/nvm-fish

${YELLOW}常见问题:${NC}
- 如果推送失败，请检查 SSH 密钥配置
- 如果构建失败，请检查 PKGBUILD 语法
- 如果版本号有问题，请手动编辑 PKGBUILD

${BLUE}提示: 运行以下命令快速提交并推送${NC}
   cd "$AUR_REPO" && git add . && git commit -m "Update nvm-fish to v$version" && git push origin master

EOF
}

# 显示使用说明
show_usage() {
    cat << EOF
AUR 同步脚本

用法: $(basename "$0") [选项]

选项:
    -h, --help      显示此帮助信息
    -f, --force     强制更新，即使版本号相同也执行
    -v, --version   显示当前版本号
    -s, --summary   只显示更改摘要，不执行同步

示例:
    $(basename "$0")           # 正常同步流程
    $(basename "$0") --force   # 强制更新
    $(basename "$0") --version # 显示版本号
    $(basename "$0") --summary # 显示更改摘要

EOF
}

# 主函数
main() {
    local force=false
    local summary_only=false

    # 解析命令行参数
    while [[ $# -gt 0 ]]; do
        case $1 in
            -h|--help)
                show_usage
                exit 0
                ;;
            -f|--force)
                force=true
                shift
                ;;
            -v|--version)
                echo "v$(get_current_version)"
                exit 0
                ;;
            -s|--summary)
                summary_only=true
                shift
                ;;
            *)
                print_message "$RED" "未知选项: $1"
                show_usage
                exit 1
                ;;
        esac
    done

    print_message "$GREEN" "=== AUR 同步脚本启动 ==="

    # 1. 检查仓库
    check_repos

    # 2. 获取当前版本
    local current_version=$(get_current_version)
    print_message "$BLUE" "当前开发仓库版本: v$current_version"

    # 3. 检查是否需要更新
    if ! $force && ! check_if_update_needed "$current_version"; then
        if $summary_only; then
            show_changes_summary "$current_version"
        fi
        print_message "$YELLOW" "使用 --force 强制更新"
        exit 0
    fi

    if $summary_only; then
        show_changes_summary "$current_version"
        exit 0
    fi

    # 4. 复制文件
    copy_files_to_aur "$current_version"

    # 5. 显示更改摘要
    show_changes_summary "$current_version"

    # 6. 显示下一步操作指南
    show_next_steps "$current_version"

    print_message "$GREEN" "=== AUR 同步完成 ==="
}

# 脚本入口点
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    main "$@"
fi