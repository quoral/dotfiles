function edit
    if [ $argv ]
       if test -e $argv
          emacsclient -n $argv
       else      
          fzf -q $argv | read MYRESULT; and emacsclient -n $MYRESULT
       end
    else
       fzf | read MYRESULT; and emacsclient -n $MYRESULT
    end
end
