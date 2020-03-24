function fc
    set -q $argv[1]; or set $argv[1] ""
    set dir (find ~/Code -maxdepth 2 -mindepth 2 -type d 2> /dev/null | fzf -q "$argv")
    cd $dir
end
