function claude-sandboxes --description "List and cd to existing sandboxes"
    set sandbox_dir ~/Code/Freda/sandbox
    if not test -d "$sandbox_dir"
        echo "No sandboxes directory found"
        return 1
    end

    set sandbox (ls -1 "$sandbox_dir" | fzf --prompt="Select sandbox: ")
    if test -n "$sandbox"
        cd "$sandbox_dir/$sandbox"
    end
end
