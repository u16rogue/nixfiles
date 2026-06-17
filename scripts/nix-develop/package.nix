{ pkgs, ... }: pkgs.writeShellApplication {
    name = "nix-develop";
    runtimeInputs = [
        pkgs.coreutils
    ];
    text = builtins.readFile ./nix-develop;
}
