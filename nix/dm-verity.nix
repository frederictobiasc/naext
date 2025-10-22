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
    structuredExtraConfig = {
      DM_VERITY_VERIFY_ROOTHASH_SIG = lib.kernel.yes;
    };
  };
  provideTrustedKeys = keys: {
    name = "provide_config_system_trusted_keys";
    patch = null;
    structuredExtraConfig = {
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
    where = lib.mkOption {
      type = lib.types.enum [
        "kernel"
        "userspace"
        "kernel+userspace"
      ];
    };
    trustedKeys = lib.mkOption {
      type = with lib.types; listOf path;
      default = [ ];
      example = [ ./certificate.pem ];
      description = ''
        Trusted certificates for the signature verification of dm-verity partitions.
        They need to be PEM encoded. For userspace validation, only certificate files
        with the .crt file extension are recognized by systemd.
      '';
    };
  };

  config = lib.mkIf cfg.enable {
    boot.kernelPatches = [
      enableVerityRoothashSig
    ]
    ++ lib.optional (
      ((cfg.where == "kernel") || (cfg.where == "kernel+userspace")) && cfg.trustedKeys != [ ]
    ) (provideTrustedKeys (mergeCertificates cfg.trustedKeys));

    environment.etc =
      let
        checkedTrustedKeys =
          lib.warnIf (!lib.lists.all (lib.hasSuffix ".crt") cfg.trustedKeys)
            "dm-verity: trustedKeys for userspace validation require .crt extension to be considered"
            cfg.trustedKeys;
      in

      lib.listToAttrs (
        lib.map (keyPath: {
          name = "verity.d/${builtins.baseNameOf keyPath}";
          value = {
            source = keyPath;
          };
        }) checkedTrustedKeys
      );
  };
}
