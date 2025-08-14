# bass_helper.fish - 智能bass环境管理和自动配置

function __nvm_setup_bass
    # 检查bass是否已经可用
    if command -v bass >/dev/null 2>&1
        echo "✅ bass already available"
        return 0
    end

    echo "🔍 bass not found, attempting automatic setup..."

    # 检查fisher插件管理器
    if command -v fisher >/dev/null 2>&1
        echo "📦 Detected fisher, installing bass..."
        if fisher install edc/bass
            echo "✅ bass installed via fisher"
            return 0
        end
    end

    # 检查Oh My Fish (OMF)
    if command -v omf >/dev/null 2>&1
        echo "📦 Detected Oh My Fish, installing bass..."
        if omf install bass
            echo "✅ bass installed via Oh My Fish"
            return 0
        end
    end

    # 本地安装bass作为备选方案
    echo "🛠️  Setting up local bass installation..."
    set -l local_bass_dir "/usr/share/nvm-fish/bass"
    set -l temp_dir "/tmp/nvm-fish-bass-$USER"

    if test -d "$local_bass_dir"
        set -gx fish_function_path $fish_function_path $local_bass_dir/functions
        return 0
    end

    echo "❌ Unable to automatically install bass"
    echo "💡 Please manually install bass using one of these methods:"
    echo "   - fisher install edc/bass"
    echo "   - omf install bass"
    return 1
end

# 自动配置Fish shell集成
function __nvm_auto_configure_fish
    set -l fish_config_file "$HOME/.config/fish/config.fish"
    
    # 检查是否已经配置过
    if test -f "$fish_config_file" && grep -q "load_nvm" "$fish_config_file"
        return 0
    end
    
    echo "🔧 Setting up nvm-fish integration in your Fish config..."
    
    # 创建fish配置目录（如果不存在）
    mkdir -p "$HOME/.config/fish"
    
    # 添加到config.fish
    echo "" >> "$fish_config_file"
    echo "# nvm-fish integration - added automatically" >> "$fish_config_file"
    echo "load_nvm > /dev/stderr" >> "$fish_config_file"
    
    echo "✅ Fish shell integration configured!"
    
    # 立即加载配置
    load_nvm > /dev/stderr
end

# 首次运行时的完整设置
function __nvm_first_run_setup
    set -l setup_marker_file "$HOME/.config/nvm-fish-setup-done"
    
    # 如果已经设置过，直接返回
    if test -f "$setup_marker_file"
        return 0
    end
    
    echo "🎉 Welcome to nvm-fish! Setting up for first use..."
    
    # 设置bass环境
    if not __nvm_ensure_bass
        return 1
    end
    
    # 配置Fish shell集成
    __nvm_auto_configure_fish
    
    # 创建标记文件表示已完成设置
    touch "$setup_marker_file"
    
    echo "🎯 Setup complete! You can now use nvm commands in Fish shell."
    
    return 0
end

# 检查bass环境并在需要时自动设置
function __nvm_ensure_bass
    if not command -v bass >/dev/null 2>&1
        __nvm_setup_bass
    end
    
    # 最终检查
    if not command -v bass >/dev/null 2>&1
        echo "❌ Unable to setup bass environment. nvm commands will not work."
        return 1
    end
    
    return 0
end