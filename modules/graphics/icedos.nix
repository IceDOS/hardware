{ ... }:

{
  outputs.nixosModules =
    { ... }:
    [
      {
        hardware.graphics = {
          enable = true;
          enable32Bit = true;
        };

        environment.sessionVariables = {
          MESA_SHADER_CACHE_MAX_SIZE = "16G";
        };
      }
    ];

  meta = {
    name = "graphics";

    dependencies = [
      {
        modules = [ "mesa" ];
      }
    ];
  };
}
