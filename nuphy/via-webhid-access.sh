#!/usr/bin/env bash
# Grant WebHID access to NuPhy keyboards so usevia.app / nuphy.io can program
# them from a Chromium-based browser (NuPhy Air75 V2/V3/V4, etc.).
#
# Why this script exists:
# On Linux the browser cannot open the keyboard's /dev/hidraw* node without
# permission. VIA then fails with:
#   NotAllowedError: Failed to open the device
#   Received invalid protocol version from device
# The second error is just a symptom of the first: VIA "opens" the device,
# can't actually read from it, and misreads the empty response as a bad
# protocol version. Granting hidraw access fixes both.
#
# What it does:
#   Adds a udev rule that tags every hidraw node belonging to NuPhy's USB
#   vendor id (0x19F5) with 'uaccess', granting the logged-in seat user
#   read/write access — no group membership or root needed.
#
# After running, UNPLUG AND REPLUG the keyboard for the rule to apply.
# Then use a Chromium-based browser (WebHID is unavailable in Firefox),
# connect over the USB-C cable, and click "Authorize device" in VIA.
# Idempotent. Safe to re-run.

set -euo pipefail

# Must sort BEFORE systemd's 73-seat-late.rules: that rule is what reads the
# 'uaccess' tag and tells logind to grant the active user an ACL. A rule added
# after 73 sets the tag too late — the tag sticks but no ACL is ever applied.
RULE_FILE=/etc/udev/rules.d/60-nuphy-via.rules
OBSOLETE_RULE=/etc/udev/rules.d/92-nuphy-via.rules
NUPHY_VID=19f5

if [ -f "$OBSOLETE_RULE" ]; then
  echo "==> Removing obsolete too-late rule: $OBSOLETE_RULE"
  sudo rm "$OBSOLETE_RULE"
fi

echo "==> Writing udev rule: $RULE_FILE"
sudo tee "$RULE_FILE" > /dev/null <<EOF
# NuPhy keyboards (Air75 V2/V3/V4 etc.) — allow WebHID access for VIA /
# nuphy.io. 'uaccess' grants the active seat user read/write on every hidraw
# node under NuPhy's USB vendor id, so no 'input'-style group is required.
KERNEL=="hidraw*", ATTRS{idVendor}=="$NUPHY_VID", MODE="0660", TAG+="uaccess"
EOF

echo "==> Reloading udev and re-applying rules to existing devices"
sudo udevadm control --reload-rules
sudo udevadm trigger

echo
echo "!! Unplug and replug the keyboard for the rule to take effect."
echo "   Then in a Chromium-based browser (NOT Firefox):"
echo "     - connect the keyboard over the USB-C cable"
echo "     - close any other app/tab holding the device (NuPhy Console, etc.)"
echo "     - open usevia.app and click 'Authorize device'"
echo
echo "   Verify the device is visible with:"
echo "     ls -l /dev/hidraw*"
