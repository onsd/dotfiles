# aliases
alias gs='git status'
alias gc='git checkout'
alias gps='git push'
alias gpl='git pull'
alias kns='kubens'
alias kctx='kubectx'
alias k='kubectl'

alias gcd='cd ~/ghq/(ghq list | peco)'

alias arduino='/Applications/Arduino.app/Contents/MacOS/Arduino'

# env variables
set -x LANG ja_JP.UTF-8
set -x PATH /Users/taka/Library/Python/3.7/bin $PATH
set -x PATH /Users/taka/.anyenv/envs/nodenv/versions/12.16.1/bin $PATH
set -x PATH $HOME/.wantedly/bin $PATH 
set -x EDITOR vim 
set -x DENO_INSTALL "/Users/taka/.deno"
set -x PATH $DENO_INSTALL/bin $PATH
set -x TF_CLI_CONFIG_FILE /Users/taka/credentials.hcl
set -x PATH /usr/local/Cellar/tfenv/1.0.2/bin/ $PATH
# eval (bash -c "source ~/.nix-profile/etc/profile.d/nix.sh; fish --command 'echo set -x NIX_PATH \"\$NIX_PATH\"\;; echo set -x PATH \"\$PATH\"\;; echo set -x SSL_CERT_FILE \"\$SSL_CERT_FILE\"'")

if status is-interactive
and not set -q TMUX
    exec tmux
end

set fish_plugins theme peco

function fish_user_key_bindings
  bind \cr peco_select_history # Bind for prco history to Ctrl+r
end

status --is-interactive; and source (anyenv init -|psub)
eval (direnv hook fish)
eval (gh completion -s fish| source)

# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/taka/google-cloud-sdk/path.fish.inc' ]; . '/Users/taka/google-cloud-sdk/path.fish.inc'; end
set -g fish_user_paths "/usr/local/opt/libpq/bin" $fish_user_paths
set -g fish_user_paths "/usr/local/opt/mysql-client/bin" $fish_user_paths

