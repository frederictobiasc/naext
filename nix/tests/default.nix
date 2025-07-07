{
  pkgs,
  nixosModules,
  enableHeavyTests ? true,
}:
let
  # Those tests require recompiling large components like the kernel. Therefore we currently
  #  disable them in places like the check attribute of the flake.
  heavyTests =
    if enableHeavyTests then
      {
        dm-verity = runNixosTest ./dm-verity.nix;
      }
    else
      { };

  runNixosTest =
    module:
    pkgs.testers.runNixOSTest {
      imports = [
        module
      ];
      interactive.defaults = ./interactive.nix;
      extraBaseModules = {
        imports = builtins.attrValues nixosModules;
      };
    };
in
{
  appliance = runNixosTest ./appliance.nix;
  basic = runNixosTest ./basic.nix;
  with-importctl = runNixosTest ./with-importctl.nix;
}
// heavyTests
