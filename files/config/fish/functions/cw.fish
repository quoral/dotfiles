function cw --description "Claude workspace: create/switch to project workspace with 3-pane layout"
    set -l state_file ~/.local/state/cw/workspaces

    if contains -- --list $argv
        _cw_list
        return
    end

    if contains -- --close $argv
        set -l rest (string match -v -- --close $argv)
        _cw_close $rest
        return
    end

    # Resolve project directory
    set -l project_dir
    if test -n "$argv[1]"
        set project_dir (fd -H -t d '^\.git$' ~/Code -d 4 --no-ignore --prune \
            --exclude reviews --exclude sandbox --exclude node_modules \
            --exec dirname {} | fzf -q "$argv[1]" --select-1 --exit-0)
    else
        set project_dir (fd -H -t d '^\.git$' ~/Code -d 4 --no-ignore --prune \
            --exclude reviews --exclude sandbox --exclude node_modules \
            --exec dirname {} | string replace "$HOME/Code/" '' \
            | fzf --prompt="Project: " \
            | string replace -r '^' "$HOME/Code/")
    end

    if test -z "$project_dir"
        echo "No project selected"
        return 1
    end

    set -l ws_name (_cw_ws_name "$project_dir")

    # If workspace already has windows, just switch
    set -l win_count (aerospace list-windows --workspace "$ws_name" --count 2>/dev/null; or echo 0)
    if test "$win_count" -gt 0
        aerospace workspace "$ws_name"
        return 0
    end

    aerospace workspace "$ws_name"
    _cw_record "$ws_name" "$project_dir"

    ~/.local/bin/cw-layout "$ws_name" "$project_dir" &
    disown
end

function _cw_ws_name --argument project_dir
    # Check for duplicate basenames across ~/Code
    set -l base (basename "$project_dir")
    set -l parent (basename (dirname "$project_dir"))
    set -l matches (fd -H -t d '^\.git$' ~/Code -d 4 --no-ignore --prune \
        --exclude reviews --exclude sandbox --exclude node_modules \
        --exec dirname {} | string match -r "/$base\$")

    if test (count $matches) -gt 1
        echo "p:$parent/$base"
    else
        echo "p:$base"
    end
end

function _cw_list
    set -l state_file ~/.local/state/cw/workspaces
    if not test -f "$state_file"
        echo "No active project workspaces"
        return
    end

    set -l active_ws (aerospace list-workspaces --all)
    while read -l line
        set -l parts (string split \t $line)
        set -l ws $parts[1]
        if contains -- "$ws" $active_ws
            set -l win_count (aerospace list-windows --workspace "$ws" --count 2>/dev/null; or echo 0)
            printf "%-20s %s (%d windows)\n" "$ws" "$parts[2]" "$win_count"
        end
    end <"$state_file"
end

function _cw_close --argument ws_name
    if test -z "$ws_name"
        set ws_name (aerospace list-workspaces --focused)
    end

    if not string match -q 'p:*' "$ws_name"
        echo "Not a project workspace: $ws_name"
        return 1
    end

    for wid in (aerospace list-windows --workspace "$ws_name" --format '%{window-id}')
        aerospace close --window-id "$wid"
    end

    set -l state_file ~/.local/state/cw/workspaces
    if test -f "$state_file"
        grep -v "^$ws_name\t" "$state_file" >"$state_file.tmp" 2>/dev/null; or true
        mv "$state_file.tmp" "$state_file"
    end

    aerospace workspace-back-and-forth
    echo "Closed workspace: $ws_name"
end

function _cw_record --argument ws_name project_dir
    set -l state_file ~/.local/state/cw/workspaces
    mkdir -p (dirname "$state_file")
    if test -f "$state_file"
        grep -v "^$ws_name\t" "$state_file" >"$state_file.tmp" 2>/dev/null; or true
        mv "$state_file.tmp" "$state_file"
    end
    printf "%s\t%s\n" "$ws_name" "$project_dir" >>"$state_file"
end
