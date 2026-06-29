{ username, persist_path, ... }: { inputs, pkgs, ... }: let
    jail = inputs.jail-nix.lib.init pkgs;
in {
    home-manager.users.${username} = {

        home.persistence."${persist_path}".directories = [ ".emulated-root/vesktop/home/${username}" ];

        xdg.desktopEntries.vesktop = {
            name = "Vesktop";
            exec = "vesktop %U";
            icon = "${pkgs.vesktop}/share/icons/hicolor/32x32/apps/vesktop.png";
            terminal = false;
            categories = [ "Network" "Chat" "InstantMessaging" ];
        };

        programs.vesktop = {
            enable = true;
            package = jail "vesktop" pkgs.vesktop (with jail.combinators; [
                  network
                  gui
                  gpu
                  pipewire
                  (rw-bind (noescape "~/.emulated-root/vesktop/home/${username}") (noescape "~/"))
            ]);
        };
    };
}
