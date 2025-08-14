# ~/.config/fish/functions/nvm_find_nvmrc.fish
# Find .nvmrc file in current or parent directories
function nvm_find_nvmrc
  # Silent first run setup
  __nvm_first_run_setup > /dev/null 2>&1
  
  # Ensure bass environment is available
  if not __nvm_ensure_bass
    return 1
  end
  
  bass source ~/.nvm/nvm.sh --no-use ';' nvm_find_nvmrc
end