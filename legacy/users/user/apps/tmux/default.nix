{ username, ... }: {...}: {
    home-manager.users.${username} = { pkgs, config, lib, ... }: {
        #xdg.desktopEntries.tmux = {
        #    name = "Tmux";
        #    exec = "kitty -e \"sh -c \"exec tmux new-session -A -s default\"\"";
        #    icon = "utilities-terminal";
        #    terminal = false;
        #};
        programs.tmux = {
            enable = true;
            baseIndex = 1;
            clock24 = true;
            escapeTime = 1; # fix vi mode
            prefix = "C-q";
            secureSocket = true;
            keyMode = "vi";
            plugins = with pkgs.tmuxPlugins; [
                {
                    plugin = catppuccin;
                    extraConfig = ''
                        set -g @catppuccin_window_status_style basic
                        set -g @catppuccin_status_default "on"

                        set -g @catppuccin_window_default_fill "number"
                        set -g @catppuccin_window_current_fill "number"
                        set -g @catppuccin_window_default_text " #W  #{window_panes}#{?window_zoomed_flag,   ,}"
                        set -g @catppuccin_window_current_text " #W  #{window_panes}#{?window_zoomed_flag,   ,}"
                        
                        set -g @catppuccin_status_fill "icon"
                        set -g @catppuccin_status_connect_separator "yes"
                        set -g @catppuccin_status_left_separator "█"
                        set -g @catppuccin_status_right_separator "█"
                        set -g @catppuccin_application_icon "󰜎  "
                        set -g @catppuccin_session_icon "  "

                        set -g status-right "#{E:@catppuccin_status_application}#{E:@catppuccin_status_session}"
                        set -g status-left ""
                    '';
                } 
            ];
            extraConfig = ''
                # if-shell "[ -n \"$WSH_ID\" ]" "set -g status-position top" "set -g status-position bottom"
                set-option -g detach-on-destroy off
                bind-key ` display-popup

                # Use vim motion
                bind j select-pane -D
                bind k select-pane -U
                bind h select-pane -L
                bind l select-pane -R
                
                # prefix > z = zoom // prefix > shift + w = switch while zoomed
                bind -r W select-pane -t .+1 \;  resize-pane -Z
                
                # color fix
                set-option -ga terminal-overrides ",xterm-256color:Tc"
            '';
        };
    };
}
