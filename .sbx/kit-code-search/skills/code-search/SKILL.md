---
name: code-search
description: Explore and search a codebase with cs and scc, and look up public repositories with the searchcode MCP. Use before Grep, Glob, find or wc whenever you need to locate code, judge a repository's size and shape, or find where something is defined.
---

# Code search

`cs` and `scc` are installed and exposed as MCP servers (`cs`, `scc`). Prefer them to `Grep`, `Glob`,
`find` and `wc -l`, which return unranked, unfiltered matches and cost more context.

## cs: find code

`cs` ranks results by relevance (BM25, complexity, file location), so the best match comes first.
There is no index to build.

```sh
cs "handleRequest" --only-declarations   # where it is defined
cs "database" --only-code                # skip comments and docs
cs "FIXME" --only-comments
cs "error" --only-strings                # where messages are defined
cs "auth AND (token OR session)"         # boolean queries
cs "retry" -i go,ts                      # limit by extension (case sensitive)
cs "retry" --format json                 # machine-readable
```

Run `cs --help` for the full flag list. Use the `cs` MCP `search` tool when it is available.

## scc: size up code

```sh
scc                     # languages, files, lines, complexity, cost estimate
scc --by-file -s complexity | head -20   # most complex files
scc --no-cocomo src/foo # one directory, without the cost estimate
```

Use it to choose where to look first, and to check whether a directory is large before reading it.

## searchcode MCP: public repositories

The `searchcode` MCP server analyses and searches any public git repository without cloning it. Use
it for third-party code, such as a dependency's source. Use `cs` for the local workspace.

## Order of work

1. `scc` to see the shape of an unfamiliar repository.
2. `cs` to locate the code.
3. `Read` only the files and ranges that `cs` pointed to.
