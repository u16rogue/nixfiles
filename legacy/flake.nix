# TODO: for packages username shouldn't be hardcoded / sourced
# TODO: include keepass database
# TODO: finish ssh and gpg keys
{
    outputs = inputs@{ flake-parts, nixpkgs, ... }:
        flake-parts.lib.mkFlake { inherit inputs; } {
            systems = [ "x86_64-linux" ];

            perSystem = { pkgs, ... }: {
                devShells.default = pkgs.mkShellNoCC {
                    packages = [];
                    shellHook = /*bash*/ ''
                        export NIX_FRAGMENT="default"
                        if [[ -f "$PWD/.devshellshook.sh" ]]; then
                            source "$PWD/.devshellshook.sh"
                        fi
                    '';
                };
            };

            flake = {
                nixosConfigurations =
                    let
                        system = "x86_64-linux";
                        pkgs = import nixpkgs { inherit system; };
                        host_entries = builtins.readDir ./host;
                        hosts = pkgs.lib.pipe host_entries [
                            builtins.attrNames
                            (builtins.filter (file: host_entries.${file} == "directory"))
                        ];
                    in
                        builtins.listToAttrs (
                            (builtins.map (host: {
                                name = host;
                                value = nixpkgs.lib.nixosSystem {
                                    inherit system;
                                    specialArgs = { inherit inputs system; };
                                    modules = [
                                        inputs.nur.modules.nixos.default
                                        inputs.impermanence.nixosModules.impermanence
                                        inputs.home-manager.nixosModules.home-manager
                                        inputs.agenix.nixosModules.default
                                        ./common.nix
                                        ./host/${host}/configuration.nix
                                        ((import ./users/user/default.nix) {
                                            persist_path = "/persist"; # TODO: this should be provided by the host
                                            username = "user";
                                            host-custom = {
                                                hyprland.settings =
                                                    let
                                                        custom = ./host/${host}/hyprland.settings.nix;
                                                    in
                                                        if builtins.pathExists "${custom}" then
                                                            ((import custom) {})
                                                        else
                                                            { append = {}; }
                                                ;
                                            };
                                        })
                                    ];
                                };
                            }))
                            hosts
                        );
                #/nixosConfigurations
            };
        };
    #/outputs

    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        nixpkgs-stable.url = "github:nixos/nixpkgs/nixos-25.11";
        flake-parts.url = "github:hercules-ci/flake-parts";

        nur = {
            url = "github:nix-community/NUR";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        home-manager = {
            url = "github:nix-community/home-manager";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        impermanence = {
            url = "github:nix-community/impermanence";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        wrappers = {
            url = "github:lassulus/wrappers";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        jail-nix = { # bwrap utility
            url = "sourcehut:~alexdavid/jail.nix";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        nvf = { # neovim
            url = "github:notashelf/nvf";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        nixpak = { # bwrap utility
            url = "github:nixpak/nixpak";
            inputs.nixpkgs.follows = "nixpkgs";
        };
        agenix = { # secrets management
            url = "github:ryantm/agenix";
            inputs.nixpkgs.follows = "nixpkgs";
        };
    };
}
