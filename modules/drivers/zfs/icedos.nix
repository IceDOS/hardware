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
            lib,
            ...
          }:
          let
            inherit (config) fileSystems icedos;
            inherit (icedos.hardware.drivers.zfs) allowHibernation autoScrub;

            inherit (lib)
              attrValues
              elemAt
              filter
              listToAttrs
              splitString
              unique
              ;

            # Extract pool names from ZFS fileSystems entries (e.g. "tank/data" -> "tank")
            # to match NixOS-generated zfs-import-<pool>.service unit names
            zfsPools = unique (
              map (fs: elemAt (splitString "/" fs.device) 0) (
                filter (fs: fs.fsType == "zfs") (attrValues fileSystems)
              )
            );
          in
          {
            boot.supportedFilesystems.zfs = true;
            boot.zfs.allowHibernation = allowHibernation;
            services.zfs.autoScrub.enable = autoScrub;

            # NixOS generates zfs-import-<pool>.service with Wants=systemd-udev-settle.service
            # (weak dep — doesn't wait for completion). This causes zpool import to scan
            # /dev/disk/by-id before udev finishes creating symlinks, blocking forever on
            # half-initialized devices (TimeoutStartUSec=infinity on oneshot services).
            # Strengthening to Requires= ensures udev settles before import starts.
            # See: https://github.com/NixOS/nixpkgs/issues/73095
            systemd.services = listToAttrs (
              map (pool: {
                name = "zfs-import-${pool}";
                value.requires = [ "systemd-udev-settle.service" ];
              }) zfsPools
            );
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
