# ~/.config/fish/functions/nvm.fish
# Fish wrapper for nvm using bass with automatic setup
function nvm
  # 首次运行时进行完整设置
  __nvm_first_run_setup
  
  # 确保bass环境可用
  if not __nvm_ensure_bass
    return 1
  end
  
  # 执行nvm命令
  bass source ~/.nvm/nvm.sh --no-use ';' nvm $argv
end