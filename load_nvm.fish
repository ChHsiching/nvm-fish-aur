# ~/.config/fish/functions/load_nvm.fish
# Automatically load nvm version when PWD changes
function load_nvm --on-variable="PWD"
  # 静默检查bass环境，避免在每次目录切换时都显示消息
  if not command -v bass >/dev/null 2>&1
    # 尝试设置bass环境，但不显示输出
    __nvm_setup_bass >/dev/null 2>&1
  end
  
  # 如果bass仍然不可用，静默退出
  if not command -v bass >/dev/null 2>&1
    return
  end
  
  set -l default_node_version (nvm version default)
  set -l node_version (nvm version)
  set -l nvmrc_path (nvm_find_nvmrc)
  if test -n "$nvmrc_path"
    set -l nvmrc_node_version (nvm version (cat $nvmrc_path))
    if test "$nvmrc_node_version" = "N/A"
      nvm install (cat $nvmrc_path)
    else if test "$nvmrc_node_version" != "$node_version"
      nvm use $nvmrc_node_version
    end
  else if test "$node_version" != "$default_node_version"
    echo "Reverting to default Node version"
    nvm use default
  end
end