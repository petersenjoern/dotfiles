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
rebind("SUPER + SHIFT + N", "Editor", "omarchy-launch-editor")
rebind("SUPER + SHIFT + T", "Activity", { tui = "btop" })
rebind("SUPER + SHIFT + D", "Docker", { tui = "lazydocker" })
rebind("SUPER + SHIFT + G", "Signal", { launch = "signal-desktop", focus = "^signal$" })
-- Class is org.telegram.desktop; omarchy-launch-or-focus matches \bpattern\b
-- case-insensitively against class or title, so the bare word is enough.
rebind("SUPER + SHIFT + ALT + G", "Telegram", { launch = "Telegram", focus = "telegram" })
rebind("SUPER + SHIFT + SLASH", "Passwords", { launch = "1password" })

-- Web apps
rebind("SUPER + SHIFT + A", "Claude", { webapp = "https://claude.ai" })
rebind("SUPER + SHIFT + ALT + A", "ChatGPT", { webapp = "https://chatgpt.com" })
rebind("SUPER + SHIFT + X", "X", { webapp = "https://x.com/" })
rebind("SUPER + SHIFT + ALT + X", "X Post", { webapp = "https://x.com/compose/post" })

-- Apps I don't use. Dropping our rebind() is not enough -- every key below is
-- also an Omarchy default (bindings/applications.lua), so the default returns
-- the moment our line goes away.
for _, keys in ipairs({
  "SUPER + SHIFT + C", -- Calendar (HEY)
  "SUPER + SHIFT + E", -- Email (HEY)
  "SUPER + SHIFT + ALT + E", -- New email (HEY)
  "SUPER + SHIFT + M", -- Music (Spotify)
  "SUPER + SHIFT + P", -- Google Photos
  "SUPER + SHIFT + CTRL + G", -- Messenger (Google)
  "SUPER + SHIFT + O", -- Obsidian
  "SUPER + SHIFT + W", -- Writing (Omawrite)
}) do
  hl.unbind(keys)
end

-- Keep workspace switching on CTRL+1..9 only (SUPER+1..0 freed up).
-- SUPER+SHIFT+code:* (move window to workspace) defaults are left untouched.
for ws = 1, 10 do
  hl.unbind("SUPER + code:" .. (ws + 9))
end
for ws = 1, 9 do
  o.bind("CTRL + code:" .. (ws + 9), "Switch to workspace " .. ws, hl.dsp.focus({ workspace = tostring(ws) }))
end
