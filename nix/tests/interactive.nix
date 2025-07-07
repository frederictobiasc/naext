{ config, ... }:
{
  services.openssh = {
    enable = true;
    settings = {
      PermitRootLogin = "yes";
      PermitEmptyPasswords = "yes";
    };
  };
  security.pam.services.sshd.allowNullPassword = true;
  virtualisation.forwardPorts = [
    {
      from = "host";
      host.port = 10022 + 100 * config.virtualisation.test.nodeNumber;
      guest.port = 22;
    }
  ];
}
