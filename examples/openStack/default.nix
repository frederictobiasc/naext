# Appliance Image-specific configuration for the openStack example
let
  pkgs = import <nixpkgs> { };
  outputs = import ../../nix/outputs.nix { inherit pkgs; };
in
{
  appliance =
    (pkgs.nixos [
      ./appliance.nix
      ./extensionImage.nix
      outputs.nixosModules.default
    ]).image;
  extensionImage =
    (pkgs.nixos [
      ./extensionImage.nix
      outputs.nixosModules.default
    ]).config.naext.extensions."hello".image;
  test = pkgs.testers.runNixOSTest {
    imports = [
      ./test.nix
    ];
    interactive.defaults = ../../nix/tests/interactive.nix;
    extraBaseModules = {
      imports = [ outputs.nixosModules.default ];
    };
  };
}
