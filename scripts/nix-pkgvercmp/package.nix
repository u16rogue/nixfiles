{ pkgs, ... }: pkgs.writeShellApplication {
    name = "nix-pkgvercmp";
    runtimeInputs = [
        pkgs.coreutils
        pkgs.jq
    ];
    text = builtins.readFile ./nix-pkgvercmp;
}
