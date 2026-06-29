{ username, ... }: { ... }: {
    home-manager.users.${username}.programs.yazi = {
        enable = true;
        shellWrapperName = "y"; # home-manager warning for using home.stateVersion < 26.05
        settings = {
            mgr = {
                show_hidden = true;
            };
        };
    };
}
