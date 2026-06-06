# bt-pair — pair a flaky Bluetooth controller that BlueZ/KDE gives up on.
#
# Some controllers (notably Xbox One S pads on MediaTek adapters) fail the first
# 1-2 BlueZ pairing attempts and need a clean re-pair. KDE's pairing wizard is
# one-shot and bails on the first failure. This wipes any stale bond, retries
# pairing, trusts, then brute-forces the link until an input device appears.
#
# The link brute-force exists because old-firmware Xbox pads intermittently send a
# corrupted HID report descriptor ("unbalanced collection ... parse failed"), so
# BlueZ reports "connected" but no js node is created. A fresh link sometimes
# transfers the descriptor cleanly, so we reconnect until an input node shows up.
#
# Usage: bt-pair [MAC]      (no MAC -> pick from a list of known/nearby devices)
#   BT_PAIR_RETRIES=N        pairing attempts             (default 5)
#   BT_PAIR_SCAN=N           per-attempt scan seconds     (default 8)
#   BT_PAIR_CONN_RETRIES=N   link/reconnect attempts      (default 8)
#
# Shebang and `set -euo pipefail` are injected by writeShellApplication.

retries="${BT_PAIR_RETRIES:-5}"
scan_secs="${BT_PAIR_SCAN:-8}"

case "${1:-}" in
  -h | --help)
    grep -E '^# ' "$0" | sed 's/^# \{0,1\}//' || true
    exit 0
    ;;
esac

mac="${1:-}"

is_mac() { [[ "$1" =~ ^([0-9A-Fa-f]{2}:){5}[0-9A-Fa-f]{2}$ ]]; }

# True if an input device bound to $mac_lc exposes a joystick handler. This is
# ground truth for "usable as a controller": a failed HID descriptor parse
# creates no such node, a clean one does.
has_input_node() {
  local uniq="" line
  while IFS= read -r line; do
    case "$line" in
    "U: Uniq="*) uniq="${line,,}" ;;
    "H: Handlers="*)
      [[ "$uniq" == *"$mac_lc"* && "$line" == *js[0-9]* ]] && return 0
      ;;
    "") uniq="" ;;
    esac
  done </proc/bus/input/devices
  return 1
}

# No MAC given: scan, then let the user pick from known/discovered devices.
if [[ -z "$mac" ]]; then
  echo "Scanning ${scan_secs}s for devices..."
  bluetoothctl --timeout "$scan_secs" scan on >/dev/null 2>&1 || true

  devs=$(bluetoothctl devices 2>/dev/null | grep -E '^Device ' || true)
  if [[ -z "$devs" ]]; then
    echo "No devices found. Put the controller in pairing mode and retry." >&2
    exit 1
  fi

  mapfile -t lines <<<"$devs"
  i=1
  for line in "${lines[@]}"; do
    printf '%2d) %s\n' "$i" "${line#Device }"
    i=$((i + 1))
  done

  read -rp "Pick number: " pick
  if ! [[ "$pick" =~ ^[0-9]+$ ]] || ((pick < 1 || pick > ${#lines[@]})); then
    echo "Invalid selection." >&2
    exit 1
  fi
  read -r _ mac _ <<<"${lines[$((pick - 1))]}"
fi

if ! is_mac "$mac"; then
  echo "Not a MAC address: $mac" >&2
  exit 1
fi
mac_lc="${mac,,}"

echo "Target: $mac"
echo "Put the controller in pairing mode (fast-blinking) now."

# Confirm it's actually reachable before wiping the bond.
bluetoothctl --timeout "$scan_secs" scan on >/dev/null 2>&1 || true
devs=$(bluetoothctl devices 2>/dev/null || true)
if ! grep -qiF "$mac" <<<"$devs"; then
  echo "Controller $mac not discoverable. Is it in pairing mode?" >&2
  exit 1
fi

echo "Removing any stale bond for $mac to re-pair fresh..."
bluetoothctl remove "$mac" >/dev/null 2>&1 || true

paired=0
for ((n = 1; n <= retries; n++)); do
  echo "Pair attempt $n/$retries..."
  bluetoothctl --timeout "$scan_secs" scan on >/dev/null 2>&1 || true
  out=$(bluetoothctl pair "$mac" 2>&1 || true)
  if grep -qiE 'Pairing successful|already.*paired' <<<"$out"; then
    paired=1
    break
  fi
  sleep 2
done

if ((!paired)); then
  echo "Pairing failed after $retries attempts. Keep it blinking and run again." >&2
  exit 1
fi

bluetoothctl trust "$mac" >/dev/null 2>&1 || true

# Brute-force the link until the controller actually exposes an input node
# (see header: old-firmware pads send corrupt HID descriptors over a flaky link).
conn_retries="${BT_PAIR_CONN_RETRIES:-8}"
bound=0
for ((c = 1; c <= conn_retries; c++)); do
  echo "Connect attempt $c/$conn_retries..."
  bluetoothctl connect "$mac" >/dev/null 2>&1 || true

  # Poll ~8s for the input node before deciding the descriptor failed.
  for ((p = 1; p <= 16; p++)); do
    if has_input_node; then
      bound=1
      break
    fi
    sleep 0.5
  done
  ((bound)) && break

  echo "  connected but HID descriptor did not parse - re-linking..."
  bluetoothctl disconnect "$mac" >/dev/null 2>&1 || true
  sleep 2
done

if ((bound)); then
  shopt -s nullglob
  js_nodes=(/dev/input/js*)
  shopt -u nullglob
  echo "Controller live: $mac  (joystick nodes: ${js_nodes[*]:-none})"
else
  {
    echo "Connected but NO input device after $conn_retries link attempts."
    echo "Controller is sending a malformed HID report descriptor (parse failed, -22)."
    echo "Real fix: update the controller firmware, or use a USB-C cable (wired bypasses BT)."
  } >&2
  exit 1
fi
