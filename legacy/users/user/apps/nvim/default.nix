{ username, ... }: { inputs, ... }: {
    home-manager.users.${username} = { ... }: {
        imports = [ inputs.nvf.homeManagerModules.default ];
        programs.nvf = {
            enable = true;
            settings = import ./settings.nix;
        };
    };
}
