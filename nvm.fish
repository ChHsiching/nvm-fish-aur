# ~/.config/fish/functions/nvm.fish
# Fish wrapper for nvm using bass with automatic setup
function nvm --description 'Node Version Manager - Fish shell integration'
  # First run setup and configuration
  __nvm_first_run_setup
  
  # Ensure bass environment is available
  if not __nvm_ensure_bass
    return 1
  end
  
  # Execute nvm command
  bass source ~/.nvm/nvm.sh --no-use ';' nvm $argv
end