# CLAUDE.md

## Workspace layout

This repository is a **workspace wrapper**: a small git repo of its own holding the environment
config (`.sbx/`, `.devcontainer/`) and workspace-level docs. The project code lives in
**independent git repositories**, each with its own history, branch, dependencies and build
tooling, and all gitignored by the wrapper:

- `.repos/<name>.git` — bare clone of each repository, with no working tree.
- `src/<name>` — a worktree of that repository, initially on its default branch. Work happens here.

Whether a `src/` worktree stays on the default branch or is switched for feature work is up to the
user. Check its current branch rather than assuming it, and don't switch it or add worktrees unless
asked.

- Run git and build/test commands from inside the worktree that owns the code
  (`git -C src/<name> ...`), never from the wrapper root. A command run from the root **succeeds**
  against the wrapper repo and reports its history instead, and `git log -- src/<name>/foo.ts` from
  the root returns nothing silently because the path isn't tracked there. If a git command returns
  empty or surprising output for a path, confirm you're scoped to the repo that owns that path
  before drawing any conclusion.
- Clones start shallow, so a short `git log`, or `git blame` attributing everything to one commit,
  may only reflect the clone depth. Run `git fetch --deepen=<n>` or `git fetch --unshallow` before
  drawing conclusions from history.
- Treat changes as repo-local: a change in one sub-repository does not affect the others, and
  there is no single repo spanning all of them.
- The quality gate (format, lint, test) differs per repo. Never guess it; read the repo's own
  `CLAUDE.md`, README or task runner.

## Code comments

Comments live with the code they describe. They must read independently of any document — spec,
plan, progress log, ticket, PR description — and of any line number in any file.

Do not reference:

- Any path in the wrapper repo. Those documents never reach the sub-repository the comment ships
  in, so a reader who clones that repo cannot follow the reference.
- Specific line numbers in any file (`see pkg/foo/bar.go:412`). Line numbers drift on every edit;
  the reference rots silently.
- Ticket IDs as the load-bearing explanation. A ticket ID is a pointer to a tracker that may or may
  not still exist or be accessible. Fine as a tag if the comment also stands alone without it.
- "See plan §4.3", "per AC", "as noted in the spec" — any phrase that requires the reader to fetch
  another document to make sense of the comment.

Instead: if the rationale is non-obvious, write the rationale itself into the comment. If it's too
much to inline, link to a file name (not a line) within the same repo, or restructure so the code
is self-explanatory. If you find yourself wanting to write "see X for the why", the why belongs in
the comment.

### Keep comments local and short

These rules are drawn from the user's hand edits to AI-written comments. The "write the why into
the comment" rule above covers the **local** why only.

1. **Explain only what someone editing this line needs.** Keep constraints, hazards and couplings
   that bite here, such as "changing this code needs the filter in X changed too". Cut everything
   else.
2. **Don't narrate other files, services or pipelines.** Name the source of a value once at most
   and stop. Don't explain how that source decides the value, who else consumes it, or which
   pipeline supplies it.
3. **One reason, not the chain.** Give the claim and its single main reason. Cut the elaborated
   consequences, the alternatives considered and the "what allows it" history.
4. **Don't restate what the code or config already shows.** No comment that repeats a name, a list,
   a threshold or a default value.
5. **Leave mechanism explanations out of the code.** Explanations of why a design is safe or
   correct are cut. If one truly matters, it belongs in the repo's README or `docs/`. This does not
   cut warnings about how something behaves (rule 6).
6. **Keep surprising behaviour.** Example: "this alarm also fires for suppressed addresses". It
   warns the reader, so rule 5 does not cut it.
7. **Skip operational how-tos and timing essays inline.** Rollout steps and tuning rationale go to
   docs, or nowhere.
8. **State the concrete consequence.** "The provider may suspend service" beats "costs the
   reputation that X depends on".
9. **Drop "as for X" / "for the same reason as Y" cross-references.** If the reason matters here,
   state it plainly.
10. **Lead with the effect, not the config.** "Open only during install, to fetch X" beats listing
    what stays closed. Absence in the config already shows that.
11. **Wrap new comments at 100 columns.** When you change an existing comment, keep its current
    wrap width.

When unsure, write the shorter comment. The user deletes long comments more readily than they add
missing ones.

## Model policy (orchestrator vs. subagents)

- The **main session acts as orchestrator**: it plans, dispatches, integrates and resolves
  cross-stream questions.
- **Subagents run on the cheapest model that fits the task.** Pass an explicit `model` on every
  `Agent` call, whatever the `subagent_type`. Do not rely on an agent definition's default model.
  - **Haiku** (`model: "haiku"`): mechanical, bounded, low-judgment work. File location and
    grep-style search, listing files, reading a single known file and reporting facts, mechanical
    renames, typo or format-only edits, and checks against a fixed checklist.
  - **Sonnet** (`model: "sonnet"`): default for implementation and review. Multi-file edits,
    writing code or tests, plan critique, diff review, and anything needing judgment about
    correctness or design.
  - **Opus** is never used for subagents. It is the main session only.
  - When unsure, pick Sonnet. Escalate a Haiku result that is incomplete or wrong to Sonnet, do not
    retry it on Haiku.
