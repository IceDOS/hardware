{ icedosLib, lib, ... }:

{
  options.icedos.hardware.network.samba =
    let
      inherit (lib)
        head
        importTOML
        ;

      inherit (icedosLib)
        mkAttrsOption
        mkBoolOption
        mkNumberOption
        mkStrListOption
        mkStrOption
        mkSubmoduleListOption
        ;

      inherit ((importTOML ./config.toml).icedos.hardware.network.samba)
        workgroup
        serverString
        serverRole
        minProtocol
        mapToGuest
        guestAccount
        useSendfile
        aioReadSize
        aioWriteSize
        socketOptions
        logFile
        maxLogSize
        openFirewall
        enableWsdd
        enableNmbd
        ;

      inherit ((importTOML ./shares.toml).icedos.hardware.network.samba)
        shares
        ;
    in
    {
      workgroup = mkStrOption { default = workgroup; };
      serverString = mkStrOption { default = serverString; };
      serverRole = mkStrOption { default = serverRole; };
      minProtocol = mkStrOption { default = minProtocol; };
      mapToGuest = mkStrOption { default = mapToGuest; };
      guestAccount = mkStrOption { default = guestAccount; };
      useSendfile = mkBoolOption { default = useSendfile; };
      aioReadSize = mkNumberOption { default = aioReadSize; };
      aioWriteSize = mkNumberOption { default = aioWriteSize; };
      socketOptions = mkStrOption { default = socketOptions; };
      logFile = mkStrOption { default = logFile; };
      maxLogSize = mkNumberOption { default = maxLogSize; };
      openFirewall = mkBoolOption { default = openFirewall; };
      enableWsdd = mkBoolOption { default = enableWsdd; };
      enableNmbd = mkBoolOption { default = enableNmbd; };
      extraGlobalSettings = mkAttrsOption { default = { }; };

      shares =
        let
          inherit (head shares)
            name
            path
            comment
            browseable
            readOnly
            guestOk
            forceUser
            forceGroup
            validUsers
            writeList
            createMask
            directoryMask
            extraSettings
            ;
        in
        mkSubmoduleListOption { default = [ ]; } {
          name = mkStrOption { default = name; };
          path = mkStrOption { default = path; };
          comment = mkStrOption { default = comment; };
          browseable = mkBoolOption { default = browseable; };
          readOnly = mkBoolOption { default = readOnly; };
          guestOk = mkBoolOption { default = guestOk; };
          forceUser = mkStrOption { default = forceUser; };
          forceGroup = mkStrOption { default = forceGroup; };
          validUsers = mkStrListOption { default = validUsers; };
          writeList = mkStrListOption { default = writeList; };
          createMask = mkStrOption { default = createMask; };
          directoryMask = mkStrOption { default = directoryMask; };
          extraSettings = mkAttrsOption { default = extraSettings; };
        };
    };

  outputs.nixosModules =
    { ... }:
    [
      (
        {
          config,
          lib,
          ...
        }:

        let
          inherit (lib)
            concatLists
            concatStringsSep
            listToAttrs
            mkIf
            optionalAttrs
            ;

          inherit (config.icedos.hardware.network.samba)
            aioReadSize
            aioWriteSize
            enableNmbd
            enableWsdd
            extraGlobalSettings
            guestAccount
            logFile
            mapToGuest
            maxLogSize
            minProtocol
            openFirewall
            serverRole
            serverString
            shares
            socketOptions
            useSendfile
            workgroup
            ;

          boolYN = b: if b then "yes" else "no";

          # INI atoms may be bool/int/float/null; formats.ini renders those without
          # newlines. List values are spliced element-by-element into the value, so
          # recurse into them — their string elements are emitted verbatim.
          hasNewline =
            v:
            if builtins.isList v then
              builtins.any hasNewline v
            else
              builtins.isString v && builtins.match ".*[\r\n].*" v != null;

          mkShare = share: {
            name = share.name;
            value = {
              "path" = share.path;
              "browseable" = boolYN share.browseable;
              "read only" = boolYN share.readOnly;
              "guest ok" = boolYN share.guestOk;
              "create mask" = share.createMask;
              "directory mask" = share.directoryMask;
            }
            // optionalAttrs (share.comment != "") { "comment" = share.comment; }
            // optionalAttrs (share.forceUser != "") { "force user" = share.forceUser; }
            // optionalAttrs (share.forceGroup != "") { "force group" = share.forceGroup; }
            // optionalAttrs (share.validUsers != [ ]) {
              "valid users" = concatStringsSep " " share.validUsers;
            }
            // optionalAttrs (share.writeList != [ ]) {
              "write list" = concatStringsSep " " share.writeList;
            }
            // share.extraSettings;
          };

          shareSettings = listToAttrs (map mkShare shares);

          globalSettings = {
            "workgroup" = workgroup;
            "server string" = serverString;
            "server role" = serverRole;
            "map to guest" = mapToGuest;
            "guest account" = guestAccount;
            "min protocol" = minProtocol;
            "use sendfile" = boolYN useSendfile;
            "aio read size" = toString aioReadSize;
            "aio write size" = toString aioWriteSize;
            "socket options" = socketOptions;
            "log file" = logFile;
            "max log size" = toString maxLogSize;
          }
          // extraGlobalSettings;
        in
        {
          assertions = concatLists [
            (map (s: {
              assertion = s.name != "" && s.path != "";
              message = "icedos.hardware.network.samba.shares: 'name' and 'path' must be non-empty for every share.";
            }) shares)
            (map (s: {
              assertion = builtins.match "^[A-Za-z0-9 _.-]+$" s.name != null && lib.toLower s.name != "global";
              message = "icedos.hardware.network.samba.shares: share name '${s.name}' is not a valid smb.conf section name (allowed: letters, digits, spaces, '_', '.', '-'; 'global' is reserved).";
            }) shares)
            (map (s: {
              assertion =
                !(builtins.any (f: hasNewline f) (
                  [
                    s.path
                    s.comment
                    s.forceUser
                    s.forceGroup
                  ]
                  ++ s.validUsers
                  ++ s.writeList
                ));
              message = "icedos.hardware.network.samba.shares: a field of share '${s.name}' contains a newline, which would inject extra smb.conf directives.";
            }) shares)
            (map (s: {
              assertion =
                !(builtins.any (k: hasNewline k || hasNewline s.extraSettings.${k}) (
                  builtins.attrNames s.extraSettings
                ));
              message = "icedos.hardware.network.samba.shares: share '${s.name}' has a key or value in extraSettings containing a newline, which would inject extra smb.conf directives.";
            }) shares)
            (
              let
                flatKeys = builtins.attrNames extraGlobalSettings;
                flatVals = builtins.attrValues extraGlobalSettings;
              in
              [
                {
                  assertion =
                    !(builtins.any (k: hasNewline k) flatKeys) && !(builtins.any (v: hasNewline v) flatVals);
                  message = "icedos.hardware.network.samba.extraGlobalSettings: a key or value contains a newline, which would inject extra smb.conf directives.";
                }
              ]
            )
          ];

          services.samba = {
            inherit openFirewall;

            enable = true;
            nmbd.enable = enableNmbd;
            settings = {
              global = globalSettings;
            }
            // shareSettings;
          };

          services.samba-wsdd = mkIf enableWsdd {
            inherit openFirewall;

            enable = true;
          };
        }
      )
    ];

  meta.name = "samba";
}
