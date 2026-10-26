# sbx-space-template

Launch point for sandboxed workspace wrapper.

## Quick Start

Install [Docker Sandboxes](https://docs.docker.com/ai/sandboxes/install) and run:

```sh
sbx env run --force
```

to start the sandbox. You can then SSH in using:

```sh
sbx setup ssh # Update ssh config to connect through sandboxd
ssh $SANDBOX_NAME.sbx # SETUP: Fill with final sandbox name
```

## Top Level Directories

| Name            | Description                                          |
| --------------- | ---------------------------------------------------- |
| `.devcontainer` | Devcontainer setup (uses same base image as sandbox) |
| `.sbx`          | Docker sandbox kits                                  |

## Todo

- Conveniences (including fzf, aliases)
- SearchCode, cs, and scc kits
- Chromium + MCP
- Spike: mount host git configs with new `mounts` override and include them
- Document local overrides
