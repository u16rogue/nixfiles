#!/usr/bin/env bash

# ctl - rebuild this nixos config for the current host.
#
# usage:
#   ./ctl                rebuild and switch (auto-detects hostname)
#   ./ctl <host>         rebuild and switch for a specific host
#   ./ctl bootstrap      first-time setup (run once per host, after install)
#   ./ctl user-password  prompt for a new login password, hash + encrypt to
#                        secrets/user-password.age (overwrites existing)
#
# hostname detection strips a leading "devshell-" so you can rebuild from
# inside the project devshell without specifying the host explicitly.
#
# secrets backend: ragenix (rust drop-in for agenix, in nixpkgs). consumes
# the same secrets.nix manifest as agenix, same CLI flags (-e, --rekey).
#
# everything else (editing arbitrary secrets, rekeying, building without
# activating) uses upstream tools directly:
#   nix run nixpkgs#ragenix -- -e secrets/<file>.age     # edit a secret
#   nix run nixpkgs#ragenix -- --rekey                   # re-encrypt all
#   nixos-rebuild build  --flake .#<host>                # build only
#   nixos-rebuild test   --flake .#<host>                # test, no boot entry
#   nixos-rebuild boot   --flake .#<host>                # next boot only

SCRIPT_NAME=$(basename "${0}")
SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
HOSTS_DIR="${SCRIPT_DIR}/host"
SECRETS_DIR="${SCRIPT_DIR}/secrets"
SECRETS_MANIFEST="${SECRETS_DIR}/secrets.nix"

err_exit() {
    printf "error: %s\n" "${1}" >&2
    exit 1
}

log() {
    printf "%s\n" "${1}"
}

validate_host() {
    local host="${1}"
    [[ "${host}" =~ ^[A-Za-z0-9][A-Za-z0-9_-]*$ ]] \
        || err_exit "invalid host name '${host}'. use letters, numbers, underscores, or hyphens."
}

# encrypt content from stdin into secrets/<rel>. agenix detects non-tty
# stdin and uses `cp -- /dev/stdin` as the editor.
agenix_write_stdin() {
    local rel_path="${1}"
    (
        cd "${SECRETS_DIR}" || exit 1
        EDITOR='cp -- /dev/stdin' nix run "nixpkgs#ragenix" -- -e "${rel_path}"
    )
}

ensure_secrets_rules() {
    nix eval --file "${SECRETS_MANIFEST}" --json >/dev/null \
        || err_exit "secrets rules have no usable recipients. run './${SCRIPT_NAME} bootstrap' on at least one host or add an admin key."
}

ensure_host_pubkey_gitignore() {
    local host="${1}"
    validate_host "${host}"
    local gitignore="${HOSTS_DIR}/${host}/.gitignore"
    [[ -f "${gitignore}" ]] || return 0
    if ! grep -qxF "!ssh_host_ed25519_key.pub" "${gitignore}"; then
        printf "\n!ssh_host_ed25519_key.pub\n" >> "${gitignore}" \
            || err_exit "failed to update host/${host}/.gitignore."
    fi
}

write_host_pubkey() {
    local host="${1}"
    validate_host "${host}"
    local system_pubkey_file="/etc/ssh/ssh_host_ed25519_key.pub"
    local repo_pubkey_file="${HOSTS_DIR}/${host}/ssh_host_ed25519_key.pub"
    [[ -r "${system_pubkey_file}" ]] || err_exit "host pubkey not found at '${system_pubkey_file}'."

    local system_pubkey
    system_pubkey=$(< "${system_pubkey_file}")
    ensure_host_pubkey_gitignore "${host}"

    if [[ -f "${repo_pubkey_file}" ]]; then
        local repo_pubkey
        repo_pubkey=$(< "${repo_pubkey_file}")
        [[ "${repo_pubkey}" == "${system_pubkey}" ]] \
            || err_exit "host/${host}/ssh_host_ed25519_key.pub does not match ${system_pubkey_file}. inspect before changing recipients."
        log "host/${host}/ssh_host_ed25519_key.pub already matches this host."
    else
        printf '%s\n' "${system_pubkey}" > "${repo_pubkey_file}" \
            || err_exit "failed to write host/${host}/ssh_host_ed25519_key.pub."
        log "wrote host/${host}/ssh_host_ed25519_key.pub."
    fi
}

# prompt twice, hash via mkpasswd, encrypt to secrets/user-password.age.
write_user_password() {
    local pass1 pass2
    while true; do
        printf "password (hidden): "
        read -rs pass1
        printf "\nconfirm: "
        read -rs pass2
        printf "\n"
        [[ "${pass1}" == "${pass2}" ]] && break
        log "warning: passwords did not match. try again."
    done
    local hash
    hash=$(printf '%s' "${pass1}" | nix run "nixpkgs#mkpasswd" -- -m sha-512 --stdin) \
        || err_exit "mkpasswd failed."
    unset pass1 pass2
    # we are writing a fresh password from scratch — there is no value in
    # the existing file. removing it first means ragenix does not try to
    # decrypt-then-edit, which would fail on any machine that is not a
    # recipient (e.g. inside a devshell). encryption itself only needs
    # the recipient pubkeys from secrets.nix, so this works anywhere.
    rm -f "${SECRETS_DIR}/user-password.age"
    printf '%s' "${hash}" | agenix_write_stdin "user-password.age" \
        || err_exit "failed to encrypt user-password.age."
    unset hash
    log "wrote secrets/user-password.age."
}

# ====================================================================================================
# rebuild

cmd_rebuild() {
    local host="${1:-}"
    if [[ -z "${host}" ]]; then
        host=$(hostname -s 2>/dev/null) || err_exit "could not detect hostname."
        # devshell sandboxes prefix the hostname with "devshell-"; strip it
        # so `./ctl` from inside the project devshell still rebuilds the
        # real host config.
        host="${host#devshell-}"
    fi
    validate_host "${host}"
    [[ -d "${SCRIPT_DIR}/host/${host}" ]] || err_exit "no flake config for host '${host}'. pass an explicit name as: ${SCRIPT_NAME} <host>"

    log "rebuilding '${host}'..."
    sudo nixos-rebuild switch --flake "${SCRIPT_DIR}#${host}" \
        || err_exit "rebuild failed."
    log "done."
}

# ====================================================================================================
# bootstrap (run once per host)

cmd_bootstrap() {
    local host
    host=$(hostname -s 2>/dev/null) || err_exit "could not detect hostname."
    host="${host#devshell-}"
    validate_host "${host}"
    [[ -d "${HOSTS_DIR}/${host}" ]] || err_exit "no flake config for host '${host}'."

    log "bootstrapping for host '${host}'..."

    # 1. make this host available as an age recipient.
    write_host_pubkey "${host}"
    ensure_secrets_rules

    # 2. user password
    if [[ -f "${SECRETS_DIR}/user-password.age" ]]; then
        log "secrets/user-password.age already exists, skipping."
    else
        write_user_password
    fi

    # 3. rekey everything (best-effort)
    #
    # rekey is decrypt-then-re-encrypt — it needs an identity matching one
    # of the existing recipients. on a fresh host that has no host ssh key
    # available (e.g. running from a devshell, or before the first boot)
    # this will fail with "no usable identity". that's fine for an initial
    # bootstrap because we just CREATED the only secret with the current
    # recipient set; nothing actually needs rekeying.
    #
    # the rekey only matters when you ADD a new host/admin and want the
    # PRE-EXISTING secrets to also become readable by them. for that case,
    # run `./ctl bootstrap` from a host that IS already a recipient, or
    # run `nix run nixpkgs#ragenix -- --rekey` directly.
    log "attempting to rekey existing secrets..."
    if (cd "${SECRETS_DIR}" && nix run "nixpkgs#ragenix" -- --rekey 2>&1); then
        log "rekey done."
    else
        printf "\n"
        log "warning: rekey skipped (no usable identity on this machine)."
        log "this is normal on a fresh host. existing secrets are still"
        log "readable by their original recipients; only NEW secrets"
        log "created here will include this host."
        log "to rekey later, run from a host that is already a recipient:"
        log "  nix run nixpkgs#ragenix -- --rekey"
    fi

    printf "\n"
    log "bootstrap done. next:"
    log "  - review:  git diff secrets/ host/"
    log "  - commit:  git add secrets/ host/ && git commit -m 'bootstrap'"
    log "  - rebuild: ./${SCRIPT_NAME}"
}

# ====================================================================================================
# user-password (rotate the encrypted user password hash file)

cmd_user_password() {
    [[ -f "${SECRETS_MANIFEST}" ]] || err_exit "no secrets/secrets.nix. run './${SCRIPT_NAME} bootstrap' first."
    ensure_secrets_rules
    log "rotating user password..."
    write_user_password
    log "rotation done. activate with: ./${SCRIPT_NAME}"
}

# ====================================================================================================
# entry

cmd="${1:-}"
shift || true
case "${cmd}" in
    ""|rebuild|switch) cmd_rebuild "${1:-}" ;;
    bootstrap)         cmd_bootstrap ;;
    user-password)     cmd_user_password ;;
    -h|--help|help)
        sed -n '3,/^$/p' "${0}" | sed 's/^#\s\?//'
        ;;
    *)
        # treat any other first arg as an explicit host name for rebuild.
        # `./ctl mistyriver` is a shortcut for `./ctl rebuild mistyriver`.
        # if the name does not match a host directory, cmd_rebuild errors
        # with a clear message.
        cmd_rebuild "${cmd}"
        ;;
esac
