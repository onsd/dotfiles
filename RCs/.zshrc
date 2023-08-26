# functions
#------------------------------------------------------------------------------------------------------------
function ghq-fzf() {
    local src=$(find $(ghq root)/github.com -d 2 -maxdepth 2 | grep -v DS_Store | sed -e "s#$(ghq root)/##g" | fzf)
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
bindkey '^a' beginning-of-line
bindkey '^e' end-of-line

###### local settings ######
HISTFILE=~/.zsh_history      # ヒストリファイルを指定
HISTSIZE=10000               # ヒストリに保存するコマンド数
SAVEHIST=10000               # ヒストリファイルに保存するコマンド数
setopt hist_ignore_all_dups  # 重複するコマンド行は古い方を削除
setopt hist_ignore_dups      # 直前と同じコマンドラインはヒストリに追加しない
setopt share_history         # コマンド履歴ファイルを共有する
setopt append_history        # 履歴を追加 (毎回 .zsh_history を作るのではなく)
setopt inc_append_history    # 履歴をインクリメンタルに追加
setopt hist_no_store         # historyコマンドは履歴に登録しない
setopt hist_reduce_blanks    # 余分な空白は詰めて記録


# aliases
alias gc='git checkout'
alias gs='git status'
alias gps='git push'
alias gpsf='git push --force'
alias gpl='git pull'
alias gcm='git checkout master || git checkout main'
alias gcd='git checkout develop'
alias gcs='git checkout staging'
alias gco='git commit'
alias grs='git reset --soft HEAD\^'
alias -g yamlb="-o yaml | bat -l yaml"
alias show-header-server='python3 $(ghq root)/github.com/onsd/dotfiles/script/simple-http-server.py'
alias mkgif='ffmpeg -filter_complex "[0:v] fps=10,scale=640:-1,split [a][b];[a] palettegen [p];[b][p] paletteuse" -i '
alias notify='osascript -e '\'' display notification "タスクが終了しました" with title "Terminal" sound name "Glass.aiff" '\'''

# PATHes
export GOPATH=~/Workspace
export GOBIN=$GOPATH/bin
export PATH=$GOBIN:$PATH
export PATH=$HOME/.anyenv/bin:$PATH
export PATH=/opt/homebrew/bin:$PATH

if [ -e "$HOME/.deno" ]
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

if [ -e "$HOME/.zsh/zsh-autosuggestions" ]
then
    source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

eval "$(starship init zsh)"

