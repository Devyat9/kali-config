tmux pipe-pane -o "cat >> /var/log/session/tmux_#S_$(date +'%d-%m-%Y_%H_%M_%S').log"
