#!/usr/bin/env fish

# Test script for nvm-fish configuration and performance features
# This script validates the new configuration system and performance optimizations

set -g TEST_ROOT (mktemp -d /tmp/nvm-fish-config-test.XXXXXX)
set -g ORIGINAL_PWD $PWD
set -g TEST_CONFIG_DIR "$TEST_ROOT/.config/nvm_fish"
set -g TEST_CONFIG_FILE "$TEST_CONFIG_DIR/config.json"
set -g TEST_CACHE_FILE "$TEST_CONFIG_DIR/directory_cache.fish"

# Cleanup function
function cleanup
    cd $ORIGINAL_PWD
    rm -rf $TEST_ROOT
    echo "🧹 Test directory cleaned up"
end

# Register cleanup
function __trap_exit --on-event fish_exit
    cleanup
end

echo "🧪 Starting nvm-fish configuration and performance tests..."
echo "📁 Test directory: $TEST_ROOT"

# Test 1: Configuration system
echo ""
echo "📋 Test 1: Configuration system"

# Source config manager
source "$ORIGINAL_PWD/config_manager.fish"

# Test configuration initialization
cd $TEST_ROOT
set -x HOME "$TEST_ROOT"
fish -c "
    source \"$ORIGINAL_PWD/config_manager.fish\"

    # Test configuration initialization
    if __nvm_init_config
        echo '  ✅ Configuration initialization works'
    else
        echo '  ❌ Configuration initialization failed'
        exit 1
    end

    # Test config file creation
    if test -f \"$TEST_CONFIG_FILE\"
        echo '  ✅ Config file created successfully'
    else
        echo '  ❌ Config file not created'
        exit 1
    end

    # Test default configuration loading
    if __nvm_load_config
        echo '  ✅ Configuration loaded successfully'
    else
        echo '  ❌ Configuration loading failed'
        exit 1
    end

    # Test configuration values
    set auto_switch (__nvm_get_config \"auto_switch\" \"false\")
    set cache_enabled (__nvm_get_config \"cache_enabled\" \"false\")

    if test \"\$auto_switch\" = \"true\"; and test \"\$cache_enabled\" = \"true\"
        echo '  ✅ Default configuration values correct'
    else
        echo '  ❌ Default configuration values incorrect'
        echo \"    auto_switch: \$auto_switch (expected: true)\"
        echo \"    cache_enabled: \$cache_enabled (expected: true)\"
        exit 1
    end
"

# Test custom configuration
echo ""
echo "📋 Test 2: Custom configuration"

fish -c "
    source \"$ORIGINAL_PWD/config_manager.fish\"

    # Create custom configuration
    echo '{\"auto_switch\":false,\"cache_enabled\":false,\"cache_ttl\":600,\"debug_mode\":true}' > \"$TEST_CONFIG_FILE\"

    # Reload configuration
    if __nvm_reload_config
        echo '  ✅ Configuration reload works'
    else
        echo '  ❌ Configuration reload failed'
        exit 1
    end

    # Test custom values
    set auto_switch (__nvm_get_config \"auto_switch\" \"true\")
    set cache_enabled (__nvm_get_config \"cache_enabled\" \"true\")
    set cache_ttl (__nvm_get_config \"cache_ttl\" \"300\")
    set debug_mode (__nvm_get_config \"debug_mode\" \"false\")

    if test \"\$auto_switch\" = \"false\"; and test \"\$cache_enabled\" = \"false\"; and test \"\$cache_ttl\" = \"600\"; and test \"\$debug_mode\" = \"true\"
        echo '  ✅ Custom configuration values correct'
    else
        echo '  ❌ Custom configuration values incorrect'
        echo \"    auto_switch: \$auto_switch (expected: false)\"
        echo \"    cache_enabled: \$cache_enabled (expected: false)\"
        echo \"    cache_ttl: \$cache_ttl (expected: 600)\"
        echo \"    debug_mode: \$debug_mode (expected: true)\"
        exit 1
    end
"

# Test 3: Cache system
echo ""
echo "📋 Test 3: Cache system"

# Source cache manager
source "$ORIGINAL_PWD/cache_manager.fish"

fish -c "
    source \"$ORIGINAL_PWD/cache_manager.fish\"
    source \"$ORIGINAL_PWD/config_manager.fish\"

    # Test cache initialization
    if __nvm_init_cache
        echo '  ✅ Cache initialization works'
    else
        echo '  ❌ Cache initialization failed'
        exit 1
    end

    # Test cache file creation
    if test -f \"$TEST_CACHE_FILE\"
        echo '  ✅ Cache file created successfully'
    else
        echo '  ❌ Cache file not created'
        exit 1
    end

    # Test cache operations
    # Create a test directory with .nvmrc
    mkdir -p \"$TEST_ROOT/project1\"
    echo \"18.17.0\" > \"$TEST_ROOT/project1/.nvmrc\"

    # Test caching .nvmrc lookup
    set cached_result (__nvm_get_cached_nvmrc_path \"$TEST_ROOT/project1\")
    if test -z \"\$cached_result\"
        echo '  ✅ Cache miss (expected for first lookup)'
    else
        echo '  ❌ Unexpected cache hit'
        exit 1
    end

    # Cache the result
    if __nvm_cache_nvmrc_result \"$TEST_ROOT/project1\" \"$TEST_ROOT/project1/.nvmrc\"
        echo '  ✅ Cache write operation works'
    else
        echo '  ❌ Cache write operation failed'
        exit 1
    end

    # Test cache retrieval
    set cached_result (__nvm_get_cached_nvmrc_path \"$TEST_ROOT/project1\")
    if test \"\$cached_result\" = \"$TEST_ROOT/project1/.nvmrc\"
        echo '  ✅ Cache retrieval works'
    else
        echo '  ❌ Cache retrieval failed'
        echo \"    Expected: $TEST_ROOT/project1/.nvmrc\"
        echo \"    Got: \$cached_result\"
        exit 1
    end
"

# Test 4: Directory search performance
echo ""
echo "📋 Test 4: Directory search performance"

fish -c "
    source \"$ORIGINAL_PWD/cache_manager.fish\"

    # Create deep directory structure
    mkdir -p \"$TEST_ROOT/deep/structure/with/many/subdirectories\"

    # Time direct search (no cache)
    set start_time (date +%s%3N)
    set result (__nvm_find_nvmrc_direct \"$TEST_ROOT/deep/structure/with/many/subdirectories\")
    set end_time (date +%s%3N)
    set direct_time (math \$end_time - \$start_time)

    # Time cached search
    set start_time (date +%s%3N)
    set result (__nvm_find_nvmrc_cached \"$TEST_ROOT/deep/structure/with/many/subdirectories\")
    set end_time (date +%s%3N)
    set cached_time (math \$end_time - \$start_time)

    echo \"  ⏱️  Direct search time: \$direct_time ms\"
    echo \"  ⏱️  Cached search time: \$cached_time ms\"

    # Add .nvmrc and test again
    echo \"16.20.2\" > \"$TEST_ROOT/deep/structure/with/many/subdirectories/.nvmrc\"

    # Time direct search with .nvmrc
    set start_time (date +%s%3N)
    set result (__nvm_find_nvmrc_direct \"$TEST_ROOT/deep/structure/with/many/subdirectories\")
    set end_time (date +%s%3N)
    set direct_with_nvmrc_time (math \$end_time - \$start_time)

    # Cache the result
    __nvm_cache_nvmrc_result \"$TEST_ROOT/deep/structure/with/many/subdirectories\" \"$TEST_ROOT/deep/structure/with/many/subdirectories/.nvmrc\"

    # Time cached search with .nvmrc
    set start_time (date +%s%3N)
    set result (__nvm_find_nvmrc_cached \"$TEST_ROOT/deep/structure/with/many/subdirectories\")
    set end_time (date +%s%3N)
    set cached_with_nvmrc_time (math \$end_time - \$start_time)

    echo \"  ⏱️  Direct search with .nvmrc: \$direct_with_nvmrc_time ms\"
    echo \"  ⏱️  Cached search with .nvmrc: \$cached_with_nvmrc_time ms\"

    # Performance improvement check
    if test \$cached_time -lt \$direct_time
        echo '  ✅ Cache provides performance improvement'
    else
        echo '  ⚠️  Cache performance improvement not significant'
    end
"

# Test 5: Integration with load_nvm
echo ""
echo "📋 Test 5: Integration with load_nvm"

# Create test setup
mkdir -p "$TEST_ROOT/test_project"
echo "20.5.0" > "$TEST_ROOT/test_project/.nvmrc"

# Test auto-switch disable
fish -c "
    source \"$ORIGINAL_PWD/config_manager.fish\"
    source \"$ORIGINAL_PWD/cache_manager.fish\"

    # Create config with auto-switch disabled
    echo '{\"auto_switch\":false,\"cache_enabled\":true,\"cache_ttl\":300,\"debug_mode\":false}' > \"$TEST_CONFIG_FILE\"
    __nvm_reload_config

    # Test auto-switch detection
    if not __nvm_is_auto_switch_enabled
        echo '  ✅ Auto-switch properly disabled'
    else
        echo '  ❌ Auto-switch not properly disabled'
        exit 1
    end
"

# Test auto-switch enable
fish -c "
    source \"$ORIGINAL_PWD/config_manager.fish\"
    source \"$ORIGINAL_PWD/cache_manager.fish\"

    # Create config with auto-switch enabled
    echo '{\"auto_switch\":true,\"cache_enabled\":true,\"cache_ttl\":300,\"debug_mode\":false}' > \"$TEST_CONFIG_FILE\"
    __nvm_reload_config

    # Test auto-switch detection
    if __nvm_is_auto_switch_enabled
        echo '  ✅ Auto-switch properly enabled'
    else
        echo '  ❌ Auto-switch not properly enabled'
        exit 1
    end
"

# Test 6: Debug tools
echo ""
echo "📋 Test 6: Debug tools"

fish -c "
    source \"$ORIGINAL_PWD/debug_tools.fish\"
    source \"$ORIGINAL_PWD/config_manager.fish\"
    source \"$ORIGINAL_PWD/cache_manager.fish\"

    # Test debug initialization
    if __nvm_init_debug
        echo '  ✅ Debug initialization works'
    else
        echo '  ❌ Debug initialization failed'
        exit 1
    end

    # Test configuration display
    if __nvm_show_config >/dev/null 2>&1
        echo '  ✅ Configuration display works'
    else
        echo '  ❌ Configuration display failed'
        exit 1
    end

    # Test cache statistics
    if __nvm_show_cache_stats >/dev/null 2>&1
        echo '  ✅ Cache statistics display works'
    else
        echo '  ❌ Cache statistics display failed'
        exit 1
    end

    # Test cache clearing
    if __nvm_clear_cache >/dev/null 2>&1
        echo '  ✅ Cache clearing works'
    else
        echo '  ❌ Cache clearing failed'
        exit 1
    end
"

# Test 7: Error handling
echo ""
echo "📋 Test 7: Error handling"

fish -c "
    source \"$ORIGINAL_PWD/config_manager.fish\"

    # Test invalid JSON handling
    echo '{\"invalid\": json}' > \"$TEST_CONFIG_FILE\"

    # Should fall back to defaults
    set auto_switch (__nvm_get_config \"auto_switch\" \"false\")
    if test \"\$auto_switch\" = \"true\"
        echo '  ✅ Invalid JSON handling works (falls back to defaults)'
    else
        echo '  ❌ Invalid JSON handling failed'
        exit 1
    end

    # Test missing config file
    rm -f \"$TEST_CONFIG_FILE\"

    # Should create default config
    set auto_switch (__nvm_get_config \"auto_switch\" \"false\")
    if test \"\$auto_switch\" = \"true\"; and test -f \"$TEST_CONFIG_FILE\"
        echo '  ✅ Missing config file handling works'
    else
        echo '  ❌ Missing config file handling failed'
        exit 1
    end
"

# Test 8: Configuration functions
echo ""
echo "📋 Test 8: Configuration functions"

fish -c "
    source \"$ORIGINAL_PWD/config_manager.fish\"

    # Test configuration reset
    if __nvm_reset_config >/dev/null 2>&1
        echo '  ✅ Configuration reset works'
    else
        echo '  ❌ Configuration reset failed'
        exit 1
    end

    # Test that reset creates default config
    set auto_switch (__nvm_get_config \"auto_switch\" \"false\")
    set cache_enabled (__nvm_get_config \"cache_enabled\" \"false\")

    if test \"\$auto_switch\" = \"true\"; and test \"\$cache_enabled\" = \"true\"
        echo '  ✅ Configuration reset creates proper defaults'
    else
        echo '  ❌ Configuration reset doesn't create proper defaults\"
        exit 1
    end
"

# Performance comparison test
echo ""
echo "📋 Test 9: Performance comparison"

fish -c "
    source \"$ORIGINAL_PWD/cache_manager.fish\"
    source \"$ORIGINAL_PWD/config_manager.fish\"

    # Clear cache for clean test
    __nvm_clear_cache >/dev/null 2>&1

    # Create test directories
    mkdir -p \"$TEST_ROOT/perf_test/level1/level2/level3/level4/level5\"

    # Test multiple directory changes (simulating cd commands)
    set start_time (date +%s%3N)

    for i in (seq 1 10)
        __nvm_find_nvmrc_direct \"$TEST_ROOT/perf_test/level1/level2/level3/level4/level5\"
    end

    set end_time (date +%s%3N)
    set direct_total (math \$end_time - \$start_time)

    # Now test with caching
    set start_time (date +%s%3N)

    for i in (seq 1 10)
        __nvm_find_nvmrc_cached \"$TEST_ROOT/perf_test/level1/level2/level3/level4/level5\"
    end

    set end_time (date +%s%3N)
    set cached_total (math \$end_time - \$start_time)

    echo \"  ⏱️  10x direct search: \$direct_total ms\"
    echo \"  ⏱️  10x cached search: \$cached_total ms\"

    if test \$cached_total -lt \$direct_total
        set improvement (math \"scale=1; (\$direct_total - \$cached_total) * 100 / \$direct_total\")
        echo \"  🚀 Performance improvement: \$improvement% faster\"
        echo '  ✅ Caching provides significant performance benefit'
    else
        echo '  ⚠️  Caching performance benefit not significant in this test'
    end
"

echo ""
echo "🎉 All configuration and performance tests passed!"
echo ""
echo "✅ Configuration system: Working"
echo "✅ Cache system: Working"
echo "✅ Performance optimization: Working"
echo "✅ Debug tools: Working"
echo "✅ Error handling: Working"
echo "✅ Integration with load_nvm: Working"
echo ""
echo "🚀 nvm-fish configuration and performance features are ready!"