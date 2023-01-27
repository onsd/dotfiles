#
# Executes commands at the start of an interactive session.
#
# Authors:
#   Sorin Ionescu <sorin.ionescu@gmail.com>
#

# Source Prezto.
if [[ -s "${ZDOTDIR:-$HOME}/.zprezto/init.zsh" ]]; then
  source "${ZDOTDIR:-$HOME}/.zprezto/init.zsh"
fi

# Customize to your needs...

autoload -Uz promptinit
promptinit
prompt steeef

# functions
#------------------------------------------------------------------------------------------------------------
function ghq-fzf() {
  local src=$(ghq list | fzf --preview "ls -laTp $(ghq root)/{} | tail -n+4 | awk '{print \$9\"/\"\$6\"/\"\$7 \" \" \$10}'")
    if [ -n "$src" ]; then
      BUFFER="cd $(ghq root)/$src"
      zle accept-line
    fi
    zle -R -c
}

function select-history() {
    BUFFER=$(history -n -r 1 | fzf --no-sort +m --query "$LBUFFER" --prompt="History > ")
    CURSOR=$#BUFFER
}

zle -N ghq-fzf
zle -N select-history
###### bindkeys ######
bindkey '^g' ghq-fzf
bindkey '^r' select-history
bindkey '^h' backward-word
bindkey '^l' forward-word

###### local settings ######
# aliases
alias gc='git checkout'
alias gs='git status'
alias gps='git push'
alias gpsf='git push --force'
alias gpl='git pull'
alias gcm='git checkout master || git checkout main'
alias gco='git commit'
alias grs='git reset --soft HEAD\^'
alias -g yamlb="-o yaml | bat -l yaml"
alias show-header-server='python3 $(ghq root)/github.com/onsd/dotfiles/script/simple-http-server.py'

# PATHes
export GOPATH=/User/taka/Workspace
export PATH=/opt/homebrew/bin:$PATH
export PATH=$HOME/.wantedly/bin:$PATH
export PATH=$HOME/.anyenv/bin:$PATH

if [ -e "$HOME/.deno"]
then
  export DENO_INSTALL="$HOME/.deno"
  export PATH="$DENO_INSTALL/bin:$PATH"
fi

# ENVs
export EDITOR="vim"

# other commands
eval "$(anyenv init -)"
eval "$(direnv hook zsh)"

if [ -e "$HOME/.anyenv" ]
then
    export ANYENV_ROOT="$HOME/.anyenv"
    export PATH="$ANYENV_ROOT/bin:$PATH"
    if command -v anyenv 1>/dev/null 2>&1
    then
        eval "$(anyenv init -)"
    fi
fi

if [ -e "$HOME/google-cloud-sdk" ]
  then 
  # The next line updates PATH for the Google Cloud SDK.
  if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

  # The next line enables shell command completion for gcloud.
  if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi
fi
