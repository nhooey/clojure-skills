#!/usr/bin/env bash
# Run skill-lint.sh ($1) on small skill trees, one problem each, and
# require that it fails on each with the matching message and passes on
# a clean tree.
set -euo pipefail

lint=${1:?usage: skill-lint-test.sh SKILL_LINT_SH}
work=$(mktemp -d)
trap 'rm -rf "$work"' EXIT
failures=0

# make_skill DIR NAME SKILL_MD_BODY: write DIR/NAME/SKILL.md.
make_skill() {
  mkdir -p "$1/$2"
  printf '%s\n' "$3" >"$1/$2/SKILL.md"
}

good_frontmatter='---
name: demo
description: |
  A demo skill
  over two lines.
---'

# expect_fail CASE PATTERN: lint $work/CASE must exit 1 and print PATTERN.
expect_fail() {
  local out
  if out=$(bash "$lint" "$work/$1" 2>&1); then
    echo "FAIL $1: lint passed, expected: $2"
    failures=$((failures + 1))
  elif ! grep -qF -- "$2" <<<"$out"; then
    echo "FAIL $1: expected '$2' in:"
    printf '%s\n' "$out"
    failures=$((failures + 1))
  else
    echo "ok   $1"
  fi
}

make_skill "$work/clean" demo "$good_frontmatter

# Demo

See [Usage](#usage) and [notes](notes.md#the-notes), not \`[code](nowhere.md)\`.

## Usage
"
printf '# The notes\n' >"$work/clean/demo/notes.md"
if bash "$lint" "$work/clean" >/dev/null; then
  echo "ok   clean"
else
  echo "FAIL clean: lint failed on a clean skill"
  bash "$lint" "$work/clean" || true
  failures=$((failures + 1))
fi

mkdir -p "$work/no-skill-md/demo"
expect_fail no-skill-md "no SKILL.md"

make_skill "$work/no-frontmatter" demo "# Demo"
expect_fail no-frontmatter "no closed --- frontmatter block"

make_skill "$work/unclosed" demo "---
name: demo
description: x"
expect_fail unclosed "no closed --- frontmatter block"

make_skill "$work/wrong-name" demo "---
name: other
description: x
---"
expect_fail wrong-name "frontmatter name 'other' differs from directory 'demo'"

make_skill "$work/bad-name" Demo "---
name: Demo
description: x
---"
expect_fail bad-name "is not 1-64 lowercase letters"

make_skill "$work/no-description" demo "---
name: demo
---"
expect_fail no-description "frontmatter has no description"

make_skill "$work/empty-block-description" demo "---
name: demo
description: |
tags: [x]
---"
expect_fail empty-block-description "frontmatter has no description"

make_skill "$work/long-description" demo "---
name: demo
description: $(printf 'x%.0s' {1..1025})
---"
expect_fail long-description "description is 1025 characters, over 1024"

make_skill "$work/missing-file" demo "$good_frontmatter
See [notes](notes.md)."
expect_fail missing-file "link to missing file: notes.md"

make_skill "$work/missing-anchor" demo "$good_frontmatter
See [Usage](#usage).
## Usages"
expect_fail missing-anchor "link to missing heading: #usage"

mkdir -p "$work/empty"
expect_fail empty "no skills found"

if ((failures > 0)); then
  echo "$failures case(s) failed"
  exit 1
fi
