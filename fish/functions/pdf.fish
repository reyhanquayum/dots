function pdf --description 'fuzzy-find a PDF, open it in sioyek, and focus the window in niri'
    set -l dir (test (count $argv) -gt 0; and echo $argv[1]; or echo ~/Documents)
    set -l selected (fd --type f --extension pdf . "$dir" 2>/dev/null | fzf --preview '~/.config/fish/pdf-preview.sh {}')

    if test -z "$selected"
        return
    end

    # setsid -f detaches the sioyek client from this shell's process group.
    # This matters when `pdf` runs inside the sioyek <C-p> kitty popup: fish -c
    # is non-interactive (no job control), so a plain `& disown` child stays in
    # the pty's foreground group and gets SIGHUPed when the popup closes --
    # before it can hand the file to the running sioyek instance.
    setsid -f sioyek --reuse-window "$selected" >/dev/null 2>&1
    echo "Opening: $selected"

    # sioyek is single-instance, so focus by app_id (works on reuse too).
    # Poll briefly only to cover the first-launch window-mapping delay.
    for i in (seq 30)
        set -l id (niri msg -j windows | jq -r \
            '[.[] | select(.app_id == "sioyek")] | sort_by(.id) | last | .id')
        if test -n "$id" -a "$id" != null
            niri msg action focus-window --id $id
            return
        end
        sleep 0.05
    end
end
