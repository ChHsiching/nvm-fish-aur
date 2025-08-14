# ~/.config/fish/functions/load_nvm.fish
# Automatically load nvm version when PWD changes
function load_nvm --on-variable="PWD" --description 'Automatically switch Node.js versions based on .nvmrc'
  # Load helper functions if not already loaded (silent check)
  if not functions -q __nvm_setup_bass
    source /usr/share/fish/vendor_functions.d/bass_helper.fish >/dev/null 2>&1
  end
  
  # Silent bass environment check to avoid messages on every directory change
  if not command -v bass >/dev/null 2>&1
    # Try to setup bass environment silently
    __nvm_setup_bass >/dev/null 2>&1
  end
  
  # Exit silently if bass is still not available
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