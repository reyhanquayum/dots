# mpv Keybindings Cheatsheet

## Playback

| Key | Action |
|-----|--------|
| `Space` | Pause / play |
| `<` / `>` | Previous / next playlist entry |
| `[` / `]` | Decrease / increase speed by 10% |
| `{` / `}` | Halve / double speed |
| `Backspace` | Reset speed to 1x |
| `l` | Set / clear A-B loop points |
| `L` | Toggle loop current file |
| `q` | Quit |
| `Q` | Quit and save position (watch later) |

## Seeking

| Key | Action |
|-----|--------|
| `Left` / `Right` | Seek -/+ 5 seconds |
| `Up` / `Down` | Seek -/+ 60 seconds |

## Audio & Video

| Key | Action |
|-----|--------|
| `9` / `0` | Volume down / up |
| `m` | Mute |
| `f` | Toggle fullscreen |
| `#` | Cycle audio tracks |
| `i` / `I` | Show stats (momentary / toggle) |
| `` ` `` | Open console |

## Subtitles

| Key | Action |
|-----|--------|
| `v` | Toggle subtitle visibility |
| `j` / `J` | Cycle forward / backward through subtitle tracks |
| `z` | Shift subtitles earlier (-0.1s) |
| `Z` or `x` | Shift subtitles later (+0.1s) |
| `Ctrl+Shift+Left` | Shift subtitles earlier (larger step) |
| `Ctrl+Shift+Right` | Shift subtitles later (larger step) |
| `Ctrl+Left` | Seek to previous subtitle |
| `Ctrl+Right` | Seek to next subtitle |
| `` ` `` then `set sub-delay 0` | Reset subtitle delay to zero |

---

## Playlist Manager (mpv-playlistmanager)

Open with `Shift+Enter`. All navigation keys below are **dynamic** (only active while the playlist overlay is visible).

| Key | Action |
|-----|--------|
| `Shift+Enter` | Toggle playlist overlay |
| `Up` / `Down` | Move cursor up / down |
| `PgUp` / `PgDn` | Page up / down |
| `Home` / `End` | Jump to first / last entry |
| `Right` or `Left` | Select / deselect file (for reordering) |
| `Enter` | Play highlighted file |
| `Backspace` | Remove file from playlist |
| `Esc` | Close playlist |

## Playlist Remaining (playlist-remaining.lua)

| Key | Action |
|-----|--------|
| `P` | Show total playlist remaining time |
| `O` | Toggle persistent remaining-time display |

## Playlist Go-To (playlist-goto.lua)

| Key | Action |
|-----|--------|
| `Ctrl+j` | Prompt to jump to playlist entry by number |

## Subtitle Search (sub-search.lua)

Vim-style search across all subtitle files in the playlist.

| Key | Action |
|-----|--------|
| `/` | Open subtitle search prompt |
| `n` | Next match (wraps) |
| `N` | Previous match (wraps) |
| `Ctrl+g` | Jump to match by number |
| `Ctrl+o` | Jump back to where search started |

## Screenshot to Clipboard (screenshot-to-clipboard.lua)

| Key | Action |
|-----|--------|
| `Ctrl+s` | Screenshot (video only) to Wayland clipboard |
| `Ctrl+S` | Screenshot (with subtitles) to Wayland clipboard |

## Playlist Resume (playlist-resume.lua)

No keybindings. Automatically saves/restores playlist position when using `pall`.
