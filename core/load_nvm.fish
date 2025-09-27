# ~/.config/fish/functions/load_nvm.fish
# Automatically load nvm version when PWD changes

# Note: nvm_utils.fish is now installed as a core function and is always available

function load_nvm --on-variable="PWD" --description 'Automatically switch Node.js versions based on .nvmrc'
    # Fast startup optimization - skip during fish initialization
    if not set -q __nvm_fish_pwd_initialized
        set -g __nvm_fish_pwd_initialized 1
        return
    end

    # Check if nvm-fish is properly set up
    if not test -f "$HOME/.config/nvm-fish-setup-done"
        return
    end

    # Load configuration if available (on-demand)
    set -l auto_switch_enabled true
    set -l cache_enabled false

    # Try to load configuration system if not already loaded
    if not functions -q __nvm_get_config
        # Try vendor functions first
        if test -f "/usr/share/fish/vendor_functions.d/config_manager.fish"
            source "/usr/share/fish/vendor_functions.d/config_manager.fish"
        else if test -f "$HOME/.config/fish/functions/config_manager.fish"
            source "$HOME/.config/fish/functions/config_manager.fish"
        end
    end

    # Use configuration if available
    if functions -q __nvm_get_config
        set auto_switch_enabled (__nvm_get_config "auto_switch" "true")
        set cache_enabled (__nvm_get_config "cache_enabled" "false")
    end

    # Exit if auto-switch is disabled
    if test "$auto_switch_enabled" != "true"
        return
    end

    # Ensure bass is available
    if not __nvm_ensure_bass_available
        return
    end

    # Find .nvmrc file
    set -l nvmrc_path (__nvm_find_nvmrc_file "$cache_enabled")

    # Process .nvmrc file or revert to default
    if test -n "$nvmrc_path"; and test -f "$nvmrc_path"
        __nvm_process_nvmrc "$nvmrc_path"
    else
        __nvm_revert_to_default
    end
end

# Ensure bass is available
function __nvm_ensure_bass_available
    if command -v bass >/dev/null 2>&1
        return 0
    end

    if test -f "$HOME/.config/fish/functions/bass.fish"
        source "$HOME/.config/fish/functions/bass.fish" 2>/dev/null
        if command -v bass >/dev/null 2>&1
            return 0
        end
    end

    return 1
end

# Find .nvmrc file with optional caching
function __nvm_find_nvmrc_file
    set -l cache_enabled "$argv[1]"

    if test "$cache_enabled" = "true"
        # Try to load cache system if not already loaded
        if not functions -q __nvm_get_cached_nvmrc_path
            if test -f "/usr/share/fish/vendor_functions.d/cache_manager.fish"
                source "/usr/share/fish/vendor_functions.d/cache_manager.fish"
            else if test -f "$HOME/.config/fish/functions/cache_manager.fish"
                source "$HOME/.config/fish/functions/cache_manager.fish"
            end
        end

        # Use cached lookup if cache system is available
        if functions -q __nvm_get_cached_nvmrc_path; and functions -q __nvm_find_nvmrc_cached
            # Use cached lookup
            set -l cached_result (__nvm_get_cached_nvmrc_path "$PWD")
            if test -n "$cached_result"
                if test "$cached_result" = "NO_NVMRC"
                    echo ""
                else
                    echo "$cached_result"
                end
                return
            end
        end

        # Perform lookup and cache result
        set -l start_time (date +%s%3N)
        set -l result (__nvm_find_nvmrc_cached "$PWD")
        set -l end_time (date +%s%3N)
        set -l lookup_time (math $end_time - $start_time)

        # Debug output
        if functions -q __nvm_is_debug_mode; and __nvm_is_debug_mode
            echo -e " \033[36m🔍 .nvmrc lookup took: $lookup_time ms\033[0m" >&2
        end

        echo "$result"
        return
    end

    # Direct lookup without caching
    if functions -q __nvm_find_nvmrc_direct
        __nvm_find_nvmrc_direct "$PWD"
    else
        # Simple directory search
        set -l current_dir "$PWD"
        set -l nvmrc_path ""
        while test -z "$nvmrc_path"; and test "$current_dir" != "/"
            if test -f "$current_dir/.nvmrc"
                set nvmrc_path "$current_dir/.nvmrc"
            else
                set current_dir (dirname "$current_dir")
            end
        end
        echo "$nvmrc_path"
    end
end

# Process .nvmrc file and switch version
function __nvm_process_nvmrc
    set -l nvmrc_path "$argv[1]"

    set -l nvmrc_content (cat "$nvmrc_path" 2>/dev/null | string trim)
    if test -z "$nvmrc_content"
        return
    end

    # Extract target version
    set -l target_version (string replace 'v' '' "$nvmrc_content")
    set -l pure_version (__nvm_extract_pure_version "$target_version")

    # Check if already on correct version
    set -l current_version (node --version 2>/dev/null | string replace 'v' '')
    if test "$current_version" = "$pure_version"
        if functions -q __nvm_is_debug_mode; and __nvm_is_debug_mode
            echo -e " \033[36m💨 Already on correct version: $pure_version\033[0m" >&2
        end
        return
    end

    # Switch to target version
    __nvm_switch_to_version "$pure_version"
end

# Extract pure version number (remove npm info)
function __nvm_extract_pure_version
    set -l version "$argv[1]"
    set -l version_regex '^([0-9]+\.[0-9]+\.[0-9]+)'

    if string match -rq $version_regex "$version"
        string match -rg $version_regex "$version"
    else
        echo "$version"
    end
end

# Switch to specific Node.js version
function __nvm_switch_to_version
    set -l version "$argv[1]"

    # Check if version is installed
    set -l installed_version (nvm version "$version" 2>/dev/null)
    if test "$installed_version" = "N/A"
        # Install version
        __nvm_install_version "$version"
    else
        # Use existing version
        __nvm_use_version "$version"
    end
end

# Install Node.js version
function __nvm_install_version
    set -l version "$argv[1]"

    set -lx NVM_AUTO 1
    bass source ~/.nvm/nvm.sh --no-use ';' nvm install "$version"
end

# Use specific Node.js version
function __nvm_use_version
    set -l version "$argv[1]"

    set -lx NVM_AUTO 1
    bass source ~/.nvm/nvm.sh --no-use ';' nvm use "$version"
end

# Revert to default Node.js version
function __nvm_revert_to_default
    set -l default_version (nvm version default 2>/dev/null)
    if test -z "$default_version"
        return
    end

    set -l default_bin "$HOME/.nvm/versions/node/$default_version/bin"

    # Only revert if not already on default
    if test -n "$NVM_BIN"; and test "$NVM_BIN" != "$default_bin"
        set -lx NVM_AUTO 1
        # Check if nvm.sh exists before sourcing
        if test -f "$HOME/.nvm/nvm.sh"
            bass source ~/.nvm/nvm.sh --no-use ';' nvm use default
        else if command -v nvm >/dev/null 2>&1
            # Try to find nvm.sh using nvm command
            set -l nvm_dir (nvm_dir 2>/dev/null)
            if test -n "$nvm_dir"; and test -f "$nvm_dir/nvm.sh"
                bass source "$nvm_dir/nvm.sh" --no-use ';' nvm use default
            else
                echo "Warning: Could not find nvm.sh, cannot switch to default version" >&2
            end
        else
            echo "Warning: nvm not installed or not in PATH" >&2
        end
    else
        if functions -q __nvm_is_debug_mode; and __nvm_is_debug_mode
            echo -e " \033[36m📭 No .nvmrc found, staying on current version\033[0m" >&2
        end
    end
end