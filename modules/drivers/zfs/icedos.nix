{ icedosLib, lib, ... }:

{
  options.icedos.hardware.drivers.zfs =
    let
      inherit (lib) importTOML;

      inherit ((importTOML ./config.toml).icedos.hardware.drivers.zfs)
        allowHibernation
        autoScrub
        forceImportRoot
        hostId
        ;

      inherit (icedosLib) mkBoolOption mkStrOption;
    in
    {
      allowHibernation = mkBoolOption {
        default = allowHibernation;

        description = ''
          Acknowledgement flag for suspend-to-disk while ZFS swap is in use.
          Hibernation with a ZFS-backed swap device is dangerous: the pool may not
          be re-importable after resume. Enabling this only consents to the module's
          `boot.resumeDevice` guard below — the actual kernel-level block is nixpkgs'
          `boot.zfs.unsafeAllowHibernation`, which this module intentionally does not
          set (it conflicts with `forceImportRoot`).
        '';
      };

      autoScrub = mkBoolOption {
        default = autoScrub;

        description = "Data integrity checks monthly.";
      };

      forceImportRoot = mkBoolOption {
        default = forceImportRoot;

        description = ''
          Import the root pool even if it was exported elsewhere or has a stale hostid.
          Unconditionally force-importing can damage a pool that another host currently
          holds — only leave this on when you know no other system touches the pool.
        '';
      };

      hostId = mkStrOption {
        default = hostId;

        description = ''
          ZFS host identifier (exactly 8 hexadecimal characters). Empty leaves
          `networking.hostId` unset: when ZFS is enabled, nixpkgs aborts the build
          with "ZFS requires networking.hostId to be set", so an existing pool is
          never silently imported under a different hostid.

          Before enabling this module on a machine that already has ZFS pools, set
          this to the pool's current hostid (`head -c 8 /etc/machine-id` or
          `zpool get hostid`) so the pools keep auto-importing. A change of hostid
          makes pools refuse to import; recover with `zpool import -f`.
        '';
      };
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
            inherit (icedos.hardware.drivers.zfs)
              allowHibernation
              autoScrub
              forceImportRoot
              hostId
              ;

            inherit (lib)
              attrValues
              elemAt
              filter
              listToAttrs
              mkIf
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
            assertions = [
              {
                assertion = hostId == "" || builtins.match "^[0-9a-fA-F]{8}$" hostId != null;
                message = ''
                  icedos.hardware.drivers.zfs.hostId: '${hostId}' is not a valid
                  ZFS host identifier. Use exactly 8 hexadecimal characters, or
                  leave it empty to let nixpkgs require networking.hostId itself.
                '';
              }
              {
                assertion = allowHibernation || config.boot.resumeDevice == "";
                message = ''
                  icedos.hardware.drivers.zfs: hibernation is configured
                  (boot.resumeDevice is set) but allowHibernation is not enabled.
                  Hibernation with ZFS swap is dangerous; set
                  icedos.hardware.drivers.zfs.allowHibernation = true to acknowledge.
                '';
              }
            ];

            boot.supportedFilesystems.zfs = true;
            boot.zfs.forceImportRoot = forceImportRoot;
            networking.hostId = mkIf (hostId != "") hostId;
            services.zfs.autoScrub.enable = autoScrub;

            # zpool import scans /dev/disk/by-id before udev finishes creating symlinks,
            # causing hangs on half-initialized devices. Run udevadm settle before import
            # to ensure device symlinks exist. (systemd-udev-settle.service was removed
            # in systemd 256, so we call udevadm settle directly via ExecStartPre.)
            # See: https://github.com/NixOS/nixpkgs/issues/73095
            systemd.services = listToAttrs (
              map (pool: {
                name = "zfs-import-${pool}";
                value.serviceConfig.ExecStartPre = [ "${config.systemd.package}/bin/udevadm settle" ];
              }) zfsPools
            );
          }
        )
      ];
  };

  meta.name = "zfs";
}
