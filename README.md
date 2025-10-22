# naext: Nix Appliance Extension Tools

Extending Appliance Images.

NixOS allows for building [Appliance Images](https://nixos.org/manual/nixos/unstable/#sec-image-repart-appliance). Since Appliance Images are immutable they typically contain everything necessary to make use of such an image.

## Problem

Appliances are usually built generically. To be useful an appliance is augmented with specifics (think of configuration, programs) for a certain use case.

## Solution

This project offers solutions to extend immutable appliances in a lightweight manner leveraging technologies provided by systemd and the kernel.

### `naext` Module

Allows for building extension images (`sysext`, `confext`).

#### Example

Create a confext image that provides the file `/etc/test` containing `Hello`.

```nix
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
```

## Tour

Check out:

- [Build an Appliance for OpenStack with discovery mechanism (pull)](./examples/openstack) with `nix build .#packages.x86_64-linux.openstackExampleAppliance`
- [Build a Hedgedoc Appliance that expects it's extension image to be pushed](./nix/tests/basic.nix) with `nix build .#packages.x86_64-linux.hedgedocExampleAppliance`
- [Basic Integration Test](./nix/tests/basic.nix)
