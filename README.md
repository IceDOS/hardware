# IceDOS hardware

Hardware and low-level system configuration for the IceDOS framework: kernels, GPU drivers, audio, peripherals, storage mounts, and networking.

## Usage

Modules in IceDOS do not have an `enable` option. To enable a module, add its name to this repository's `modules` list in your configuration (e.g., `config.toml`):

```toml
[[icedos.repositories]]
url = "github:icedos/hardware"
modules = [
  "bluetooth",
  "graphics",
  "pipewire",
]
```

Where a module has options, its defaults are in its `config.toml` and its schema in `icedos.nix`; both are searchable with `icedos configuration search --options icedos.hardware`. For dependency resolution and the repository flags `fetchDependencies` and `fetchOptionalDependencies`, see [Enabling modules](https://github.com/IceDOS/core#enabling-modules) in core's README.

## Default module

The `default` module loads whenever this repository is used, directly or because another repository depends on it.

### Baseline settings

- `hardware.enableAllFirmware = true`
- `services.fstrim.enable = true`
- `networking.firewall.enable` from `icedos.hardware.network.firewall`, which defaults to `true`
- `systemd.services.NetworkManager-wait-online.enable = false`

### Automatically loaded dependencies

- [`hostname`](modules/network/hostname/icedos.nix)
- [`kmscon`](modules/kmscon/icedos.nix)
- [`mounts`](modules/mounts/icedos.nix)
- [`network-manager`](modules/network/network-manager/icedos.nix)

## Exposed modules

| Module | Path | Description |
| :--- | :--- | :--- |
| `bluetooth` | [modules/bluetooth/icedos.nix](modules/bluetooth/icedos.nix) | Bluetooth support with tuned controller and pairing settings |
| `btrfs` | [modules/drivers/btrfs/icedos.nix](modules/drivers/btrfs/icedos.nix) | Adds `icedos btrfs-zstd` to compress a btrfs path with zstd |
| `cachyos-kernel` | [modules/kernel/modules/cachyos-kernel/icedos.nix](modules/kernel/modules/cachyos-kernel/icedos.nix) | CachyOS kernel packages fetched from third-party caches |
| `deckbd` | [modules/drivers/deckbd/icedos.nix](modules/drivers/deckbd/icedos.nix) | Steam Deck controls work as a keyboard at the disk-unlock prompt |
| `disable-ipv6` | [modules/network/disable-ipv6/icedos.nix](modules/network/disable-ipv6/icedos.nix) | Turns IPv6 off system-wide through kernel sysctls |
| `graphics` | [modules/graphics/icedos.nix](modules/graphics/icedos.nix) | 64-bit and 32-bit graphics support through the Mesa stack |
| `hostname` | [modules/network/hostname/icedos.nix](modules/network/hostname/icedos.nix) | Sets the hostname other devices see on the network |
| `hosts` | [modules/network/hosts/icedos.nix](modules/network/hosts/icedos.nix) | Adds /etc/hosts entries to block or redirect domains |
| `intel` | [modules/cpus/intel/icedos.nix](modules/cpus/intel/icedos.nix) | Intel CPU microcode updates and the throttled thermal service |
| `kernel` | [modules/kernel/icedos.nix](modules/kernel/icedos.nix) | Kernel variant selection and vm.swappiness tuning |
| `kmscon` | [modules/kmscon/icedos.nix](modules/kmscon/icedos.nix) | kmscon console with hardware acceleration and optional auto-login |
| `mesa` | [modules/graphics/modules/mesa/icedos.nix](modules/graphics/modules/mesa/icedos.nix) | Mesa driver with optional RC or git builds and shader cache size |
| `monitors` | [modules/monitors/icedos.nix](modules/monitors/icedos.nix) | Monitor modes, rotation and optional EDID overclocking; Hyprland monitor settings need the `default` module from hyprland, not fetched automatically |
| `mounts` | [modules/mounts/icedos.nix](modules/mounts/icedos.nix) | Mounts extra drives and swap devices at boot |
| `network-manager` | [modules/network/network-manager/icedos.nix](modules/network/network-manager/icedos.nix) | NetworkManager with an optional connection editor and tray applet |
| `nvidia` | [modules/graphics/modules/nvidia/icedos.nix](modules/graphics/modules/nvidia/icedos.nix) | NVIDIA driver; laptops get PRIME offload and `icedos force-nvidia` |
| `openrgb` | [modules/drivers/openrgb/icedos.nix](modules/drivers/openrgb/icedos.nix) | OpenRGB lighting service that applies an accent colour or profile |
| `pipewire` | [modules/pipewire/icedos.nix](modules/pipewire/icedos.nix) | PipeWire audio with optional noise cancellation and mute commands |
| `power-profiles-daemon` | [modules/drivers/power-profiles-daemon/icedos.nix](modules/drivers/power-profiles-daemon/icedos.nix) | Power profile daemon that applies the chosen profile at login |
| `ps4` | [modules/devices/ps4/icedos.nix](modules/devices/ps4/icedos.nix) | PlayStation 4 profile: PS4 kernel, Mesa, firmware and HDMI keepalive; asserts that cachyos-kernel, scx, ryzen, intel, zenstates, zenergy and steamdeck from this repository are disabled |
| `ps4-kernel` | [modules/devices/ps4/kernel/icedos.nix](modules/devices/ps4/kernel/icedos.nix) | PS4 kernel and Linux packages built from the rmuxnet source tree |
| `radeon` | [modules/graphics/modules/radeon/icedos.nix](modules/graphics/modules/radeon/icedos.nix) | AMD GPU options: feature mask, lockup timeouts, optional ROCm |
| `rtl8821ce` | [modules/drivers/rtl8821ce/icedos.nix](modules/drivers/rtl8821ce/icedos.nix) | Realtek RTL8821CE Wi-Fi driver with the rtw88 module blacklisted |
| `ryzen` | [modules/cpus/ryzen/icedos.nix](modules/cpus/ryzen/icedos.nix) | AMD Ryzen microcode updates and amd-pstate CPU scaling |
| `samba` | [modules/network/samba/icedos.nix](modules/network/samba/icedos.nix) | Samba file shares with global and per-share options |
| `scx` | [modules/kernel/modules/scx/icedos.nix](modules/kernel/modules/scx/icedos.nix) | sched-ext CPU scheduler loader with a selectable scheduler |
| `steamdeck` | [modules/devices/steamdeck/icedos.nix](modules/devices/steamdeck/icedos.nix) | Steam Deck support via Jovian with optional LCD overclock |
| `uinput` | [modules/uinput/icedos.nix](modules/uinput/icedos.nix) | uinput access so apps can create virtual input devices |
| `upower` | [modules/upower/icedos.nix](modules/upower/icedos.nix) | UPower battery information and low-battery warnings |
| `wake-on-lan` | [modules/network/wake-on-lan/icedos.nix](modules/network/wake-on-lan/icedos.nix) | Wake-on-LAN on listed interfaces, with the `wakeonlan` tool |
| `xpadneo` | [modules/drivers/xpadneo/icedos.nix](modules/drivers/xpadneo/icedos.nix) | Xbox controller support with rumble and battery reporting |
| `zenergy` | [modules/drivers/zenergy/icedos.nix](modules/drivers/zenergy/icedos.nix) | zenergy kernel module for Ryzen power readings |
| `zenstates` | [modules/drivers/zenstates/icedos.nix](modules/drivers/zenstates/icedos.nix) | Runs zenstates with your undervolt arguments at boot |
| `zfs` | [modules/drivers/zfs/icedos.nix](modules/drivers/zfs/icedos.nix) | ZFS support with host ID, auto-scrub and force-import options |
| `zram` | [modules/zram/icedos.nix](modules/zram/icedos.nix) | Compressed zram swap sized as a percentage of RAM |

## Documentation

- [AGENTS.md](AGENTS.md) covers what is specific to this repository.
- [core AGENTS.md](https://github.com/IceDOS/core/blob/main/AGENTS.md) is the canonical reference for the framework internals.
