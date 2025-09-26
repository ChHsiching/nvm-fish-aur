# ~/.config/fish/functions/load_nvm.fish
# Automatically load nvm version when PWD changes
function load_nvm --on-variable="PWD" --description 'Automatically switch Node.js versions based on .nvmrc'
  # Fast startup optimization - only do minimal work during fish startup
  if not set -q __nvm_fish_pwd_initialized
    set -g __nvm_fish_pwd_initialized 1
    # On startup, only set the flag and exit immediately
    # Actual nvm operations will happen on first directory change
    return
  end
  
  # Lightweight check - only proceed if nvm-fish is properly set up
  if not test -f "$HOME/.config/nvm-fish-setup-done"
    return
  end
  
  # Quick bass availability check - avoid heavy sourcing on every directory change
  if not command -v bass >/dev/null 2>&1
    if test -f "$HOME/.config/fish/functions/bass.fish"
      source "$HOME/.config/fish/functions/bass.fish" 2>/dev/null
    else
      return
    end
  end
  
  # Look for .nvmrc in current or parent directories
  set -l nvmrc_path ""
  set -l current_dir "$PWD"

  # Search up the directory tree for .nvmrc
  while test -z "$nvmrc_path" -a "$current_dir" != "/"
    if test -f "$current_dir/.nvmrc"
      set nvmrc_path "$current_dir/.nvmrc"
    else
      set current_dir (dirname "$current_dir")
    end
  end

  if test -n "$nvmrc_path" -a -f "$nvmrc_path"
    # Only call nvm if there's actually a .nvmrc file
    set -l nvmrc_content (cat "$nvmrc_path" 2>/dev/null | string trim)
    if test -n "$nvmrc_content"
      # Check if we're already using this version (avoid unnecessary nvm calls)
      set -l current_version_check (node --version 2>/dev/null | string replace 'v' '')
      set -l target_version (string replace 'v' '' "$nvmrc_content")

      # Extract pure version number (remove npm info if present)
      set -l pure_version (string match -rg '^([0-9]+\.[0-9]+\.[0-9]+)' "$target_version" || echo "$target_version")

      # Compare using pure version numbers
      if test "$current_version_check" != "$pure_version"
        set -l nvmrc_node_version (nvm version "$pure_version" 2>/dev/null)
        if test "$nvmrc_node_version" = "N/A"
          # Use direct bass call to avoid .nvmrc management prompts
          bass source ~/.nvm/nvm.sh --no-use ';' nvm install "$pure_version"
        else
          # Use direct bass call to avoid .nvmrc management prompts
          bass source ~/.nvm/nvm.sh --no-use ';' nvm use "$pure_version"
        end
      end
    end
  else
    # Only revert to default if we're not already on default
    # This avoids calling nvm on every directory without .nvmrc
    if test -n "$NVM_BIN" -a "$NVM_BIN" != "$HOME/.nvm/versions/node/$(nvm version default 2>/dev/null)/bin"
      # Use direct bass call to avoid .nvmrc management prompts and output
      bass source ~/.nvm/nvm.sh --no-use ';' nvm use default
    end
  end
end