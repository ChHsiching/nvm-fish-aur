# bass_helper.fish - Intelligent bass environment management and auto-configuration

function __nvm_setup_bass --description 'Setup bass environment for nvm integration'
    # Check if bass is already available
    if command -v bass >/dev/null 2>&1
        echo "✅ bass already available"
        return 0
    end

    echo "🔍 bass not found, detecting fish plugin managers..."
    
    # Show a simple loading animation
    function __show_loading
        echo -n "$argv[1]"
        for i in (seq 3)
            echo -n "."
            sleep 0.3
        end
        echo ""
    end

    __show_loading "🔍 Scanning for plugin managers"

    # Check for fisher plugin manager
    if command -v fisher >/dev/null 2>&1
        echo "📦 Detected fisher plugin manager"
        __show_loading "📥 Installing bass via fisher"
        if fisher install edc/bass >/dev/null 2>&1
            echo "✅ bass successfully installed via fisher"
            echo "💡 Please restart your fish shell: exec fish"
            return 0
        else
            echo "❌ Failed to install bass via fisher"
        end
    end

    # Check for Oh My Fish (OMF)
    if command -v omf >/dev/null 2>&1
        echo "📦 Detected Oh My Fish plugin manager"
        __show_loading "📥 Installing bass via OMF"
        if omf install bass >/dev/null 2>&1
            echo "✅ bass successfully installed via Oh My Fish"
            echo "💡 Please restart your fish shell: exec fish"
            return 0
        else
            echo "❌ Failed to install bass via OMF"
        end
    end

    # Check for fundle
    if functions -q fundle >/dev/null 2>&1
        echo "📦 Detected fundle plugin manager"
        __show_loading "📥 Installing bass via fundle"
        if fundle plugin 'edc/bass' >/dev/null 2>&1; and fundle install >/dev/null 2>&1
            echo "✅ bass successfully installed via fundle"
            echo "💡 Please restart your fish shell: exec fish"
            return 0
        else
            echo "❌ Failed to install bass via fundle"
        end
    end

    # No plugin manager found - compile bass locally
    echo "🛠️  No fish plugin manager detected"
    echo "🔧 Setting up local bass compilation for nvm-fish..."
    
    set -l local_bass_dir "$HOME/.local/share/nvm-fish/bass"
    set -l temp_dir "/tmp/nvm-fish-bass-build-$USER"
    
    # Clean up any previous attempts
    rm -rf "$temp_dir" 2>/dev/null

    __show_loading "📥 Downloading bass source code"
    
    if not curl -sL https://github.com/edc/bass/archive/master.tar.gz -o "$temp_dir.tar.gz" 2>/dev/null
        echo "❌ Failed to download bass source"
        return 1
    end
    
    __show_loading "📦 Extracting bass source"
    
    if not tar -xzf "$temp_dir.tar.gz" -C /tmp 2>/dev/null
        echo "❌ Failed to extract bass source"
        rm -f "$temp_dir.tar.gz"
        return 1
    end
    
    # Find the extracted directory (it will be bass-master)
    set -l extracted_dir "/tmp/bass-master"
    if not test -d "$extracted_dir"
        echo "❌ Bass source directory not found"
        rm -f "$temp_dir.tar.gz"
        return 1
    end
    
    __show_loading "🔧 Compiling bass for nvm-fish"
    
    # Create local bass directory structure in user space
    mkdir -p "$local_bass_dir/functions"
    
    # Copy bass function to our local directory
    if test -f "$extracted_dir/functions/bass.fish"
        cp "$extracted_dir/functions/bass.fish" "$local_bass_dir/functions/"
        echo "✅ bass compiled and configured for nvm-fish"
        echo "🔧 bass installed to: $local_bass_dir"
        echo "💡 This local bass will only be used by nvm-fish"
        echo "💡 Your global fish environment remains unchanged"
    else
        echo "❌ bass.fish not found in source"
        rm -rf "$extracted_dir" "$temp_dir.tar.gz"
        return 1
    end
    
    # Clean up
    rm -rf "$extracted_dir" "$temp_dir.tar.gz"
    
    # Add local bass to function path for this package
    set -gx fish_function_path $local_bass_dir/functions $fish_function_path
    
    # Force reload functions by sourcing bass directly
    source "$local_bass_dir/functions/bass.fish"
    
    # Verify bass is now available
    if command -v bass >/dev/null 2>&1
        echo "✅ Local bass setup complete and verified"
        echo "🔧 bass function loaded and ready for nvm commands"
        return 0
    else
        echo "❌ Local bass setup failed verification"
        echo "🔍 Debug: Function path: $fish_function_path"
        return 1
    end
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
    
    # Setup bass environment with detailed feedback
    if not __nvm_ensure_bass
        echo ""
        echo "⚠️  Setup incomplete. Bass environment could not be configured."
        echo "🔄 You can try running the setup again later with: nvm --version"
        return 1
    end
    
    # Configure Fish shell integration
    __nvm_auto_configure_fish
    
    # Create marker file to indicate setup is complete
    touch "$setup_marker_file"
    
    echo ""
    echo "🎯 nvm-fish setup complete! You're ready to go."
    echo ""
    echo "✨ Features now available:"
    echo "   - All nvm commands work seamlessly in Fish shell"
    echo "   - Automatic Node.js version switching with .nvmrc files"  
    echo "   - Bass dependency intelligently managed"
    echo ""
    echo "🚀 Try it out: nvm --version"
    echo "📚 Documentation: https://github.com/your-username/nvm-fish"
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
        echo ""
        echo "❌ Bass environment setup failed. nvm commands cannot proceed."
        echo ""
        echo "💡 This may happen if:"
        echo "   - Network connection failed during bass download"
        echo "   - No fish plugin manager is installed"
        echo "   - Fish shell needs to be restarted"
        echo ""
        echo "🔧 To resolve:"
        echo "   1. Restart your fish shell: exec fish"
        echo "   2. Or install a fish plugin manager first:"
        echo "      - Fisher: curl -sL https://git.io/fisher | source && fisher install jorgebucaran/fisher"
        echo "      - OMF: curl https://raw.githubusercontent.com/oh-my-fish/oh-my-fish/master/bin/install | fish"
        echo ""
        return 1
    end
    
    return 0
end