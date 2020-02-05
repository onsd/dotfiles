# install fish shell if not exists
if !(type "fish" > /dev/null 2>&1); then
    echo "Install fish shell"
    git clone https://github.com/fish-shell/fish-shell.git
    cd fish-shell; cmake .; make; sudo make install
fi

if !(type "anyenv" > /dev/null 2>&1); then
    echo "Install anyenv"
    git clone https://github.com/anyenv/anyenv ~/.anyenv
    set -Ux fish_user_paths $HOME/.anyenv/bin $fish_user_paths
    ~/.anyenv/bin/anyenv init
fi
