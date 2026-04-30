#!/usr/bin/env bash
# Grant the current user access to /dev/uinput and /dev/input/event* so
# Mouseless can read keyboard events from hot-plugged keyboards (NuPhy
# Air75 over USB/Bluetooth, etc.).
#
# Why this script exists:
# The Mouseless Wayland docs (https://mouseless.click/docs/wayland_configuration.html)
# suggest a tmpfiles or udev rule that assigns device ownership to your
# non-system user. Modern systemd-udev rejects that with
#   1. Add the user to the existing 'input' system group (covers all
#      hot-plugged /dev/input/event*).
#   2. Add a udev rule for /dev/uinput (which has no default group), giving
#      it group=input so the same group membership covers it too.
#
# After running, log out and back in for the group membership to apply.
# Idempotent. Safe to re-run.

set -euo pipefail

RULE_FILE=/etc/udev/rules.d/99-mouseless-input.rules
MODULES_LOAD=/etc/modules-load.d/uinput.conf
TMPFILES_CONF=/etc/tmpfiles.d/mouseless-input.conf

echo "==> Ensuring 'uinput' kernel module loads at boot: $MODULES_LOAD"
echo "uinput" | sudo tee "$MODULES_LOAD" > /dev/null
if ! lsmod | grep -q '^uinput'; then
  echo "==> Loading uinput module now"
  sudo modprobe uinput
fi

if id -nG "$USER" | tr ' ' '\n' | grep -qx input; then
  echo "==> $USER already in 'input' group"
else
  echo "==> Adding $USER to 'input' group"
  sudo usermod -aG input "$USER"
  RELOGIN_REQUIRED=1
fi

echo "==> Writing udev rule: $RULE_FILE"
sudo tee "$RULE_FILE" > /dev/null <<'EOF'
# /dev/uinput — for Mouseless to create virtual output devices.
# Uses the 'input' system group; user must be a member of 'input'.
KERNEL=="uinput", GROUP:="input", MODE:="0660"
EOF

if [ -f "$TMPFILES_CONF" ]; then
  echo "==> Removing obsolete tmpfiles fallback: $TMPFILES_CONF"
  sudo rm "$TMPFILES_CONF"
fi

echo "==> Reloading udev and re-applying rules to existing devices"
sudo udevadm control --reload-rules
sudo udevadm trigger

if [ -n "${RELOGIN_REQUIRED:-}" ]; then
  echo
  echo "!! Log out and back in for the 'input' group membership to take effect."
  echo "   Verify after re-login with: id -nG | tr ' ' '\\n' | grep input"
fi
