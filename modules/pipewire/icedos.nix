{ icedosLib, lib, ... }:

{
  options.icedos.hardware.pipewire.noiseCancellation =
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

      vadThreshold = mkNumberOption { default = vadThreshold; };
      vadGracePeriod = mkNumberOption { default = vadGracePeriod; };
      retroactiveVadGrace = mkNumberOption { default = retroactiveVadGrace; };
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
            mapAttrs
            mkIf
            ;

          inherit (config.icedos.hardware.pipewire) noiseCancellation;

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
            };

            pulseaudio.enable = false;
          };

          # Enable service which hands out realtime scheduling priority to user processes on demand
          security.rtkit.enable = true;

          environment.systemPackages = with pkgs; [ pwvucontrol ];

          icedos.applications.toolset.commands = [
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

          home-manager.users = mapAttrs (
            user: _:
            mkIf noiseCancellation.enable {
              home.file.".config/pipewire/pipewire.conf.d/99-input-denoising.conf".text = ''
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
            }
          ) config.icedos.users;
        }
      )
    ];

  meta.name = "pipewire";
}
