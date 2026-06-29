{ ... }: {
    nix.settings = {
        experimental-features = [ "nix-command" "flakes" "pipe-operators" ];
        extra-experimental-features = [ "pipe-operators" ];
    };
    nixpkgs.config.allowUnfree = true;
    home-manager = {
        useGlobalPkgs = true;
        useUserPackages = true;
        backupFileExtension = "bak";
    };
    programs.vim.enable = true;
    users.mutableUsers = false;

    age.identityPaths = [ "/persist/etc/ssh/ssh_host_ed25519_key" ];
}
