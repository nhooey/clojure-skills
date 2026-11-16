#!/usr/bin/env bash
# Lint every skill under the directory given as $1:
#   - SKILL.md opens with a `---` frontmatter block that is closed
#   - frontmatter `name:` equals the skill's directory name and is a valid
#     Claude Code skill name (lowercase letters, digits, hyphens, 1-64)
#   - frontmatter `description:` is present, non-empty and at most 1024
#     characters
#   - every relative Markdown link in a skill's .md files points at a file
#     that exists, and every `#anchor` link points at a heading in its file
# Prints one line per problem and exits 1 if there were any.
set -euo pipefail
shopt -s nullglob

skills_dir=${1:?usage: skill-lint.sh SKILLS_DIR}
problems=0

problem() {
  printf '%s\n' "$*" >&2
  problems=$((problems + 1))
}

# The frontmatter block of $1, without its `---` fences. Empty when the
# file has no closed block at the top.
frontmatter() {
  awk 'NR == 1 { if ($0 != "---") exit; next }
       $0 == "---" { closed = 1; exit }
       { block = block $0 "\n" }
       END { if (closed) printf "%s", block }' "$1"
}

# The description's text: an inline value, or the indented lines of a
# `|` / `>` block scalar, joined by single spaces.
description() {
  awk '/^description:/ {
         sub(/^description:[[:space:]]*/, "")
         if ($0 ~ /^[|>][-+]?$/) { block = 1; next }
         print; exit
       }
       block && /^[[:space:]]/ { sub(/^[[:space:]]+/, ""); out = out (out ? " " : "") $0; next }
       block { exit }
       END { if (block) print out }'
}

# GitHub-style anchor slug of each heading in $1, one per line.
anchors() {
  awk '/^```/ { fence = !fence; next }
       !fence && /^#+ / { sub(/^#+ +/, ""); print }' "$1" |
    tr '[:upper:]' '[:lower:]' |
    sed -e 's/[^a-z0-9 _-]//g' -e 's/ /-/g'
}

# Link targets of inline Markdown links in $1, outside code fences and
# inline code, one per line.
link_targets() {
  awk '/^```/ { fence = !fence; next } !fence { gsub(/`[^`]*`/, ""); print }' "$1" |
    grep -oE '\]\([^)[:space:]]+\)' |
    sed -e 's/^](//' -e 's/)$//' || true
}

check_links() {
  local file=$1 dir target path anchor
  dir=$(dirname "$file")
  while IFS= read -r target; do
    case $target in
      *://* | mailto:*) continue ;;
    esac
    path=${target%%#*}
    anchor=
    [[ $target == *'#'* ]] && anchor=${target#*#}
    if [[ -n $path && ! -e "$dir/$path" ]]; then
      problem "$file: link to missing file: $target"
      continue
    fi
    if [[ -n $anchor ]]; then
      local into=$file
      [[ -n $path ]] && into="$dir/$path"
      if [[ $into == *.md ]] && ! anchors "$into" | grep -qxF -- "$anchor"; then
        problem "$file: link to missing heading: $target"
      fi
    fi
  done < <(link_targets "$file")
}

found=0
for skill in "$skills_dir"/*/; do
  skill=${skill%/}
  dirname=$(basename "$skill")
  file="$skill/SKILL.md"
  found=$((found + 1))

  if [[ ! -f $file ]]; then
    problem "$skill: no SKILL.md"
    continue
  fi

  fm=$(frontmatter "$file")
  if [[ -z $fm ]]; then
    problem "$file: no closed --- frontmatter block at the top"
  else
    name=$(printf '%s\n' "$fm" | sed -n 's/^name:[[:space:]]*//p' | head -n1)
    if [[ -z $name ]]; then
      problem "$file: frontmatter has no name"
    elif [[ $name != "$dirname" ]]; then
      problem "$file: frontmatter name '$name' differs from directory '$dirname'"
    elif ! [[ $name =~ ^[a-z0-9-]{1,64}$ ]]; then
      problem "$file: name '$name' is not 1-64 lowercase letters, digits or hyphens"
    fi

    desc=$(printf '%s\n' "$fm" | description)
    if [[ -z $desc ]]; then
      problem "$file: frontmatter has no description"
    elif ((${#desc} > 1024)); then
      problem "$file: description is ${#desc} characters, over 1024"
    fi
  fi

  while IFS= read -r -d '' md; do
    check_links "$md"
  done < <(find "$skill" -name '*.md' -print0)
done

if ((found == 0)); then
  problem "$skills_dir: no skills found"
fi

if ((problems > 0)); then
  printf '%d problem(s)\n' "$problems" >&2
  exit 1
fi
printf 'skill-lint: %d skill(s) clean\n' "$found"
