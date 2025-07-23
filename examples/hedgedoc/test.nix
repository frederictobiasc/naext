# The integration test for the hedgedoc example

{
  lib,
  ...
}:
{
  name = "hedgedoc";
  nodes = {
    hedgedoc = _: {
      imports = [
        ./config.nix
        ./extensionImage.nix
      ];
      # Not relevant for the test
      services.cloud-init.enable = lib.mkForce false;
    };
  };
  testScript =
    { nodes, ... }:
    # python
    ''
      start_all()

      # Load and activate hedgedoc settings extension
      hedgedoc.copy_from_host("${nodes.hedgedoc.naext.extensions.hedgedoc.image}", "/run/confexts/hedgedoc.confext.raw")
      hedgedoc.succeed("systemd-confext merge")

      hedgedoc.wait_for_unit("hedgedoc.service")
      content = hedgedoc.wait_until_succeeds("curl -f localhost:3000")
      assert "HedgeDoc" in content, "HedgeDoc seems running"
    '';
}
