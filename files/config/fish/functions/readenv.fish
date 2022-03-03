function readenv --on-variable PWD
    if test -r "$argv"
        while read -l line
            set -l kv (string split -m 1 = -- $line)
            set -l key (string trim -c '"' -- $kv[2..])
            set -gx $kv[1] $key # this will set the variable named by $kv[1] to the rest of $kv
        end < "$argv"
   end
end
