#!/usr/bin/env bash
# Run the command line of every skill's "Your preferences" section under
# SKILLS_DIR ($1) the way Claude Code does, and require that it prints
# nothing when neither preferences file exists, and the user's file then
# the project's when both do.
#
# An installed skill's folder is often a symlink into the Nix store,
# `~/.claude/skills/<skill> -> /nix/store/.../<skill>`, with the user's
# `<skill>.preferences.md` beside the link. Claude Code puts the link's path
# in place of `${CLAUDE_SKILL_DIR}` as text, so the line must find the
# user's file through that path as written, not through the folder the link
# points to. The fixture's paths hold spaces, which the line must quote.
set -euo pipefail
shopt -s nullglob

skills_dir=${1:?usage: preferences-section-test.sh SKILLS_DIR}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
failures=0
found=0

# The command in the `!` lines of $1's "Your preferences" section: each
# line that is an exclamation mark and one code span, without them.
command_lines() {
  awk '/^```/ { fence = !fence; next }
       fence { next }
       /^## / { inside = ($0 == "## Your preferences"); next }
       inside && /^!`[^`]*`$/ { print substr($0, 3, length($0) - 3) }' "$1"
}

# expect_output CASE WANT LINE SKILL_DIR PROJECT: LINE, with Claude Code's
# textual substitution of SKILL_DIR and PROJECT, must exit 0 and print
# WANT on stdout. Its stderr is shown only when the case fails.
expect_output() {
  local name=$1 want=$2 line=$3 out status=0
  line=${line//'${CLAUDE_SKILL_DIR}'/"$4"}
  line=${line//'${CLAUDE_PROJECT_DIR}'/"$5"}
  out=$(bash -c "$line" 2>"$work/stderr") || status=$?
  if ((status != 0)) || [[ $out != "$want" ]]; then
    echo "FAIL $name: exit $status, expected 0 and:"
    printf '%s\n' "$want" "got:" "$out" "stderr:"
    cat "$work/stderr"
    failures=$((failures + 1))
  else
    echo "ok   $name"
  fi
}

for file in "$skills_dir"/*/SKILL.md; do
  grep -qxF '## Your preferences' "$file" || continue
  found=$((found + 1))
  skill=$(basename "$(dirname "$file")")

  lines=()
  while IFS= read -r command; do
    lines+=("$command")
  done < <(command_lines "$file")
  if ((${#lines[@]} != 1)); then
    echo "FAIL $skill: ${#lines[@]} preferences command lines, expected 1"
    failures=$((failures + 1))
    continue
  fi

  case_dir="$work/$skill"
  store="$case_dir/nix/store/hash-skill/share/claude-skills/$skill"
  skills="$case_dir/home dir/.claude/skills"
  project="$case_dir/the project"
  mkdir -p "$store" "$skills" "$project/.agents/skills"
  ln -s "$store" "$skills/$skill"

  expect_output "$skill: neither file" "" "${lines[0]}" "$skills/$skill" "$project"

  printf -- '- Never use: Brave Browser\n' >"$skills/$skill.preferences.md"
  printf -- '- Project: yes\n' >"$project/.agents/skills/$skill.preferences.md"
  expect_output "$skill: the user's file, then the project's" \
    $'- Never use: Brave Browser\n- Project: yes' \
    "${lines[0]}" "$skills/$skill" "$project"
done

if ((found == 0)); then
  echo "FAIL $skills_dir: no skill has a \"Your preferences\" section"
  failures=$((failures + 1))
fi

if ((failures > 0)); then
  echo "$failures case(s) failed"
  exit 1
fi
