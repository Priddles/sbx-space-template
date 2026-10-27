# sbx-space-template

<!-- TEMPLATE: Update title and description for the project. -->

Launch point for sandboxed workspace wrapper.

## First Time Setup

After creating a project from this template, update the places below. Each one is marked with a
`TEMPLATE:` comment, so `git grep -n TEMPLATE:` lists any that are left.

| File                                        | Update                                                                  |
| ------------------------------------------- | ----------------------------------------------------------------------- |
| `README.md`                                 | Title, description, sandbox name in the SSH command, and clone commands |
| `sbxenv.yaml`                               | Sandbox `name`                                                          |
| `.devcontainer/devcontainer.json`           | Devcontainer `name`                                                     |
| `sbx-space-template.code-workspace`         | Rename the file, and add each `src/<repo>` to `folders`                 |
| `.sbx/kit-sbx-base/kit-sbx-base.dockerfile` | Sandbox `ENTRYPOINT` for the chosen harness                             |

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
| `.repos`        | Bare clones of the project's repositories (ignored)  |
| `.sbx`          | Docker sandbox kits                                  |
| `src`           | One worktree per repository (ignored)                |
| `CLAUDE.md`     | Workspace-wide guidance for Claude Code              |
| `commands.sh`   | Workspace commands                                   |

## Repositories

Each repository is cloned bare into `.repos`, with a worktree of its default branch in `src`:

```sh
./commands.sh clone <url> [<name>]
```

Clones start shallow and without file contents, which are fetched as needed. Run
`git fetch --unshallow` in a worktree for full history.

<!-- TEMPLATE: List the clone command for each of the project's repositories. -->

How you use the worktrees from there is up to you: keep `src` on the default branch and add your
own worktrees for feature work, or switch branches in `src` directly.

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

## Troubleshooting

### Claude Code Remote Control disconnects

If `/remote-control` reports "Remote Control disconnected" shortly after starting inside the sandbox,
enable Remote Control in sbx on the host:

```sh
sbx settings set claude.remoteControl true
```

## Todo

- SearchCode, cs, and scc kits
- Chromium + MCP
- Spike: mount host git configs with new `mounts` override and include them
- Document local overrides
