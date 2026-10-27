# Adds `z` and `zi`. `cd` is deliberately left alone: `z` jumps to a frecent match when the path
# doesn't exist, which silently sends scripts and agents to the wrong directory.
command -v zoxide >/dev/null && eval "$(zoxide init bash)"
