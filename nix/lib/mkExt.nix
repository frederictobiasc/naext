# Create extension images
{ pkgs, lib, ... }:

{
  # Create a verity-protected extension image
  verity =
    {
      name,
      ddiType,
      sourceTree,
      privateKey,
      certificate,
      seed,
    }:

    pkgs.runCommand "${name}.${ddiType}.raw"
      {
        nativeBuildInputs = with pkgs; [
          erofs-utils
          tree
        ];
      }
      ''
        set -eux
        # TODO: Investigate why repart needs tree to be writable and relatively accessible
        mkdir tree
        cp -rL ${sourceTree}/. tree
        chmod -R 755 tree
        ${pkgs.systemd}/bin/systemd-repart \
          --make-ddi=${ddiType} \
          --copy-source=tree \
          --private-key=${privateKey} \
          --certificate=${certificate} \
          --seed=${seed} \
          $out
      '';
  # Create a plain erofs extension image
  raw =
    let
      # Reproducibly derive UUID from a seed and a name
      mkUuid =
        name: seed:
        pkgs.runCommand "hmac-256" { nativeBuildInputs = [ pkgs.openssl ]; } ''
          set -eux
          # Compute HMAC using OpenSSL
          hmac=$(echo -n '${name}' | openssl dgst -sha256 -hmac '${seed}' | awk '{print $2}')

          # Format the HMAC as a UUID (first 32 characters of the HMAC)
          uuid=''${hmac:0:8}-''${hmac:8:4}-''${hmac:12:4}-''${hmac:16:4}-''${hmac:20:12}

          # Write the UUID to the output file
          echo -n $uuid > $out
        '';
    in
    {
      name,
      ddiType,
      sourceTree,
      seed ? "12345678-1234-1234-1234-123456789123",
      ...
    }:

    pkgs.runCommand "${name}.${ddiType}.raw"
      {
        nativeBuildInputs = with pkgs; [
          erofs-utils
          tree
        ];
      }
      ''
        set -eux
        truncate -s 100M ${name}.${ddiType}.raw
        ${pkgs.erofs-utils}/bin/mkfs.erofs \
          --quiet \
          --force-uid=0 \
          --force-gid=0 \
          -U "${lib.readFile (mkUuid name seed)}" \
          -T 0 \
          $out \
          ${sourceTree}
      '';
}
