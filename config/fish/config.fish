function fish_prompt
    set_color magenta
    echo -n (vcprompt -f "(%s:%b%a%m)")
    set_color red
    echo -ne 'λ '
    set_color white
end

function fish_right_prompt
   set_color --bold yellow
   echo -n '['
   set_color --bold blue
   echo -n (prompt_pwd)
   set_color --bold yellow
   echo -n ']'
end

set -gx EDITOR "emacsclient -n -create-frame"
set -gx ALTERNATE_EDITOR emacs
set -gx VISUAL emacsclient

#Lol commits, for extra lol
alias lolcommit "lolcommit --fork --stealth --animate=3"


set fish_greeting ""

#Settings for Homebrew Cask
set -x HOMEBREW_CASK_OPTS '--appdir="/Applications"'


set -x JAVA_HOME "/Library/Java/JavaVirtualMachines/jdk1.7.0_21.jdk/Contents/Home"

set -x PATH /usr/local/tranquil/bin /usr/local/bin ~/bin $PATH
set -x PATH "/Library/Java/JavaVirtualMachines/jdk1.7.0_21.jdk/Contents/Home/bin" $PATH

. ~/.config/fish/boxen/env.fish

