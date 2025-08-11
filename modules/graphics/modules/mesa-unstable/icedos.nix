{ icedosLib, ... }:

{
  options.icedos.hardware.graphics.mesa-unstable = icedosLib.mkBoolOption { default = true; };

  outputs.nixosModules =
    { ... }:
    [
      {
        chaotic.mesa-git.enable = true;
      }
    ];

  meta = {
    name = "mesa-unstable";
    depends = [ "graphics" ]; # TODO implement dependencies
  };
}
