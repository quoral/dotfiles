function edit

    set search_args ""
    set EDE emc
    getopts $argv | while read -l key option
        switch $key
            case _
                set search_args (string join \n $search_args $option)
            case e editor
                set EDE $option
        end
    end

    if [ "$search_args" ]
        if test -e "$search_args"
            eval $EDE $search_args
        else
            fzf -q "$search_args" | read MYRESULT; and eval $EDE "$MYRESULT"
        end
    else
        fzf | read MYRESULT; and emc $MYRESULT
    end
end
