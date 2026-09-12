if status is-interactive
    set -g PRIVATE_DIRS /home/reyhan/Pictures/.stuff

    function __private_history --on-variable PWD
        for dir in $PRIVATE_DIRS
            if test "$PWD" = "$dir"; or string match -q -- "$dir/*" "$PWD"
                set -g fish_history ""
                return
            end
        end
        set -g fish_history fish
    end

    # run once so it also applies if the shell starts in one of those dirs
    __private_history
end
