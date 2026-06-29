{ username, ... }: { ... }: {
    home-manager.users.${username} = { pkgs, ... }: {
        home.packages = [ pkgs.btop ];
    };
}
