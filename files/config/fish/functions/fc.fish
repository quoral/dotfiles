function fc --argument args
    set dir (fd --glob -H -t d '**/.git' ~/Code -d 5 --min-depth 2 --no-ignore --exclude 'reviews' --exec dirname {} | string replace "$HOME/Code/" '~/Code/' | fzf -q "$args" | string replace '~' "$HOME" )
    cd "$dir"
end
