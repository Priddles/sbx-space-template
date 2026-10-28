# Wrappers for `sbx env` that layer the git-ignored sbxenv.local.yaml over sbxenv.yaml.
#
#   make run ARGS=--force
#   make exec CMD="npm test"
#   make clone URL=https://github.com/org/repo.git [REPO=repo]

SBXENV_FILES := sbxenv.yaml $(wildcard sbxenv.local.yaml)

# Extra flags passed to the sbx subcommand
ARGS ?=
# Command run by `make exec`
CMD ?= bash

# Repository to clone, and its directory name (defaults to the URL's basename)
URL ?=
REPO ?= $(basename $(notdir $(URL)))

SBX_ENV = sbx env

.DEFAULT_GOAL := help
.PHONY: help plan create run exec rm clone

help:
	@echo "usage: make <plan|create|run|exec|rm> [ARGS=...] [CMD=...]"
	@echo "       make clone URL=<url> [REPO=<name>]"
	@echo "files: $(SBXENV_FILES)"

plan create run rm:
	$(SBX_ENV) $@ $(SBXENV_FILES) $(ARGS)

exec:
	$(SBX_ENV) exec $(SBXENV_FILES) $(ARGS) -- $(CMD)

# Clone URL bare into .repos/REPO.git and add a worktree of its default branch at src/REPO.
# Not `git clone --bare`: it sets no fetch refspec, so origin/* is never updated and every remote
# branch becomes a local one. The fetch is the equivalent of
# `--depth=1 --no-single-branch --filter=blob:none`.
clone:
	@test -n "$(URL)" || { echo "usage: make clone URL=<url> [REPO=<name>]" >&2; exit 1; }
	@set -e; \
	repo=".repos/$(REPO).git"; tree="src/$(REPO)"; \
	if [ -e "$$repo" ] || [ -e "$$tree" ]; then echo "$(REPO) already exists" >&2; exit 1; fi; \
	git init --quiet --bare "$$repo"; \
	git -C "$$repo" remote add origin "$(URL)"; \
	git -C "$$repo" config remote.origin.promisor true; \
	git -C "$$repo" config remote.origin.partialclonefilter blob:none; \
	git -C "$$repo" fetch --quiet --depth=1 --filter=blob:none origin; \
	git -C "$$repo" remote set-head origin --auto >/dev/null; \
	branch=$$(git -C "$$repo" symbolic-ref --short refs/remotes/origin/HEAD); \
	branch=$${branch\#origin/}; \
	git -C "$$repo" symbolic-ref HEAD "refs/heads/$$branch"; \
	git -C "$$repo" worktree add --quiet --track -b "$$branch" "$$tree" "origin/$$branch"
