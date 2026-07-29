# Mouseless on Omarchy — compatibility status

Tracking whether [mouseless.click](https://mouseless.click) is usable on this
machine (Arch / Omarchy / Hyprland). Not installed yet as of the last review.

**Last reviewed: 2026-07-28** against Mouseless **v1.0.0** (released 2026-07-07).

Companion to `mouseless-input-access.sh` in this directory, which handles the
uinput/udev side.

---

## Verdict

Blocked on nothing technical — the historical Hyprland breakage is fixed. Two
open questions specific to this machine make it worth waiting rather than
buying a license blind.

## This machine

    eDP-1   2880x1920@120   scale 2.00
    DP-4    3840x2160@60    scale 1.50   (at 1440x0)

Mixed per-monitor fractional scaling. This is the risky configuration — see
open question 2.

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

### 1. Waybar offset bug — check first

On preview.3 the layer-shell overlay did not cover the area under a top bar, so
the grid was shifted by roughly one level-1 cell and clicks landed off-target.
Reported by a Quickshell user; workaround was `--overlay-renderer cairo`.

The maintainer listed it under "Known issues / workarounds" in the preview.3
notes with "Will be fixed in next release!" — **but I found no explicit
confirmation it was actually fixed in preview.5 or 1.0.0.** Omarchy always runs
waybar anchored top, so this hits directly. Verify before anything else.

### 2. Mixed fractional scaling — unverified

No post-1.0 report either confirming or denying correctness on mixed
per-monitor scale factors. The [troubleshooting
docs](https://mouseless.click/docs/troubleshooting.html) still ship manual
escape hatches:

- "Overlay scaling" — size/position correction
- "Mouse scaling" — click-location accuracy
- "Mouse screen offset scaling" — multi-monitor
- `--dpi-scale <n>` CLI (system DPI / 96)
- `{"overlay_offset": {"x": 100, "y": -50}}` in debug options

These are **global, not per-monitor**, which is the wrong shape for a 2.0 + 1.5
mix. Test click accuracy on *both* monitors.

### 3. Key-remapper conflicts

[#581](https://github.com/cymian/mouseless/issues/581) open as of 2026-07-23 —
keyboard goes fully unresponsive alongside xremap; keyd similar. Intended fix is
excluding vendor id `736e` in the remapper's config, but it hasn't worked for
everyone. Only relevant if keyd/xremap/kanata gets added to this setup.

## Distribution: flatpak only

v1.0.0 retired the AppImage — "a single, robust **flatpak** distribution".

- **flatpak** — the only official Linux channel now. `flatpak` is not installed
  on this machine. Costs `sudo pacman -S flatpak` plus the `org.gnome.Platform`
  runtime (~400MB), which the app is built against.
- **AppImage** — still downloadable up to `v1.0.0-preview.5`, but dead-ended and
  predates the final Wayland input fixes. Not worth it.
- **AUR** — does not exist for this app. `mouseless` / `mouseless-bin` in the AUR
  are [jbensmann/mouseless](https://github.com/jbensmann/mouseless), an
  unrelated Go key remapper. Someone asked for an Arch build in the
  [v1.0.0 Linux thread](https://github.com/cymian/mouseless/issues/577) on
  2026-07-15 and got no answer.

## Host setup — already done

`mouseless-input-access.sh` was run 2026-04-27 and verified still live on
2026-07-28:

| Check | State |
|---|---|
| `input` group membership | active |
| `/dev/uinput` | `root:input 660` |
| `/dev/input/event*` | `root:input 660` |
| `uinput` module | loaded + in `/etc/modules-load.d/` |
| `99-mouseless-input.rules` | present |
| brltty udev conflict | brltty not installed — N/A |

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
overlay by default, which hurts responsiveness. The old
`windowrule = noblur,center, class:Mouseless` should no longer be needed under
layer-shell, but is the fallback if the app *window* (not overlay) misbehaves.

---

## Recheck procedure

Re-verify host permissions (should all still pass):

    id -nG | tr ' ' '\n' | grep -x input
    stat -c '%n owner=%U group=%G mode=%a' /dev/uinput /dev/input/event0

Then, in order:

1. **Is there a release after v1.0.0?** — https://github.com/cymian/mouseless/releases
   The [roadmap](https://mouseless.click/docs/roadmap_and_issues.html) had v1.1
   slated for July 2026 (custom actions, revamped config editor, dark mode).
   Roadmap also lists "single overlay spanning multiple monitors" as a *future*
   item — relevant to open question 2.
2. **Waybar offset** — search the [v1.0.0 Linux
   thread](https://github.com/cymian/mouseless/issues/577) and any newer Linux
   feedback thread for "bar" / "offset" / "waybar" / "cairo". Looking for
   confirmation the layer-shell overlay now covers the full output.
3. **Mixed scaling** — search issues for `scale` / `dpi` / `fractional` with a
   Hyprland or multi-monitor context. Looking for anyone on non-uniform
   per-monitor scale.
4. **Hyprland regressions** — `gh api "search/issues?q=repo:cymian/mouseless+hyprland"`
   and check anything created after the last review date above.

If 2 and 3 both look clear, install and trial it (there is a trial; it's paid
software) before committing to a license.

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
  [#581 xremap conflict](https://github.com/cymian/mouseless/issues/581)
