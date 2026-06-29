{ username, persist_path, ... }: { pkgs, inputs, ... }: let
    jail = inputs.jail-nix.lib.init pkgs;
in {
    home-manager.users.${username} = {
        home.persistence."${persist_path}".directories = [ ".emulated-root/steamguard-cli/home/${username}" ];
        home.packages = [
            (jail "steamguard" pkgs.steamguard-cli (with jail.combinators; [
                network
                (set-env "RUST_BACKTRACE" "full")
                (rw-bind (noescape "~/.emulated-root/steamguard-cli/home/${username}") (noescape "~/"))
            ]))
        ];
    };
}
