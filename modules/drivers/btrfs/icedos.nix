{ ... }:

{
  outputs = {
    nixosModules =
      { ... }:
      [
        (
          {
            icedosLib,
            pkgs,
            ...
          }:

          let
            inherit (icedosLib.bash) genHelpFlags;
          in
          {
            icedos.system.toolset.commands = [
              {
                command = "btrfs-zstd";

                script = ''
                  if [[ ${genHelpFlags { }} ]]; then
                    die "specify path as an argument"
                  fi

                  sudo "${pkgs.btrfs-progs}/bin/btrfs" filesystem defrag -czstd -r -v "$@"
                '';

                help = "compress btrfs path using zstd";

                completion.files = true;
              }
            ];

            icedos.system.tips.list = [
              "icedos btrfs-zstd <folder> compresses files on a btrfs drive to free up space."
            ];
          }
        )
      ];
  };

  meta.name = "btrfs";
}
