function edit
    if [ $argv ]
       if test -e $argv
          emc $argv
       else      
          fzf -q $argv | read MYRESULT; and emc $MYRESULT
       end
    else
       fzf | read MYRESULT; and emc $MYRESULT
    end
end
