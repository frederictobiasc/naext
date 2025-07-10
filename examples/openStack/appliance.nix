# Appliance image-specific configuration for the openStack example
# See https://github.com/NixOS/nixpkgs/blob/fbdf0b99ff76a37e8c8185525495f676a881c572/nixos/doc/manual/installation/building-images-via-systemd-repart.chapter.md
{
  config,
  lib,
  pkgs,
  modulesPath,
  ...
}:
let
  inherit (pkgs.stdenv.hostPlatform) efiArch;
in
{
  boot = {
    initrd = {
      availableKernelModules = [
        "virtio_blk"
        "virtio_rng"
      ];
      systemd = {
        enable = true;
        emergencyAccess = true;
      };
      # Enable support for mounting our root partition.
      supportedFilesystems = {
        ext4 = true;
      };
    };
  };

  boot.loader = {
    grub.enable = lib.mkForce false;
    systemd-boot.enable = lib.mkForce false;
  };

  imports = [ "${modulesPath}/image/repart.nix" ];
  services.openssh.enable = true;
  users.users.root.openssh.authorizedKeys.keys = [
    "ssh-ed25519 AAAAC3NzaC1lZDI1NTE5AAAAIMbdTWamOCcGSsd3w6O86ftuYnAe4I+Xh9RBSskoQi9u istobic@secuprobook-fch"
  ];
  fileSystems."/".device = "/dev/disk/by-label/nixos";
  image.repart = {
    name = "image";
    partitions = {
      "esp" = {
        contents = {
          "/EFI/BOOT/BOOT${lib.toUpper efiArch}.EFI".source =
            "${pkgs.systemd}/lib/systemd/boot/efi/systemd-boot${efiArch}.efi";
          "/EFI/Linux/${config.system.boot.loader.ukiFile}".source =
            "${config.system.build.uki}/${config.system.boot.loader.ukiFile}";
        };
        repartConfig = {
          Type = "esp";
          Format = "vfat";
          SizeMinBytes = "256M";
        };
      };
      "root" = {
        storePaths = [ config.system.build.toplevel ];
        repartConfig = {
          Type = "root";
          Format = "ext4";
          Label = "nixos";
          Minimize = "guess";
        };
      };
    };
  };
}
