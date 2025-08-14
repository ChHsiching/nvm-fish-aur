# bass_helper.fish - Intelligent bass environment management and auto-configuration

function __nvm_setup_bass --description 'Setup bass environment for nvm integration'
    # Check if bass is already available
    if command -v bass >/dev/null 2>&1
        echo "✅ bass already available"
        return 0
    end

    echo "🔍 bass not found, attempting automatic installation..."

    # Check for fisher plugin manager
    if command -v fisher >/dev/null 2>&1
        echo "📦 Detected fisher, installing bass..."
        if fisher install edc/bass
            echo "✅ bass installed via fisher"
            echo "💡 Please restart your fish shell or run: exec fish"
            return 0
        end
    end

    # Check for Oh My Fish (OMF)
    if command -v omf >/dev/null 2>&1
        echo "📦 Detected Oh My Fish, installing bass..."
        if omf install bass
            echo "✅ bass installed via Oh My Fish"
            echo "💡 Please restart your fish shell or run: exec fish"
            return 0
        end
    end

    # Check for fundle
    if functions -q fundle
        echo "📦 Detected fundle, installing bass..."
        if fundle plugin 'edc/bass'
            fundle install
            echo "✅ bass installed via fundle"
            echo "💡 Please restart your fish shell or run: exec fish"
            return 0
        end
    end

    # Fallback: local bass installation
    echo "🛠️  No fish plugin manager found, setting up local bass..."
    set -l local_bass_dir "/usr/share/nvm-fish/bass"
    set -l temp_dir "/tmp/nvm-fish-bass-$USER"

    if test -d "$local_bass_dir"
        set -gx fish_function_path $fish_function_path $local_bass_dir/functions
        echo "✅ Using local bass installation"
        return 0
    end

    echo "❌ Unable to automatically install bass"
    echo ""
    echo "💡 Please install bass manually using one of these methods:"
    echo "   1. Install fisher first, then bass:"
    echo "      curl -sL https://raw.githubusercontent.com/jorgebucaran/fisher/main/functions/fisher.fish | source"
    echo "      fisher install jorgebucaran/fisher"
    echo "      fisher install edc/bass"
    echo ""
    echo "   2. Install Oh My Fish, then bass:"
    echo "      curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish"
    echo "      omf install bass"
    echo ""
    echo "   3. Visit: https://github.com/edc/bass for more installation options"
    echo ""
    return 1
end

# Auto-configure Fish shell integration
function __nvm_auto_configure_fish --description 'Configure Fish shell for nvm integration'
    set -l fish_config_file "$HOME/.config/fish/config.fish"
    
    # Check if already configured
    if test -f "$fish_config_file" && grep -q "load_nvm" "$fish_config_file"
        return 0
    end
    
    echo "🔧 Configuring nvm-fish integration in your Fish config..."
    
    # Create fish config directory if it doesn't exist
    mkdir -p "$HOME/.config/fish"
    
    # Add to config.fish
    echo "" >> "$fish_config_file"
    echo "# nvm-fish integration - added automatically" >> "$fish_config_file"
    echo "# You must call it on initialization or directory switching won't work" >> "$fish_config_file"
    echo "load_nvm > /dev/stderr" >> "$fish_config_file"
    
    echo "✅ Fish shell integration configured!"
    echo "💡 The configuration will take effect in new fish sessions"
    
    # Load immediately for current session
    load_nvm > /dev/stderr
end

# Complete setup for first run
function __nvm_first_run_setup --description 'First-time setup for nvm-fish'
    set -l setup_marker_file "$HOME/.config/nvm-fish-setup-done"
    
    # Skip if already set up
    if test -f "$setup_marker_file"
        return 0
    end
    
    echo "🎉 Welcome to nvm-fish! Setting up for first use..."
    echo ""
    
    # Setup bass environment
    if not __nvm_ensure_bass
        echo ""
        echo "⚠️  Setup incomplete. Please install bass manually and try again."
        return 1
    end
    
    # Configure Fish shell integration
    __nvm_auto_configure_fish
    
    # Create marker file to indicate setup is complete
    touch "$setup_marker_file"
    
    echo ""
    echo "🎯 Setup complete! nvm-fish is ready to use."
    echo "💡 Features enabled:"
    echo "   - All nvm commands work in Fish shell"
    echo "   - Automatic version switching with .nvmrc files"
    echo "   - Bass dependency automatically managed"
    echo ""
    echo "🚀 Try: nvm --version"
    echo ""
    
    return 0
end

# Ensure bass environment is available
function __nvm_ensure_bass --description 'Ensure bass is available for nvm commands'
    if not command -v bass >/dev/null 2>&1
        __nvm_setup_bass
    end
    
    # Final check
    if not command -v bass >/dev/null 2>&1
        echo "❌ Bass environment not available. nvm commands will not work."
        echo "💡 Please restart your fish shell after installing bass"
        return 1
    end
    
    return 0
end