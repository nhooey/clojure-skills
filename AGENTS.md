# clojure-skills

Coding-agent skills for writing Clojure and ClojureScript, packaged as a Nix
flake built by agent-skill-flake. Each skill is a directory under `skills/`
with a `SKILL.md` and its own `flake.nix`. The dev shell's own skills are
skillspkgs' `skill-collections` family combination, with no additions, taken
by the `skills-devshell/` sub-flake; they install into `.agents/skills/`.

## Build and test

- `nix develop`: enter the dev shell, which installs the dev-shell skills
- `nix fmt`: format `*.nix` with nixfmt and `*.md` / `*.yaml` with prettier
- `nix flake check`: the formatting check, a build of every package,
  `skill-lint` with its tests, and `skill-citations verify` for each skill
  with a `citations.lock.json`
- `skill-lint`: lint each skill's frontmatter and links
  (`checks/skill-lint.sh`, tested by `checks/skill-lint-test.sh`); run
  `menu` in the dev shell for the other commands
- `nix build .#agent-skill-nhooey-<skill>`: build one skill's package
