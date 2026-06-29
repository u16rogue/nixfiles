{ username, ... }: { ... }: {
    home-manager.users.${username}.programs.waybar = {
        enable = true;
        systemd.enable = true;
        settings = {
            mainBar = {
                layer = "top";
                mode = "hide";
                ipc = true;
                on-sigusr1 = "toggle";
                start_hidden = true;
                modules-left = [ "hyprland/workspaces" "hyprland/submap" ];
                modules-right = [ "battery" ];
                "battery" = {
                    "format" = "{capacity}% {icon}";
                    "format-charging" = "{capacity}% +";
                    "format-discharging" = "{capacity}% -";
                    "tooltip" = false;
                    "interval" = 30;
                };
            };
        };
    };
}
