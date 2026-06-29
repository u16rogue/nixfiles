{ username, ... }: { ... }: {
    home-manager.users.${username} = {
        programs.zellij = {
            enable = true;
            settings = {
                theme = "catppuccin-macchiato";
                show_startup_tips = false;
            };
        };
    };
}
