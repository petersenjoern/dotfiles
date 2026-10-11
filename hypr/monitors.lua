-- List monitors and supported modes: hyprctl monitors all

-- Optimized for retina-class 2x displays.
hl.env("GDK_SCALE", "2")

-- Matched by EDID because the connector name varies by port (DP-3, DP-4).
local lenovo = "desc:Lenovo Group Limited N27p"

hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = "auto" }) -- framework laptop
-- auto picks 1.5 (soft text) and 2 is too large; 5/3 is the compromise.
hl.monitor({ output = lenovo, mode = "preferred", position = "auto", scale = 1.666667 }) -- Lenovo work
-- hl.monitor({ output = "DP-4", mode = "preferred", position = "auto", scale = "auto" }) -- dell

-- Pin workspaces to the external monitor; Hyprland falls back to the
-- active monitor automatically when the Lenovo is disconnected.
for ws = 1, 9 do
  hl.workspace_rule({ workspace = tostring(ws), monitor = lenovo })
end
