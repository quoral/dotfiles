function wt --argument args
    set dir (git worktree list | awk '{print $1}' | fzf -q "$args")
    and cd "$dir"
end
