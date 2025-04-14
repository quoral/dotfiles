function for_all_folder --description 'Run a command in multiple folders, exiting on first error'
    if test (count $argv) -lt 2
        echo "Usage: for_all_folder <command> <folder1> [folder2] ..." >&2
        return 1
    end

    set -l command_to_run $argv[1]
    set -l folders $argv[2..-1]
    set -l original_dir (pwd)
    set -l last_status 0

    for folder in $folders
        if not test -d "$folder"
            echo "Error: '$folder' is not a valid directory." >&2
            # No need to cd back since we didn't cd in
            return 1
        end

        echo "--> Entering $folder"
        cd "$folder"
        set last_status $status
        if test $last_status -ne 0
            echo "Error: Failed to change directory to '$folder'." >&2
            cd "$original_dir" # Attempt to return to original dir
            return $last_status
        end

        # Execute the command
        eval $command_to_run
        set last_status $status

        # Always try to return to the original directory
        cd "$original_dir"
        set -l cd_back_status $status
        if test $cd_back_status -ne 0
             echo "Error: Failed to change back to original directory '$original_dir' from '$folder'." >&2
             # If cd back failed, we still prioritize returning the command's status if it failed
             if test $last_status -ne 0
                 return $last_status
             else
                 return $cd_back_status
             fi
        end

        # Check command status after successfully changing back
        if test $last_status -ne 0
            echo "Error: Command '$command_to_run' failed in '$folder' with status $last_status." >&2
            return $last_status
        end
        echo "<-- Exited $folder"
    end

    return 0
end
