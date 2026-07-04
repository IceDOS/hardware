# AGENTS.md — IceDOS **hardware**

> Utilizes the **IceDOS** framework. The full bible — module structure, config flow,
> the `icedos rebuild --build` test loop, `validate.*` helpers, dep loading — lives in
> **core**: <https://github.com/IceDOS/core/blob/main/AGENTS.md> — this file only
> covers what is specific to **hardware**.

## Non-negotiable rules (full detail in core)

- Build/test only via the `icedos` CLI — **never `sudo nixos-rebuild`**.
- **Never** `git commit/stash/reset/pull` — the user manages git.
- Every option uses a `validate.*`/`mk*Option` helper; **no untyped options**.
- A module's `config.toml` defaults must mirror its `icedos.nix` defaults.
- Format with `icedos nixf .` after editing any `.nix`.
- If a repo or the config root you need isn't checked out locally, **ask the user** for
  its path or permission to `git clone` it — don't guess or clone unprompted.

## Purpose

Hardware and low-level system configuration: kernels, GPU drivers, audio,
peripherals, storage mounts, networking.

## Layout

- `modules/<name>/{icedos.nix,config.toml}` per module; `flake.nix` exposes them via
  `icedosLib.scanModules { path = ./modules; filename = "icedos.nix"; }`.
- Some modules nest sub-modules: e.g. `graphics/` has `graphics/modules/` (radeon,
  nvidia, …).

## Module shape here

Standard IceDOS module under `options.icedos.hardware.<name>`. Same shape as apps
(options from sibling `config.toml` → `outputs.nixosModules` → `meta.name`).

## Test a change to this repo

In the config root's `config.toml`, point this repo's `overrideUrl` at your local
checkout (`path:/abs/path/to/hardware`), then `icedos rebuild --build` (no activation).
Kernel/driver changes that affect the running system need a real `switch` + reboot —
that's the **user's** call.

## Notable modules / gotchas

- `kernel` (variant selection, e.g. `latest-lto-x86_64-v3`), `graphics/radeon` &
  `graphics/nvidia`, `pipewire` (echo/noise cancellation),
  `bluetooth`, `openrgb`, `zram`, `uinput`, `upower`, `monitors`, `mounts`, `network`.
- `scx` (CPU scheduler), `lact` & `low-latency-vulkan-layer` (GPU), `power-profiles-daemon`,
  `samba` (file shares), `solaar`, `input-remapper`, `ambiled` (peripherals/LED).
- Hardware modules can change boot/kernel — be conservative; prefer `--build` validation
  and let the user activate.
