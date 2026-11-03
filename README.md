# clojure-skills

Coding-agent skills for writing Clojure and ClojureScript, packaged as a
Nix flake.

Each skill is a self-contained directory under [`skills/`](skills/) with a
`SKILL.md` that an agent loads on demand. Skills are built by
[`agent-skill-flake`](https://github.com/nhooey/agent-skill-flake).
Packaging Clojure with Nix has its own skill, `nix-clojure`, in
[nix-skills](https://github.com/nhooey/nix-skills).

## Skills

| Skill                                                      | What it does                                                                                           |
| ---------------------------------------------------------- | ------------------------------------------------------------------------------------------------------ |
| [`clojure-repl-first`](skills/clojure-repl-first/SKILL.md) | Change Clojure REPL-first: reload changed namespaces, keep trials as tests, lint and test, build once. |

A project names its own dev-shell commands for each step in
`.agents/skills/clojure-repl-first.preferences.md`.

## Install

```bash
# Preview what installing every skill would change, without writing anything
nix run github:nhooey/clojure-skills#preview

# Install all skills into the agent's skill directory
nix run github:nhooey/clojure-skills#install
```

Package outputs:

- `agent-skills-nhooey-clojure-all`: the aggregate of every skill (also `default`)
- `agent-skill-nhooey-clojure-repl-first`

## Development

```bash
nix develop      # enter the dev shell; run `menu` to list commands
nix fmt          # nixfmt over *.nix, prettier over *.md / *.yaml
nix flake check  # the treefmt check, and `skill-citations verify` for each skill with citations
```
