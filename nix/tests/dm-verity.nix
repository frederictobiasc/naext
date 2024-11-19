# 1. Copy confext created with naext into confext search path
# 2. systemd-confext refresh
# 3. Assert that the confext has been activated and the provided file has the expected content
{
  pkgs,
  ...
}:
let
  cert_id = "a6b64f7fdadc8ba80554f9da58363cbee9b48d88";
  cert = ./fixtures/cert.pem;
  privk = ./fixtures/privk.pem;
in
{
  name = "confext-dm-verity";
  nodes = {
    machine =
      {
        modulesPath,
        ...
      }:
      {
        imports = [
          "${modulesPath}/image/repart.nix"
        ];

        # Embed certificate in the kernel's keyring
        dm-verity = {
          enable = true;
          trustedKeys = [ ./fixtures/cert.pem ];
        };

        # Define our extension image.
        naext = {
          seed = "12345678-1234-1234-1234-123456789123";
          privateKey = privk;
          certificate = cert;
          extensions = {
            test = {
              extensionType = "confext";
              imageFormat = "verity";
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
      testExt = nodes.machine.naext.extensions.test;
    in
    # python
    ''
      with subtest("Kernel was built with an additional certificate"):
        keyring = machine.succeed("cat /proc/keys")
        assert "${cert_id}" in keyring, "expected key not in kernel keyring"

      with subtest("Confext gets applied successfully"):
        machine.copy_from_host("${testExt.image}", "/var/lib/confexts/${testExt.name}.${testExt.extensionType}.raw")
        machine.succeed("systemd-confext refresh")
        machine.wait_for_file("/etc/test")
        content=machine.succeed("cat /etc/test")
        assert content=="Hello", "File provided by confext has expected content"
    '';
}
