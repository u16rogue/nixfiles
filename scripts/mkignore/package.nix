{ pkgs, ... }: pkgs.writeShellApplication {
    name = "mkignore";
    runtimeInputs = [
        pkgs.coreutils
        pkgs.findutils
    ];
    text = builtins.readFile ./mkignore;
}
