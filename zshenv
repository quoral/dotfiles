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




export PATH=/usr/local/tranquil/bin:/usr/local/bin:/usr/local/tranquil/bin:$HOME/bin:$PATH
export PYENV_ROOT=/opt/boxen/homebrew/var/pyenv
export PYENV_VIRTUALENV_DISABLE_PROMPT=1
[ -f /opt/boxen/env.sh ] && source /opt/boxen/env.sh

if which pyenv > /dev/null; then
    eval "$(pyenv init -)";
fi
