# ~/.config/fish/functions/nvm_find_nvmrc.fish
# Find .nvmrc file in current or parent directories
function nvm_find_nvmrc
  bass source ~/.nvm/nvm.sh --no-use ';' nvm_find_nvmrc
end