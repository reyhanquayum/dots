#!/bin/sh
# fzf preview: render the first page of a PDF as an image (cover) in the right pane.
# Falls back to extracted text if rendering tools are unavailable.

file="$1"

cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/pdf-preview"
mkdir -p "$cache_dir"

# Cache key based on path + mtime so re-renders only happen when the file changes.
mtime=$(stat -c %Y "$file" 2>/dev/null || echo 0)
key=$(printf '%s\n%s' "$file" "$mtime" | cksum | tr -d ' ')
img="$cache_dir/$key.png"

if [ ! -f "$img" ]; then
    # -singlefile + -f 1 renders only page 1; -r controls resolution.
    pdftoppm -png -singlefile -f 1 -l 1 -r 150 "$file" "$cache_dir/$key" 2>/dev/null
fi

if [ -f "$img" ] && command -v kitten >/dev/null 2>&1 && [ -n "$KITTY_WINDOW_ID" ]; then
    kitten icat --clear --transfer-mode=memory --unicode-placeholder --stdin=no \
        --place="${FZF_PREVIEW_COLUMNS:-80}x${FZF_PREVIEW_LINES:-25}@0x0" "$img"
elif [ -f "$img" ] && command -v chafa >/dev/null 2>&1; then
    chafa -s "${FZF_PREVIEW_COLUMNS:-80}x${FZF_PREVIEW_LINES:-25}" "$img"
else
    pdftotext "$file" - 2>/dev/null | head -200
fi
