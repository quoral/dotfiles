function git

   if type -q hub
       hub $argv
   else
       set git_location (which git)
       $git_location $argv
   end
end
