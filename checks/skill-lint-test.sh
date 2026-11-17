#!/usr/bin/env bash
# Run the skill-lint command ($1) on small skill trees, one problem each,
# and require that it fails on each with the matching message and passes
# on a clean tree; then check its usage handling and exit statuses.
set -euo pipefail

lint=${1:?usage: skill-lint-test.sh SKILL_LINT}
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
  if out=$("$lint" "$work/$1" 2>&1); then
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

See [Usage](#usage) and [notes](notes.md#the-notes \"The notes\"), not \`[code](nowhere.md)\`.

1. In a list item:

   \`\`\`clojure
   (str \"[code](nowhere.md)\")
   # Not a heading
   \`\`\`

~~~text
[code](nowhere.md)
~~~

## Usage
"
printf '# The notes\n' >"$work/clean/demo/notes.md"
if "$lint" "$work/clean" >/dev/null; then
  echo "ok   clean"
else
  echo "FAIL clean: lint failed on a clean skill"
  "$lint" "$work/clean" || true
  failures=$((failures + 1))
fi

make_skill "$work/quoted-name" demo '---
name: "demo" # the skill
description: >
  A demo skill.
---'
if out=$("$lint" "$work/quoted-name" 2>&1); then
  echo "ok   quoted-name"
else
  echo "FAIL quoted-name: lint failed on a quoted name:"
  printf '%s\n' "$out"
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

make_skill "$work/invalid-yaml" demo '---
name: demo
description: "unclosed
---'
expect_fail invalid-yaml "frontmatter is not valid YAML"

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

make_skill "$work/missing-titled-file" demo "$good_frontmatter
See [notes](notes.md \"The notes\")."
expect_fail missing-titled-file "link to missing file: notes.md"

make_skill "$work/fenced-heading" demo "$good_frontmatter
See [Usage](#usage).
~~~sh
# Usage
~~~"
expect_fail fenced-heading "link to missing heading: #usage"

make_skill "$work/missing-anchor" demo "$good_frontmatter
See [Usage](#usage).
## Usages"
expect_fail missing-anchor "link to missing heading: #usage"

mkdir -p "$work/empty"
expect_fail empty "no skills found"

# expect_usage NAME STATUS PATTERN ARGS...: lint ARGS must exit STATUS
# and print PATTERN.
expect_usage() {
  local name=$1 want=$2 pattern=$3 out status=0
  shift 3
  out=$("$lint" "$@" 2>&1) || status=$?
  if ((status != want)); then
    echo "FAIL $name: exit $status, expected $want"
    failures=$((failures + 1))
  elif ! grep -qF -- "$pattern" <<<"$out"; then
    echo "FAIL $name: expected '$pattern' in:"
    printf '%s\n' "$out"
    failures=$((failures + 1))
  else
    echo "ok   $name"
  fi
}

expect_usage help 0 "usage: skill-lint" --help
expect_usage help-short 0 "usage: skill-lint" -h
expect_usage unknown-option 2 "unknown option: --nope" --nope
expect_usage two-dirs 2 "usage: skill-lint" "$work/clean" "$work/empty"
expect_usage missing-dir 2 "not a directory" "$work/absent"
mkdir -p "$work/default/skills"
cp -R "$work/clean/demo" "$work/default/skills/"
pushd "$work" >/dev/null
expect_usage default-dir-absent 2 "not a directory: skills"
cd "$work/default"
expect_usage default-dir 0 "1 skill(s) clean"
popd >/dev/null

if ((failures > 0)); then
  echo "$failures case(s) failed"
  exit 1
fi
