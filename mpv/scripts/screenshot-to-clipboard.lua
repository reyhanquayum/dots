-- screenshot-to-clipboard.lua
-- Takes a screenshot and copies it to the Wayland clipboard via wl-copy,
-- without leaving a file on disk.
--
-- NOTE on wl-copy behavior:
--   wl-copy reads all input into memory, then fork()s a daemon child to serve
--   clipboard paste requests. The parent exits, but the child stays alive until
--   another program replaces the clipboard.
--
--   If you run wl-copy synchronously (e.g. utils.subprocess), the shell waits
--   for all foreground children to exit — including the daemon. This blocks the
--   caller (mpv) until something else copies to the clipboard.
--
--   Fix: background wl-copy with '&' so sh doesn't wait for the daemon, and
--   use mp.command_native_async so mpv doesn't block either.
--
--   The temp file can be rm'd immediately after backgrounding because wl-copy
--   still holds an open fd. On unix, unlink() removes the directory entry but
--   the inode/data persists until all open file descriptors are closed.

local utils = require("mp.utils")

local function screenshot_to_clipboard(mode)
    local tmp = "/tmp/mpv-screenshot-" .. os.time() .. ".png"

    mp.commandv("screenshot-to-file", tmp, mode)

    -- Background wl-copy so the shell exits immediately, and run async
    -- so mpv doesn't block. wl-copy keeps the fd open after rm (unix semantics).
    mp.command_native_async({
        name = "subprocess",
        args = {"sh", "-c", "wl-copy --type image/png < '" .. tmp .. "' & rm -f '" .. tmp .. "'"},
        playback_only = false,
    }, function(success, result)
        if success and result and result.status == 0 then
            mp.osd_message("Screenshot copied to clipboard", 2)
        else
            mp.osd_message("Failed to copy screenshot", 2)
        end
    end)
end

mp.add_key_binding("Ctrl+s", "screenshot-to-clipboard", function()
    screenshot_to_clipboard("video")
end)
mp.add_key_binding("Ctrl+S", "screenshot-to-clipboard-subs", function()
    screenshot_to_clipboard("subtitles")
end)
