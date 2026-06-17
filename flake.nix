{
    inputs = {
        nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
        flake-parts.url = "github:hercules-ci/flake-parts";
        wrappers.url = "github:lassulus/wrappers";
    };

    outputs = inputs@{ self, nixpkgs, ... }: inputs.flake-parts.lib.mkFlake { inherit inputs; } ({ config, ... }: {
        flake = {
            description = "nix stuff";
            templates = import ./templates/default.nix { inherit nixpkgs; };
        };

        imports = [];

        systems = [ "x86_64-linux" ];
        perSystem = { self', config, pkgs, ... }: {
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
    });
}

# TODO:
