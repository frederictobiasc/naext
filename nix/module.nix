{
  config,
  lib,
  options,
  pkgs,
  ...
}:
let
  mkExt = pkgs.callPackage ./lib/mkExt.nix { };

  # Allowed root paths for each extension type
  pathMappings = {
    sysext = "/opt";
    confext = "/etc";
  };

  # Helper function to fetch the permitted root path for a given extension type
  getPathPrefix =
    extensionType:
    let
      default = throw "[naext] Unsupported extension type '${extensionType}'";
    in
    lib.attrByPath [ extensionType ] default pathMappings;

  # Ensures a string starts with a given prefix. Otherwise, throw an error.
  ensurePrefix =
    prefix: str:
    if lib.strings.hasPrefix prefix str then
      str
    else
      throw "[naext] The string '${str}' must start with '${prefix}'";

  # Helper function to format extension release metadata.
  createExtensionReleaseFile = name: ''
    mkdir -p $out/etc/extension-release.d

    cat >$out/etc/extension-release.d/extension-release.${name} <<EOF
    ID=nixos
    VERSION_ID="24.11"
    CONFEXT_SCOPE=system initrd
    EOF
  '';

  # Create the tree for an extension image
  mkExtTree =
    type: files: name:
    pkgs.runCommand "tree" { } ''
      set -euo pipefail

      ${createExtensionReleaseFile name}

      mkFile() {
        src="$1"
        target="$2"

        if [[ "$src" = *'*'* ]]; then
          # If the source name contains '*', perform globbing.
          mkdir -p "$out/$target"
          for fn in $src; do
              cp -rL "$fn" "$out/$target/"
          done
        else
          mkdir -p "$out/$(dirname "$target")"
          if ! [ -e "$out/$target" ]; then
            cp -rL "$src" "$out/$target"
          else
            echo "duplicate entry $target -> $src"
            if [ "$(readlink "$out/$target")" != "$src" ]; then
              echo "mismatched duplicate entry $(readlink "$out/$target") <-> $src"
              ret=1
              continue
            fi
          fi
        fi
      }

      ${lib.concatMapStringsSep "\n" (
        fileEntry:
        lib.escapeShellArgs [
          "mkFile"
          # Force local source paths to be added to the store
          "${fileEntry.source}"
          (ensurePrefix (getPathPrefix type) fileEntry.target)
        ]
      ) (lib.attrValues files)}
    '';

  fileSubmodule = lib.types.submodule (
    {
      name,
      config,
      options,
      ...
    }:
    {
      options = {
        target = lib.mkOption {
          type = lib.types.str;
          description = "File target relative to the extension image's root";
        };
        source = lib.mkOption {
          type = lib.types.path;
          description = "Path of the source file";
        };
      };
      config.target = lib.mkDefault name;
    }
  );

  cfg = config.naext;
in
{
  options.naext = {
    privateKey = lib.mkOption {
      description = "Signing key to use for the verity signature";
      type = lib.types.path;
    };
    certificate = lib.mkOption {
      description = "PEM encoded X.509 certificate to create the verity signature";
      type = lib.types.path;
    };
    seed = lib.mkOption {
      description = "Used to derive UUIDs to assign to partitions and the partition table. Takes a UUID as argument or the special value random.";
      example = "12345678-1234-1234-1234-123456789123";
      type = lib.types.str;
    };
    extensions = lib.mkOption {
      description = "Extension Image";
      type = lib.types.attrsOf (
        lib.types.submodule (
          {
            name,
            config,
            options,
            ...
          }:
          {
            options = {
              extensionType = lib.mkOption {
                description = "Extension Image Type";
                type = lib.types.enum [
                  "sysext"
                  "confext"
                ];
              };
              imageFormat = lib.mkOption {
                description = "Extension Image Type";
                type = lib.types.enum [
                  "verity" # verity-protected raw erofs image
                  "raw" # raw erofs image
                ];
              };
              extension-release = lib.mkOption {
                description = "Contents of the Extension Release file.";
                type = lib.types.lines;
                default = ''
                  ID=nixos
                  VERSION_ID="24.11"
                  CONFEXT_SCOPE=system initrd
                '';
                example = lib.literalExpression ''
                  ID=nixos
                  VERSION_ID="24.11"
                  CONFEXT_SCOPE=system initrd
                '';
              };
              files = lib.mkOption {
                description = "Extension Image Files";
                type = lib.types.attrsOf fileSubmodule;
                default = { };
              };
              image = lib.mkOption {
                readOnly = true;
                description = "Resulting Extension Image";
                type = lib.types.package;
              };
              json = lib.mkOption {
                readOnly = true;
                description = "JSON description of the resulting Extension Image";
                type = lib.types.package;
              };
              name = lib.mkOption {
                description = "Name of the Extension Image";
                type = lib.types.str;
              };
            };
            config = {

              name = lib.mkDefault name;
              json = pkgs.writeText "json" (builtins.toJSON (lib.attrValues cfg.extensions."${name}".files));

              image =
                let
                  # The configuration of the current extension we're dealing with.
                  self = cfg.extensions."${name}";
                  # Add the extension-release to the files.
                  mergedFiles = self.files // {
                    "/etc/extension-release.d/extension-release.${name}" = {
                      source = self.extension-release;
                      target = "/etc/extension-release.d/extension-release.${name}";
                    };
                  };
                  # The tree to create the extension image from.
                  tree = mkExtTree self.extensionType mergedFiles self.name;
                  # Determin the function to use for creating the extension image.
                  mkExtMethod =
                    if self.imageFormat == "verity" then
                      mkExt.verity
                    else if self.imageFormat == "raw" then
                      mkExt.raw
                    else
                      abort "[naext] `imageFormat` has a wrong value defined.";
                in
                mkExtMethod {
                  inherit name;
                  ddiType = cfg.extensions."${name}".extensionType;
                  sourceTree = tree;
                  inherit (cfg) certificate privateKey seed;
                };
            };
          }
        )
      );
    };
  };
}
