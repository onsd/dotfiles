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

function git-branch-fzf() {
    local selected=$(git branch | while read line; do
        if [[ "$line" == \+* ]]; then
            branch=$(echo "$line" | sed 's/^[+ ]*//')
            worktree_path=$(git worktree list | grep "\[$branch\]" | awk '{print $1}')
            echo "$branch (worktree: $worktree_path)"
        elif [[ "$line" == \** ]]; then
            echo "$line" | sed 's/^[* ]*//'
        else
            echo "$line" | sed 's/^ *//'
        fi
    done | fzf)

    if [ -n "$selected" ]; then
        if [[ "$selected" == *"(worktree:"* ]]; then
            worktree_path=$(echo "$selected" | sed 's/.*worktree: \(.*\))/\1/')
            BUFFER="cd $worktree_path"
        else
            BUFFER="git switch $selected"
        fi
        zle accept-line
    fi
    zle -R -c
}

function select-history() {
    BUFFER=$(history -n -r 1 | fzf --no-sort +m --query "$LBUFFER" --prompt="History > ")
    CURSOR=$#BUFFER
}

zle -N ghq-fzf
zle -N git-branch-fzf
zle -N select-history

###### bindkeys ######
bindkey '^g' ghq-fzf
bindkey '^b' git-branch-fzf
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

# Add this line to treat '/' as a word boundary
WORDCHARS=${WORDCHARS//\//}

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
export PATH=/opt/homebrew/bin:$PATH

if [ -e "$HOME/.deno" ]
then
  export DENO_INSTALL="$HOME/.deno"
  export PATH="$DENO_INSTALL/bin:$PATH"
fi

# ENVs
export EDITOR="vim"
export GOPRIVATE=github.com/LayerXcom

# other commands
# eval "$(anyenv init -)"
eval "$(direnv hook zsh)"

# if [ -e "$HOME/.local/bin/mise" ]
# then
#   eval "$(~/.local/bin/mise activate zsh)"
# fi


if [ -e "$HOME/google-cloud-sdk" ]
  then
  # The next line updates PATH for the Google Cloud SDK.
  if [ -f "$HOME/google-cloud-sdk/path.zsh.inc" ]; then . "$HOME/google-cloud-sdk/path.zsh.inc"; fi

  # The next line enables shell command completion for gcloud.
  if [ -f "$HOME/google-cloud-sdk/completion.zsh.inc" ]; then . "$HOME/google-cloud-sdk/completion.zsh.inc"; fi
fi

# git clone https://github.com/zsh-users/zsh-autosuggestions ~/.zsh/zsh-autosuggestions
if [ -e "$HOME/.zsh/zsh-autosuggestions" ]
then
    source ~/.zsh/zsh-autosuggestions/zsh-autosuggestions.zsh
fi

eval "$(starship init zsh)"


# pnpm
export PNPM_HOME="/Users/takamichi.omori/Library/pnpm"
case ":$PATH:" in
  *":$PNPM_HOME:"*) ;;
  *) export PATH="$PNPM_HOME:$PATH" ;;
esac
# pnpm end


# bun completions
[ -s "/Users/takamichi.omori/.bun/_bun" ] && source "/Users/takamichi.omori/.bun/_bun"

export PATH="$HOME/.local/bin:$PATH"

# aqua
export AQUA_GLOBAL_CONFIG="/Users/takamichi.omori/Workspace/github.com/LayerXcom/layerone/go/cli/global-aqua/global-aqua.yaml"
export PATH="$(aqua root-dir)/bin:$PATH"

[[ "$TERM_PROGRAM" == "kiro" ]] && . "$(kiro --locate-shell-integration-path zsh)"

# Bakuraku開発環境設定
source ~/.zshrc.bakuraku

export AQUA_GLOBAL_CONFIG="/Users/takamichi.omori/.config/aquaproj-aqua/aqua.yaml"

export NPM_CONFIG_PREFIX="${XDG_DATA_HOME:-$HOME/.local/share}/npm-global"

export PATH=$NPM_CONFIG_PREFIX/bin:$PATH
export PATH="/usr/local/opt/mysql-client/bin:$PATH"
export PATH="/opt/homebrew/opt/mysql-client/bin:$PATH"
