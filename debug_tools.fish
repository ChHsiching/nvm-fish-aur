# ~/.config/fish/functions/debug_tools.fish
# Debug and performance monitoring tools for nvm-fish

# Load utility functions if available
if test -f "$HOME/.config/fish/functions/nvm_utils.fish"
    source "$HOME/.config/fish/functions/nvm_utils.fish"
end

# Performance monitoring variables
set -g __nvm_fish_debug_enabled false
set -g __nvm_fish_perf_log_enabled false
set -g __nvm_fish_perf_log_file "$HOME/.config/nvm_fish/performance.log"

# Initialize debug system
function __nvm_init_debug --description "Initialize nvm-fish debug system"
    # Check if debug mode is enabled in config
    if functions -q __nvm_is_debug_mode; and __nvm_is_debug_mode
        set __nvm_fish_debug_enabled true
        __nvm_debug_log "Debug mode enabled"
    end

    # Ensure config directory exists
    if not test -d "$HOME/.config/nvm_fish"
        mkdir -p "$HOME/.config/nvm_fish" 2>/dev/null
    end

    return 0
end

# Debug logging function
function __nvm_debug_log --description "Log debug message if debug mode is enabled"
    if not test $__nvm_fish_debug_enabled = true
        return 0
    end

    set -l message "$argv[1]"
    set -l timestamp (date "+%Y-%m-%d %H:%M:%S.%3N")

    echo -e " \033[35m🔧 [$timestamp] $message\033[0m" >&2

    # Also log to performance log if enabled
    if test $__nvm_fish_perf_log_enabled = true
        echo "[$timestamp] DEBUG: $message" >> "$__nvm_fish_perf_log_file" 2>/dev/null
    end
end

# Performance timing function
function __nvm_perf_timer --description "Time execution of a command"
    set -l operation_name "$argv[1]"
    set -l command_to_run "$argv[2..-1]"

    # Security validation: only allow safe commands
    set -l allowed_commands "nvm" "node" "npm" "fish" "date" "string" "math" "dirname" "basename" "test" "command" "functions" "set" "echo" "printf" "ls" "cat" "head" "tail" "grep" "find" "mkdir" "rm" "cp" "mv" "chmod" "sleep" "realpath" "read"

    # Extract the first command from the command string
    set -l first_command (string split ' ' -- "$command_to_run")[1]

    # Check if the command is in the allowed list
    if not contains "$first_command" $allowed_commands
        echo "Error: Command '$first_command' is not allowed for performance timing" >&2
        return 1
    fi

    # Additional security check: prevent potentially dangerous operations
    if string match -q "*rm*" "$command_to_run"; and string match -q "*-rf*" "$command_to_run"
        echo "Error: Dangerous rm -rf operation not allowed in performance timing" >&2
        return 1
    end

    if string match -q "*chmod*" "$command_to_run"; and string match -q "*777*" "$command_to_run"
        echo "Error: Insecure chmod operation not allowed in performance timing" >&2
        return 1
    end

    set -l start_time (date +%s%3N)

    # Execute the command safely using fish -c instead of eval
    fish -c "$command_to_run"
    set -l exit_status $status

    set -l end_time (date +%s%3N)
    set -l duration (math $end_time - $start_time)

    # Log performance data
    if test $__nvm_fish_debug_enabled = true; or test $__nvm_fish_perf_log_enabled = true
        __nvm_perf_log "$operation_name" $duration $exit_status
    end

    return $exit_status
end

# Log performance data
function __nvm_perf_log --description "Log performance data"
    set -l operation "$argv[1]"
    set -l duration "$argv[2]"
    set -l exit_status "$argv[3]"

    set -l timestamp (date "+%Y-%m-%d %H:%M:%S.%3N")
    set -l log_entry "[$timestamp] PERF: $operation took $duration""ms (status: $exit_status)"

    if test $__nvm_fish_debug_enabled = true
        echo -e " \033[33m⏱️  $log_entry\033[0m" >&2
    end

    if test $__nvm_fish_perf_log_enabled = true
        echo "$log_entry" >> "$__nvm_fish_perf_log_file" 2>/dev/null
    end
end

# Start performance logging
function __nvm_start_perf_logging --description "Start performance logging to file"
    set __nvm_fish_perf_log_enabled true
    echo "Performance logging enabled. Log file: $__nvm_fish_perf_log_file"
    return 0
end

# Stop performance logging
function __nvm_stop_perf_logging --description "Stop performance logging"
    set __nvm_fish_perf_log_enabled false
    echo "Performance logging disabled"
    return 0
end

# Show performance report
function __nvm_show_performance_report --description "Show performance report"
    if not test -f "$__nvm_fish_perf_log_file"
        echo "No performance log file found"
        return 1
    end

    echo "nvm-fish Performance Report"
    echo "=========================="

    # Calculate statistics
    set -l total_operations 0
    set -l total_time 0
    set -l slowest_operation ""
    set -l slowest_time 0
    set -l fastest_operation ""
    set -l fastest_time 999999

    # Process log file
    while read -l line
        if string match -rq 'PERF: (.+) took ([0-9]+)ms' -- "$line"
            set -l operation (string match -rg 'PERF: (.+) took' -- "$line")
            set -l duration (string match -rg 'took ([0-9]+)ms' -- "$line")

            set total_operations (math $total_operations + 1)
            set total_time (math $total_time + $duration)

            if test $duration -gt $slowest_time
                set slowest_operation "$operation"
                set slowest_time $duration
            end

            if test $duration -lt $fastest_time
                set fastest_operation "$operation"
                set fastest_time $duration
            end
        end
    end < "$__nvm_fish_perf_log_file"

    if test $total_operations -gt 0
        set -l avg_time (math "round($total_time / $total_operations)")

        echo "Total operations:  $total_operations"
        echo "Total time:         $total_time""ms"
        echo "Average time:       $avg_time""ms"
        echo "Fastest operation:  $fastest_operation ($fastest_time""ms)"
        echo "Slowest operation:  $slowest_operation ($slowest_time""ms)"
        echo ""

        echo "Recent operations:"
        echo "------------------"

        # Show last 10 operations
        tail -n 10 "$__nvm_fish_perf_log_file" | grep 'PERF:' | while read -l line
            if string match -rq 'PERF: (.+) took ([0-9]+)ms' -- "$line"
                set -l operation (string match -rg 'PERF: (.+) took' -- "$line")
                set -l duration (string match -rg 'took ([0-9]+)ms' -- "$line")
                echo "  $operation: $duration""ms"
            end
        end
    else
        echo "No performance data available"
    end

    echo ""
    echo "Log file: $__nvm_fish_perf_log_file"
end

# Clear performance log
function __nvm_clear_perf_log --description "Clear performance log"
    if test -f "$__nvm_fish_perf_log_file"
        echo "" > "$__nvm_fish_perf_log_file"
        echo "Performance log cleared"
    else
        echo "No performance log file found"
    end
    return 0
end

# System information display
function __nvm_show_system_info --description "Display system information"
    echo "System Information:"
    echo "  OS: "(uname -s)
    echo "  Architecture: "(uname -m)
    echo "  Fish version: "(fish --version | string split ' ')[-1]
end

# nvm information display
function __nvm_show_nvm_info --description "Display nvm information"
    if command -v nvm >/dev/null 2>&1
        echo "nvm Information:"
        echo "  nvm version: "(nvm --version 2>/dev/null || echo "N/A")
        echo "  nvm root: "(nvm root 2>/dev/null || echo "N/A")
        echo "  Current node: "(node --version 2>/dev/null || echo "N/A")
        echo "  Default node: "(nvm version default 2>/dev/null || echo "N/A")
    else
        echo "nvm: Not installed or not in PATH"
    end
end

# bass information display
function __nvm_show_bass_info --description "Display bass information"
    if command -v bass >/dev/null 2>&1
        echo "bass: Installed"
    else
        echo "bass: Not installed or not in PATH"
    end
end

# Configuration information display
function __nvm_show_config_info --description "Display configuration information"
    echo "Configuration:"
    if functions -q __nvm_load_config; and __nvm_load_config
        echo "  Auto-switch:     "(functions -q __nvm_get_config; and __nvm_get_config "auto_switch" "N/A" or echo "N/A")
        echo "  Cache enabled:   "(functions -q __nvm_get_config; and __nvm_get_config "cache_enabled" "N/A" or echo "N/A")
        echo "  Cache TTL:       "(functions -q __nvm_get_config; and __nvm_get_config "cache_ttl" "N/A" or echo "N/A")" seconds"
        echo "  Debug mode:      "(functions -q __nvm_get_config; and __nvm_get_config "debug_mode" "N/A" or echo "N/A")
    else
        echo "  Failed to load configuration"
    end
end

# File system check
function __nvm_check_filesystem --description "Check nvm-fish file system"
    echo "File System Check:"
    echo "  Config directory: $HOME/.config/nvm_fish"
    if test -d "$HOME/.config/nvm_fish"
        echo "    Status: Exists"
        echo "    Permissions: "(ls -ld "$HOME/.config/nvm_fish" | awk '{print $1}')
        echo "    Files: "(count (ls -A "$HOME/.config/nvm_fish" 2>/dev/null))
    else
        echo "    Status: Does not exist"
    end

    echo "  Config file: $HOME/.config/nvm_fish/config.json"
    if test -f "$HOME/.config/nvm_fish/config.json"
        echo "    Status: Exists"
        echo "    Size: "(ls -lh "$HOME/.config/nvm_fish/config.json" | awk '{print $5}')
        echo "    Modified: "(ls -l "$HOME/.config/nvm_fish/config.json" | awk '{print $6" "$7" "$8}')
    else
        echo "    Status: Does not exist"
    end

    echo "  Cache file: $HOME/.config/nvm_fish/directory_cache.fish"
    if test -f "$HOME/.config/nvm_fish/directory_cache.fish"
        echo "    Status: Exists"
        echo "    Size: "(ls -lh "$HOME/.config/nvm_fish/directory_cache.fish" | awk '{print $5}')
        echo "    Modified: "(ls -l "$HOME/.config/nvm_fish/directory_cache.fish" | awk '{print $6" "$7" "$8}')
    else
        echo "    Status: Does not exist"
    end
end

# Performance test
function __nvm_run_performance_test --description "Run performance test"
    echo "Performance Test:"

    # Create temporary directory safely
    set -l test_dir (__nvm_create_temp_dir "nvm-fish-test")
    if test $status -ne 0
        echo "  Error: Failed to create test directory"
        return 1
    end

    # Test directory search performance
    set -l start_time (date +%s%3N)
    set -l result (__nvm_find_nvmrc_direct "$test_dir" 2>/dev/null)
    set -l end_time (date +%s%3N)
    set -l search_time (math $end_time - $start_time)

    echo "  Directory search (no .nvmrc): $search_time ms"

    # Test with .nvmrc file
    echo "v18.17.0" > "$test_dir/.nvmrc"

    set -l start_time (date +%s%3N)
    set -l result (__nvm_find_nvmrc_direct "$test_dir" 2>/dev/null)
    set -l end_time (date +%s%3N)
    set -l search_time (math $end_time - $start_time)

    echo "  Directory search (with .nvmrc): $search_time ms"

    # Clean up
    __nvm_safe_remove "$test_dir"
end

# System diagnostics (main function)
function __nvm_system_diagnostics --description "Run system diagnostics"
    echo "nvm-fish System Diagnostics"
    echo "==========================="

    __nvm_show_system_info
    echo ""

    __nvm_show_nvm_info
    echo ""

    __nvm_show_bass_info
    echo ""

    __nvm_show_config_info
    echo ""

    # Cache statistics
    if functions -q __nvm_show_cache_stats
        __nvm_show_cache_stats
    else
        echo "Cache statistics not available"
    end

    echo ""

    __nvm_check_filesystem
    echo ""

    __nvm_run_performance_test

    echo ""
    echo "Diagnostics complete"
end

# Interactive debug shell
function __nvm_debug_shell --description "Start interactive debug shell"
    echo "nvm-fish Debug Shell"
    echo "===================="
    echo "Type 'help' for available commands, 'exit' to quit"
    echo ""

    set -l debug_running true

    while test $debug_running = true
        echo -n "nvm-debug> "
        set -l input (read -l)

        switch "$input"
            case help
                echo "Available commands:"
                echo "  config        - Show current configuration"
                echo "  cache         - Show cache statistics"
                echo "  cache-clear   - Clear cache"
                echo "  perf          - Show performance report"
                echo "  perf-clear    - Clear performance log"
                echo "  diag          - Run system diagnostics"
                echo "  debug-on      - Enable debug mode"
                echo "  debug-off     - Disable debug mode"
                echo "  perf-on       - Enable performance logging"
                echo "  perf-off      - Disable performance logging"
                echo "  status        - Show current status"
                echo "  exit          - Exit debug shell"

            case config
                __nvm_show_config_info

            case cache
                if functions -q __nvm_show_cache_stats
                    __nvm_show_cache_stats
                else
                    echo "Cache statistics not available"
                end

            case cache-clear
                if functions -q __nvm_clear_cache
                    __nvm_clear_cache
                else
                    echo "Cache clearing not available"
                end

            case perf
                __nvm_show_performance_report

            case perf-clear
                __nvm_clear_perf_log

            case diag
                __nvm_system_diagnostics

            case debug-on
                set __nvm_fish_debug_enabled true
                echo "Debug mode enabled"

            case debug-off
                set __nvm_fish_debug_enabled false
                echo "Debug mode disabled"

            case perf-on
                __nvm_start_perf_logging

            case perf-off
                __nvm_stop_perf_logging

            case status
                echo "Debug mode:      $__nvm_fish_debug_enabled"
                echo "Perf logging:    $__nvm_fish_perf_log_enabled"
                echo "Config loaded:   "$__nvm_fish_config_loaded
                echo "Cache loaded:    "$__nvm_fish_cache_loaded

            case exit quit
                set debug_running false
                echo "Exiting debug shell..."

            case ""
                # Empty input, continue

            case '*'
                echo "Unknown command: $input"
                echo "Type 'help' for available commands"
        end
    end
end

# Initialize debug system when loaded
__nvm_init_debug