{ pkgs, ... }: pkgs.writeShellApplication {
    name = "nix-develop-sync";
    runtimeInputs = [
        pkgs.coreutils
        pkgs.jq
        pkgs.nix
    ];
    text = builtins.readFile ./nix-develop-sync;
}
