function fc --argument args
    # set -q $args[1]; or set $args[1] ""

    set dir (find ~/Code -maxdepth 2 -mindepth 2 -type d 2> /dev/null | fzf -q "$args")
    cd $dir
end
