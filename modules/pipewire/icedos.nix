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
          inherit (lib) mapAttrs mkIf;
          inherit (config.icedos.hardware.pipewire) noiseCancellation;

          inherit (noiseCancellation)
            dynamic
            mono
            vadThreshold
            vadGracePeriod
            retroactiveVadGrace
            ;
        in
        {
          services = {
            pipewire = {
              enable = true;
              alsa.enable = true;
              alsa.support32Bit = true;
              pulse.enable = true;
            };

            pulseaudio.enable = false;
          };

          # Enable service which hands out realtime scheduling priority to user processes on demand
          security.rtkit.enable = true;

          environment.systemPackages = with pkgs; [ pwvucontrol ];

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
                            plugin = ${pkgs.rnnoise-plugin}/lib/ladspa/librnnoise_ladspa.so
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
                          if dynamic then ''
                            filter.smart = true
                            filter.smart.name =  "rnnoise-input"
                          '' else ''
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
