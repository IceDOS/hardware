{ icedosLib, ... }:

{
  options.icedos.hardware.monitors =
    let
      inherit (icedosLib)
        mkBoolOption
        mkNumberOption
        mkStrOption
        mkSubmoduleListOption
        ;
    in
    mkSubmoduleListOption { default = [ ]; } {
      name = mkStrOption { };
      disable = mkBoolOption { default = false; };
      resolution = mkStrOption { };
      refreshRate = mkNumberOption { };
      position = mkStrOption { };
      scaling = mkNumberOption { default = 1; };
      rotation = mkNumberOption { default = 0; };
      tenBit = mkBoolOption { default = false; };
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
            concatMapStrings
            filter
            genList
            hasAttr
            imap
            length
            mapAttrs
            mkIf
            optionals
            ;

          getMonitorRotation =
            m:
            if (m.name == "eDP-1" && cfg.hardware.devices.steamdeck) then
              ",transform,3"
            else
              ",transform,${toString m.rotation}";

          workspaceBinds =
            bind: command:
            (concatLists (
              imap (
                i: _:
                genList (
                  w:
                  let
                    cw = toString ((w + 1) + ((i - 1) * 10));
                    cb = if (w == 9) then "0" else "${toString (w + 1)}";

                    extraBind =
                      if (i == 4) then
                        "CTRL ALT"
                      else if (i == 3) then
                        "ALT"
                      else if (i == 2) then
                        "CTRL"
                      else
                        "";
                  in
                  if (i < 5) then "$mainMod ${bind} ${extraBind},${cb},${command},${cw}" else ""
                ) 10
              ) (filter (m: !m.disable) monitors)
            ));

          cfg = config.icedos;
          monitors = cfg.hardware.monitors;
          noMonitors = length monitors == 0;
          hasHyprland = hasAttr "hyprland" cfg.desktop;
        in
        {
          boot.kernelParams =
            [ ]
            ++ optionals (!noMonitors) [
              (concatMapStrings (
                m:
                let
                  name = m.name;
                  resolution = m.resolution;
                  bitDepth = if (m.tenBit) then "-30" else "";
                  refreshRate = toString (m.refreshRate);
                  rotation = toString (m.rotation);
                in
                "video=${name}:${resolution}${bitDepth}@${refreshRate},rotate=${rotation}"
              ) monitors)
            ];

          home-manager.users = mapAttrs (user: _: {
            wayland.windowManager.hyprland = mkIf hasHyprland {
              settings = {
                bind = [ ] ++ workspaceBinds "" "workspace" ++ workspaceBinds "SHIFT" "movetoworkspace";

                monitor = (
                  map (
                    m:
                    let
                      name = m.name;
                      resolution = m.resolution;
                      refreshRate = toString (m.refreshRate);
                      position = toString (m.position);
                      scaling = toString (m.scaling);
                      rotation = getMonitorRotation m;
                      bitDepth = if (m.tenBit) then ",bitdepth,10" else "";
                    in
                    if (m.disable) then
                      "${name},disable"
                    else
                      "${name},${resolution}@${refreshRate},${position},${scaling}${rotation}${bitDepth}"
                  ) monitors
                );

                workspace = (
                  concatLists (
                    imap (
                      i: m:
                      let
                        name = m.name;
                      in
                      genList (
                        w:
                        let
                          cw = toString ((w + 1) + ((i - 1) * 10));
                          default = if (w == 0) then ",default:true" else "";
                        in
                        "${cw},monitor:${name}${default}"
                      ) 10
                    ) (filter (m: !m.disable) monitors)
                  )
                );
              };
            };
          }) cfg.users;
        }
      )
    ];

  meta.name = "monitors";
}
