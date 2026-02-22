local ARABIC_DEFAULT = 52
local DEFAULT = 55

local font_offset = 0

local function apply_font_size(base)
    mp.set_property("sub-font-size", tostring(base + font_offset))
end

local function update_font()
    local path = mp.get_property("current-tracks/sub/external-filename") or ""
    local lang = mp.get_property("current-tracks/sub/lang") or ""
    if path:find("%.ar%.[^.]+$") or lang == "ar" or lang == "ara" then
        mp.set_property("sub-font", "Noto Naskh Arabic")
        apply_font_size(ARABIC_DEFAULT)
        mp.set_property("sub-border-size", "2")
    else
        mp.set_property("sub-font", "sans-serif")
        apply_font_size(DEFAULT)
        mp.set_property("sub-border-size", "3")
    end
end

mp.register_script_message("sub-font-adjust", function(delta_str)
    local delta = tonumber(delta_str) or 0
    font_offset = font_offset + delta
    mp.set_property("user-data/sub-font-offset", tostring(font_offset))
    mp.set_property("sub-font-size", tostring(mp.get_property_number("sub-font-size") + delta))
end)

-- Initialize offset from script-opt (passed by pall on resume)
font_offset = tonumber(mp.get_opt("sub_font_offset")) or 0
mp.set_property("user-data/sub-font-offset", tostring(font_offset))

mp.observe_property("current-tracks/sub/lang", "string", update_font)
mp.observe_property("current-tracks/sub/external-filename", "string", update_font)
