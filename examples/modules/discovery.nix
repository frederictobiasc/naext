{ pkgs, ... }:
{
  systemd.services.discovery = {
    wantedBy = [ "multi-user.target" ];
    after = [ "network-online.target" ];
    requires = [ "network-online.target" ];
    path = with pkgs; [
      bash
      curl
      jq
    ];
    unitConfig.StartLimitIntervalSec = 0;
    serviceConfig = {
      RestartSec = "3s";
      Restart = "on-failure";
    };
    script = builtins.readFile ./discovery.sh;
  };
}
