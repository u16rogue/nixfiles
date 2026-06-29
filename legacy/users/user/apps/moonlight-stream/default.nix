{ username, persist_path, ... }: { config, inputs, pkgs, ... }: let
    jail = inputs.jail-nix.lib.init pkgs;
    mkNixPak = inputs.nixpak.lib.nixpak {
       inherit (pkgs) lib;
       inherit pkgs; 
    };
in {
    home-manager.users.${username} = {

        home.persistence."${persist_path}".directories = [ ".emulated-root/moonlight-stream/home/${username}" ];

        xdg.desktopEntries.moonlight-qt = {
            name = "Moonlight Stream";
            exec = "moonlight";
            icon = "${pkgs.moonlight-qt}/share/icons/hicolor/scalable/apps/moonlight.svg";
            terminal = false;
            categories = [ "Game" "Network" ];
        };

        home.packages = [
            (jail "moonlight" pkgs.moonlight-qt (with jail.combinators; [
                network
                gui
                gpu
                (rw-bind (noescape "~/.emulated-root/moonlight-stream/home/${username}") (noescape "~/"))
                # fix attempt for latency:
                #(set-env "IGNORE_RFI_LATENCY_BUG" 1)
                #(set-env "SDL_DEBUG" 1)
                #(readonly "/nix/store")
                #(add-pkg-deps [ config.boot.kernelPackages.nvidiaPackages.latest ])
                (add-runtime /*bash*/ ''
                    # Hardware acceleration fix for nvidia
                    for dev in /dev/nvidia*; do
                        if [ -e "$dev" ]; then
                            RUNTIME_ARGS+=(--dev-bind "$dev" "$dev")
                        fi
                    done
                '')
            ]))
        ];
    };
}
