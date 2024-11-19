# 1. Copy confext created with naext into confext search path
# 2. systemd-confext refresh
# 3. Assert that the confext has been activated and the provided file has the expected content
{
  pkgs,
  ...
}:
{
  name = "confext-basic";
  nodes = {
    machine = _: {
      naext = {
        seed = "12345678-1234-1234-1234-123456789123";
        extensions = {
          test = {
            extensionType = "confext";
            imageFormat = "raw";
            files = {
              "/etc/test".source = pkgs.writeText "example" ''Hello'';
            };
          };
        };
      };
    };
  };
  testScript =
    { nodes, ... }:
    let
      ext = nodes.machine.naext.extensions.test;
    in
    # python
    ''
      machine.copy_from_host("${ext.image}", "/var/lib/confexts/${ext.name}.${ext.extensionType}.raw")
      machine.succeed("systemd-confext refresh")
      machine.wait_for_file("/etc/test")
      content=machine.succeed("cat /etc/test")
      assert content=="Hello", "File provided by confext has expected content"
    '';
}
