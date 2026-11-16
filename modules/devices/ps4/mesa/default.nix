final: prev: {
  mesa-ps4 = prev.mesa.overrideAttrs (old: {
    patches = (old.patches or [ ]) ++ [
      ./patches/0001-ps4-liverpool-gladius.patch
      ./patches/0002-radv-ps4-no-hiz.patch
      ./patches/0003-aco-ps4-no-flat-global.patch
    ];
  });
}
