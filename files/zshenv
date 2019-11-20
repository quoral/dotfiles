source $HOME/.antigen/antigen.zsh
antigen use oh-my-zsh

antigen theme sorin

antigen bundle git
antigen bundle brew
antigen bundle brew-cask
antigen bundle gem
antigen bundle osx
antigen bundle npm
antigen bundle command-not-found
antigen bundle zsh-users/zsh-syntax-highlighting


antigen apply

pyclean () {
    find . -name "*.pyc" | xargs -I {} rm -v "{}"
    find . -type d -name "__pycache__" -delete
}

# Fix for boxen in zsh
export LC_ALL=en_US.UTF-8
export LANG=en_US.UTF-8


alias edit="emacsclient --no-wait"
export PYLINTRC="~/.pylintrc"
export EDITOR="emacsclient -n"

export GOPATH="$HOME/Code/go"


export PATH=/usr/local/bin:$HOME/bin:$GOPATH/bin:$PATH


if which pyenv > /dev/null; then
    eval "$(pyenv init -)";
fi
