{ icedosLib, lib, ... }:

{
  options.icedos.hardware.drivers.zfs =
    let
      inherit (lib) readFile;

      inherit ((fromTOML (readFile ./config.toml)).icedos.hardware.drivers.zfs)
        allowHibernation
        autoScrub
        ;

      inherit (icedosLib) mkBoolOption;
    in
    {
      allowHibernation = mkBoolOption { default = allowHibernation; };
      autoScrub = mkBoolOption { default = autoScrub; };
    };

  outputs = {
    nixosModules =
      { ... }:
      [
        (
          {
            config,
            ...
          }:
          let
            inherit (config.icedos.hardware.drivers.zfs) allowHibernation autoScrub;
          in
          {
            boot.supportedFilesystems.zfs = true;
            boot.zfs.allowHibernation = allowHibernation;
            services.zfs.autoScrub.enable = autoScrub;
          }
        )
      ];

    nixosModulesText = [
      ''
        { networking.hostId = "${builtins.substring 0 8 (builtins.readFile /etc/machine-id)}"; }
      ''
    ];
  };

  meta.name = "zfs";
}
