# Workload-related configuration of the appliance's base image
{ lib, ... }:
{
  services = {
    hedgedoc = {
      enable = true;
    };
    cloud-init = {
      enable = true;
    };
  };
  # Effectively deactivates the module's configuration handling
  systemd.services.hedgedoc = {
    preStart = lib.mkForce "";
    serviceConfig.Environment = lib.mkForce [
      "CMD_CONFIG_FILE=/etc/hedgedoc/config.json"
      "NODE_ENV=production"
    ];
  };
  systemd.paths.hedgedoc = {
    pathConfig."PathExists" = "/etc/hedgedoc/config.json";
  };
}
