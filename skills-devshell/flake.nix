{
  description = "clojure-skills dev-shell skill set — an isolated sub-flake invoked at RUNTIME by the root devShell, never a root input. The skill source (skillspkgs' `skill-collections` family combination) lives only in THIS flake's lock, so the root clojure-skills stays a leaf with zero skill inputs and transitive consumers never drag the skill mesh in.";

  inputs = {
    nixpkgs.url = "github:NixOS/nixpkgs/nixos-unstable";
    systems.url = "github:nix-systems/default";

    # The builder lib. agent-skill-flake carries zero skill inputs, so it does
    # not drag the skill mesh into this sub-flake's lock — only the skill
    # source below does.
    agent-skill-flake = {
      url = "github:nhooey/agent-skill-flake";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    # skillspkgs' per-family combinations, surfaced through their own subdir
    # flake. It follows this flake's `nixpkgs` but NOT `agent-skill-flake`:
    # forcing the combination's transitive sources onto one pinned builder
    # surfaces an ownerless aggregate-key the strict namespace check rejects.
    # `mkDevshellSkillsFlake` still runs from this flake's
    # `agent-skill-flake.lib`, so the combiner is the pinned rev above.
    skillspkgs-combinations = {
      url = "github:nhooey/skillspkgs?dir=sources/combinations";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  # One `mkDevshellSkillsFlake` call: the dev shell's whole skill set is the
  # skill-collections family's combination, with no additions. This repo's
  # own Clojure skills are not installed here: the repo holds Nix, Markdown
  # and shell, not Clojure code.
  outputs =
    {
      nixpkgs,
      agent-skill-flake,
      ...
    }@inputs:
    agent-skill-flake.lib.mkDevshellSkillsFlake {
      inherit nixpkgs;
      systems = import inputs.systems;
      name = "shell-skills-devshell";
      # envName and packagePrefix are left at their library defaults:
      # mkDevshellSkillsFlake derives envName = "agent-skills-${name}"
      # (== agent-skills-shell-skills-devshell) and packagePrefix
      # defaults to "agent-skill-".
      sources = [
        { source = inputs.skillspkgs-combinations.combinations.skill-collections; }
      ];
    };
}
