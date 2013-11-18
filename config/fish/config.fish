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

set fish_greeting ""

set PATH /usr/local/tranquil/bin /usr/local/bin ~/bin $PATH
. ~/.config/fish/alias.fish
. ~/.config/fish/boxen.fish
