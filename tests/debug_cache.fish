#!/usr/bin/env fish

# Debug cache functionality
set -g TEST_ROOT (mktemp -d /tmp/nvm-fish-debug-test.XXXXXX)
set -g ORIGINAL_PWD $PWD

echo "🔍 Debug cache functionality"
echo "📁 Test directory: $TEST_ROOT"

# Create test environment
mkdir -p "$TEST_ROOT/test_project"
echo "18.17.0" > "$TEST_ROOT/test_project/.nvmrc"

echo "📋 Test environment created"
echo "  .nvmrc file: $TEST_ROOT/test_project/.nvmrc"
echo "  Content: "(cat "$TEST_ROOT/test_project/.nvmrc")

# Source functions
source "$ORIGINAL_PWD/config_manager.fish"
source "$ORIGINAL_PWD/cache_manager.fish"

# Initialize
set -x HOME "$TEST_ROOT"
__nvm_init_config
__nvm_init_cache

echo ""
echo "📋 Testing cache functions..."

# Test directory search
set result (__nvm_find_nvmrc_direct "$TEST_ROOT/test_project")
echo "Direct search result: $result"

# Test cache writing
echo "Testing cache writing..."
set nvmrc_path "$TEST_ROOT/test_project/.nvmrc"
echo "nvmrc_path variable: $nvmrc_path"
echo "File exists test: "(test -f "$nvmrc_path"; and echo "YES" or echo "NO")

if __nvm_cache_nvmrc_result "$TEST_ROOT/test_project" "$nvmrc_path"
    echo "✅ Cache write succeeded"
else
    echo "❌ Cache write failed"
end

# Manual cache save to see debug output
echo "Manual cache save:"
__nvm_save_cache_to_file

# Check cache file
echo ""
echo "📋 Cache file contents:"
cat "$TEST_ROOT/.config/nvm_fish/directory_cache.fish"

# Test cache reading
set cached_result (__nvm_get_cached_nvmrc_path "$TEST_ROOT/test_project")
echo ""
echo "Cache retrieval result: '$cached_result'"

# Cleanup
cd $ORIGINAL_PWD
rm -rf $TEST_ROOT

echo ""
echo "🔍 Debug complete"