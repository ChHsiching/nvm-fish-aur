# nvm_utils.fish - Common utility functions module
# Provides utility functions for nvm-fish project to reduce code duplication

# Create secure temporary directory
function __nvm_create_temp_dir --description "Create secure temporary directory"
    set -l prefix "$argv[1]"
    if test -z "$prefix"
        set prefix "nvm-fish"
    end

    set -l temp_dir (mktemp -d "/tmp/$prefix.XXXXXX")
    if test $status -ne 0
        echo "Error: Failed to create temporary directory" >&2
        return 1
    end

    # Set secure permissions
    chmod 700 "$temp_dir"
    echo "$temp_dir"
end

# Secure directory creation
function __nvm_ensure_dir --description "Ensure directory exists, create if not"
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

# Check if command is available
function __nvm_command_exists --description "Check if command is available"
    set -l cmd "$argv[1]"

    if command -v "$cmd" >/dev/null 2>&1
        return 0
    else
        return 1
    end
end

# Check if file exists and is readable
function __nvm_file_readable --description "Check if file exists and is readable"
    set -l file_path "$argv[1]"

    if test -f "$file_path"; and test -r "$file_path"
        return 0
    else
        return 1
    end
end

# Standardized error handling
function __nvm_error --description "Standard error output"
    set -l message "$argv[1]"
    set -l exit_code "$argv[2]"

    if test -z "$exit_code"
        set exit_code 1
    end

    echo -e "\033[31m❌ $message\033[0m" >&2
    return $exit_code
end

# Standardized success message
function __nvm_success --description "Standard success output"
    set -l message "$argv[1]"
    echo -e "\033[32m✅ $message\033[0m"
end

# Standardized warning message
function __nvm_warning --description "Standard warning output"
    set -l message "$argv[1]"
    echo -e "\033[33m⚠️  $message\033[0m" >&2
end

# Standardized info message
function __nvm_info --description "Standard info output"
    set -l message "$argv[1]"
    echo -e "\033[36mℹ️  $message\033[0m"
end

# Secure file deletion
function __nvm_safe_remove --description "Safely delete files or directories"
    set -l target "$argv[1]"

    if test -z "$target"
        return 1
    end

    # Prevent accidental deletion of important directories
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

# Get file size
function __nvm_file_size --description "Get file size in bytes"
    set -l file_path "$argv[1]"

    if not __nvm_file_readable "$file_path"
        echo 0
        return 1
    end

    stat -c "%s" "$file_path" 2>/dev/null | string trim
end

# Validate Node.js version number format
function __nvm_validate_version --description "Validate Node.js version number format"
    set -l version "$argv[1]"

    # Basic format validation
    if not string match -rq '^[0-9]+\.[0-9]+\.[0-9]+$' -- "$version"
        # Check if contains npm version info
        if not string match -rq '^[0-9]+\.[0-9]+\.[0-9]+ \(npm v[0-9]+\.[0-9]+\.[0-9]+\)$' -- "$version"
            return 1
        end
    end

    return 0
end

# Secure string escaping
function __nvm_escape_string --description "Escape special characters in string"
    set -l str "$argv[1]"
    string escape --style=script -- "$str"
end

# Check if array contains element
function __nvm_contains --description "Check if array contains specified element"
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

# Get configuration directory path
function __nvm_get_config_dir --description "Get nvm-fish configuration directory"
    echo "$HOME/.config/nvm_fish"
end

# Get configuration file path
function __nvm_get_config_file --description "Get nvm-fish configuration file path"
    set -l config_dir (__nvm_get_config_dir)
    echo "$config_dir/config.json"
end

# Get cache file path
function __nvm_get_cache_file --description "Get nvm-fish cache file path"
    set -l config_dir (__nvm_get_config_dir)
    echo "$config_dir/directory_cache.fish"
end

# Standardized HTTP download
function __nvm_download_file --description "Safely download files"
    set -l url "$argv[1]"
    set -l output "$argv[2]"

    if test -z "$url"; or test -z "$output"
        __nvm_error "Missing URL or output path"
        return 1
    end

    # Create output directory
    set -l output_dir (dirname "$output")
    __nvm_ensure_dir "$output_dir"

    # Secure download options
    curl -L --fail --max-redirs 3 --max-time 30 \
         --connect-timeout 10 \
         -o "$output" \
         "$url" >/dev/null 2>&1

    return $status
end

# Verify file integrity (basic check)
function __nvm_verify_file --description "Verify file integrity"
    set -l file_path "$argv[1]"
    set -l min_size "$argv[2]"

    if test -z "$min_size"
        set min_size 1
    end

    if not __nvm_file_readable "$file_path"
        return 1
    end

    set -l size (__nvm_file_size "$file_path")
    if test "$size" -lt "$min_size"
        return 1
    end

    return 0
end

# Cleanup function (for trap)
function __nvm_cleanup --description "Clean up temporary files and resources"
    set -l temp_files "$argv"

    for file in $temp_files
        if test -n "$file"
            __nvm_safe_remove "$file"
        end
    end

    return 0
end