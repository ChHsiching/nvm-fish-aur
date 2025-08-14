# ~/.config/fish/functions/nvm.fish
# Fish wrapper for nvm using bass with automatic setup
function nvm --description 'Node Version Manager - Fish shell integration'
  # Ensure helper functions are available
  if not functions -q __nvm_first_run_setup
    if test -f /usr/share/fish/vendor_functions.d/bass_helper.fish
      source /usr/share/fish/vendor_functions.d/bass_helper.fish
    end
  end
  # First run setup and configuration
  __nvm_first_run_setup
  
  # Ensure bass environment is available
  if not __nvm_ensure_bass
    return 1
  end
  
  # Execute nvm command
  bass source ~/.nvm/nvm.sh --no-use ';' nvm $argv
end