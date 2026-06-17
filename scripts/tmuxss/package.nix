{ pkgs, ... }: pkgs.writeShellApplication {
    name = "tmuxss";
    runtimeInputs = [
        pkgs.coreutils
    ];
    text = builtins.readFile ./tmuxss;
}
