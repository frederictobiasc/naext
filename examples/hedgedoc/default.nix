{ pkgs, naextModule }:
{
  appliance =
    (pkgs.nixos [
      ./appliance.nix
      ./config.nix
    ]).image;

  extensionImage =
    (pkgs.nixos [
      ./extensionImage.nix
      naextModule
    ]).config.naext.extensions."hedgedoc".image;

  test = pkgs.testers.runNixOSTest {
    imports = [
      ./test.nix
    ];
    interactive.defaults = ../../nix/tests/interactive.nix;
    extraBaseModules = {
      imports = [ naextModule ];
    };
  };
}
