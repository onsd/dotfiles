
# for anyenv
status --is-interactive; and source (anyenv init -|psub)

# PATHs
set -x PATH $GOPATH/bin $PATH
set -x PATH $HOME/.nodenv/bin $PATH
set -x PATH /Users/taka/.nodenv/versions/ $PATH
set -x PATH /users/taka/.anyenv/envs/nodenv/versions/12.4.0/bin $PATH
set -x PATH /Users/taka/Workspace/tmp/istio-1.3.0 $PATH
set -x PATH /Users/taka/flutter/bin $PATH
set -x GOROOT /Users/taka/.anyenv/envs/goenv/shims/
set -x GOPATH $HOME/go

# locale
set -x LC_ALL en_US.UTF-8
set -x LANG en_US.UTF-8

# default PORT
# set -x PORT 8080

# for fzf
set -U FZF_LEGACY_KEYBINDINGS 0

# aliases for git
alias gs='git status'
alias gc='git checkout'
alias gps='git push'
alias gpl='git pull'
alias ga='git add'
# alias k='kubectl --kubeconfig /Users/taka/Workspace/HERP/infra/terraform/k8s-tb/next-cluster/kubeconfig.yaml'
alias k='kubectl --kubeconfig /Users/taka/Workspace/HERP/cluster/src/zedd/tmp/kubeconfig.yaml'


# The next line updates PATH for the Google Cloud SDK.
if [ -f '/Users/taka/google-cloud-sdk/path.fish.inc' ]; . '/Users/taka/google-cloud-sdk/path.fish.inc'; end

if [ ! -n $TMUX ] && [ $VSCODE_PID == "" ]; 
  tmux new-session
end

bass source /Users/taka/.nix-profile/etc/profile.d/nix.sh

# TerrafromCloud CLI
set -x TF_CLI_CONFIG_FILE /Users/taka/.TERRAFORM_CREDENTIALS.hcl
