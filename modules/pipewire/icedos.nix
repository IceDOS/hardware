{ icedosLib, lib, ... }:

{
  options.icedos.hardware.pipewire = {
    echoCancellation =
      let
        inherit (icedosLib) mkBoolOption;

        inherit
          (
            let
              inherit (lib) readFile;
            in
            (fromTOML (readFile ./config.toml)).icedos.hardware.pipewire.echoCancellation
          )
          enable
          ;
      in
      {
        enable = mkBoolOption { default = enable; };
      };

    noiseCancellation =
      let
        inherit (icedosLib) mkBoolOption mkNumberOption;

        inherit
          (
            let
              inherit (lib) readFile;
            in
            (fromTOML (readFile ./config.toml)).icedos.hardware.pipewire.noiseCancellation
          )
          enable
          dynamic
          mono
          vadThreshold
          vadGracePeriod
          retroactiveVadGrace
          ;
      in
      {
        enable = mkBoolOption { default = enable; };
        dynamic = mkBoolOption { default = dynamic; };
        mono = mkBoolOption { default = mono; };
        retroactiveVadGrace = mkNumberOption { default = retroactiveVadGrace; };
        vadGracePeriod = mkNumberOption { default = vadGracePeriod; };
        vadThreshold = mkNumberOption { default = vadThreshold; };
      };
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
          inherit (lib) mkIf optional;
          inherit (config.icedos.hardware.pipewire) echoCancellation noiseCancellation;

          inherit (noiseCancellation)
            dynamic
            mono
            vadThreshold
            vadGracePeriod
            retroactiveVadGrace
            ;

          wpctl = "${pkgs.wireplumber}/bin/wpctl";
          awk = "${pkgs.gawk}/bin/awk";

          listIds = kind: ''
            ${wpctl} status | ${awk} -v section="${kind}:" '
              $0 ~ section { in_s = 1; next }
              in_s && /^ ├─|^ └─/ { in_s = 0 }
              in_s && match($0, /[0-9]+\./) {
                print substr($0, RSTART, RLENGTH - 1)
              }
            '
          '';

          toggleAllBody = kind: ''
            is_muted() { ${wpctl} get-volume "$1" 2>/dev/null | grep -q '\[MUTED\]'; }
            ids=$(${listIds kind})
            [ -z "$ids" ] && exit 0
            any_unmuted=0
            for id in $ids; do
              if ! is_muted "$id"; then any_unmuted=1; break; fi
            done
            if [ "$any_unmuted" = "1" ]; then target=1; else target=0; fi
            for id in $ids; do ${wpctl} set-mute "$id" "$target"; done
          '';
        in
        {
          services = {
            pipewire = {
              enable = true;
              alsa.enable = true;
              alsa.support32Bit = true;
              extraLadspaPackages = [ pkgs.rnnoise-plugin ];
              pulse.enable = true;

              extraConfig.pipewire = mkIf echoCancellation.enable {
                "99-echo-cancel" = {
                  "context.modules" = [
                    {
                      name = "libpipewire-module-echo-cancel";
                      args = {
                        "monitor.mode" = true;
                        "audio.rate" = 48000;
                        "audio.channels" = 2;
                        "audio.position" = [
                          "FL"
                          "FR"
                        ];
                        "node.latency" = "1024/48000";

                        "capture.props" = {
                          "node.passive" = true;
                        };

                        "source.props" = {
                          "node.name" = "echo-cancel-source";
                          "node.description" = "Echo Cancelled Microphone";
                          "priority.session" = 2500;
                          "priority.driver" = 2500;
                        };

                        "aec.args" = { };
                      };
                    }
                  ];
                };
              };
            };

            pulseaudio.enable = false;
          };

          # Enable service which hands out realtime scheduling priority to user processes on demand
          security.rtkit.enable = true;

          environment.systemPackages = with pkgs; [ pwvucontrol ];

          icedos.system.toolset.commands = [
            {
              command = "pipewire";
              help = "pipewire audio controls";
              commands = [
                {
                  command = "toggle-mute-default-input";
                  script = "${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle";
                  help = "toggle mute on default microphone";
                }
                {
                  command = "toggle-mute-default-output";
                  script = "${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle";
                  help = "toggle mute on default speaker";
                }
                {
                  command = "toggle-mute-default";
                  script = ''
                    ${wpctl} set-mute @DEFAULT_AUDIO_SOURCE@ toggle
                    ${wpctl} set-mute @DEFAULT_AUDIO_SINK@ toggle
                  '';
                  help = "toggle mute on default microphone and speaker";
                }
                {
                  command = "toggle-mute-all-inputs";
                  script = toggleAllBody "Sources";
                  help = "toggle mute on all microphones";
                }
                {
                  command = "toggle-mute-all-outputs";
                  script = toggleAllBody "Sinks";
                  help = "toggle mute on all speakers";
                }
                {
                  command = "toggle-mute-all";
                  script = ''
                    ${toggleAllBody "Sources"}
                    ${toggleAllBody "Sinks"}
                  '';
                  help = "toggle mute on all microphones and speakers";
                }
              ];
            }
          ];

          home-manager.sharedModules = optional noiseCancellation.enable {
            xdg.configFile."pipewire/pipewire.conf.d/99-input-denoising.conf".text = ''
              context.modules = [
                {
                  name = libpipewire-module-filter-chain
                  args = {
                    filter.graph = {
                      nodes = [
                        {
                          type = ladspa
                          name = rnnoise
                          plugin = librnnoise_ladspa
                          label = ${if mono then "noise_suppressor_mono" else "noise_suppressor_stereo"}
                          control = {
                            "VAD Threshold (%)" ${toString vadThreshold}
                            "VAD Grace Period (ms)" ${toString vadGracePeriod}
                            "Retroactive VAD Grace (ms)" ${toString retroactiveVadGrace}
                          }
                        }
                      ]
                    }
                    capture.props = {
                      node.name =  "rnnoise_input.capture"
                      node.passive = true
                      audio.rate = 48000
                    }
                    playback.props = {
                      node.name =  "rnnoise"
                      media.class = Audio/Source
                      audio.rate = 48000
                      ${
                        if dynamic then
                          ''
                            filter.smart = true
                            filter.smart.name =  "rnnoise-input"
                          ''
                        else
                          ''
                            node.description =  "RNNoise"
                          ''
                      }
                    }
                  }
                }
              ]
            '';
          };
        }
      )
    ];

  meta.name = "pipewire";
}
