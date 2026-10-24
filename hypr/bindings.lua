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
rebind("SUPER + SHIFT + D", "Docker", { tui = "lazydocker" })
-- Class is org.telegram.desktop; omarchy-launch-or-focus matches \bpattern\b
-- case-insensitively against class or title, so the bare word is enough.
rebind("SUPER + SHIFT + ALT + G", "Telegram", { launch = "Telegram", focus = "telegram" })
rebind("SUPER + SHIFT + W", "Workspace layout", "$HOME/.local/scripts/workspace-layout")
rebind("SUPER + SHIFT + P", "Tmux project", "$HOME/.local/scripts/tmux-project")
rebind("SUPER + SHIFT + M", "Next waiting Claude", "$HOME/.local/scripts/claude-next")

-- Pop-ups: each app lives in its own special workspace
rebind("SUPER + SHIFT + SLASH", "Passwords", "$HOME/.local/scripts/popup 1password '^com.onepassword.OnePassword$' 'uwsm-app -- 1password'")
rebind("SUPER + SHIFT + L", "Discord", "$HOME/.local/scripts/popup discord '^chrome-discord.com__' 'omarchy-launch-webapp https://discord.com/channels/@me'")
-- Straight to the client: app.slack.com/'s Launch button opens a tab in the main browser
rebind("SUPER + SHIFT + S", "Slack", "$HOME/.local/scripts/popup slack '^chrome-app.slack.com__' 'omarchy-launch-webapp https://app.slack.com/client/T08N66L1N84'")
rebind("SUPER + SHIFT + K", "Notion", "$HOME/.local/scripts/popup notion '^chrome-app.notion.com__' 'omarchy-launch-webapp \"https://app.notion.com/p/2b686ca41a59802fa493f3f7874d0c37?v=3c986ca41a598012a3a8000c4573cbc8\"'")
rebind("SUPER + SHIFT + C", "Calendar", "$HOME/.local/scripts/popup calendar '^chrome-calendar.google.com__' 'omarchy-launch-webapp https://calendar.google.com'")
rebind("SUPER + SHIFT + E", "Email", "$HOME/.local/scripts/popup email '^chrome-mail.google.com__' 'omarchy-launch-webapp https://mail.google.com'")
rebind("SUPER + SHIFT + T", "Activity", "$HOME/.local/scripts/popup activity '^org.omarchy.btop$' 'omarchy-launch-tui btop'")
rebind("SUPER + SHIFT + G", "Signal", "$HOME/.local/scripts/popup signal '^signal$' 'uwsm-app -- signal-desktop'")

-- Web apps
rebind("SUPER + SHIFT + A", "Claude", { webapp = "https://claude.ai" })
rebind("SUPER + SHIFT + ALT + A", "ChatGPT", { webapp = "https://chatgpt.com" })
rebind("SUPER + SHIFT + X", "X", { webapp = "https://x.com/" })
rebind("SUPER + SHIFT + ALT + X", "X Post", { webapp = "https://x.com/compose/post" })

-- Apps I don't use. Dropping our rebind() is not enough -- every key below is
-- also an Omarchy default (bindings/applications.lua), so the default returns
-- the moment our line goes away.
for _, keys in ipairs({
  "SUPER + SHIFT + ALT + E", -- New email (HEY)
  "SUPER + SHIFT + CTRL + G", -- Messenger (Google)
  "SUPER + SHIFT + O", -- Obsidian
}) do
  hl.unbind(keys)
end

-- Second scratchpad, mirroring Omarchy's SUPER+S / SUPER+ALT+S pair
o.bind("SUPER + D", "Toggle scratchpad 2", hl.dsp.workspace.toggle_special("scratchpad2"))
o.bind("SUPER + ALT + D", "Move window to scratchpad 2", hl.dsp.window.move({ workspace = "special:scratchpad2", follow = false }))

-- Keep workspace switching on CTRL+1..9 only (SUPER+1..0 freed up).
-- SUPER+SHIFT+code:* (move window to workspace) defaults are left untouched.
for ws = 1, 10 do
  hl.unbind("SUPER + code:" .. (ws + 9))
end
for ws = 1, 9 do
  o.bind("CTRL + code:" .. (ws + 9), "Switch to workspace " .. ws, hl.dsp.focus({ workspace = tostring(ws) }))
end
