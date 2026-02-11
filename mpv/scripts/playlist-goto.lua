-- playlist-goto.lua — Jump to a specific playlist entry by number
--
-- Keybinding:
--   Ctrl+j  open prompt to type a playlist number (1-based)

local input

local function playlist_goto()
    if not input then
        local ok, mod = pcall(require, "mp.input")
        if not ok then
            mp.osd_message("mp.input not available (requires mpv 0.36+)", 3)
            return
        end
        input = mod
    end

    local count = mp.get_property_number("playlist-count", 0)
    if count == 0 then
        mp.osd_message("No playlist loaded", 2)
        return
    end

    input.get({
        prompt = string.format("Go to video [1-%d]: ", count),
        submit = function(text)
            input.terminate()
            if not text or text == "" then return end
            local num = tonumber(text)
            if not num or num < 1 or num > count or num ~= math.floor(num) then
                mp.osd_message(string.format("Invalid video number (1-%d)", count), 2)
                return
            end
            mp.set_property_number("playlist-pos", num - 1)
            mp.osd_message(string.format("Jumped to video %d/%d", num, count), 2)
        end,
    })
end

mp.add_key_binding("Ctrl+j", "playlist-goto", playlist_goto)
