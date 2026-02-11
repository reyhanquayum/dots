-- playlist-goto.lua — Jump to a specific playlist entry by number
--
-- Keybinding:
--   Ctrl+j  enter goto mode
--
-- In goto mode, type digits to build a number, then:
--   Enter   jump to that playlist entry
--   Esc     cancel
--   BS      delete last digit
--
-- Uses print-text for terminal compatibility (audio-only mode).
-- Falls back to osd_message when a video window is available.

local active = false
local digits = ""

local function has_window()
    local w, h = mp.get_osd_size()
    return w > 0 and h > 0
end

local function show(text, duration)
    if has_window() then
        mp.osd_message(text, duration or 30)
    else
        mp.commandv("print-text", text)
    end
end

local function clear_osd()
    if has_window() then mp.osd_message("") end
end

local function show_prompt()
    local count = mp.get_property_number("playlist-count", 0)
    local display = digits == "" and "_" or digits
    show(string.format("Go to [1-%d]: %s", count, display))
end

local function cleanup()
    active = false
    digits = ""
    for i = 0, 9 do
        mp.remove_key_binding("goto-digit-" .. i)
    end
    mp.remove_key_binding("goto-confirm")
    mp.remove_key_binding("goto-cancel")
    mp.remove_key_binding("goto-backspace")
    clear_osd()
end

local function confirm()
    local count = mp.get_property_number("playlist-count", 0)
    local num = tonumber(digits)
    cleanup()
    if not num or num < 1 or num > count or num ~= math.floor(num) then
        show(string.format("Invalid entry number (1-%d)", count), 2)
        return
    end
    mp.set_property_number("playlist-pos", num - 1)
    show(string.format("Jumped to %d/%d", num, count), 2)
end

local function cancel()
    cleanup()
    show("Cancelled", 1)
end

local function backspace()
    if #digits > 0 then
        digits = digits:sub(1, -2)
    end
    show_prompt()
end

local function add_digit(d)
    return function()
        digits = digits .. d
        show_prompt()
    end
end

local function playlist_goto()
    local count = mp.get_property_number("playlist-count", 0)
    if count == 0 then
        show("No playlist loaded", 2)
        return
    end
    if active then
        cleanup()
        return
    end
    active = true
    digits = ""
    for i = 0, 9 do
        mp.add_forced_key_binding(tostring(i), "goto-digit-" .. i, add_digit(tostring(i)), { repeatable = true })
    end
    mp.add_forced_key_binding("ENTER", "goto-confirm", confirm)
    mp.add_forced_key_binding("ESC", "goto-cancel", cancel)
    mp.add_forced_key_binding("BS", "goto-backspace", backspace, { repeatable = true })
    show_prompt()
end

mp.add_key_binding("Ctrl+j", "playlist-goto", playlist_goto)
