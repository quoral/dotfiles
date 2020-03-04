function edit

    set search_args ""
    getopts $argv | while read -l key option
        switch $key
            case _
                set search_args (string join " " $search_args $option)
        end
    end
    set search_args (string trim -- $search_args)
    if [ "$search_args" ]
        if test -e "$search_args"
            open_editor_no_wait $search_args
        else
            fzf -q "$search_args" | read READRESULT
            open_editor_no_wait $READRESULT
        end
    else
        fzf | read READRESULT
        open_editor_no_wait $READRESULT
    end
end

function edit_ag
     set search_args ""
     getops
end

function open_editor_no_wait
    emacsclient -q $argv &; disown
end
