# Mouseless on Omarchy — compatibility status

Tracking whether [mouseless.click](https://mouseless.click) is usable on this
machine (Arch / Omarchy / Hyprland). Not installed yet as of the last review.

**Last reviewed: 2026-09-03** against Mouseless **v1.0.0** (released 2026-07-07,
still the newest release).

Companion to `mouseless-input-access.sh` in this directory, which handles the
uinput/udev side.

---

## Verdict

Runnable, but not on defaults. Two things must be set before the first launch:

1. Re-run `mouseless-input-access.sh` — the `input` group membership was wiped
   (see "Host setup" below).
2. Launch with `--overlay-renderer cairo`. The top-bar offset bug is **not
   fixed** in v1.0.0, and this machine will pick the buggy renderer by default.

With both in place, a user on a near-identical stack (Arch + Hyprland +
Quickshell top bar) reports it working. Remaining unknown is click accuracy
under 2.0 + 1.5 mixed scaling, which only a trial will settle.

## This machine

    Omarchy    4.0.0.alpha (quattro)
    Hyprland   0.56.2
    Bar        quickshell, layer namespace `omarchy-bar`, anchored top, 26px
    GPU        no NVIDIA module loaded → webview is the default renderer

    eDP-1   2880x1920   scale 2.00   logical 1440x960    at 0,0
    DP-4    3840x2160   scale 1.50   logical 2560x1440   at 1440,0

Two changes since the last review matter. Omarchy 4 replaced waybar with
quickshell, which is the same bar the one confirmed-working Hyprland report
used. And `hypr/monitors.lua` now sets `GDK_SCALE=2` session-wide — see open
question 2.

## What was broken, and when it got fixed

The Omarchy report is [#489](https://github.com/cymian/mouseless/issues/489)
(Dec 2025, Hyprland 0.52, v0.5.0-preview.2): overlay drawn half off-screen, not
centred. Cause: the overlay was an ordinary XWayland/GTK window, so Hyprland
positioned it. Community workaround at the time was
`windowrule = noblur,center, class:Mouseless`.

Fixed in **v1.0.0-preview.3** (2026-05-15, Linux-only release), which states it
"improves support for various compositors (tested Niri, **Hyprland**, Plasma
x11, i3 + picom)". The root fix: **the overlay now uses `wlr-layer-shell` by
default on Wayland**, so the compositor no longer repositions it.

**v1.0.0** (2026-07-07) rolls that up and reworks Wayland input handling —
fixed vendor id `736e` for virtual devices, an `excluded_input_devices` config
field, and "fixed bug where keys can get stuck after executing a command". That
addresses [#523](https://github.com/cymian/mouseless/issues/523) (Arch +
Hyprland, Shift/Ctrl/Super going completely dead).

Corroborating reports from Arch-family Hyprland users in the
[preview.3 thread](https://github.com/cymian/mouseless/issues/549):
CachyOS + Hyprland + Quickshell — "works perfectly on my setup" (2026-05-19);
EndeavourOS + Hyprland also working.

Note: #489 is still formally *open*, but it is stale against a codebase that
changed underneath it. Don't read its open state as "still broken".

## Open questions for this setup

### 1. Top-bar offset — answered, still broken, workaround confirmed

**Resolved as of this review: not fixed in v1.0.0.** The maintainer said in
May it would land in "the next release", but neither the preview.5 nor the
v1.0.0 notes mention it. The only Linux overlay work in v1.0.0 was the NVIDIA
renderer default.

The bug still reproduces on v1.0.0:
[#601](https://github.com/cymian/mouseless/issues/601) (2026-08-09, Manjaro
KDE) — overlay leaves a gap the height of the panel, and clicks land shifted
vertically by that same gap. The maintainer suggested the `overlay_offset`
debug field; the reporter came back saying it doesn't work, because it moves
the hit-test layout while the rendered surface stays put, so the two coordinate
spaces drift apart instead of lining up.

The workaround that does work is `--overlay-renderer cairo`. The report is from
the closest match to this machine there is — CachyOS/Arch + Hyprland +
Quickshell anchored top, grid starting below the bar and clicks off by about
one level-1 cell
([#549](https://github.com/cymian/mouseless/issues/549), 2026-05-19). After
switching to cairo: "Mouseless now works perfectly on my setup."

This machine has no NVIDIA GPU, so it gets the webview renderer by default and
will hit the bug on first launch. Set cairo before judging anything else.

Cairo costs three overlay features per the v1.0.0 notes:
`highlight_animation`, the `dots` and `dashed` grid line styles, and
`always_show_subgrid`. The maintainer's own advice for reducing input lag is to
turn the first off and use `lines` anyway.

One KDE user found cairo made things worse — the overlay became a window with
its own title bar ([#549](https://github.com/cymian/mouseless/issues/549),
2026-06-05). That has not been reported under Hyprland.

### 2. Scaling — one new risk, one still unverified

**`GDK_SCALE=2` (new).** `hypr/monitors.lua` exports it session-wide for the
retina panel. [#618](https://github.com/cymian/mouseless/issues/618)
(2026-08-23) shows that GDK-level scaling corrupts click coordinates inside the
flatpak: with `text-scaling-factor = 1.25`, every click landed at exactly
`1 / 1.25` of the intended position, on both axes and both monitors, measured
off the `ABS_X`/`ABS_Y` written to the uinput device. Their fix was
`flatpak override --user --env=GDK_DPI_SCALE=0.8 net.sonuscape.mouseless`.

`GDK_SCALE=2` is integer scaling on a different env var, so this is an
inference, not a confirmed report. But it is the first thing to test, and the
fix has the same shape:

    flatpak override --user --env=GDK_SCALE=1 net.sonuscape.mouseless

`gsettings get org.gnome.desktop.interface text-scaling-factor` returns `1.0`
here, so the exact #618 trigger is absent.

**Mixed per-monitor scale (2.0 + 1.5).** Still no report either way. #618 is
partial evidence that the multi-monitor geometry itself is sound — that
reporter got pixel-exact clicks across two outputs, one rotated 270°, once GDK
scaling was neutralised. But both of their outputs were scale 1, so it tests
layout math, not mixed scale factors.

The manual escape hatches in the
[troubleshooting docs](https://mouseless.click/docs/troubleshooting.html) are
still global rather than per-monitor, which is the wrong shape for a 2.0 + 1.5
mix:

- "Overlay scaling", "Mouse scaling", "Mouse screen offset scaling"
- `--dpi-scale <n>` CLI (system DPI / 96)
- `{"overlay_offset": {"x": 100, "y": -50}}` in debug options

Test click accuracy on *both* monitors during the trial.

### 3. Modifier stuck after suspend — new, open, laptop-specific

[#615](https://github.com/cymian/mouseless/issues/615) (2026-08-20, open):
suspend with a modifier held and it stays held on resume, so every subsequent
key arrives as `Super+<key>` and triggers compositor bindings instead of
reaching apps. Reported on CachyOS + Hyprland 0.56.0 on a ThinkPad, grabbing
the internal keyboard — the same shape as this machine. The internal keyboard
is reset during suspend, so the key-up never reaches the evdev grab.

Pressing the modifier again doesn't clear it. Killing the app does, because
closing the uinput fd makes the kernel release everything held on that device.
If this shows up during the trial, bind:

    flatpak kill net.sonuscape.mouseless; sleep 0.5; flatpak run net.sonuscape.mouseless

No fix released.

### 4. Key-remapper conflicts — not applicable

[#581](https://github.com/cymian/mouseless/issues/581) open as of 2026-07-23 —
keyboard goes fully unresponsive alongside xremap; keyd similar. Intended fix is
excluding vendor id `736e` in the remapper's config, but it hasn't worked for
everyone. Nothing of that kind runs here (checked: no keyd, xremap or kanata).

## Distribution: flatpak only

v1.0.0 retired the AppImage — "a single, robust flatpak distribution".

- **flatpak** — the only official Linux channel now. Still not installed on this
  machine. Costs `sudo pacman -S flatpak` plus the `org.gnome.Platform//50`
  runtime (~400MB), which the app is built against.
- **AppImage** — still downloadable up to `v1.0.0-preview.5`, but dead-ended and
  predates the final Wayland input fixes. Not worth it.
- **AUR** — does not exist for this app. `mouseless` / `mouseless-bin` in the AUR
  are [jbensmann/mouseless](https://github.com/jbensmann/mouseless), an
  unrelated Go key remapper. Someone asked for an Arch build in the
  [v1.0.0 Linux thread](https://github.com/cymian/mouseless/issues/577) on
  2026-07-15 and got no answer.

Install:

    sudo pacman -S flatpak
    flatpak remote-add --user --if-not-exists sonuscape \
      https://dl.sonuscape.net/flatpak/sonuscape.flatpakrepo
    flatpak install --user flathub org.gnome.Platform/x86_64/50
    flatpak install net.sonuscape.mouseless

Two people in #577 hit a missing `org.gnome.Platform/x86_64/50` and needed the
flathub remote added `--user` first, hence the explicit runtime line.

## Host setup — regressed, needs re-running

`mouseless-input-access.sh` was run 2026-04-27 and verified live on 2026-07-28.
It is **no longer fully in place**: `/etc/group` was rewritten on 31 Aug 10:56
(the Omarchy 4 upgrade) and the `input` group is now empty.

| Check | State |
|---|---|
| `input` group membership | **gone** — `input:x:993:` has no members |
| `/dev/uinput` | `root:input 660` |
| `/dev/input/event*` | `root:input 660` |
| `uinput` module | loaded + in `/etc/modules-load.d/` |
| `99-mouseless-input.rules` | present (dated 27 Apr) |
| brltty udev conflict | brltty not installed — N/A |

Only the group membership was lost; the udev rule and module config survived.
Re-run the script (idempotent) and log out and back in.

The script was written for the AppImage, but the host-side setup carries over to
the flatpak unchanged: the sandbox exposes `/dev/input` and `/dev/uinput`
(users in the 1.0.0 threads get full device enumeration from
`flatpak run net.sonuscape.mouseless --list-input-devices`).

The brltty caveat is worth remembering only if brltty ever gets pulled in as a
dependency — its udev rules grab input devices and break the permission setup
([reported in #577](https://github.com/cymian/mouseless/issues/577)).

## Hyprland config to add when installing

    layerrule = noanim, mouseless-overlay

Maintainer-recommended: layer-shell compositors apply a fade animation to the
overlay by default, which hurts responsiveness. Confirm the real namespace with
`hyprctl layers` once it's running rather than trusting the name above. The old
`windowrule = noblur,center, class:Mouseless` should no longer be needed under
layer-shell, but is the fallback if the app *window* (not overlay) misbehaves.

---

## Trial procedure

Host side first:

    ./mouseless-input-access.sh    # then log out and back in
    id -nG | tr ' ' '\n' | grep -x input
    stat -c '%n owner=%U group=%G mode=%a' /dev/uinput /dev/input/event0

Then install per the commands above and launch with the renderer already
overridden:

    flatpak run net.sonuscape.mouseless --overlay-renderer cairo

In order:

1. **Does the grid start at y=0, above the bar?** If it starts below
   `omarchy-bar` you are still on webview — check `Linux render configuration`
   in the startup log.
2. **Click accuracy on eDP-1** (scale 2.0). If every click lands at half the
   intended coordinate, `GDK_SCALE=2` is leaking in; apply the
   `flatpak override` from open question 2.
3. **Click accuracy on DP-4** (scale 1.5), same grid positions. A different
   error ratio per monitor means mixed fractional scaling is genuinely
   unsupported, and the global correction fields cannot fix it.
4. **Suspend with Super held**, resume, type. Confirms whether #615 hits here.
5. **Touchpad still moves the cursor** while Mouseless runs. A KDE user lost
   mouse movement when Mouseless grabbed a combined keyboard+pointer device
   (#577, 2026-08-03); the maintainer says a fix is queued for the next
   release. Check what `--list-input-devices` reports for the Framework
   internal keyboard.

If 1-3 pass, buy the license. If 3 fails, wait — the
[roadmap](https://mouseless.click/docs/roadmap_and_issues.html) lists "single
overlay spanning multiple monitors" as a future item, which is where a real
per-monitor scaling fix would come from.

## Sources

- [Getting started – Linux](https://mouseless.click/docs/getting_started.html#linux)
- [Wayland configuration](https://mouseless.click/docs/wayland_configuration.html)
- [Troubleshooting](https://mouseless.click/docs/troubleshooting.html)
- [Roadmap](https://mouseless.click/docs/roadmap_and_issues.html)
- [Releases](https://github.com/cymian/mouseless/releases)
- Issues: [#489 Omarchy](https://github.com/cymian/mouseless/issues/489) ·
  [#523 Hyprland modifiers](https://github.com/cymian/mouseless/issues/523) ·
  [#549 preview.3 feedback](https://github.com/cymian/mouseless/issues/549) ·
  [#577 v1.0.0 Linux feedback](https://github.com/cymian/mouseless/issues/577) ·
  [#581 xremap conflict](https://github.com/cymian/mouseless/issues/581) ·
  [#601 KDE panel gap](https://github.com/cymian/mouseless/issues/601) ·
  [#615 stuck modifier after suspend](https://github.com/cymian/mouseless/issues/615) ·
  [#618 GDK scaling breaks clicks](https://github.com/cymian/mouseless/issues/618)
