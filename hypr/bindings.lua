-- Personal keybindings, ported 1:1 from the pre-Quattro bindings.conf.
-- Unbind first: Omarchy 4 defaults claim most of these keys, and duplicate
-- binds on one key all fire (an exec would launch twice).
-- View current bindings: omarchy menu keybindings --print
local function rebind(keys, desc, dispatcher)
  hl.unbind(keys)
  o.bind(keys, desc, dispatcher)
end

-- Application bindings
rebind("SUPER + RETURN", "Terminal", "omarchy-launch-terminal") -- == uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)"
rebind("SUPER + SHIFT + RETURN", "Browser", "omarchy-launch-browser")
rebind("SUPER + SHIFT + F", "File manager", { launch = "nautilus --new-window" })
rebind("SUPER + ALT + SHIFT + F", "File manager (cwd)", 'uwsm-app -- nautilus --new-window "$(omarchy-cmd-terminal-cwd)"')
rebind("SUPER + SHIFT + B", "Browser", "omarchy-launch-browser")
rebind("SUPER + SHIFT + ALT + B", "Browser (private)", "omarchy-launch-browser --private")
-- rebind("SUPER + SHIFT + M", "Music", { launch = "spotify", focus = "spotify" })
rebind("SUPER + SHIFT + N", "Editor", "omarchy-launch-editor")
rebind("SUPER + SHIFT + T", "Activity", { tui = "btop" })
rebind("SUPER + SHIFT + D", "Docker", { tui = "lazydocker" })
rebind("SUPER + SHIFT + G", "Signal", { launch = "signal-desktop", focus = "^signal$" })
rebind("SUPER + SHIFT + O", "Obsidian", { launch = "obsidian -disable-gpu --enable-wayland-ime", focus = "^obsidian$" })
rebind("SUPER + SHIFT + SLASH", "Passwords", { launch = "1password" })

-- Web apps
-- rebind("SUPER + SHIFT + A", "ChatGPT", { webapp = "https://chatgpt.com" })
-- rebind("SUPER + SHIFT + ALT + A", "Grok", { webapp = "https://grok.com" })
rebind("SUPER + SHIFT + C", "Calendar", { webapp = "https://app.hey.com/calendar/weeks/" })
rebind("SUPER + SHIFT + E", "Email", { webapp = "https://app.hey.com" })
-- rebind("SUPER + SHIFT + Y", "YouTube", { webapp = "https://youtube.com/" })
rebind("SUPER + SHIFT + ALT + G", "WhatsApp", { webapp = "https://web.whatsapp.com/", focus = true })
rebind("SUPER + SHIFT + CTRL + G", "Google Messages", { webapp = "https://messages.google.com/web/conversations", focus = true })
rebind("SUPER + SHIFT + P", "Google Photos", { webapp = "https://photos.google.com/", focus = true })
rebind("SUPER + SHIFT + X", "X", { webapp = "https://x.com/" })
rebind("SUPER + SHIFT + ALT + X", "X Post", { webapp = "https://x.com/compose/post" })

-- Keep workspace switching on CTRL+1..9 only (SUPER+1..0 freed up).
-- SUPER+SHIFT+code:* (move window to workspace) defaults are left untouched.
for ws = 1, 10 do
  hl.unbind("SUPER + code:" .. (ws + 9))
end
for ws = 1, 9 do
  o.bind("CTRL + code:" .. (ws + 9), "Switch to workspace " .. ws, hl.dsp.focus({ workspace = tostring(ws) }))
end
