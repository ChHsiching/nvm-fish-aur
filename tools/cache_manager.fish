# ~/.config/fish/functions/cache_manager.fish
# Directory cache management for nvm-fish performance optimization

# Cache data structure
# Key: directory path
# Value: "NO_NVMRC" or "/path/to/.nvmrc"

# Global cache variables
set -g __nvm_fish_cache_loaded false
set -g __nvm_fish_cache_data
set -g __nvm_fish_cache_timestamp 0
set -g __nvm_fish_cache_hits 0
set -g __nvm_fish_cache_misses 0
set -g __nvm_fish_cache_max_entries 1000

# Initialize cache data as a simple list
set -g __nvm_fish_cache_keys
set -g __nvm_fish_cache_values

# Initialize cache system
function __nvm_init_cache --description "Initialize nvm-fish cache system"
    # Ensure config directory exists
    if not test -d "$NVM_FISH_CONFIG_DIR"
        mkdir -p "$NVM_FISH_CONFIG_DIR" 2>/dev/null
        or return 1
    end

    # Load existing cache if available
    if test -f "$NVM_FISH_CACHE_FILE"
        __nvm_load_cache_from_file
    else
        # Create empty cache file
        echo "# nvm-fish directory cache" > "$NVM_FISH_CACHE_FILE" 2>/dev/null
        or return 1
    end

    return 0
end

# Load cache from file
function __nvm_load_cache_from_file --description "Load cache data from file"
    if not test -f "$NVM_FISH_CACHE_FILE"
        return 1
    end

    # Reset cache data
    set -g __nvm_fish_cache_keys
    set -g __nvm_fish_cache_values

    # Read cache file line by line
    set -l line_number 0
    while read -l line
        set line_number (math $line_number + 1)

        # Skip comments and empty lines
        if string match -q '#*' -- "$line"; or test -z "$line"
            continue
        end

        # Parse cache entry: dir_path|result|timestamp
        if string match -rq '^([^|]+)\|([^|]+)\|([0-9]+)$' -- "$line"
            set -l cache_dir (string match -rg '^([^|]+)\|' -- "$line")
            set -l cache_result (string match -rg '\|([^|]+)\|' -- "$line")
            set -l cache_timestamp (string match -rg '\|([0-9]+)$' -- "$line")

            # Store cache entry using simple lists
            set -g __nvm_fish_cache_keys $__nvm_fish_cache_keys $cache_dir
            set -g __nvm_fish_cache_values $__nvm_fish_cache_values "$cache_result|$cache_timestamp"
        end
    end < "$NVM_FISH_CACHE_FILE"

    set __nvm_fish_cache_loaded true
    return 0
end

# Save cache to file
function __nvm_save_cache_to_file --description "Save cache data to file"
    if not test -d "$NVM_FISH_CONFIG_DIR"
        return 1
    end

    # Write cache header
    echo "# nvm-fish directory cache" > "$NVM_FISH_CACHE_FILE"
    echo "# Generated: "(date) >> "$NVM_FISH_CACHE_FILE"
    echo "# Format: directory|result|timestamp" >> "$NVM_FISH_CACHE_FILE"
    echo "" >> "$NVM_FISH_CACHE_FILE"

    # Write cache entries
    for i in (seq (count $__nvm_fish_cache_keys))
        set -l cache_key $__nvm_fish_cache_keys[$i]
        set -l cache_value $__nvm_fish_cache_values[$i]
        echo "$cache_key|$cache_value" >> "$NVM_FISH_CACHE_FILE"
    end

    return 0
end

# Get cached .nvmrc path for directory
function __nvm_get_cached_nvmrc_path --description "Get cached .nvmrc path for directory"
    set -l target_dir "$argv[1]"

    # Ensure cache is loaded
    if not __nvm_ensure_cache_loaded
        return 1
    end

    # Check if we have a cache entry for this directory
    for i in (seq (count $__nvm_fish_cache_keys))
        if test "$__nvm_fish_cache_keys[$i]" = "$target_dir"
            set -l cache_entry $__nvm_fish_cache_values[$i]

            # Parse cache entry: result|timestamp
            if string match -rq '^([^|]+)\|([0-9]+)$' -- "$cache_entry"
                set -l cached_result (string match -rg '^([^|]+)\|' -- "$cache_entry")
                set -l cache_timestamp (string match -rg '\|([0-9]+)$' -- "$cache_entry")

                # Check if cache entry is still valid
                set -l current_time (date +%s)
                set -l cache_ttl (__nvm_get_config "cache_ttl" "300")

                if test (math $current_time - $cache_timestamp) -lt $cache_ttl
                    # Cache hit - check if directory still exists
                    if test -d "$target_dir"
                        set __nvm_fish_cache_hits (math $__nvm_fish_cache_hits + 1)
                        echo "$cached_result"
                        return 0
                    else
                        # Directory no longer exists, remove cache entry
                        set -e __nvm_fish_cache_keys[$i]
                        set -e __nvm_fish_cache_values[$i]
                    end
                else
                    # Cache expired, remove entry
                    set -e __nvm_fish_cache_keys[$i]
                    set -e __nvm_fish_cache_values[$i]
                end
            end
            break
        end
    end

    # Cache miss
    set __nvm_fish_cache_misses (math $__nvm_fish_cache_misses + 1)
    return 1
end

# Cache .nvmrc lookup result
function __nvm_cache_nvmrc_result --description "Cache .nvmrc lookup result"
    set -l target_dir "$argv[1]"
    set -l nvmrc_path "$argv[2]"

    # Ensure cache is loaded
    if not __nvm_ensure_cache_loaded
        return 1
    end

    # Remove existing entry if present
    for i in (seq (count $__nvm_fish_cache_keys))
        if test "$__nvm_fish_cache_keys[$i]" = "$target_dir"
            set -e __nvm_fish_cache_keys[$i]
            set -e __nvm_fish_cache_values[$i]
            break
        end
    end

    # Determine cache value
    if test -n "$nvmrc_path"; and test -f "$nvmrc_path"
        set -l cache_value "$nvmrc_path"
    else
        set -l cache_value "NO_NVMRC"
    end

    # Set cache entry with timestamp
    set -l current_time (date +%s)
    set -g __nvm_fish_cache_keys $__nvm_fish_cache_keys $target_dir
    set -g __nvm_fish_cache_values $__nvm_fish_cache_values "$cache_value|$current_time"

    # Limit cache size (LRU eviction would be better, but this is simpler)
    set -l cache_size (count $__nvm_fish_cache_keys)
    if test $cache_size -gt $__nvm_fish_cache_max_entries
        __nvm_cleanup_old_cache_entries
    end

    # Save cache to file
    __nvm_save_cache_to_file >/dev/null 2>&1
    return 0
end

# Find .nvmrc with caching
function __nvm_find_nvmrc_cached --description "Find .nvmrc file with caching support"
    set -l target_dir "$argv[1]"

    # Perform actual directory search
    set -l nvmrc_path (__nvm_find_nvmrc_direct "$target_dir")

    # Cache the result
    __nvm_cache_nvmrc_result "$target_dir" "$nvmrc_path"

    echo "$nvmrc_path"
    return 0
end

# Direct .nvmrc search (original logic)
function __nvm_find_nvmrc_direct --description "Direct .nvmrc search without caching"
    set -l target_dir "$argv[1]"

    # Look for .nvmrc in current or parent directories
    set -l nvmrc_path ""
    set -l current_dir "$target_dir"

    # Search up the directory tree for .nvmrc
    while test -z "$nvmrc_path"; and test "$current_dir" != "/"
        if test -f "$current_dir/.nvmrc"
            set nvmrc_path "$current_dir/.nvmrc"
        else
            set current_dir (dirname "$current_dir")
        end
    end

    echo "$nvmrc_path"
    return 0
end

# Ensure cache is loaded
function __nvm_ensure_cache_loaded --description "Ensure cache is loaded"
    if test $__nvm_fish_cache_loaded = false
        __nvm_init_cache
        return $status
    end
    return 0
end

# Clean up old cache entries
function __nvm_cleanup_old_cache_entries --description "Clean up old cache entries"
    set -l current_time (date +%s)
    set -l cache_ttl (__nvm_get_config "cache_ttl" "300")
    set -l entries_removed 0

    # Remove expired entries (iterate backwards to avoid index issues)
    for i in (seq (count $__nvm_fish_cache_keys) -1 1)
        set -l cache_entry $__nvm_fish_cache_values[$i]

        if string match -rq '^([^|]+)\|([0-9]+)$' -- "$cache_entry"
            set -l cache_timestamp (string match -rg '\|([0-9]+)$' -- "$cache_entry")

            if test (math $current_time - $cache_timestamp) -gt $cache_ttl
                set -e __nvm_fish_cache_keys[$i]
                set -e __nvm_fish_cache_values[$i]
                set entries_removed (math $entries_removed + 1)
            end
        else
            # Invalid cache entry format, remove it
            set -e __nvm_fish_cache_keys[$i]
            set -e __nvm_fish_cache_values[$i]
            set entries_removed (math $entries_removed + 1)
        end
    end

    # Save cleaned cache
    if test $entries_removed -gt 0
        __nvm_save_cache_to_file >/dev/null 2>&1
    end

    return 0
end

# Clear all cache
function __nvm_clear_cache --description "Clear all cache entries"
    set -g __nvm_fish_cache_keys
    set -g __nvm_fish_cache_values
    set -g __nvm_fish_cache_hits 0
    set -g __nvm_fish_cache_misses 0
    set -g __nvm_fish_cache_loaded false

    # Reset cache file
    echo "# nvm-fish directory cache" > "$NVM_FISH_CACHE_FILE" 2>/dev/null
    echo "# Generated: "(date) >> "$NVM_FISH_CACHE_FILE" 2>/dev/null
    echo "# Format: directory|result|timestamp" >> "$NVM_FISH_CACHE_FILE" 2>/dev/null

    echo "Cache cleared"
    return 0
end

# Show cache statistics
function __nvm_show_cache_stats --description "Show cache statistics"
    # Ensure cache is loaded
    if not __nvm_ensure_cache_loaded
        echo "Failed to load cache"
        return 1
    end

    set -l total_requests (math $__nvm_fish_cache_hits + $__nvm_fish_cache_misses)
    set -l hit_rate 0
    if test $total_requests -gt 0
        set -l hit_rate (math $__nvm_fish_cache_hits \* 100 / $total_requests)
    end

    echo "nvm-fish cache statistics:"
    echo "  Total entries:     "(count $__nvm_fish_cache_keys)
    echo "  Cache hits:        $__nvm_fish_cache_hits"
    echo "  Cache misses:      $__nvm_fish_cache_misses"
    echo "  Hit rate:          $hit_rate%"
    echo "  Max entries:       $__nvm_fish_cache_max_entries"
    echo "  Cache file:        $NVM_FISH_CACHE_FILE"
    echo "  Cache TTL:         "(__nvm_get_config "cache_ttl" "300")" seconds"
end

# Purge cache entries for non-existent directories
function __nvm_purge_invalid_cache --description "Purge cache entries for non-existent directories"
    # Ensure cache is loaded
    if not __nvm_ensure_cache_loaded
        echo "Failed to load cache"
        return 1
    end

    set -l entries_removed 0

    # Remove entries for non-existent directories (iterate backwards)
    for i in (seq (count $__nvm_fish_cache_keys) -1 1)
        set -l cache_key $__nvm_fish_cache_keys[$i]
        if not test -d "$cache_key"
            set -e __nvm_fish_cache_keys[$i]
            set -e __nvm_fish_cache_values[$i]
            set entries_removed (math $entries_removed + 1)
        end
    end

    # Save cleaned cache
    if test $entries_removed -gt 0
        __nvm_save_cache_to_file >/dev/null 2>&1
        echo "Removed $entries_removed invalid cache entries"
    else
        echo "No invalid cache entries found"
    end

    return 0
end