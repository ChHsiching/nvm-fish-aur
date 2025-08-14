# ~/.config/fish/functions/nvm.fish
# Fish wrapper for nvm using bass
function nvm --description 'Node Version Manager - Fish shell integration'
  # Ensure helper functions are available
  if not functions -q __nvm_check_setup
    if test -f /usr/share/fish/vendor_functions.d/bass_helper.fish
      source /usr/share/fish/vendor_functions.d/bass_helper.fish
    end
  end
  
  # Handle 'init' subcommand
  if test "$argv[1]" = "init"
    echo "🎉 Initializing nvm-fish..."
    __nvm_run_setup
    return $status
  end
  
  # Check if nvm-fish is initialized
  if not __nvm_check_setup
    echo ""
    echo "❌ nvm-fish is not initialized yet."
    echo ""
    echo "🔧 Please run the following command first:"
    echo "    nvm init"
    echo ""
    echo "💡 This will:"
    echo "   - Detect and install bass (if needed)"
    echo "   - Configure Fish shell integration"
    echo "   - Enable .nvmrc automatic switching"
    echo ""
    return 1
  end
  
  # Ensure bass is available (quick check)
  if not __nvm_ensure_bass_quick
    echo ""
    echo "❌ Bass environment not available."
    echo "🔄 Try running: nvm init"
    echo ""
    return 1
  end
  
  # Execute nvm command
  bass source ~/.nvm/nvm.sh --no-use ';' nvm $argv
end