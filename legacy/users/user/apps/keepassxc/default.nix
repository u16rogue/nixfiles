{ username, persist_path, ... }: { pkgs, inputs, ... }: let
    jail = inputs.jail-nix.lib.init pkgs;
in {
    home-manager.users.${username} = {

        home.persistence."${persist_path}".directories = [ ".emulated-root/keepass/home/${username}" ];

        xdg.desktopEntries.keepassxc = {
            name = "KeePassXC";
            exec = "keepassxc %f";
            icon = "${pkgs.keepassxc}/share/icons/hicolor/256x256/apps/keepassxc.png";
            terminal = false;
            categories = [ "Utility" "Security" "Qt" ];
        };

        home.packages = [
            (jail "keepassxc" pkgs.keepassxc (with jail.combinators; [
                  gui
                  (rw-bind (noescape "~/.emulated-root/keepass/home/${username}") (noescape "~/"))
            ]))
        ];
    };
}
