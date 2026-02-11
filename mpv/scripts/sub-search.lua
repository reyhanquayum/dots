-- sub-search.lua — Search subtitles across an mpv playlist
--
-- Keybindings:
--   /       open search prompt
--   n       next match (wraps)
--   N       previous match (wraps)
--   Ctrl+g  go to match number (type a number to jump directly)
--   Ctrl+o  jump back to where search was initiated

local utils = require("mp.utils")
local input -- lazy-loaded mp.input

-- Script options (--script-opts=subtitle_search_dir=/path)
local opts = {
    subtitle_search_dir = "",
}
require("mp.options").read_options(opts, "subtitle_search")

----------------------------------------------------------------------------
-- SRT cache: path -> list of {start=seconds, text=string}
----------------------------------------------------------------------------
local srt_cache = {}

local function parse_srt(path)
    if srt_cache[path] then return srt_cache[path] end

    local fh = io.open(path, "r")
    if not fh then return nil end
    local raw = fh:read("*all")
    fh:close()

    -- Strip BOM
    if raw:sub(1, 3) == "\239\187\191" then
        raw = raw:sub(4)
    end
    -- Normalise line endings
    raw = raw:gsub("\r\n", "\n"):gsub("\r", "\n")

    local subs = {}
    -- State machine: expect_index -> expect_time -> collect_text
    local state = "expect_index"
    local cur_start = nil
    local cur_lines = {}

    local function flush()
        if cur_start and #cur_lines > 0 then
            local text = table.concat(cur_lines, " ")
            -- Strip HTML tags and ASS overrides
            text = text:gsub("<[^>]+>", "")
            text = text:gsub("{[^}]+}", "")
            text = text:gsub("^%s+", ""):gsub("%s+$", "")
            if #text > 0 then
                subs[#subs + 1] = { start = cur_start, text = text }
            end
        end
        cur_start = nil
        cur_lines = {}
    end

    for line in (raw .. "\n"):gmatch("([^\n]*)\n") do
        line = line:gsub("%s+$", "") -- trim trailing whitespace

        if state == "expect_index" then
            if line:match("^%d+$") then
                state = "expect_time"
            end
            -- skip blank lines between entries

        elseif state == "expect_time" then
            local h1, m1, s1, ms1, h2, m2, s2, ms2 = line:match(
                "(%d+):(%d+):(%d+)[,.](%d+)%s*%-%->%s*(%d+):(%d+):(%d+)[,.](%d+)"
            )
            if h1 then
                cur_start = tonumber(h1) * 3600 + tonumber(m1) * 60
                    + tonumber(s1) + tonumber(ms1) / 1000
                cur_lines = {}
                state = "collect_text"
            else
                -- Malformed entry, reset
                state = "expect_index"
            end

        elseif state == "collect_text" then
            if line == "" then
                flush()
                state = "expect_index"
            else
                cur_lines[#cur_lines + 1] = line
            end
        end
    end
    flush() -- handle file not ending with blank line

    srt_cache[path] = subs
    return subs
end

----------------------------------------------------------------------------
-- SRT directory discovery (mirrors pall's logic)
----------------------------------------------------------------------------
local function find_srt_dir()
    -- User override
    if opts.subtitle_search_dir ~= "" then
        return opts.subtitle_search_dir
    end

    local cwd = mp.get_property("working-directory")
    if not cwd then return nil end

    -- 1. Current directory has .srt files
    local ls = utils.readdir(cwd, "files")
    if ls then
        for _, f in ipairs(ls) do
            if f:match("%.srt$") then
                return cwd
            end
        end
    end

    -- 2. <cwd>_subtitles sibling directory
    local sub_dir = cwd .. "_subtitles"
    local info = utils.file_info(sub_dir)
    if info and info.is_dir then
        return sub_dir
    end

    -- 3. Sibling directory with spaces instead of underscores
    local parent = cwd:match("^(.+)/[^/]+$")
    local base = cwd:match("([^/]+)$")
    if parent and base then
        local space_name = base:gsub("_", " ")
        if space_name ~= base then
            local space_dir = parent .. "/" .. space_name
            info = utils.file_info(space_dir)
            if info and info.is_dir then
                return space_dir
            end
        end
    end

    return nil
end

----------------------------------------------------------------------------
-- Collect sorted SRT file list from the subtitle directory
----------------------------------------------------------------------------
local function get_sorted_srts(srt_dir)
    local files = utils.readdir(srt_dir, "files")
    if not files then return {} end
    local srts = {}
    for _, f in ipairs(files) do
        if f:match("%.srt$") then
            srts[#srts + 1] = f
        end
    end
    table.sort(srts)
    return srts
end

----------------------------------------------------------------------------
-- Build playlist-index -> srt-path mapping (3-tier matching from pall)
----------------------------------------------------------------------------
local function strip_ext(name)
    return name:match("^(.+)%.[^.]+$") or name
end

local function leading_digits(name)
    return name:match("^(%d+)")
end

local function build_srt_map()
    local srt_dir = find_srt_dir()
    if not srt_dir then return nil end

    local srt_files = get_sorted_srts(srt_dir)
    if #srt_files == 0 then return nil end

    -- Build lookup tables for fast matching
    local srt_by_base = {} -- stripped basename -> full path
    local srt_by_num = {}  -- leading number -> full path (first match wins)
    for _, f in ipairs(srt_files) do
        local full = srt_dir .. "/" .. f
        local base = strip_ext(f)
        srt_by_base[base] = full
        local num = leading_digits(f)
        if num and not srt_by_num[num] then
            srt_by_num[num] = full
        end
    end

    local count = mp.get_property_number("playlist-count", 0)
    local mapping = {} -- 0-based playlist index -> srt path

    for i = 0, count - 1 do
        local pfile = mp.get_property("playlist/" .. i .. "/filename")
        if pfile then
            local pname = pfile:match("([^/]+)$") or pfile
            local pbase = strip_ext(pname)
            local pnum = leading_digits(pname)
            local matched = nil

            -- Tier 1: exact filename match
            if srt_by_base[pbase] then
                matched = srt_by_base[pbase]
            end

            -- Tier 2: number-prefix match
            if not matched and pnum and srt_by_num[pnum] then
                matched = srt_by_num[pnum]
            end

            -- Tier 3: positional fallback (1-based index into sorted srts)
            if not matched and (i + 1) <= #srt_files then
                matched = srt_dir .. "/" .. srt_files[i + 1]
            end

            if matched then
                mapping[i] = matched
            end
        end
    end

    return mapping
end

----------------------------------------------------------------------------
-- Search state
----------------------------------------------------------------------------
local matches = {}       -- sorted list of {playlist_pos, start, text, srt_path, playlist_name}
local match_idx = 0      -- current index into matches (1-based)
local last_query = ""
local mark = nil         -- {playlist_pos, time_pos} saved on search open
local jump_to_match      -- forward declaration

----------------------------------------------------------------------------
-- Perform the search across all playlist SRTs
----------------------------------------------------------------------------
local function do_search(query)
    matches = {}
    match_idx = 0
    last_query = query

    local srt_map = build_srt_map()
    if not srt_map then
        mp.osd_message("No subtitle files found", 3)
        return
    end

    local query_lower = query:lower()
    local count = mp.get_property_number("playlist-count", 0)

    -- Collect matches in playlist order, then timestamp order
    for pi = 0, count - 1 do
        local srt_path = srt_map[pi]
        if srt_path then
            local subs = parse_srt(srt_path)
            if subs then
                local pfile = mp.get_property("playlist/" .. pi .. "/filename")
                local pname = strip_ext((pfile or ""):match("([^/]+)$") or pfile or "")
                for _, sub in ipairs(subs) do
                    if sub.text:lower():find(query_lower, 1, true) then
                        matches[#matches + 1] = {
                            playlist_pos = pi,
                            start = sub.start,
                            text = sub.text,
                            playlist_name = pname,
                        }
                    end
                end
            end
        end
    end

    if #matches == 0 then
        mp.osd_message("No matches for: " .. query, 3)
        return
    end

    -- Find first match at or after current position
    local cur_pi = mp.get_property_number("playlist-pos", 0)
    local cur_time = mp.get_property_number("time-pos", 0) or 0

    match_idx = 1 -- default to first match
    for i, m in ipairs(matches) do
        if m.playlist_pos > cur_pi
            or (m.playlist_pos == cur_pi and m.start >= cur_time) then
            match_idx = i
            break
        end
    end

    jump_to_match()
end

----------------------------------------------------------------------------
-- Jump to current match
----------------------------------------------------------------------------
local function show_match_osd()
    if #matches == 0 or match_idx == 0 then return end
    local m = matches[match_idx]
    mp.osd_message(
        string.format("[%d/%d] (%s)\n%s", match_idx, #matches, m.playlist_name, m.text),
        5
    )
end

local function seek_and_show(time)
    mp.commandv("seek", tostring(time), "absolute+exact")
    show_match_osd()
end

jump_to_match = function()
    if #matches == 0 or match_idx == 0 then return end
    local m = matches[match_idx]
    local cur_pi = mp.get_property_number("playlist-pos", 0)

    if m.playlist_pos == cur_pi then
        seek_and_show(m.start)
    else
        -- Switch playlist entry, then seek after file loads
        local function on_load()
            mp.unregister_event(on_load)
            -- Small delay to let the demuxer initialise
            mp.add_timeout(0.1, function()
                seek_and_show(m.start)
            end)
        end
        mp.register_event("file-loaded", on_load)
        mp.set_property_number("playlist-pos", m.playlist_pos)
    end
end

----------------------------------------------------------------------------
-- Navigation: n / N
----------------------------------------------------------------------------
local function next_match()
    if #matches == 0 then
        mp.osd_message("No search results — press / to search", 2)
        return
    end
    match_idx = (match_idx % #matches) + 1
    jump_to_match()
end

local function prev_match()
    if #matches == 0 then
        mp.osd_message("No search results — press / to search", 2)
        return
    end
    match_idx = match_idx - 1
    if match_idx == 0 then match_idx = #matches end
    jump_to_match()
end

----------------------------------------------------------------------------
-- Go to match number: Ctrl+g
----------------------------------------------------------------------------
local function goto_match()
    if #matches == 0 then
        mp.osd_message("No search results — press / to search", 2)
        return
    end

    if not input then
        local ok, mod = pcall(require, "mp.input")
        if not ok then
            mp.osd_message("mp.input not available (requires mpv 0.36+)", 3)
            return
        end
        input = mod
    end

    input.get({
        prompt = string.format("Go to match [1-%d]: ", #matches),
        submit = function(text)
            input.terminate()
            if not text or text == "" then return end
            local num = tonumber(text)
            if not num or num < 1 or num > #matches or num ~= math.floor(num) then
                mp.osd_message(string.format("Invalid match number (1-%d)", #matches), 2)
                return
            end
            match_idx = num
            jump_to_match()
        end,
    })
end

----------------------------------------------------------------------------
-- Go-back: Ctrl+o
----------------------------------------------------------------------------
local function go_back()
    if not mark then
        mp.osd_message("No search mark set", 2)
        return
    end
    local cur_pi = mp.get_property_number("playlist-pos", 0)
    if mark.playlist_pos == cur_pi then
        mp.commandv("seek", tostring(mark.time_pos), "absolute+exact")
        mp.osd_message("Jumped back", 1.5)
    else
        local function on_load()
            mp.unregister_event(on_load)
            mp.add_timeout(0.1, function()
                mp.commandv("seek", tostring(mark.time_pos), "absolute+exact")
                mp.osd_message("Jumped back", 1.5)
            end)
        end
        mp.register_event("file-loaded", on_load)
        mp.set_property_number("playlist-pos", mark.playlist_pos)
    end
end

----------------------------------------------------------------------------
-- Open search prompt
----------------------------------------------------------------------------
local function open_search()
    -- Lazy-load mp.input
    if not input then
        local ok, mod = pcall(require, "mp.input")
        if not ok then
            mp.osd_message("mp.input not available (requires mpv 0.36+)", 3)
            return
        end
        input = mod
    end

    -- Save mark (one level deep, like vim)
    mark = {
        playlist_pos = mp.get_property_number("playlist-pos", 0),
        time_pos = mp.get_property_number("time-pos", 0) or 0,
    }

    input.get({
        prompt = "/",
        submit = function(text)
            input.terminate()
            if text and text ~= "" then
                do_search(text)
            end
        end,
    })
end

----------------------------------------------------------------------------
-- Keybindings
----------------------------------------------------------------------------
mp.add_key_binding("/", "sub-search-open", open_search)
mp.add_key_binding("n", "sub-search-next", next_match)
mp.add_key_binding("N", "sub-search-prev", prev_match)
mp.add_key_binding("Ctrl+g", "sub-search-goto", goto_match)
mp.add_key_binding("Ctrl+o", "sub-search-go-back", go_back)
