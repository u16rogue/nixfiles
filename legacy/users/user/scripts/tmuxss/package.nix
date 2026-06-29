{ pkgs, ... }: pkgs.writeShellApplication {
    name = "tmuxss";
    runtimeInputs = [
        pkgs.coreutils
        # perhaps it should check for tmux instead of having it as an input incase
        # there's a special case where the `tmux` in `pkgs` is not the appropriate
        # package but it should be overlayed or overridden anyway.
        pkgs.tmux
    ];
    text = builtins.readFile ./tmuxss;
}
