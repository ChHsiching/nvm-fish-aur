#!/usr/bin/env fish

# CI test script for nvm-fish
# This script runs automated tests to verify nvm-fish functionality

set -g TEST_ROOT (mktemp -d)
set -g ORIGINAL_PWD $PWD

# Cleanup function
function cleanup
    cd $ORIGINAL_PWD
    rm -rf $TEST_ROOT
    echo "🧹 Test directory cleaned up"
end

# Register cleanup
trap cleanup EXIT

echo "🧪 Starting nvm-fish CI tests..."
echo "📁 Test directory: $TEST_ROOT"

# Test 1: Syntax validation
echo ""
echo "📋 Test 1: Syntax validation"
for file in *.fish
    if test -f "$file"
        echo "  Checking $file..."
        if not fish -c "source $file"
            echo "❌ Syntax error in $file"
            exit 1
        end
        echo "  ✅ $file"
    end
end

# Test 2: Function definitions
echo ""
echo "📋 Test 2: Function definitions"
fish -c "
    source nvm.fish

    # Check main function exists
    if functions -q nvm
        echo '  ✅ nvm function defined'
    else
        echo '  ❌ nvm function not found'
        exit 1
    end

    # Check helper functions exist
    set -l helper_functions __nvm_write_nvmrc_file __nvm_handle_nvmrc_file __nvm_create_nvmrc __nvm_prompt_override_nvmrc __nvm_backup_nvmrc
    for func in $helper_functions
        if functions -q $func
            echo "  ✅ $func function defined"
        else
            echo "  ❌ $func function not found"
            exit 1
        end
    end
"

# Test 3: Basic functionality
echo ""
echo "📋 Test 3: Basic functionality simulation"
cd $TEST_ROOT

# Test version extraction regex
fish -c "
    set test_output 'Now using node v18.17.0 (npm v9.6.7)'
    set version (string match -rg 'Now using node v([0-9]+\\.[0-9]+\\.[0-9]+)' \$test_output)

    if test \"\$version\" = \"18.17.0\"
        echo '  ✅ Version extraction works correctly'
    else
        echo '  ❌ Version extraction failed: got \"\$version\", expected \"18.17.0\"'
        exit 1
    end
"

# Test 4: File operations
echo ""
echo "📋 Test 4: File operations"
cd $TEST_ROOT

# Test .nvmrc writing
fish -c "
    source $ORIGINAL_PWD/nvm.fish

    # Test .nvmrc file creation
    if __nvm_write_nvmrc_file '18.17.0'
        echo '  ✅ .nvmrc file creation works'

        # Verify file content
        if test -f .nvmrc
            set content (cat .nvmrc)
            if test \"\$content\" = \"18.17.0\"
                echo '  ✅ .nvmrc content correct'
            else
                echo '  ❌ .nvmrc content incorrect: \$content'
                exit 1
            end
        end
    else
        echo '  ❌ .nvmrc file creation failed'
        exit 1
    end
"

# Test 5: Backup functionality
echo ""
echo "📋 Test 5: Backup functionality"
cd $TEST_ROOT

# Create test .nvmrc
echo "16.20.2" > .nvmrc

fish -c "
    source $ORIGINAL_PWD/nvm.fish

    # Test backup function
    if __nvm_backup_nvmrc
        echo '  ✅ Backup function works'

        # Check backup was created
        if test -d .nvm
            set backup_files (ls .nvm/.nvmrc_* 2>/dev/null | wc -l)
            if test \$backup_files -gt 0
                echo '  ✅ Backup file created'
            else
                echo '  ❌ No backup files found'
                exit 1
            end
        end
    else
        echo '  ❌ Backup function failed'
        exit 1
    end
"

echo ""
echo "🎉 All CI tests passed!"
echo "✅ nvm-fish is ready for release"