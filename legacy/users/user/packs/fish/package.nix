{ inputs, pkgs, ... }: (inputs.wrappers.lib.wrapPackage {
    inherit pkgs;
    package = pkgs.fish;
    flags = {
        "--init-command" = builtins.toString (pkgs.writeText "config.fish" (builtins.readFile ./config.fish));
    };
})
