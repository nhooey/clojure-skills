---
name: clojure-repl-first
description: |
  Change Clojure or ClojureScript REPL-first and bottom up: evaluate what
  you'll touch before writing, write small documented functions, reload
  only changed namespaces (never `:reload-all`), keep each REPL trial worth
  keeping as a `deftest`, lint to zero clj-kondo warnings and run the tests
  before one full build at the end. Covers the project's dev-shell commands
  for each step, bracket repair around edits, Malli function schemas on
  boundary functions, and why a REPL hides deleted vars. Use for any change
  to Clojure or ClojureScript source in a project with an nREPL.
tags: [clojure]
allowed-tools:
  - Bash
---

# Clojure, REPL-first

Work in the REPL from the bottom up, and let tools check what reading the
code can't. A running REPL answers what a function takes and returns
today in a second; a full build answers it in minutes.

The project names its own commands for each step below, in its dev shell
(`menu` lists them, and each takes `--help`) or in its preferences file
(see [Your preferences](#your-preferences)). Use those, not the long forms
they wrap. If the nREPL isn't running, start it once in the background and
keep it.

## The loop

1. **Find out before writing.** Evaluate the functions you'll touch in the
   nREPL, on real or seeded data, to see what they take and return now.
   `clj-nrepl-eval`, where the dev shell has it, evaluates a form and
   repairs its brackets first.
2. **Write small functions, bottom up.** Each does one thing, with a
   docstring that says what it gives the caller, not how. Implementation
   notes go in `;;` comments, only where the code does something
   surprising.
3. **Edit with the edit tool.** Where the project has an edit hook that
   repairs brackets and formats with cljfmt, it runs around every edit;
   never fix brackets by hand, and never rewrite source with a script.
4. **Reload, then try it.** Reload only the namespaces that changed, with
   clj-reload or tools.namespace (`user/reload` in most projects). Never
   `(require … :reload-all)`: it reloads every dependency too, and a
   library holding state, such as a database node, can hang the JVM. Try
   the change against a throwaway in-memory instance of any store, never
   the one the running app holds.
5. **Keep what you tried.** A REPL trial worth keeping becomes a `deftest`
   beside the code's other tests, with a fixture giving each test fresh
   data. A query written as data (XTQL, HoneySQL, Datalog) gets a test
   whenever it's new: only running it shows a query the database won't
   take.
6. **Lint: zero warnings.** Run clj-kondo over every source directory. It
   takes about a second and catches what the REPL hides: a REPL keeps old
   definitions, so a renamed or deleted var still resolves there until a
   fresh build fails.
7. **Test.** Run the tests through the REPL, so they see the reloaded
   code, failing when a test does; for ClojureScript, also the project's
   JS-side tests and a compile of the app.
8. **Build once, at the end.** A full build, such as `nix build`, compiles
   everything from scratch and takes minutes: it is the last check, not a
   way to find errors. Restart the app from that build to try it whole.

## Types at boundaries

Public functions that cross a boundary (an API handler, a queue consumer,
a module's entry point) get a Malli function schema beside them:
`(m/=> name [:=> [:cat …] ret])`. With `(malli.dev/start!)` in the dev
`user` namespace, the REPL checks calls to them and writes their types for
clj-kondo to lint against.

## When to apply

- Any change to Clojure or ClojureScript source in a project with an
  nREPL.
- About to run a full build to find out whether a change works.
- About to `:reload-all`, or to fix brackets by hand.

## Your preferences

!`cat "${CLAUDE_SKILL_DIR}/../clojure-repl-first.preferences.md" "${CLAUDE_PROJECT_DIR}/.agents/skills/clojure-repl-first.preferences.md" 2>/dev/null || true`

If your agent doesn't run the line above, read these files yourself if they
exist: `clojure-repl-first.preferences.md` next to this skill's folder, then
`.agents/skills/clojure-repl-first.preferences.md` in the project. A project's
file overrides the user's, and the user's overrides this skill's defaults.

A project's file names its commands for each step (eval, reload, reset,
test, lint, build, serve), its nREPL port, its test directory and fixture,
and its own rules, such as which store not to touch from the REPL.

## Related skills

When one of these applies and it's in your skill listing, load it
without asking. If it isn't in your listing, tell the user which skill is
missing and ask whether to install it from the same collection this skill
came from; don't apply it from memory.

- `nix-clojure`: packaging the project with Nix, its dev shell's tools, and wiring cljfmt, clj-kondo and the tests in as flake checks.
- `xtdb-xtql-queries`: writing the XTQL queries that step 5 tests.
