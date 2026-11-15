# clojure-skills

Coding-agent skills for writing Clojure and ClojureScript, packaged as a Nix
flake built by agent-skill-flake. Each skill is a directory under `skills/`
with a `SKILL.md` and its own `flake.nix`. The dev shell's own skills come
from the `skills-devshell/` sub-flake and install into `.agents/skills/`.

## Build and test

- `nix develop`: enter the dev shell, which installs the dev-shell skills
- `nix fmt`: format `*.nix` with nixfmt and `*.md` / `*.yaml` with prettier
- `nix flake check`: the formatting check, a build of every package, and
  `skill-citations verify` for each skill with a `citations.lock.json`
- `nix build .#agent-skill-nhooey-<skill>`: build one skill's package
