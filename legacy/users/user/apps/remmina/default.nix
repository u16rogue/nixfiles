{ username, persist_path, ... }: { config, inputs, pkgs, ... }: let
    jail = inputs.jail-nix.lib.init pkgs;
in {
    home-manager.users.${username} = {

        home.persistence."${persist_path}".directories = [ ".emulated-root/remmina/home/${username}" ];

        xdg.desktopEntries.remmina = {
            name = "Remmina";
            exec = "remmina";
            icon = "${pkgs.remmina}/share/icons/hicolor/scalable/apps/org.remmina.Remmina.svg";
            terminal = false;
            categories = [ "Network" ];
        };

        home.packages = [
            (jail "remmina" pkgs.remmina (with jail.combinators; [
                network
                gui
                (rw-bind (noescape "~/.emulated-root/remmina/home/${username}") (noescape "~/"))
                (try-readwrite (noescape "/tmp/remmina-share"))
            ]))
        ];
    };
}
