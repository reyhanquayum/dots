source /usr/share/cachyos-fish-config/cachyos-config.fish

# Override CachyOS bat manpager — less breaks with Fish 4.x + Kitty keyboard protocol
set -x MANPAGER "nvim +Man!"

# overwrite greeting
# potentially disabling fastfetch
#function fish_greeting
#    # smth smth
#end
#
#alias sioyek="kitty +kitten launch sioyek"
#alias nautilus="kitty +kitten launch nautilus"
alias ocr='tesseract'
alias ltst='eza -s modified -r --color=always --icons=always | head -1'
alias lsd='eza -D -1 --icons --hyperlink'
alias lsh='eza --hyperlink --icons --long --no-permissions --no-user'
alias unlock='~/.config/scripts/unlock-vault.sh'
alias lock='~/.config/scripts/lock-vault.sh'
alias vpn='~/.config/scripts/vpn.sh'
alias vpnd='~/.config/scripts/vpnd.sh'
alias vpnjp='~/.config/scripts.vpnjp.sh'
alias vpndjp='~/.config/scripts/vpnd-jp.sh'
alias vpn-gt='sudo openconnect --protocol=gp vpn.gatech.edu -u rquayum6 --background'
alias vpn-gtd='sudo killall openconnect'
alias vpn-gt-split='sudo openconnect --protocol=gp vpn.gatech.edu \
    -u rquayum6 \
    -s "vpn-slice login-ice.pace.gatech.edu" \
    --background
'

function compress
    set input $argv[1]
    set name (path change-extension "" $input)
    ffmpeg -i "$input" \
        -c:v libx265 -preset medium -crf 32 -tag:v hvc1 \
        -c:a aac -b:a 64k \
        "$name"_small.mp4
end

function fe
    nautilus . >/dev/null 2>&1 &
    disown
end

alias img  "kitty +kitten icat"

function fish_prompt
    # Set colors
    set_color green
    echo -n (whoami)
    set_color normal
    echo -n "@"
    set_color blue
    echo -n (hostname|cut -d . -f 1)
    set_color normal
    echo -n ":"
    set_color magenta
    echo -n (prompt_pwd) # Current working directory, often shortened
    set_color red
    # Add the Git VCS prompt if in a Git repository
    echo -n (fish_vcs_prompt)
    set_color normal
    echo -n "> " # Your prompt ending character
end

function latestvid
    set vid (find . -type f \( -iname "*.mkv" -o -iname "*.mp4" -o -iname "*.mov" \) -printf "%T@ %p\n" | sort -nr | head -n1 | cut -d" " -f2-)
    if test -n "$vid"
        mpv "$vid"
    end
end

function pdf
    set -l dir (test (count $argv) -gt 0; and echo $argv[1]; or echo ~/Documents)
    set -l selected (find "$dir" -type f -name "*.pdf" 2>/dev/null | fzf --preview 'pdftotext {} - | head -200')

    if test -n "$selected"
        sioyek "$selected" &>/dev/null &
        disown
        echo "Opening: $selected"
    end
end

# set up zoxide to replace cd alias

eval "$(zoxide init --cmd cd fish)"

function fish_user_key_bindings
  fish_vi_key_bindings
end

# make unzip default to creating new folder
function uzip
    set f $argv[1]
    if test -z "$f"
        command unzip $argv
        return
    end

    set dir (dirname "$f")
    set file (basename "$f")
    set base (string replace -r '\.zip$' '' "$file")

    set target "$dir/$base"
    mkdir -p "$target"
    command unzip -q "$f" -d "$target"
end

# set up starfish
starship init fish | source

export ELECTRON_OZONE_PLATFORM_HINT="auto"
export BROWSER=firefox
set -x JAVA_HOME /usr/lib/jvm/java-17-openjdk
fish_add_path $JAVA_HOME/bin

# Start/create persistent GIOS container
function gios-start
    docker run -d --name gios-dev \
        -v ~/Documents/OMSCS/gios/projects/:/workspace \
        -w /workspace \
        gios-custom \
        sleep infinity
end

# Auto-start containers if they exist but aren't running
function gios
    if not docker ps -q -f name=gios-dev > /dev/null
        if docker ps -a -q -f name=gios-dev > /dev/null
            docker start gios-dev
        else
            echo "Run gios-start first!"
            return 1
        end
    end
    docker exec -it gios-dev bash -c "tmux new -A -s gios"
end

function gios-stop
  docker stop gios-dev
  docker rm gios-dev
end

# Start/create persistent HPCA container
function hpca-start
    docker run -d --name hpca-dev \
        -v ~/Documents/OMSCS/hpca/projects/:/home/cs6290 \
        -w /home/cs6290 \
        jsachs123/cs6290 \
        sleep infinity
end

# Same for HPCA
function hpca
    if not docker ps -q -f name=hpca-dev > /dev/null
        if docker ps -a -q -f name=hpca-dev > /dev/null
            docker start hpca-dev
        else
            echo "Run hpca-start first!"
            return 1
        end
    end
    docker exec -it hpca-dev bash
end

# Stop HPCA container when done
function hpca-stop
    docker stop hpca-dev
    docker rm hpca-dev
end

function fwrec
    set filename record_(date +%Y%m%d_%H%M%S).wav
    echo "Recording audio... Press Ctrl+C to stop."

    ffmpeg -f pulse -i default $filename

    echo "Recording saved to $filename"
    echo "Transcribing..."

    # Activate pipenv and run whisper
    set transcript (pipenv run whisper $filename --model small --language en --fp16 --output_format txt --output_dir . | tee /dev/tty)

    set transcript_file (string replace -r '\.wav$' '.txt' $filename)
    cat $transcript_file | wl-copy
    echo "Transcript copied to clipboard."
end

function pall
    # function to play all media in a directory, map subtitles, sticky settings
    # made for OMSCS, but should work in general
    set -l extra_mpv_args
    if contains -- --video $argv
        set -a extra_mpv_args --force-window=yes --sub-pos=50
    end

    # --- Collect media files ---
    set -l media
    for ext in mp4 mkv webm avi mov opus mp3 flac m4a wav ogg aac wma
        set -a media *.$ext 2>/dev/null
    end
    set media (for f in $media; test -f "$f"; and echo "$f"; end | sort)
    if test (count $media) -eq 0
        echo "No media files found in current directory."
        return 1
    end

    # --- Resume state ---
    set -l state_dir "$HOME/.local/state/mpv-playall"
    set -l encoded_dir (string replace -a '/' '%' (pwd))
    set -l state_file "$state_dir/$encoded_dir"
    set -l resume_args --script-opts=playlist_resume=yes

    if test -f "$state_file"
        set -l lines (string trim < "$state_file" | string split \n)
        set -l saved_pos $lines[1]
        set -l saved_speed $lines[2]
        set -l saved_time $lines[3]
        set -l saved_font_offset $lines[4]
        set -l file_count (count $media)
        set -l has_resume false
        if string match -qr '^\d+$' "$saved_pos"; and test "$saved_pos" -ge 0 2>/dev/null; and test "$saved_pos" -lt "$file_count" 2>/dev/null
            set -l time_display ""
            if string match -qr '^[0-9.]+$' "$saved_time"; and test "$saved_time" != 0
                set -l mins (math "floor($saved_time / 60)")
                set -l secs (math "floor($saved_time % 60)")
                set time_display (printf " at %d:%02d" $mins $secs)
                set resume_args[1] --script-opts=playlist_resume=yes,playlist_resume_time=$saved_time
                set has_resume true
            end
            if test "$saved_pos" -gt 0
                set -a resume_args --playlist-start=$saved_pos
                set has_resume true
            end
            if test "$has_resume" = true
                echo "Resuming playlist from file "(math $saved_pos + 1)"/$file_count$time_display"
            end
        end
        if string match -qr '^[0-9.]+$' "$saved_speed"; and test "$saved_speed" != 1
            set -a resume_args --speed=$saved_speed
            echo "Restoring playback speed: $saved_speed""x"
        end
        if string match -qr '^-?[0-9]+$' "$saved_font_offset"; and test "$saved_font_offset" != 0
            set resume_args[1] "$resume_args[1],sub_font_offset=$saved_font_offset"
            echo "Restoring subtitle font offset: $saved_font_offset"
        end
    end

    # --- Locate subtitle directory ---
    set -l srt_dir ""

    # 1. Current directory has .srt files (HPCA same-dir modules)
    if find . -maxdepth 1 -name '*.srt' -print -quit | read -l _found
        set srt_dir (pwd)
    # 2. Child "subtitles" directory
    else if test -d (pwd)"/subtitles"
        set srt_dir (pwd)"/subtitles"
    else
        set -l parent (dirname (pwd))
        set -l base (basename (pwd))

        # 3. GIOS style: <dirname>_subtitles sibling
        if test -d (pwd)"_subtitles"
            set srt_dir (pwd)"_subtitles"
        else
            # 4. HPCA style: sibling dir with spaces instead of underscores
            set -l space_name (string replace -a '_' ' ' "$base")
            if test "$space_name" != "$base"; and test -d "$parent/$space_name"
                set srt_dir "$parent/$space_name"
            end
        end
    end

    # No subtitles found — plain playback
    if test -z "$srt_dir"
        mpv --fs $extra_mpv_args $resume_args $media
        return
    end

    set -l srts (find "$srt_dir" -maxdepth 1 -name '*.srt' -print | sort)
    if test (count $srts) -eq 0
        mpv --fs $extra_mpv_args $resume_args $media
        return
    end

    # --- Build mpv args with per-file subtitle matching ---
    set -l args --fs --sub-auto=no
    set -l idx 0
    for f in $media
        set idx (math $idx + 1)
        set -l base_name (string replace -r '\.[^.]+$' '' "$f")
        set -l num_prefix (string match -r '^\d+' "$base_name")
        set -l matched ""

        # 1) Exact filename match
        if test -f "$srt_dir/$base_name.srt"
            set matched "$srt_dir/$base_name.srt"
        end

        # 2) Number-prefix match (handles quiz name differences like
        #    "Quiz Question.mp4" → "Quiz.srt" when both are numbered 118)
        if test -z "$matched"; and test -n "$num_prefix"
            for srt in $srts
                set -l srt_num (string match -r '^\d+' (basename "$srt"))
                if test "$srt_num" = "$num_prefix"
                    set matched "$srt"
                    break
                end
            end
        end

        # 3) Positional fallback (different numbering like 521→01, 522→02...)
        if test -z "$matched"; and test $idx -le (count $srts)
            set matched $srts[$idx]
        end

        set -a args '--{'
        if test -n "$matched"
            set -a args --sub-file="$matched"
        end
        set -a args "$f"
        set -a args '--}'
    end

    mpv $extra_mpv_args $resume_args $args
end

function openw --description 'Open docx files silently in the background'
    nohup xdg-open $argv >/dev/null 2>&1 &
    disown
end

function pomo
    set work 25
    set short_break 5
    set long_break 30
    set cycles 4

    while true
        for i in (seq $cycles)
            echo (date +%H:%M)" Cycle $i/$cycles — Focus!"
            sleep (math "$work * 60")
            notify-send -u critical -t 0 "Time for a break!"

            if test $i -lt $cycles
                echo (date +%H:%M)" Short break for 5 minutes"
                sleep (math "$short_break * 60")
                notify-send -u critical -t 0 "Back to work!"
            end
        end

        echo (date +%H:%M)" Long break for 30 minutes"
        sleep (math "$long_break * 60")
        notify-send -u critical -t 0 "Back to work!"
    end
end
