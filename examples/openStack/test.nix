# The integration test for the openStack example
# ## Configuree
#
# - [X] Discovery-Service
#   - [X] Read dispenser URL from metadata endpoint
#   - [X] Import extension from endpoint
#   - [X] Apply extension

{
  pkgs,
  ...
}:
let
  webRoot = pkgs.runCommand "webroot" { } ''
    mkdir -p $out/openstack/2020-10-14
    echo '{ "dispenser": "http://metadata/hello.sysext.raw" }' > $out/openstack/2020-10-14/user_data
  '';
in
{
  name = "basic";
  nodes = {
    configuree = _: {
      imports = [
        ../modules/discovery.nix
      ];
      # Add link-local address for accessing mock user_data endpoint
      networking.interfaces.eth1.ipv4.addresses = [
        {
          address = "169.254.169.5";
          prefixLength = 16;
        }
      ];
      services.nginx = {
        enable = true;
        virtualHosts."localhost".locations."/".root = "/usr/share/www";
      };
    };
    metadata =
      { config, ... }:
      {
        imports = [
          ./extensionImage.nix
        ];
        # Add link-local address for serving mock user_data endpoint
        networking.interfaces.eth1.ipv4.addresses = [
          {
            address = "169.254.169.254";
            prefixLength = 16;
          }
        ];
        networking.firewall.enable = false;
        # Mock user_data endpoint
        services.nginx = {
          enable = true;
          virtualHosts."169.254.169.254" = {
            locations."/openstack/2020-10-14".root = webRoot;
          };
          virtualHosts."metadata".locations."/".root = pkgs.runCommand "" { } ''
            mkdir $out
            cp ${config.naext.extensions.hello.image} $out/hello.sysext.raw
          '';
        };
      };
  };
  testScript =
    { nodes, ... }:
    # python
    ''
      start_all()
      configuree.wait_for_file("/usr/share/www/index.html")

      content=configuree.succeed("cat /usr/share/www/index.html")
      assert "Hello, world!" in content, "File provided by sysext has expected content"

      web_content=configuree.succeed("curl localhost")
      assert "Hello, world!" in web_content, "nginx serves expected content"
    '';
}
