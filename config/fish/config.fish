set -gx EDITOR "emacsclient -n -create-frame"
set -gx ALTERNATE_EDITOR emacs
set -gx VISUAL emacsclient
set -gx  LC_ALL en_US.UTF-8

set fish_function_path $fish_function_path "/usr/local/lib/python2.7/site-packages/powerline/bindings/fish"

# Please don't talk to me computer
set fish_greeting ""

#Fixes a nasty bug, where pyenv started reporting errors *everywhere*
function setenv
    set -gx $argv
end

# Aliases that are good to have.
alias e edit
alias c "edit --editor charm"
alias we "edit --editor webstorm"
alias gs "git status --short"
alias gl "git lg"
alias gd "git diff"
alias gb "git branch"
alias x "aunpack -q -e"
alias emc 'emacsclient -n'
alias g "git"
alias ipy "ipython"
# Kill the last command, I like to ctrl-c in projects that have messed too much with the signals.
alias kp "kill %1"

set -x GOPATH "$HOME/Code/go"
set -x JAVA_HOME (/usr/libexec/java_home)
set -x PATH "/usr/local/bin" $PATH
set -x PATH "$GOPATH/bin" $PATH
set -x PATH "$HOME/.cargo/bin" $PATH

set -x DYLD_LIBRARY_PATH $HOME/.rustup/toolchains/stable-x86_64-apple-darwin/lib
set -x RLS_ROOT $HOME/src/rls

if [ $TERM ]
   powerline-setup
   status --is-interactive; and source (pyenv init - | psub); and . (nodenv init -|psub)
   status --is-interactive; and . (pyenv virtualenv-init -|psub)
end

