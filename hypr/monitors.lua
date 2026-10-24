-- List monitors and supported modes: hyprctl monitors all

-- Optimized for retina-class 2x displays.
hl.env("GDK_SCALE", "2")

-- Matched by EDID because the connector name varies by port (DP-3, DP-4).
local lenovo = "desc:Lenovo Group Limited N27p"

hl.monitor({ output = "eDP-1", mode = "preferred", position = "auto", scale = "auto" }) -- framework laptop
-- auto picks 1.5 (soft text) and 2 is too large; 5/3 is the compromise.
hl.monitor({ output = lenovo, mode = "preferred", position = "auto", scale = 1.666667 }) -- Lenovo work
-- hl.monitor({ output = "DP-4", mode = "preferred", position = "auto", scale = "auto" }) -- dell

-- Opening an empty workspace launches its app (ws 1 is created empty at login).
local apps = {
  ["1"] = o.launch("google-chrome-stable"),
  ["2"] = o.launch("ghostty"),
}

-- Pin workspaces to the external monitor; Hyprland falls back to the
-- active monitor automatically when the Lenovo is disconnected.
for ws = 1, 9 do
  local name = tostring(ws)
  hl.workspace_rule({ workspace = name, monitor = lenovo, on_created_empty = apps[name] })
end

hl.on("hyprland.start", function()
  hl.exec_cmd(apps["2"], { workspace = "2 silent" })
end)

-- The rule above only places newly created workspaces, so pull existing
-- ones over when the Lenovo is plugged in.
hl.on("monitor.added", function()
  for _, m in ipairs(hl.get_monitors()) do
    if m.description:find("Lenovo Group Limited N27p", 1, true) then
      for _, w in ipairs(hl.get_workspaces()) do
        if not w.special and w.id >= 1 and w.id <= 9 then
          hl.dispatch(hl.dsp.workspace.move({ workspace = w.name, monitor = lenovo }))
        end
      end
    end
  end
end)
