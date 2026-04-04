{ ... }:

{
  outputs.nixosModules =
    { ... }:
    [
      (
        { config, ... }:

        {
          hardware.xpadneo.enable = true;

          # ERTM must be disabled for Xbox One controllers (BR/EDR).
          # The upstream NixOS xpadneo module only disables it for kernels < 5.12,
          # but Xbox One controllers still need it disabled on modern kernels.
          boot.extraModprobeConfig = ''
            options bluetooth disable_ertm=1
          ''
          + (if (!config.icedos.hardware.devices.laptop) then "options btusb enable_autosuspend=0" else "");
        }
      )
    ];

  meta.name = "xpadneo";
}
