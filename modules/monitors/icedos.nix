{ icedosLib, lib, ... }:

{
  options.icedos.hardware.monitors =
    let
      inherit (icedosLib)
        mkBoolOption
        mkNumberOption
        mkStrOption
        mkSubmoduleListOption
        ;

      inherit (lib) head readFile;

      inherit (head (fromTOML (readFile ./config.toml)).icedos.hardware.monitors)
        disable
        overclock
        rotation
        scaling
        tenBit
        ;
    in
    mkSubmoduleListOption { default = [ ]; } {
      disable = mkBoolOption { default = disable; };
      name = mkStrOption { };
      overclock = mkBoolOption { default = overclock; };
      position = mkStrOption { };
      refreshRate = mkNumberOption { };
      resolution = mkStrOption { };
      rotation = mkNumberOption { default = rotation; };
      scaling = mkNumberOption { default = scaling; };
      tenBit = mkBoolOption { default = tenBit; };
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
          inherit (lib)
            concatLists
            concatMapStrings
            elemAt
            filter
            genList
            hasAttr
            imap
            length
            listToAttrs
            mkIf
            optionals
            splitString
            toInt
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
                    cb = if (w == 9) then "0" else toString (w + 1);

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
          ocMonitors = filter (m: !m.disable && m.overclock) monitors;
          ocKey = m: "${m.name}_oc";

          mkModeline =
            m:
            let
              parts = splitString "x" m.resolution;
              w = toInt (elemAt parts 0);
              h = toInt (elemAt parts 1);
              hz = m.refreshRate;
              rb = if (hz / 60) * 60 == hz then "-r " else "";
              drv =
                pkgs.runCommand "modeline-${m.name}-${toString w}x${toString h}-${toString hz}"
                  {
                    nativeBuildInputs = [ pkgs.libxcvt ];
                  }
                  ''
                    cvt ${rb}${toString w} ${toString h} ${toString hz} \
                      | awk '/^Modeline/ { sub(/^Modeline +"[^"]*"[[:space:]]+/, ""); printf "%s", $0; exit }' \
                      > $out
                  '';
              raw = builtins.readFile drv;
              pclkMHz = toInt (elemAt (splitString "." (elemAt (splitString " " raw) 0)) 0);
            in
            if pclkMHz > 655 then
              throw "icedos.hardware.monitors.${m.name}: pixel clock ${toString pclkMHz} MHz for ${m.resolution}@${toString hz}Hz exceeds the 655.35 MHz EDID 1.4 detailed-timing limit. Lower refreshRate, or pick a 60Hz multiple (60/120/240) so reduced-blanking applies."
            else
              raw;
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

          hardware.display = mkIf (ocMonitors != [ ]) {
            edid.enable = true;

            edid.modelines = listToAttrs (
              map (m: {
                name = ocKey m;
                value = mkModeline m;
              }) ocMonitors
            );

            outputs = listToAttrs (
              map (m: {
                name = m.name;
                value = {
                  edid = "${ocKey m}.bin";
                };
              }) ocMonitors
            );
          };

          home-manager.sharedModules = [
            {
              wayland.windowManager.hyprland = mkIf hasHyprland {
                settings = {
                  bind = workspaceBinds "" "workspace" ++ workspaceBinds "SHIFT" "movetoworkspace";

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
            }
          ];
        }
      )
    ];

  meta.name = "monitors";
}
