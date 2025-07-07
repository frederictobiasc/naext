# In difference to the basic test, this builds a standalone image. This is necessary since the /nix/store is
# extended. This failes with the testing driver's default setup relying on mounting the hosts /nix/store
# 1. Copy confext created with naext into confext search path
# 1. Copy sysext created with naext into sysext search path
# 2. systemd-confext refresh
# 3. Assert that the confext has been activated and the provided file has the expected content
{
  pkgs,
  lib,
  ...
}:

let
  inherit (pkgs.stdenv.hostPlatform) efiArch;
in
{
  name = "confext-appliance";
  nodes = {
    machine =
      { config, modulesPath, ... }:
      {
        imports = [ "${modulesPath}/image/repart.nix" ];

        virtualisation = {
          directBoot.enable = false;
          mountHostNixStore = false;
          useEFIBoot = true;
        };

        boot.loader.grub.enable = false;

        fileSystems."/".device = "/dev/disk/by-label/nixos";

        image.repart = {
          name = "image";
          partitions = {
            "esp" = {
              contents = {
                # Necessary for the image to boot
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

        naext = {
          seed = "12345678-1234-1234-1234-123456789123";
          extensions = {
            test-confext = {
              extensionType = "confext";
              imageFormat = "raw";
              files = {
                "/etc/test".source = pkgs.writeText "example" ''Hello'';
              };
            };
            test-sysext = {
              extensionType = "sysext";
              imageFormat = "raw";
              files = {
                "/usr/bin/cowsay".source = pkgs.cowsay;
                "/nix/store/figlet".source = pkgs.figlet;
              };
            };
          };
        };
      };
  };
  testScript =
    { nodes, ... }:
    let
      confext = nodes.machine.naext.extensions.test-confext;
      sysext = nodes.machine.naext.extensions.test-sysext;
    in
    # python
    ''
      import os
      import subprocess
      import tempfile

      # Boilerplate for running appliance images

      tmp_disk_image = tempfile.NamedTemporaryFile()

      subprocess.run([
        "${nodes.machine.virtualisation.qemu.package}/bin/qemu-img",
        "create",
        "-f",
        "qcow2",
        "-b",
        "${nodes.machine.system.build.image}/${nodes.machine.image.repart.imageFile}",
        "-F",
        "raw",
        tmp_disk_image.name,
      ])

      # Set NIX_DISK_IMAGE so that the qemu script finds the right disk image.
      os.environ['NIX_DISK_IMAGE'] = tmp_disk_image.name

      machine.wait_for_unit("multi-user.target")

      machine.copy_from_host("${confext.image}", "/var/lib/confexts/${confext.name}.${confext.extensionType}.raw")
      machine.copy_from_host("${sysext.image}", "/var/lib/extensions/${sysext.name}.${sysext.extensionType}.raw")
      # Make sure sshd key generation finished before extension images render FS immutable
      machine.wait_for_unit("multi-user.target")
      machine.succeed("systemd-confext refresh")
      # By default, extending the /nix hierarchy is not allowed. This can be overwritten.
      machine.succeed("SYSTEMD_SYSEXT_HIERARCHIES=\"/usr/:/opt/:/nix/\" systemd-sysext refresh")

      # Checks only for presence for now
      figletBin = "/nix/store/figlet/bin/figlet"
      machine.wait_for_file(figletBin)

      cowsayBin = "/usr/bin/cowsay/bin/cowsay"
      machine.wait_for_file(cowsayBin)

      machine.wait_for_file("/etc/test")
      content=machine.succeed("cat /etc/test")
      assert content=="Hello", "File provided by confext has expected content"
    '';
}
