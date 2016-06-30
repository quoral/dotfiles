function edit
    if [ $argv ]
       if test -e $argv
          emacsclient -n $argv
       else      
          fzf -q $argv | read MYRESULT; and charm $MYRESULT
       end
    else
       fzf | read MYRESULT; and charm $MYRESULT
    end
end
