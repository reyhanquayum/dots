function srt2md --description 'Combine all .srt files in a directory into one markdown file, separated by headings'
    set -l dir .
    set -l out combined_subtitles.md

    if test (count $argv) -ge 1
        set dir $argv[1]
    end
    if test (count $argv) -ge 2
        set out $argv[2]
    end

    if not test -d $dir
        echo "srt2md: directory '$dir' not found" >&2
        return 1
    end

    set -l files (find $dir -maxdepth 1 -name '*.srt' | sort -V)
    if test (count $files) -eq 0
        echo "srt2md: no .srt files found in $dir" >&2
        return 1
    end

    set -l outfile "$dir/$out"
    rm -f $outfile

    for f in $files
        set -l title (basename $f .srt)
        echo "# $title" >> $outfile
        echo >> $outfile
        cat $f >> $outfile
        echo >> $outfile
        echo >> $outfile
    end

    echo "srt2md: wrote "(count $files)" subtitle files into $outfile"
end
