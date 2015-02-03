source $HOME/.antigen/antigen.zsh

antigen use oh-my-zsh

antigen theme sorin

antigen bundle pip
antigen bundle git
antigen bundle brew
antigen bundle npm
antigen bundle command-not-found
antigen bundle zsh-users/zsh-syntax-highlighting

#
# OS specific plugins
if [[ $CURRENT_OS == 'OS X' ]]; then
    antigen bundle brew
    antigen bundle brew-cask
    antigen bundle gem
    antigen bundle osx
fi
#

antigen apply

# Customize to your needs...

# Fix for boxen in zsh
export LC_ALL=en_US.UTF-8  
export LANG=en_US.UTF-8

#path
export PATH=/usr/local/tranquil/bin:/usr/local/bin:/usr/local/tranquil/bin:$HOME/bin:$PATH

#fix for altkeys
bindkey '[D' backward-word
bindkey '[C' forward-word

[ -f /opt/boxen/env.sh ] && source /opt/boxen/env.sh 
