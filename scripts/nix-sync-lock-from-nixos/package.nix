{ pkgs, ... }: pkgs.writeShellApplication {
    name = "nix-sync-lock-from-nixos";
    runtimeInputs = [
        pkgs.coreutils
        pkgs.jq
        pkgs.nix
    ];
    text = builtins.readFile ./nix-sync-lock-from-nixos;
}
