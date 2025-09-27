# nvm_utils.fish - 通用工具函数模块
# 提供 nvm-fish 项目中常用的工具函数，减少代码重复

# 创建安全临时目录
function __nvm_create_temp_dir --description "创建安全的临时目录"
    set -l prefix "$argv[1]"
    if test -z "$prefix"
        set prefix "nvm-fish"
    end

    set -l temp_dir (mktemp -d "/tmp/$prefix.XXXXXX")
    if test $status -ne 0
        echo "Error: Failed to create temporary directory" >&2
        return 1
    end

    # 设置安全权限
    chmod 700 "$temp_dir"
    echo "$temp_dir"
end

# 安全的目录创建
function __nvm_ensure_dir --description "确保目录存在，如不存在则创建"
    set -l dir_path "$argv[1]"

    if not test -d "$dir_path"
        mkdir -p "$dir_path"
        if test $status -ne 0
            echo "Error: Failed to create directory $dir_path" >&2
            return 1
        end
    end

    return 0
end

# 检查命令是否可用
function __nvm_command_exists --description "检查命令是否可用"
    set -l cmd "$argv[1]"

    if command -v "$cmd" >/dev/null 2>&1
        return 0
    else
        return 1
    end
end

# 检查文件是否存在并可读
function __nvm_file_readable --description "检查文件是否存在并可读"
    set -l file_path "$argv[1]"

    if test -f "$file_path"; and test -r "$file_path"
        return 0
    else
        return 1
    end
end

# 标准化的错误处理
function __nvm_error --description "标准错误输出"
    set -l message "$argv[1]"
    set -l exit_code "$argv[2]"

    if test -z "$exit_code"
        set exit_code 1
    end

    echo -e "\033[31m❌ $message\033[0m" >&2
    return $exit_code
end

# 标准化的成功消息
function __nvm_success --description "标准成功输出"
    set -l message "$argv[1]"
    echo -e "\033[32m✅ $message\033[0m"
end

# 标准化的警告消息
function __nvm_warning --description "标准警告输出"
    set -l message "$argv[1]"
    echo -e "\033[33m⚠️  $message\033[0m" >&2
end

# 标准化的信息消息
function __nvm_info --description "标准信息输出"
    set -l message "$argv[1]"
    echo -e "\033[36mℹ️  $message\033[0m"
end

# 安全的文件删除
function __nvm_safe_remove --description "安全删除文件或目录"
    set -l target "$argv[1]"

    if test -z "$target"
        return 1
    end

    # 防止误删重要目录
    if string match -q "$HOME" "$target"
        __nvm_error "Refusing to remove HOME directory"
        return 1
    end

    if string match -q "/" "$target"
        __nvm_error "Refusing to remove root directory"
        return 1
    end

    if test -e "$target"
        rm -rf "$target"
        return $status
    end

    return 0
end

# 获取文件大小
function __nvm_file_size --description "获取文件大小（字节）"
    set -l file_path "$argv[1]"

    if not __nvm_file_readable "$file_path"
        echo 0
        return 1
    end

    stat -c "%s" "$file_path" 2>/dev/null | string trim
end

# 验证 Node.js 版本号格式
function __nvm_validate_version --description "验证 Node.js 版本号格式"
    set -l version "$argv[1]"

    # 基本格式验证
    if not string match -rq '^[0-9]+\.[0-9]+\.[0-9]+$' -- "$version"
        # 检查是否带有 npm 版本信息
        if not string match -rq '^[0-9]+\.[0-9]+\.[0-9]+ \(npm v[0-9]+\.[0-9]+\.[0-9]+\)$' -- "$version"
            return 1
        end
    end

    return 0
end

# 安全的字符串转义
function __nvm_escape_string --description "转义字符串中的特殊字符"
    set -l str "$argv[1]"
    string escape --style=script -- "$str"
end

# 检查数组是否包含元素
function __nvm_contains --description "检查数组是否包含指定元素"
    set -l item "$argv[1]"
    set -l array_name "$argv[2]"

    if not set -q $array_name
        return 1
    end

    set -l array_items $$array_name
    if contains -- "$item" $array_items
        return 0
    else
        return 1
    end
end

# 获取配置目录路径
function __nvm_get_config_dir --description "获取 nvm-fish 配置目录"
    echo "$HOME/.config/nvm_fish"
end

# 获取配置文件路径
function __nvm_get_config_file --description "获取 nvm-fish 配置文件路径"
    set -l config_dir (__nvm_get_config_dir)
    echo "$config_dir/config.json"
end

# 获取缓存文件路径
function __nvm_get_cache_file --description "获取 nvm-fish 缓存文件路径"
    set -l config_dir (__nvm_get_config_dir)
    echo "$config_dir/directory_cache.fish"
end

# 标准化的 HTTP 下载
function __nvm_download_file --description "安全地下载文件"
    set -l url "$argv[1]"
    set -l output "$argv[2]"

    if test -z "$url"; or test -z "$output"
        __nvm_error "Missing URL or output path"
        return 1
    end

    # 创建输出目录
    set -l output_dir (dirname "$output")
    __nvm_ensure_dir "$output_dir"

    # 安全的下载选项
    curl -L --fail --max-redirs 3 --max-time 30 \
         --connect-timeout 10 \
         -o "$output" \
         "$url" >/dev/null 2>&1

    return $status
end

# 验证文件完整性（基本检查）
function __nvm_verify_file --description "验证文件完整性"
    set -l file_path "$argv[1]"
    set -l min_size "$argv[2]"

    if test -z "$min_size"
        set min_size 1
    fi

    if not __nvm_file_readable "$file_path"
        return 1
    end

    set -l size (__nvm_file_size "$file_path")
    if test "$size" -lt "$min_size"
        return 1
    end

    return 0
end

# 清理函数（用于 trap）
function __nvm_cleanup --description "清理临时文件和资源"
    set -l temp_files "$argv"

    for file in $temp_files
        if test -n "$file"
            __nvm_safe_remove "$file"
        end
    end

    return 0
end