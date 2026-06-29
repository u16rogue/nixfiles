# agenix access manifest.
#
# This file is plaintext-committable. It only contains PUBLIC keys and a
# declaration of which recipients can decrypt which encrypted files.
#
# Workflow:
#   - Edit a secret:        nix run nixpkgs#ragenix -- -e <file>.age   (from this dir)
#   - Rotate recipients:    nix run nixpkgs#ragenix -- --rekey         (from this dir)
#   - Add a new host:       put its ssh_host_ed25519_key.pub in host/<name>/,
#                           then rekey from any host that is already a recipient.
#
# Bootstrap: each host's age identity is its sshd-generated
# /etc/ssh/ssh_host_ed25519_key. The host pubkey (its .pub file) is stored
# in host/<name>/ssh_host_ed25519_key.pub. The private half stays on the host's
# /persist/etc/ssh, never leaves the disk.

let

    # ╔════════════════════════════════════════════════════════════════════╗
    # ║  USER REGION — edit these freely                                   ║
    # ║                                                                    ║
    # ║  Anything below this banner up to the matching "END USER REGION"   ║
    # ║  is meant to be modified by you. Add admin keys or change          ║
    # ║  per-secret access here. Add hosts under ../host/<name>/ instead.  ║
    # ╚════════════════════════════════════════════════════════════════════╝

    # ── Admin user keys ──────────────────────────────────────────────────
    # YOUR personal age/ssh pubkey(s). These let you decrypt secrets from
    # a laptop or workstation that is NOT one of the hosts. Optional — if
    # you only ever edit secrets while logged into one of the hosts, leave
    # this empty. Use ssh-ed25519 pubkeys or age1... recipients.
    admins = [
        # "ssh-ed25519 AAAA... user@machine"
    ];

    # ── Per-secret access overrides ──────────────────────────────────────
    # By default every secret is encrypted to ALL real hosts + ALL real
    # admins. To restrict a specific secret to a subset, add an entry here
    # that maps the path inside secrets/ to a custom recipient list.
    # Example:
    #   secretAccess = {
    #     "api-keys/mistyriver-only.age" = [ hostKeys.mistyriver ];
    #   };
    secretAccess = {
        # "user-password.age" = all;                 # already the default
        # "api-keys/mistylake-only.age" = [ hostKeys.mistylake ];
    };

    # ╔════════════════════════════════════════════════════════════════════╗
    # ║  END USER REGION                                                   ║
    # ║                                                                    ║
    # ║  Everything below is internal plumbing. You should not normally    ║
    # ║  need to touch it; doing so risks breaking encryption / rekeying.  ║
    # ╚════════════════════════════════════════════════════════════════════╝

    # ── Internal: recipient resolution ───────────────────────────────────
    hostRoot = ../host;
    hostEntries = builtins.readDir hostRoot;
    hostNames = builtins.filter
        (name: hostEntries.${name} == "directory")
        (builtins.attrNames hostEntries);

    trimPubkey = key: builtins.replaceStrings [ "\n" "\r" ] [ "" "" ] key;
    hostPubkeyPath = host: hostRoot + "/${host}/ssh_host_ed25519_key.pub";
    hostPubkey = host:
        let path = hostPubkeyPath host;
        in if builtins.pathExists path then trimPubkey (builtins.readFile path) else null;

    hostKeyEntries = builtins.filter
        (entry: entry.value != null)
        (map (host: { name = host; value = hostPubkey host; }) hostNames);
    hostKeys = builtins.listToAttrs hostKeyEntries;
    hosts = builtins.attrValues hostKeys;

    realHosts = builtins.filter (key: key != "") hosts;
    realAdmins = builtins.filter (key: key != "") admins;
    rawAll = realHosts ++ realAdmins;

    # Sanity: there must be at least one real recipient or no secret can
    # be encrypted at all. Crash with a useful message rather than letting
    # age silently fail. Inlined into `all` so reading it forces the check.
    all = if rawAll == [] then
        throw "secrets/secrets.nix: no recipients found. run './ctl bootstrap' on at least one host or add an admin key."
    else rawAll;

    # ── Internal: auto-enumeration ───────────────────────────────────────
    # Walk a subdirectory and produce a rule for every *.age file in it.
    # Mirrors the host enumeration pattern used in flake.nix.
    recipientsFor = path: secretAccess.${path} or all;
    enumerateDir = subdir:
        let
            path = ./. + "/${subdir}";
            entries = if builtins.pathExists path then builtins.readDir path else {};
            ageFiles = builtins.filter
                (name: entries.${name} == "regular" && builtins.match ".*\\.age$" name != null)
                (builtins.attrNames entries);
        in
            builtins.listToAttrs (map (name: {
                name = "${subdir}/${name}";
                value = { publicKeys = recipientsFor "${subdir}/${name}"; };
            }) ageFiles);

    # ── Internal: top-level known secrets ────────────────────────────────
    # These are listed by name (not enumerated) because ragenix needs a
    # rule to EXIST before it will let you CREATE the encrypted file. With
    # filesystem enumeration alone, the first-time creation of these
    # secrets is impossible (chicken-and-egg).
    knownTopLevel = {
        "user-password.age".publicKeys = recipientsFor "user-password.age";
    };

    # Plus any other *.age the user drops in by hand at the top level.
    enumeratedTopLevel =
        let
            entries = builtins.readDir ./.;
            ageFiles = builtins.filter
                (name: entries.${name} == "regular" && builtins.match ".*\\.age$" name != null)
                (builtins.attrNames entries);
        in
            builtins.listToAttrs (map (name: {
                inherit name;
                value = { publicKeys = recipientsFor name; };
            }) ageFiles);
in
    # Order matters: knownTopLevel wins on key collision so a manual
    # override in the USER REGION above takes precedence over the
    # filesystem enumeration default.
    enumeratedTopLevel
    // (enumerateDir "ssh")
    // (enumerateDir "gpg")
    // (enumerateDir "api-keys")
    // knownTopLevel
