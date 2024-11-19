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
      extraBaseModules = {
        imports = builtins.attrValues nixosModules;
      };
    };
in
{
  basic = runNixosTest ./basic.nix;

}
// heavyTests
