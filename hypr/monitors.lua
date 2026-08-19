-- List monitors and supported modes: hyprctl monitors all

-- Optimized for retina-class 2x displays.
hl.env("GDK_SCALE", "2")

hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = "auto" }) -- framework laptop
hl.monitor({ output = "DP-3", mode = "preferred", position = "auto", scale = "auto" }) -- Lenovo work
-- hl.monitor({ output = "DP-4", mode = "preferred", position = "auto", scale = "auto" }) -- dell

-- Pin workspaces to the external monitor; Hyprland falls back to the
-- active monitor automatically when DP-3 is disconnected.
for ws = 1, 9 do
  hl.workspace_rule({ workspace = tostring(ws), monitor = "DP-3" })
end
