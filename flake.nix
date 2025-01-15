{
  description = "Extension Images built with Nix";

  inputs = {
    flake-compat = {
      url = "github:edolstra/flake-compat";
      flake = false;
    };
    flake-parts = {
      url = "github:hercules-ci/flake-parts";
      inputs.nixpkgs-lib.follows = "nixpkgs";
    };
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    pre-commit-hooks-nix = {
      url = "github:cachix/pre-commit-hooks.nix";
      inputs = {
        nixpkgs.follows = "nixpkgs";
        flake-compat.follows = "flake-compat";
      };
    };
    systems.url = "github:nix-systems/default";
  };
  outputs =

    inputs:
    inputs.flake-parts.lib.mkFlake { inherit inputs; } {
      systems = import inputs.systems;
      imports = [ inputs.pre-commit-hooks-nix.flakeModule ];
      flake.nixosModules = {
        dm-verity = import ./nix/dm-verity.nix;
        naext = import ./nix/module.nix;
      };
      perSystem =
        {
          config,
          pkgs,
          ...
        }:
        {
          checks =
            { }
            // (import ./nix/tests {
              inherit (inputs.self) nixosModules;
              inherit pkgs;
              enableHeavyTests = false;
            });

          pre-commit = {
            check.enable = true;
            settings = {
              hooks = {
                nixfmt-rfc-style.enable = true;
                statix.enable = true;
              };
            };
          };
          devShells.default =
            let
              example-basic-mount =
                pkgs.writeShellScriptBin "example-basic-mount" # bash
                  ''
                    partition=p1 # assume the data partition is p1
                    top=$(git rev-parse --show-toplevel)
                    set -eux

                    # Build the example image and mount it as a loop device
                    nix-build $top/examples/basic.nix --out-link $top/result "$@"
                    cp -rL $top/result $top/basic.raw
                    loopdev=$(systemd-dissect --attach $top/basic.raw)

                    # Wait until the data partition becomes available
                    while [ ! -e "''\${loopdev}''\${partition}" ]; do
                      sleep 0.1 # adjust the delay as necessary
                    done

                    # Create the mount point
                    if [ ! -e $top/mnt ]; then
                      mkdir $top/mnt
                    fi
                    mount "''\${loopdev}''\${partition}" $top/mnt
                  '';
              example-basic-umount =
                pkgs.writeShellScriptBin "example-basic-umount" # bash
                  ''
                    top=$(git rev-parse --show-toplevel)
                    set -eux
                    umount $top/mnt
                    systemd-dissect --detach $top/basic.raw
                    rm $top/result $top/basic.raw
                  '';
            in
            pkgs.mkShell {
              shellHook = ''
                ${config.pre-commit.installationScript}
              '';
              packages = with pkgs; [
                example-basic-mount
                example-basic-umount
                nixfmt-rfc-style
                statix
                util-linux
              ];
            };
        };
    };
}
