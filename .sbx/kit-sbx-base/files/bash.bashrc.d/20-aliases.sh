# Aliases shared by every user of the image. Personal aliases belong in ~/.bash_aliases.
alias dc='docker compose'
alias g='git'
alias gi='git'
alias ll='ls -alh'
alias nr='npm run'

# Complete aliases as the command they expand to.
if [ -r /usr/local/share/complete-alias/complete_alias ]; then
    . /usr/local/share/complete-alias/complete_alias
    complete -F _complete_alias dc g gi
fi
