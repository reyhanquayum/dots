-- playlist-remaining.lua
-- Press Shift+P to show total playlist remaining time
-- Press Shift+O to toggle persistent display

local utils = require("mp.utils")

local durations = {}
local scanned = false
local persistent = false
local timer = nil

local function format_time(s)
    if not s or s < 0 then return "?:??:??" end
    s = math.floor(s)
    local h = math.floor(s / 3600)
    local m = math.floor((s % 3600) / 60)
    local sec = s % 60
    if h > 0 then
        return string.format("%d:%02d:%02d", h, m, sec)
    else
        return string.format("%d:%02d", m, sec)
    end
end

local function scan_durations()
    if scanned then return end
    local count = mp.get_property_number("playlist-count", 0)
    for i = 0, count - 1 do
        local path = mp.get_property(string.format("playlist/%d/filename", i))
        if path and not durations[path] then
            local r = utils.subprocess({
                args = {"ffprobe", "-v", "quiet", "-show_entries",
                        "format=duration", "-of", "csv=p=0", path},
                cancellable = false,
            })
            if r.status == 0 and r.stdout then
                durations[path] = tonumber(r.stdout:match("([%d%.]+)"))
            end
        end
    end
    scanned = true
end

local function get_remaining()
    local pos = mp.get_property_number("playlist-pos", 0)
    local count = mp.get_property_number("playlist-count", 0)
    local speed = mp.get_property_number("speed", 1)
    local cur_remaining = mp.get_property_number("playtime-remaining") or 0
    local cur_remaining_raw = mp.get_property_number("time-remaining") or 0

    local total = cur_remaining
    local total_raw = cur_remaining_raw
    for i = pos + 1, count - 1 do
        local path = mp.get_property(string.format("playlist/%d/filename", i))
        if path and durations[path] then
            total = total + durations[path] / speed
            total_raw = total_raw + durations[path]
        end
    end
    return total, total_raw, speed, pos + 1, count
end

local function format_remaining(label, remaining, remaining_raw, speed, pos, count)
    local msg = string.format("[%d/%d]  %s: %s", pos, count, label, format_time(remaining))
    if speed ~= 1 then
        msg = msg .. string.format(" (%s at 1x)", format_time(remaining_raw))
    end
    return msg
end

local function show_remaining()
    scan_durations()
    local remaining, remaining_raw, speed, pos, count = get_remaining()
    mp.osd_message(format_remaining("Playlist remaining", remaining, remaining_raw, speed, pos, count), 5)
end

local function update_persistent()
    if not persistent then return end
    local remaining, remaining_raw, speed, pos, count = get_remaining()
    mp.osd_message(format_remaining("Remaining", remaining, remaining_raw, speed, pos, count), 2)
end

local function toggle_persistent()
    scan_durations()
    persistent = not persistent
    if persistent then
        timer = mp.add_periodic_timer(1, update_persistent)
        update_persistent()
    else
        if timer then timer:kill() timer = nil end
        mp.osd_message("")
    end
end

mp.register_event("file-loaded", function() scan_durations() end)

mp.add_key_binding("P", "playlist-remaining", show_remaining)
mp.add_key_binding("O", "playlist-remaining-toggle", toggle_persistent)
