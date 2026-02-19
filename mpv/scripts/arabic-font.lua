local function update_font()
    local path = mp.get_property("current-tracks/sub/external-filename") or ""
    local lang = mp.get_property("current-tracks/sub/lang") or ""
    if path:find("%.ar%.[^.]+$") or lang == "ar" or lang == "ara" then
        mp.set_property("sub-font", "Noto Naskh Arabic")
        mp.set_property("sub-font-size", "52")
        mp.set_property("sub-border-size", "2")
    else
        mp.set_property("sub-font", "sans-serif")
        mp.set_property("sub-font-size", "55")
        mp.set_property("sub-border-size", "3")
    end
end

mp.observe_property("current-tracks/sub/lang", "string", update_font)
mp.observe_property("current-tracks/sub/external-filename", "string", update_font)
