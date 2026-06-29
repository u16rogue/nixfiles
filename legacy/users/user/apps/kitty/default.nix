{ username, ... }: { pkgs, ...}: {
    home-manager.users.${username}.programs.kitty = {
        enable = true;
        font = {
            package = pkgs.nerd-fonts.comic-shanns-mono;
            name = "ComicShannsMono Nerd Font Mono";
            #package = pkgs.comic-mono;
            #name = "Comic Mono";
        };
        themeFile = "Catppuccin-Mocha";
        extraConfig = builtins.readFile ./kitty.conf;
    };
}

