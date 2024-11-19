{
  pkgs,
  ...
}:
rec {
  nixosModules = {
    default = import ./module.nix;
    dm-verity = import ./dm-verity.nix;
  };
  checks.tests = import ./tests {
    inherit nixosModules pkgs;
  };
}
