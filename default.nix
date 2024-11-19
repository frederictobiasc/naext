{
  system ? builtins.currentSystem,
}:
let
  sources = import ./nix/sources.nix;
  pkgs = import sources.nixpkgs {
    inherit system;
    config.allowAliases = false;
  };
  outputs = import ./nix/outputs.nix { inherit pkgs; };
in
{
  inherit (outputs) checks;
}
