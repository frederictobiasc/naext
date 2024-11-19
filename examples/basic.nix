{
  system ? builtins.currentSystem,
}:
let
  sources = import ../nix/sources.nix;
  pkgs = import sources.nixpkgs {
    inherit system;
    config.allowAliases = false;
  };
  outputs = import ../nix/outputs.nix { inherit pkgs; };
in
(pkgs.lib.evalModules {
  modules = [
    outputs.nixosModules.default
    (_: {
      naext = {
        seed = "12345678-1234-1234-1234-123456789123";
        extensions = {
          "hello" = {
            extensionType = "confext";
            imageFormat = "raw";
            files = {
              "/etc/test".source = pkgs.writeText "example" ''Hello'';
            };
          };
        };
      };
    })
  ];
  specialArgs = {
    inherit pkgs;
  };
}).config.naext.extensions."hello".image
