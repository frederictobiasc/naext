{ pkgs, ... }:
let
  wwwRoot = "/usr/share/www";
in
{
  naext = {
    seed = "12345678-1234-1234-1234-123456789123";
    extensions = {
      "hello" = {
        extensionType = "sysext";
        imageFormat = "raw";
        files = {
          "${wwwRoot}/index.html".source = pkgs.writeText "example" ''
            <!DOCTYPE html>
            <html>
                <head></head>
                <body>Hello, world!</body>
            </html>
          '';
        };
      };
    };
  };
}
