-- playlist-resume.lua
-- Saves playlist position on quit so playall can resume later.
-- Activated by passing --script-opts=playlist_resume=yes

local state_dir = (os.getenv("XDG_STATE_HOME") or (os.getenv("HOME") .. "/.local/state"))
    .. "/mpv-playall"

local function get_state_file()
    local cwd = mp.get_property("working-directory")
    if not cwd then return nil end
    local encoded = cwd:gsub("/", "%%")
    return state_dir .. "/" .. encoded
end

-- Track time-pos continuously since it's unavailable during shutdown
local last_time_pos = 0
mp.observe_property("time-pos", "number", function(_, val)
    if val then last_time_pos = val end
end)

mp.register_event("shutdown", function()
    if mp.get_opt("playlist_resume") ~= "yes" then return end

    local count = mp.get_property_number("playlist-count", 0)
    if count <= 1 then return end

    local pos = mp.get_property_number("playlist-pos", -1)
    local state_file = get_state_file()
    if not state_file then return end

    if pos < 0 then
        -- playlist-pos is -1 → playlist finished naturally, clear state
        os.remove(state_file)
    else
        local speed = mp.get_property_number("speed", 1)
        os.execute("mkdir -p '" .. state_dir .. "'")
        local fh = io.open(state_file, "w")
        if fh then
            fh:write(tostring(pos) .. "\n")
            fh:write(tostring(speed) .. "\n")
            fh:write(tostring(last_time_pos) .. "\n")
            fh:close()
        end
    end
end)

-- Seek to saved timestamp on resume (passed via script-opts from pall)
local resumed = false
mp.register_event("file-loaded", function()
    if resumed then return end
    local time = tonumber(mp.get_opt("playlist_resume_time"))
    if time and time > 0 then
        resumed = true
        mp.commandv("seek", tostring(time), "absolute+exact")
    end
end)
