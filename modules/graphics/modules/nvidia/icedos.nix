{ icedosLib, lib, ... }:
{
  options.icedos.hardware.graphics.nvidia =
    let
      inherit (icedosLib) mkBoolOption mkNumberOption;
      inherit (lib) readFile;

      inherit ((fromTOML (readFile ./config.toml)).icedos.hardware.graphics.nvidia)
        beta
        cuda
        openDrivers
        powerLimit
        ;
    in
    {
      beta = mkBoolOption { default = beta; };
      cuda = mkBoolOption { default = cuda; };
      openDrivers = mkBoolOption { default = openDrivers; };

      powerLimit =
        let
          inherit (powerLimit) enable value;
        in
        {
          enable = mkBoolOption { default = enable; };
          value = mkNumberOption { default = value; };
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
          inherit (lib) mkIf;
          cfg = config.icedos;
          hardware = cfg.hardware;
          graphics = hardware.graphics;
          powerLimit = graphics.nvidia.powerLimit;
          nvidia_x11 = config.boot.kernelPackages.nvidia_x11.bin;
        in
        {
          services.xserver.videoDrivers = [ "nvidia" ]; # Install the nvidia drivers

          hardware.nvidia = {
            modesetting.enable = true;
            open = graphics.nvidia.openDrivers;

            package =
              if (graphics.nvidia.beta) then
                config.boot.kernelPackages.nvidiaPackages.beta
              else
                config.boot.kernelPackages.nvidiaPackages.stable;

            prime = mkIf (cfg.hardware.devices.laptop) {
              offload.enable = true;
              intelBusId = "PCI:0:2:0";
              nvidiaBusId = "PCI:1:0:0";
            };
          };

          # Enable nvidia gpu acceleration for containers
          hardware.nvidia-container-toolkit.enable =
            let
              inherit (lib) hasAttr;
              applications = cfg.applications;
            in
            (hasAttr "docker" applications || hasAttr "podman" applications);

          icedos.applications.toolset.commands = mkIf (cfg.hardware.devices.laptop) [
            {
              command = "force-nvidia";

              script = ''
                export __NV_PRIME_RENDER_OFFLOAD=1
                export __NV_PRIME_RENDER_OFFLOAD_PROVIDER=NVIDIA-G0
                export __GLX_VENDOR_LIBRARY_NAME=nvidia
                export __VK_LAYER_NV_optimus=NVIDIA_only
                exec "$@"
              '';

              help = "forces command to use nvidia gpu";
            }
          ];

          nixpkgs.config.cudaSupport = graphics.nvidia.cuda;

          # Set nvidia gpu power limit
          systemd.services.nv-power-limit = mkIf (powerLimit.enable) {
            enable = true;
            description = "Nvidia power limit control";
            after = [
              "syslog.target"
              "systemd-modules-load.service"
            ];

            unitConfig = {
              ConditionPathExists = "${nvidia_x11}/bin/nvidia-smi";
            };

            serviceConfig = {
              User = "root";
              ExecStart = "${nvidia_x11}/bin/nvidia-smi --power-limit=${toString (powerLimit.value)}";
            };

            wantedBy = [ "multi-user.target" ];
          };
        }
      )
    ];

  meta = {
    name = "nvidia";

    dependencies = [
      {
        modules = [ "graphics" ];
      }
    ];
  };
}
