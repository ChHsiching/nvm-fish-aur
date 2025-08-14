# ~/.config/fish/functions/nvm.fish
# Fish wrapper for nvm using bass
function nvm
  bass source ~/.nvm/nvm.sh --no-use ';' nvm $argv
end