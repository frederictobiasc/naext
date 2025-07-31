{
  config,
  lib,
  pkgs,
  ...
}:
let
  cfg = config.dm-verity;
  enableVerityRoothashSig = {
    name = "enable_dm_verity_verify_roothash_sig";
    patch = null;
    extraStructuredConfig = {
      DM_VERITY_VERIFY_ROOTHASH_SIG = lib.kernel.yes;
    };
  };
  provideTrustedKeys = keys: {
    name = "provide_config_system_trusted_keys";
    patch = null;
    extraStructuredConfig = {
      SYSTEM_TRUSTED_KEYS.freeform = "${keys}";
    };
  };

  mergeCertificates =
    certFiles:
    pkgs.runCommand "merged-certificates.pem" { } (
      lib.concatMapStringsSep "\n" (c: "cat ${c} >> $out") certFiles
    );
in
{
  options.dm-verity = {
    enable = lib.mkEnableOption "support for the dm-verity roothash signature verification mechanism.";
    trustedKeys = lib.mkOption {
      type = with lib.types; listOf path;
      default = [ ];
      example = [ ./certificate.pem ];
      description = ''
        Trusted certificates for the signature verification of dm-verity partitions. The listed
        certificate files will be provided as input for the kernel build process in order
        to embed them in the kernel keyring.
      '';
    };
  };
  config = lib.mkIf cfg.enable {
    boot.kernelPatches = [
      enableVerityRoothashSig
    ]
    ++ lib.optional (cfg.trustedKeys != [ ]) (provideTrustedKeys (mergeCertificates cfg.trustedKeys));
  };
}
