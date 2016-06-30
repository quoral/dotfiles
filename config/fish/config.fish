#function fish_prompt
#    set_color magenta
#    echo -n (vcprompt -f "(%s:%b%a%m)")
#    set_color red
#    echo -ne 'λ '
#    set_color white
#end

#function fish_right_prompt
#   set_color --bold yellow
#   echo -n '['
#   set_color --bold blue
#   echo -n (prompt_pwd)
#   set_color --bold yellow
#   echo -n ']'
#end

set -gx EDITOR "emacsclient -n -create-frame"
set -gx ALTERNATE_EDITOR emacs
set -gx VISUAL emacsclient

set -U LC_ALL en_US.UTF-8
set -U LANG en_US.UTF-8

set fish_greeting ""
set fish_function_path $fish_function_path "/usr/local/lib/python2.7/site-packages/powerline/bindings/fish"
powerline-setup

# Aliases that are good to have.
alias e edit
alias gs "git status --short"
alias gl "git lg"
alias gd "git diff"
alias x "aunpack -q -e"


# Settings for Homebrew Cask
set -x PATH "/usr/local/bin" $PATH
