# ~/.config/fish/functions/nvm_find_nvmrc.fish
# Find .nvmrc file in current or parent directories
function nvm_find_nvmrc
  # 首次运行时进行完整设置（静默）
  __nvm_first_run_setup > /dev/null 2>&1
  
  # 确保bass环境可用
  if not __nvm_ensure_bass
    return 1
  end
  
  bass source ~/.nvm/nvm.sh --no-use ';' nvm_find_nvmrc
end