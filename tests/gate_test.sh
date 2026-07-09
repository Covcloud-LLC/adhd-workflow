#!/usr/bin/env bash
# Tests for scripts/slice-gate.sh — the machine witness for a slice.
#
# Run: bash tests/gate_test.sh
# Exits 0 if every assertion holds, 1 otherwise. No dependencies beyond git.

TESTS_DIR=$(cd "$(dirname "$0")" && pwd)
GATE="$TESTS_DIR/../scripts/slice-gate.sh"

TMPROOT=$(mktemp -d "${TMPDIR:-/tmp}/gate_test.XXXXXX")
trap 'rm -rf "$TMPROOT"' EXIT

pass=0
fail=0

ok() {
    pass=$((pass + 1))
    printf 'ok   - %s\n' "$1"
}

no() {
    fail=$((fail + 1))
    printf 'FAIL - %s\n' "$1"
    [ -n "$2" ] && printf '       %s\n' "$2"
}

# A throwaway git repo with one commit containing a check file.
# Prints the repo path. Callers run this in a subshell, so they must read the
# commit sha back themselves with head_sha — an assignment made in here would
# not survive.
new_repo() {
    repo="$TMPROOT/repo.$$.$pass.$fail.$RANDOM"
    mkdir -p "$repo"
    git -C "$repo" init --quiet
    git -C "$repo" config user.email gate@test
    git -C "$repo" config user.name gate
    mkdir -p "$repo/tests"
    printf 'the check\n' >"$repo/tests/check.sh"
    printf 'the source\n' >"$repo/src.txt"
    git -C "$repo" add -A
    git -C "$repo" commit --quiet -m "agent A authors the check"
    printf '%s\n' "$repo"
}

head_sha() {
    git -C "$1" rev-parse HEAD
}

# Snapshot everything the gate must not touch: HEAD, the index+worktree
# status, and the bytes of every tracked file.
snapshot() {
    git -C "$1" rev-parse HEAD
    git -C "$1" status --porcelain
    find "$1" -type f -not -path '*/.git/*' -exec cksum {} +
}

# assert_gate <name> <expected-exit> <repo> <stderr-must-contain|-> <args...>
assert_gate() {
    name=$1
    want=$2
    repo=$3
    needle=$4
    shift 4

    before=$(snapshot "$repo")
    errfile="$TMPROOT/stderr.$$"
    (cd "$repo" && bash "$GATE" "$@") >/dev/null 2>"$errfile"
    got=$?
    after=$(snapshot "$repo")

    if [ "$got" -ne "$want" ]; then
        no "$name" "expected exit $want, got $got; stderr: $(cat "$errfile")"
        return
    fi

    if [ "$before" != "$after" ]; then
        no "$name" "the gate mutated the repo"
        return
    fi

    if [ "$needle" != "-" ]; then
        if [ ! -s "$errfile" ]; then
            no "$name" "expected the failing condition on stderr, got nothing"
            return
        fi
        if ! grep -q "$needle" "$errfile"; then
            no "$name" "stderr did not name the failing condition ($needle): $(cat "$errfile")"
            return
        fi
    fi

    ok "$name"
}

PASSING='exit 0'
FAILING='exit 1'

# --- preflight -------------------------------------------------------------
# A check that is already green before the work is a vacuous check, or the
# work already exists. Either way the slice cannot proceed.
# preflight <check-cmd> <check-paths...> — the paths are the check files agent
# A authored; every one must exist and be non-empty before the command runs.

repo=$(new_repo)
assert_gate "(a) preflight exits 1 when the check passes" \
    1 "$repo" "check command passed" \
    preflight "$PASSING" tests/check.sh

repo=$(new_repo)
assert_gate "(b) preflight exits 0 when the check fails with a genuine assertion failure (1)" \
    0 "$repo" "-" \
    preflight "$FAILING" tests/check.sh

# --- preflight: fact one ----------------------------------------------------
# A red is only evidence when the check could run (see
# docs/notes/slice-gate-convention.md). A missing or empty check path, or a
# check exit other than 0/1, is a harness error: exit 2, distinct from both
# the vacuous green (1) and the genuine red (0).

repo=$(new_repo)
assert_gate "(h) preflight exits 2 when a named check path does not exist" \
    2 "$repo" "does not exist" \
    preflight "$FAILING" tests/no_such_check.sh

repo=$(new_repo)
assert_gate "(i) preflight exits 2 when any one of several check paths is missing" \
    2 "$repo" "does not exist" \
    preflight "$FAILING" tests/check.sh tests/no_such_check.sh

repo=$(new_repo)
: >"$repo/tests/empty_check.sh"
assert_gate "(j) preflight exits 2 when a named check path exists but is empty" \
    2 "$repo" "is empty" \
    preflight "$FAILING" tests/empty_check.sh

repo=$(new_repo)
assert_gate "(k) preflight exits 2 when the check command exits 127 (not found)" \
    2 "$repo" "harness error" \
    preflight 'exit 127' tests/check.sh

repo=$(new_repo)
assert_gate "(l) preflight exits 2 when the check command exits 2 (syntax/usage error)" \
    2 "$repo" "harness error" \
    preflight 'exit 2' tests/check.sh

# --- postflight ------------------------------------------------------------
# postflight <check-cmd> <tree-cmd> <check-paths...> <agent-a-sha>

repo=$(new_repo); sha_a=$(head_sha "$repo")
assert_gate "(c) postflight exits 1 when the check fails" \
    1 "$repo" "check command failed" \
    postflight "$FAILING" "$PASSING" tests/check.sh "$sha_a"

repo=$(new_repo); sha_a=$(head_sha "$repo")
assert_gate "(d) postflight exits 1 when the whole-tree check fails" \
    1 "$repo" "whole-tree check failed" \
    postflight "$PASSING" "$FAILING" tests/check.sh "$sha_a"

repo=$(new_repo); sha_a=$(head_sha "$repo")
printf 'agent B rewrote the check\n' >"$repo/tests/check.sh"
assert_gate "(e) postflight exits 1 when agent B modified the check" \
    1 "$repo" "check files modified" \
    postflight "$PASSING" "$PASSING" tests/check.sh "$sha_a"

repo=$(new_repo); sha_a=$(head_sha "$repo")
printf 'agent B did the work\n' >"$repo/src.txt"
assert_gate "(f) postflight exits 0 when check green, tree green, check untouched" \
    0 "$repo" "-" \
    postflight "$PASSING" "$PASSING" tests/check.sh "$sha_a"

# A committed modification to the check is caught too — the diff is against
# agent A's sha, not against the worktree.
repo=$(new_repo); sha_a=$(head_sha "$repo")
printf 'agent B rewrote and committed the check\n' >"$repo/tests/check.sh"
git -C "$repo" commit --quiet -am "agent B touched the check"
assert_gate "(e') postflight exits 1 when agent B committed a change to the check" \
    1 "$repo" "check files modified" \
    postflight "$PASSING" "$PASSING" tests/check.sh "$sha_a"

# Multiple check paths: a modification to any one of them trips the gate.
repo=$(new_repo)
printf 'second check\n' >"$repo/tests/check2.sh"
git -C "$repo" add -A
git -C "$repo" commit --quiet -m "agent A authors a second check"
sha_a=$(git -C "$repo" rev-parse HEAD)
printf 'agent B rewrote the second check\n' >"$repo/tests/check2.sh"
assert_gate "(e'') postflight exits 1 on a modification to any check path" \
    1 "$repo" "check files modified" \
    postflight "$PASSING" "$PASSING" tests/check.sh tests/check2.sh "$sha_a"

# --- postflight: fact five --------------------------------------------------
# An ADDED file under a check path is caught, not just a modification. git
# diff against agent A's sha cannot see an untracked file; the convention
# (docs/notes/slice-gate-convention.md) tightens the assertion with
# git status --porcelain. The check path here is a directory — the case where
# a planted file (a conftest.py, a globbed helper) can neuter a check without
# editing it.

repo=$(new_repo); sha_a=$(head_sha "$repo")
printf 'agent B did the work\n' >"$repo/src.txt"
printf 'a file agent B planted beside the checks\n' >"$repo/tests/planted.sh"
assert_gate "(m) postflight exits 1 when agent B adds a new file under a check path" \
    1 "$repo" "added" \
    postflight "$PASSING" "$PASSING" tests "$sha_a"

# ...but changes outside the check paths are agent B's legitimate work: the
# status assertion must be scoped to the check paths, not the whole tree.
repo=$(new_repo); sha_a=$(head_sha "$repo")
printf 'agent B did the work\n' >"$repo/src.txt"
printf 'a new source file\n' >"$repo/newfile.txt"
assert_gate "(m') postflight exits 0 when B's additions are outside the check paths" \
    0 "$repo" "-" \
    postflight "$PASSING" "$PASSING" tests "$sha_a"

# --- usage -----------------------------------------------------------------

repo=$(new_repo)
assert_gate "(g) an unknown subcommand exits 1 and says so" \
    1 "$repo" "usage" \
    frobnicate

repo=$(new_repo)
assert_gate "(g) preflight with no check command exits 1 and says so" \
    1 "$repo" "usage" \
    preflight

repo=$(new_repo)
assert_gate "(g) preflight with no check paths exits 1 and says so" \
    1 "$repo" "usage" \
    preflight "$FAILING"

repo=$(new_repo)
assert_gate "(g) postflight with too few arguments exits 1 and says so" \
    1 "$repo" "usage" \
    postflight "$PASSING" "$PASSING"

# --- report ----------------------------------------------------------------

printf '\n%d passed, %d failed\n' "$pass" "$fail"
[ "$fail" -eq 0 ]
