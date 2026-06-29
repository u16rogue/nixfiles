{ username, persist_path, ... }: { inputs, pkgs, ... }: let
    jail = inputs.jail-nix.lib.init pkgs;
in {
    home-manager.users.${username} = {

        home.persistence."${persist_path}".directories = [ ".emulated-root/monero-gui/home/${username}" ];

        xdg.desktopEntries.monero-wallet-gui = {
            name = "Monero Wallet GUI";
            exec = "monero-wallet-gui";
            icon = "${pkgs.monero-gui}/share/icons/hicolor/32x32/apps/monero.png";
            terminal = false;
            categories = [ "Utility" "Network" ];
        };

        home.packages = [
            (jail "monero-wallet-gui" pkgs.monero-gui (with jail.combinators; [
                network
                gui
                gpu
                xwayland
                (rw-bind (noescape "~/.emulated-root/monero-gui/home/${username}") (noescape "~/"))
            ]))
        ];
    };
}
