{ ... }:

{
  outputs.nixosModules =
    { ... }:
    [
      (
        { config, ... }:

        {
          hardware.xpadneo.enable = true;

          # ERTM must be disabled for Xbox One controllers on modern kernels too
          # (upstream NixOS module only disables it for kernels < 5.12).
          boot.extraModprobeConfig = ''
            options bluetooth disable_ertm=1
          ''
          + (if (!config.icedos.hardware.devices.laptop) then "options btusb enable_autosuspend=0" else "");
        }
      )
    ];

  meta.name = "xpadneo";
}
