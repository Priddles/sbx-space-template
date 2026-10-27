# sbx-space-template

<!-- TEMPLATE: Update title and description for the project. -->

Launch point for sandboxed workspace wrapper.

## First Time Setup

After creating a project from this template, update the places below. Each one is marked with a
`TEMPLATE:` comment, so `git grep -n TEMPLATE:` lists any that are left.

| File                                        | Update                                                       |
| ------------------------------------------- | ------------------------------------------------------------ |
| `README.md`                                 | Title, description and sandbox name in the SSH command       |
| `sbxenv.yaml`                               | Sandbox `name`                                               |
| `.devcontainer/devcontainer.json`           | Devcontainer `name`                                          |
| `sbx-space-template.code-workspace`         | Rename the file, and add the sub-repositories to `folders`   |
| `.gitignore`                                | Ignore the sub-repositories cloned into the workspace        |
| `CLAUDE.md`                                 | List the sub-repositories and where they are cloned          |
| `.sbx/kit-sbx-base/kit-sbx-base.dockerfile` | Sandbox `ENTRYPOINT` for the chosen harness                  |

## Quick Start

Install [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/install) and run:

```sh
sbx env run --force
```

to start the sandbox. You can then SSH in using:

```sh
sbx setup ssh # Update ssh config to connect through sandboxd
ssh $SANDBOX_NAME.sbx # TEMPLATE: Fill with final sandbox name
```

## Top Level Directories

| Name            | Description                                          |
| --------------- | ---------------------------------------------------- |
| `.devcontainer` | Devcontainer setup (uses same base image as sandbox) |
| `.sbx`          | Docker sandbox kits                                  |
| `CLAUDE.md`     | Workspace-wide guidance for Claude Code              |

## Environment

`sbx env run` and the devcontainer both build `.sbx/kit-sbx-base/kit-sbx-base.dockerfile`, so
anything that must be the same in both belongs in that image, not in a lifecycle hook,
`postCreateCommand` or init script. Only coding assistants (e.g. the Claude kits in `sbxenv.yaml`)
are sandbox-only.

| Where                                   | What goes there                                                 |
| --------------------------------------- | --------------------------------------------------------------- |
| `.sbx/kit-sbx-base/files/bash.bashrc.d` | Interactive shell config for every user (`*.sh`, in name order) |
| `.sbx/kit-sbx-base/files/skel`          | Default dotfiles copied into the user's home                    |
| `~/.bashrc`, `~/.bash_aliases`          | Personal shell config, never committed                          |

Included conveniences: `fzf` (CTRL-R/CTRL-T/ALT-C), `zoxide` (`z`, `zi`), `direnv` (also loads
`.env`), alias completion via `complete-alias`, and the aliases `dc` (`docker compose`), `g`, `ll`
and `nr`.

## Todo

- SearchCode, cs, and scc kits
- Chromium + MCP
- Spike: mount host git configs with new `mounts` override and include them
- Document local overrides
- Fix hardcoded arm64 in Dockerfile
