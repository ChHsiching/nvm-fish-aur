# ~/.config/fish/functions/load_nvm.fish
# Automatically load nvm version when PWD changes
function load_nvm --on-variable="PWD" --description 'Automatically switch Node.js versions based on .nvmrc'
  # Ensure helper functions are available
  if not functions -q __nvm_check_setup
    if test -f /usr/share/fish/vendor_functions.d/bass_helper.fish
      source /usr/share/fish/vendor_functions.d/bass_helper.fish
    end
  end
  
  # Silent check - exit if not initialized to avoid spam on directory changes
  if not __nvm_check_setup >/dev/null 2>&1
    return
  end
  
  # Silent bass check - exit if not available
  if not __nvm_ensure_bass_quick >/dev/null 2>&1
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