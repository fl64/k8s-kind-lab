#!/usr/bin/env bash

# https://unix.stackexchange.com/questions/553463/how-can-i-programmatically-get-this-layout-in-tmux
SESSION="${USER}-k8s-kind-lab"

tmux -2 kill-session -t "${SESSION}" || true
tmux -2 new-session -d -s "${SESSION}"

tmux new-window -t "${SESSION}:1" -n 'k8s-kind-lab'
tmux split-window -h # -d "echo pane 1; bash"
tmux select-pane -t 1
tmux split-window -v # -d "echo pane 2; bash"

tmux select-pane -t 0
#tmux resize-pane -L 300

tmux select-pane -t 1
#tmux resize-pane -L 100
tmux send-keys 'while true; do kubectl --context kind-dev0 -n prober-00 logs deployments/prober -f; sleep 5; done' C-m

tmux select-pane -t 2
#tmux resize-pane -L 100
tmux send-keys 'while true; do kubectl --context kind-dev1 -n prober-00 logs deployments/prober -f; sleep 5; done' C-m

# tmux select-pane -t 3
# #tmux resize-pane -L 100
# tmux send-keys 'kubectl edit cm deckhouse -n d8-system' C-m

# # # Set default window
tmux select-window -t "${SESSION}":1
tmux select-pane -t 0
# # Attach to session
tmux -2 attach-session -t "${SESSION}"


# tmux kill-session -t user-k8s-kind-lab
