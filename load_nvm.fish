# ~/.config/fish/functions/load_nvm.fish
# Automatically load nvm version when PWD changes
function load_nvm --on-variable="PWD" --description 'Automatically switch Node.js versions based on .nvmrc'
  # Check if this is startup (no previous PWD set) - be silent during startup
  set -l is_startup (not set -q __nvm_fish_pwd_initialized)
  if test -z "$is_startup"
    set -g __nvm_fish_pwd_initialized 1
    set is_startup true
  else
    set is_startup false
  end
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
  
  set -l default_node_version (nvm version default 2>/dev/null)
  set -l node_version (nvm version 2>/dev/null)
  set -l nvmrc_path (nvm_find_nvmrc 2>/dev/null)
  if test -n "$nvmrc_path"
    set -l nvmrc_node_version (nvm version (cat $nvmrc_path) 2>/dev/null)
    if test "$nvmrc_node_version" = "N/A"
      if test "$is_startup" = "true"
        nvm install (cat $nvmrc_path) >/dev/null 2>&1
      else
        nvm install (cat $nvmrc_path)
      end
    else if test "$nvmrc_node_version" != "$node_version"
      if test "$is_startup" = "true"
        nvm use $nvmrc_node_version >/dev/null 2>&1
      else
        nvm use $nvmrc_node_version
      end
    end
  else if test "$node_version" != "$default_node_version"
    if test "$is_startup" = "true"
      # Silent revert during startup
      nvm use default >/dev/null 2>&1
    else
      # Show message during interactive directory changes
      echo "Reverting to default Node version"
      nvm use default
    end
  end
end