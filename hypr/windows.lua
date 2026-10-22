-- Single-purpose web apps always land on their workspace, wherever they were
-- launched from. No rules for Chrome, Ghostty or Nautilus, or every link,
-- terminal and folder would follow.
o.window("^chrome-github\\.com__.*$", { workspace = "3 silent" })
-- Claude is a Chrome-installed PWA, so its class is the app's extension id.
o.window("^chrome-fmpnliohjhemenmnlpbfagaolkdacoja-Default$", { workspace = "8 silent" })

-- 1Password opens its SSH approval prompt beside the vault window rather than
-- where you are working, which with the vault in its pop-up means hidden.
-- Unanswered, the request times out and ssh reports it as
-- "sign_and_send_pubkey: agent refused operation", which reads like a broken
-- key rather than a dialog sitting unseen.
--
-- Title can't tell the two windows apart: the vault window's initial_title is
-- also "1Password" and it only renames itself after this fires. Window count
-- can. The prompt is the one that anchors to an already-open vault window, so
-- when it is the only 1Password window, leaving it alone is correct.
local op_class = "com.onepassword.OnePassword"

hl.on("window.open", function(win)
  if win.class ~= op_class then
    return
  end

  local others = 0
  for _, other in ipairs(hl.get_windows()) do
    if other.class == op_class and other.address ~= win.address then
      others = others + 1
    end
  end
  if others == 0 then
    return
  end

  local target = hl.get_active_workspace()
  if win.workspace.id == target.id then
    return
  end

  local selector = "address:" .. win.address
  hl.dispatch(hl.dsp.window.move({ workspace = tostring(target.id), window = selector }))
  hl.dispatch(hl.dsp.focus({ window = selector }))
end)
