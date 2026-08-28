{ icedosLib, lib, ... }:

{
  options.icedos.hardware.drivers.zenstates.serviceArgs =
    let
      inherit (lib) importTOML;
      inherit ((importTOML ./config.toml).icedos.hardware.drivers.zenstates) serviceArgs;
    in
    icedosLib.mkStrListOption {
      default = serviceArgs;

      description = ''
        Arguments passed to the zenstates binary on every boot (a "Ryzen Undervolt"
        profile, e.g. ["-p" "0" "-v" "3C" "-f" "A0"]). List of strings — one element
        per argument (previously this was a single space-separated string).
      '';
    };

  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          lib,
          pkgs,
          ...
        }:

        let
          inherit (lib) concatStringsSep map;
          inherit (config.icedos.hardware.drivers.zenstates) serviceArgs;

          # Escape each arg for ExecStart= (matches nixpkgs systemd module:
          # toJSON + doubled % and $ to prevent systemd expansion).
          escapeExecArg = arg: builtins.replaceStrings [ "%" "$" ] [ "%%" "$$" ] (builtins.toJSON arg);
        in
        {
          environment.systemPackages = [
            pkgs.zenstates
          ];

          systemd.services.zenstates = {
            enable = true;
            description = "Ryzen Undervolt";
            after = [
              "syslog.target"
              "systemd-modules-load.service"
            ];

            unitConfig = {
              ConditionPathExists = "${pkgs.zenstates}/bin/zenstates";
            };

            serviceConfig = {
              User = "root";
              ExecStart =
                "${pkgs.zenstates}/bin/zenstates"
                + concatStringsSep "" (map (arg: " " + escapeExecArg arg) serviceArgs);
            };

            wantedBy = [ "multi-user.target" ];
          };
        }
      )
    ];

  meta.name = "zenstates";
}
