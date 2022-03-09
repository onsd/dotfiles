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
prompt giddie

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
bindkey '^g' ghq-fzf
zle -N select-history
bindkey '^r' select-history

###### local settings ######
# aliases
alias gc='git checkout'
alias gs='git status'
alias gps='git push'
alias gpsf='git push --force'
alias gpl='git pull'
alias gcm='git checkout master || git checkout main'
alias -g yamlb="-o yaml | bat -l yaml"

# PATHes
export GOPATH=/User/taka/Workspace
export PATH="$HOME/.wantedly/bin:$PATH"
export PATH="/usr/local/bin:$PATH"
export PATH="$HOME/.anyenv/bin/:$PATH"

# ENVs
export EDITOR="vim"

# anyenv
eval "$(anyenv init -)"
eval "$(direnv hook zsh)"