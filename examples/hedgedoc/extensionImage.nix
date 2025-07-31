# Extension Image for the Hedgedoc example
#
# - [ ] OAuth2 parameters
# - [ ] domain
# - [ ] port
#
#
# To solve:
#
# - [ ] How to provide: defaultNotePath, docsPath, viewPath, ...
#
{ pkgs, ... }:
let
  settingsFormat = pkgs.formats.json { };
  hedgedocSettings = settingsFormat.generate "hedgedoc-config.json" {
    production = {
      db = {
        dialect = "sqlite";
        storage = "/var/lib/hedgedoc/db.sqlite";
      };
      domain = "hedgedoc";
      host = "localhost";
      path = null;
      port = 3000;
      protocolUseSSL = true;
      uploadsPath = "/var/lib/hedgedoc/uploads";
      urlPath = null;
      useSSL = false;
      #sessionSecret = "";
      # "defaultNotePath": "/nix/store/64v6z4c6pp9svp1392fpihdb1s3xg48q-hedgedoc-1.10.3/share/hedgedoc/public/default.md",
      # "docsPath": "/nix/store/64v6z4c6pp9svp1392fpihdb1s3xg48q-hedgedoc-1.10.3/share/hedgedoc/public/docs",
      # "viewPath":  "/nix/store/64v6z4c6pp9svp1392fpihdb1s3xg48q-hedgedoc-1.10.3/share/hedgedoc/public/views;
    };
  };
in
{
  naext = {
    seed = "12345678-1234-1234-1234-123456789123";
    extensions = {
      "hedgedoc" = {
        extensionType = "confext";
        imageFormat = "raw";
        files = {
          "/etc/hostname".source = pkgs.writeText "hostname" "hedgedoc-host";
          "/etc/hedgedoc/config.json".source = hedgedocSettings;
        };
      };
    };
  };
}
