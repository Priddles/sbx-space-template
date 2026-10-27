#!/usr/bin/env sh
set -e

ROOT=$(cd "$(dirname "$0")" && pwd)

usage() {
    echo "usage: $0 clone <url> [<name>]" >&2
    exit 1
}

# Clone <url> bare into .repos/<name>.git and add a worktree of its default branch at src/<name>.
clone() {
    [ -n "$1" ] || usage
    url=$1
    name=${2:-$(basename "$url" .git)}
    repo="$ROOT/.repos/$name.git"
    tree="$ROOT/src/$name"

    if [ -e "$repo" ] || [ -e "$tree" ]; then
        echo "$name already exists" >&2
        exit 1
    fi

    # Not `git clone --bare`: it sets no fetch refspec, so origin/* is never updated and every
    # remote branch becomes a local one. The fetch is the equivalent of
    # `--depth=1 --no-single-branch --filter=blob:none`.
    git init --quiet --bare "$repo"
    git -C "$repo" remote add origin "$url"
    git -C "$repo" config remote.origin.promisor true
    git -C "$repo" config remote.origin.partialclonefilter blob:none
    git -C "$repo" fetch --quiet --depth=1 --filter=blob:none origin
    git -C "$repo" remote set-head origin --auto >/dev/null
    branch=$(git -C "$repo" symbolic-ref --short refs/remotes/origin/HEAD)
    branch=${branch#origin/}
    git -C "$repo" symbolic-ref HEAD "refs/heads/$branch"
    git -C "$repo" worktree add --quiet --track -b "$branch" "$tree" "origin/$branch"
}

case "${1:-}" in
    clone) shift; clone "$@" ;;
    *) usage ;;
esac
