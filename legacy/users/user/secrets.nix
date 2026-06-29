# Auto-enumerate secrets/ssh/ and secrets/gpg/ and install them into the
# user's home directory at activation time. Mirrors the host enumeration
# pattern: drop a new file into the directory, rebuild, done.
#
# - *.age files are decrypted by agenix to /run/secrets/<category>-<name>
#   (tmpfs, 0400, owned by the user)
# - *.pub files (and any non-.age plaintext) are installed verbatim from
#   the repo (public keys are public — no decryption needed)
#
# Final layout:
#   ~/.ssh/id_ed25519         (from secrets/ssh/id_ed25519.age)
#   ~/.ssh/id_ed25519.pub     (from secrets/ssh/id_ed25519.pub)
#   ~/.gnupg/private.asc      (from secrets/gpg/private.age, then imported)
#
# Files in ~/.ssh / ~/.gnupg that are NOT sourced from this module get
# wiped on every boot (these dirs are no longer in impermanence). The repo
# is the single source of truth.

{ username }: { config, lib, pkgs, ... }:
let
    secretsDir = ../../secrets;

    # Read a subdir of secrets/ and split into encrypted (.age) vs plaintext.
    enumerate = subdir:
        let
            path = secretsDir + "/${subdir}";
            entries = if builtins.pathExists path then builtins.readDir path else {};
            regularFiles = builtins.filter
                (name: entries.${name} == "regular")
                (builtins.attrNames entries);
            ageFiles = builtins.filter
                (name: builtins.match ".*\\.age$" name != null)
                regularFiles;
            plainFiles = builtins.filter
                (name: builtins.match ".*\\.age$" name == null)
                regularFiles;
        in
            { inherit ageFiles plainFiles; };

    sshEnum = enumerate "ssh";
    gpgEnum = enumerate "gpg";

    # Strip the trailing ".age" so secrets/ssh/id_ed25519.age installs as
    # ~/.ssh/id_ed25519 (not ~/.ssh/id_ed25519.age).
    stripAge = name:
        let m = builtins.match "(.*)\\.age$" name;
        in if m == null then name else builtins.head m;

    # Build the age.secrets attrset for one category.
    # Each secret is decrypted to /run/secrets/<category>-<stripped-name>
    # with mode 0400 and ownership = the user.
    mkAgeSecrets = category: files:
        builtins.listToAttrs (map (name: {
            name = "${category}-${stripAge name}";
            value = {
                file = secretsDir + "/${category}/${name}";
                owner = username;
                group = "users";
                mode = "0400";
            };
        }) files);

    # Per-file install commands for the activation script.
    # Encrypted: copy from /run/secrets/<id> to ~/<category>/<stripped name>
    # Plaintext: copy from the repo path directly
    mkInstallLines = { homeSubdir, category, ageFiles, plainFiles, fileMode }:
        let
            ageLines = map (name:
                let
                    stripped = stripAge name;
                    secretId = "${category}-${stripped}";
                    src = config.age.secrets.${secretId}.path;
                    dest = "$HOME/${homeSubdir}/${stripped}";
                in ''
                    if [ -r "${src}" ]; then
                        install -m ${fileMode} -o ${username} -g users "${src}" "${dest}"
                    fi
                ''
            ) ageFiles;

            plainLines = map (name:
                let
                    src = "${secretsDir}/${category}/${name}";
                    dest = "$HOME/${homeSubdir}/${name}";
                in ''
                    install -m 0444 -o ${username} -g users "${src}" "${dest}"
                ''
            ) plainFiles;
        in
            ageLines ++ plainLines;

    sshInstallLines = mkInstallLines {
        homeSubdir = ".ssh";
        category = "ssh";
        ageFiles = sshEnum.ageFiles;
        plainFiles = sshEnum.plainFiles;
        fileMode = "0400";
    };

    gpgInstallLines = mkInstallLines {
        homeSubdir = ".gnupg";
        category = "gpg";
        ageFiles = gpgEnum.ageFiles;
        plainFiles = gpgEnum.plainFiles;
        fileMode = "0600";
    };

    hasSsh = sshEnum.ageFiles != [] || sshEnum.plainFiles != [];
    hasGpg = gpgEnum.ageFiles != [] || gpgEnum.plainFiles != [];
in
{
    # Declare every age.secrets.* entry that exists under secrets/ssh and secrets/gpg.
    age.secrets =
        (mkAgeSecrets "ssh" sshEnum.ageFiles)
        // (mkAgeSecrets "gpg" gpgEnum.ageFiles);

    # System activation: install the keys into the user's home.
    # Runs after `users` (so $HOME exists) and after `agenix` (so /run/secrets is populated).
    system.activationScripts.installUserSecrets = lib.mkIf (hasSsh || hasGpg) {
        deps = [ "users" "agenix" ];
        text = ''
            set -u
            HOME=/home/${username}

            ${lib.optionalString hasSsh ''
                install -d -m 0700 -o ${username} -g users "$HOME/.ssh"
                ${lib.concatStringsSep "\n" sshInstallLines}
            ''}

            ${lib.optionalString hasGpg ''
                install -d -m 0700 -o ${username} -g users "$HOME/.gnupg"
                ${lib.concatStringsSep "\n" gpgInstallLines}

                # If a GPG private key was provided, import it on every boot so
                # the user's keyring is populated. Safe to re-run (idempotent).
                ${lib.optionalString (builtins.elem "private.age" gpgEnum.ageFiles) ''
                    if [ -r "$HOME/.gnupg/private" ]; then
                        ${pkgs.sudo}/bin/sudo -u ${username} -- ${pkgs.gnupg}/bin/gpg --batch --import "$HOME/.gnupg/private" || true
                    fi
                ''}
                ${lib.optionalString (builtins.elem "ownertrust.age" gpgEnum.ageFiles) ''
                    if [ -r "$HOME/.gnupg/ownertrust" ]; then
                        ${pkgs.sudo}/bin/sudo -u ${username} -- ${pkgs.gnupg}/bin/gpg --batch --import-ownertrust "$HOME/.gnupg/ownertrust" || true
                    fi
                ''}
            ''}
        '';
    };
}
