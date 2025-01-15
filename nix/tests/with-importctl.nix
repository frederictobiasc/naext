#This test showcases how you can use importctl to import and apply an extension image from a remote source.

{ pkgs, ... }:
{
  name = "Extend via importctl";
  nodes = {
    machine =
      { config, ... }:
      {
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
        services.nginx = {
          enable = true;
          virtualHosts."localhost" = {
            root = pkgs.runCommand "nginx-root" { } ''
              mkdir $out
              cp ${config.naext.extensions.test.image} $out/test.confext.raw
            '';
          };
        };

      };
  };
  testScript =
    _:
    # python
    ''
      machine.wait_for_unit("nginx.service")
      machine.succeed("importctl --verify=no --class=confext pull-raw \"http://localhost/test.confext.raw\" test.confext.raw")
      machine.succeed("systemd-confext refresh")
      machine.wait_for_file("/etc/test")
      content=machine.succeed("cat /etc/test")
      assert content=="Hello", "File provided by confext has expected content"
    '';
}
