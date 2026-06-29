{ username, ... }: { inputs, pkgs, ... }: {
    #nixpkgs.overlays = [(final: prev: {
    #    fish = (inputs.wrappers.lib.wrapPackage {
    #        inherit pkgs;
    #        package = prev.fish;
    #        flags = {
    #          "--init-command" = builtins.readFile ./config.fish;
    #        };
    #    });
    #})];
    programs.fish.enable = true;
    home-manager.users.${username}.programs.fish = {
        enable = true;
        interactiveShellInit = builtins.readFile ./config.fish;
    };
}
