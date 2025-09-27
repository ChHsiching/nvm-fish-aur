# ~/.config/fish/functions/config_manager.fish
# Configuration management for nvm-fish
# Handles JSON config parsing and caching

# Configuration directory and file paths
set -g NVM_FISH_CONFIG_DIR "$HOME/.config/nvm_fish"
set -g NVM_FISH_CONFIG_FILE "$NVM_FISH_CONFIG_DIR/config.json"
set -g NVM_FISH_CACHE_FILE "$NVM_FISH_CONFIG_DIR/directory_cache.fish"
set -g NVM_FISH_CONFIG_CACHE_EXPIRY 300 # 5 minutes

# Default configuration
set -g NVM_FISH_DEFAULT_CONFIG '{"auto_switch":true,"cache_enabled":true,"cache_ttl":300,"debug_mode":false}'

# Global configuration variables
set -g __nvm_fish_config_loaded false
set -g __nvm_fish_config_cache_timestamp 0
set -g __nvm_fish_auto_switch true
set -g __nvm_fish_cache_enabled true
set -g __nvm_fish_cache_ttl 300
set -g __nvm_fish_debug_mode false

# Initialize configuration system
function __nvm_init_config --description "Initialize nvm-fish configuration"
    # Create config directory if it doesn't exist
    if not test -d "$NVM_FISH_CONFIG_DIR"
        mkdir -p "$NVM_FISH_CONFIG_DIR" 2>/dev/null
        or return 1
    end

    # Create default config file if it doesn't exist
    if not test -f "$NVM_FISH_CONFIG_FILE"
        echo "$NVM_FISH_DEFAULT_CONFIG" > "$NVM_FISH_CONFIG_FILE" 2>/dev/null
        or return 1
    end

    # Initialize cache file if it doesn't exist
    if not test -f "$NVM_FISH_CACHE_FILE"
        echo "# nvm-fish directory cache" > "$NVM_FISH_CACHE_FILE" 2>/dev/null
        or return 1
    end

    return 0
end

# Load configuration from file with caching
function __nvm_load_config --description "Load nvm-fish configuration with caching"
    # Check if we need to reload configuration
    set -l current_time (date +%s)
    if test $__nvm_fish_config_cache_timestamp -gt 0
        set -l cache_age (math $current_time - $__nvm_fish_config_cache_timestamp)
    else
        set -l cache_age $NVM_FISH_CONFIG_CACHE_EXPIRY
    end

    # Return cached config if still valid
    if test $__nvm_fish_config_loaded = true; and test $cache_age -lt $NVM_FISH_CONFIG_CACHE_EXPIRY
        return 0
    end

    # Initialize config system if needed
    if not __nvm_init_config
        echo -e " \033[31m✘ Failed to initialize nvm-fish configuration\033[0m" >&2
        return 1
    end

    # Read and parse JSON configuration
    if not test -f "$NVM_FISH_CONFIG_FILE"
        echo -e " \033[31m✘ Configuration file not found: $NVM_FISH_CONFIG_FILE\033[0m" >&2
        return 1
    end

    # Use Fish's string manipulation for basic JSON parsing
    set -l config_content (cat "$NVM_FISH_CONFIG_FILE" 2>/dev/null)
    if test -z "$config_content"
        echo -e " \033[31m✘ Failed to read configuration file\033[0m" >&2
        return 1
    end

    # Parse JSON configuration (simplified parser)
    __nvm_parse_json_config "$config_content"
    if test $status -ne 0
        echo -e " \033[31m✘ Failed to parse configuration JSON\033[0m" >&2
        return 1
    end

    # Update cache state
    set __nvm_fish_config_loaded true
    set __nvm_fish_config_cache_timestamp $current_time

    return 0
end

# Simple JSON parser for configuration
function __nvm_parse_json_config --description "Parse JSON configuration string"
    set -l json_string "$argv[1]"

    # Extract auto_switch setting
    if string match -rq '"auto_switch"\s*:\s*true' -- "$json_string"
        set -g __nvm_fish_auto_switch true
    else if string match -rq '"auto_switch"\s*:\s*false' -- "$json_string"
        set -g __nvm_fish_auto_switch false
    else
        set -g __nvm_fish_auto_switch true # default
    end

    # Extract cache_enabled setting
    if string match -rq '"cache_enabled"\s*:\s*true' -- "$json_string"
        set -g __nvm_fish_cache_enabled true
    else if string match -rq '"cache_enabled"\s*:\s*false' -- "$json_string"
        set -g __nvm_fish_cache_enabled false
    else
        set -g __nvm_fish_cache_enabled true # default
    end

    # Extract cache_ttl setting
    if string match -rq '"cache_ttl"\s*:\s*([0-9]+)' -- "$json_string"
        set -g __nvm_fish_cache_ttl (string match -rg '"cache_ttl"\s*:\s*([0-9]+)' -- "$json_string")
    else
        set -g __nvm_fish_cache_ttl 300 # default 5 minutes
    end

    # Extract debug_mode setting
    if string match -rq '"debug_mode"\s*:\s*true' -- "$json_string"
        set -g __nvm_fish_debug_mode true
    else if string match -rq '"debug_mode"\s*:\s*false' -- "$json_string"
        set -g __nvm_fish_debug_mode false
    else
        set -g __nvm_fish_debug_mode false # default
    end

    return 0
end

# Get configuration value
function __nvm_get_config --description "Get configuration value"
    set -l config_key "$argv[1]"
    set -l default_value "$argv[2]"

    # Ensure configuration is loaded
    if not __nvm_load_config
        echo "$default_value"
        return 1
    end

    # Return the requested configuration value
    switch "$config_key"
        case auto_switch
            echo "$__nvm_fish_auto_switch"
        case cache_enabled
            echo "$__nvm_fish_cache_enabled"
        case cache_ttl
            echo "$__nvm_fish_cache_ttl"
        case debug_mode
            echo "$__nvm_fish_debug_mode"
        case '*'
            echo "$default_value"
            return 1
    end

    return 0
end

# Check if auto-switch is enabled
function __nvm_is_auto_switch_enabled --description "Check if auto-switching is enabled"
    __nvm_get_config "auto_switch" "true"
    test "$argv" = "true"
end

# Check if caching is enabled
function __nvm_is_cache_enabled --description "Check if caching is enabled"
    __nvm_get_config "cache_enabled" "true"
    test "$argv" = "true"
end

# Check if debug mode is enabled
function __nvm_is_debug_mode --description "Check if debug mode is enabled"
    __nvm_get_config "debug_mode" "false"
    test "$argv" = "true"
end

# Reload configuration
function __nvm_reload_config --description "Reload nvm-fish configuration"
    set -e __nvm_fish_config_loaded
    set -e __nvm_fish_config_cache_timestamp
    __nvm_load_config
end

# Show current configuration
function __nvm_show_config --description "Show current nvm-fish configuration"
    # Ensure configuration is loaded
    if not __nvm_load_config
        echo "Failed to load configuration"
        return 1
    end

    echo "nvm-fish configuration:"
    echo "  Auto-switch:     $__nvm_fish_auto_switch"
    echo "  Cache enabled:   $__nvm_fish_cache_enabled"
    echo "  Cache TTL:       $__nvm_fish_cache_ttl seconds"
    echo "  Debug mode:      $__nvm_fish_debug_mode"
    echo ""
    echo "Configuration file: $NVM_FISH_CONFIG_FILE"
    echo "Cache file:        $NVM_FISH_CACHE_FILE"
end

# Reset configuration to defaults
function __nvm_reset_config --description "Reset nvm-fish configuration to defaults"
    echo "$NVM_FISH_DEFAULT_CONFIG" > "$NVM_FISH_CONFIG_FILE" 2>/dev/null
    if test $status -eq 0
        __nvm_reload_config
        echo "Configuration reset to defaults"
        return 0
    else
        echo "Failed to reset configuration"
        return 1
    end
end