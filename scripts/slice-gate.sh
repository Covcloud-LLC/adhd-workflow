#!/usr/bin/env bash
# slice-gate.sh — the machine witness for a slice.
#
# Run by the orchestrator, never by a subagent. Decides by exit code alone; no
# model is in the decision path. It reads, it runs commands, it reports. It does
# not commit, does not retry, and does not modify the tree.
#
#   slice-gate.sh preflight  <check-cmd> <check-paths...>
#       0  genuine red: every check path exists and is non-empty, and the
#          check fails with an assertion failure (exit 1)
#       1  the check passes — vacuous check, or the work is already done
#       2  harness error: a check path is missing or empty, or the check
#          could not run (exit 2..125 or >= 126) — halt, distinct from red;
#          a red is only evidence when the check is red for the reason the
#          slice claims (docs/notes/slice-gate-convention.md, fact one)
#
#   slice-gate.sh postflight <check-cmd> <tree-cmd> <check-paths...> <agent-a-sha>
#       0  check green, whole-tree green, and agent A's check files untouched
#          — untouched means BOTH `git diff --name-only <sha>` and
#          `git status --porcelain` are empty under the check paths, so an
#          added file is caught as well as a modification (convention, fact five)
#       1  any one of those is false
#
# No `set -e`: every command's exit status is inspected deliberately, and a
# swallowed status here would be a false green.

usage() {
    cat >&2 <<'EOF'
usage:
  slice-gate.sh preflight  <check-cmd> <check-paths...>
  slice-gate.sh postflight <check-cmd> <tree-cmd> <check-paths...> <agent-a-sha>
EOF
    exit 1
}

say() {
    printf 'slice-gate: %s\n' "$1" >&2
}

preflight() {
    [ $# -ge 2 ] || usage
    check=$1
    shift

    # Fact one: the check must be able to run before its exit code means
    # anything. A missing or empty check file "fails" too — with the same
    # non-zero status a real red has — and would green-light agent B on a
    # check that never ran.
    for path in "$@"; do
        if [ ! -e "$path" ]; then
            say "preflight: harness error: check path does not exist: $path"
            exit 2
        fi
        if [ -d "$path" ]; then
            if [ -z "$(find "$path" -mindepth 1 -print 2>/dev/null | head -n 1)" ]; then
                say "preflight: harness error: check path is empty: $path"
                exit 2
            fi
        elif [ ! -s "$path" ]; then
            say "preflight: harness error: check path is empty: $path"
            exit 2
        fi
    done

    sh -c "$check"
    code=$?
    case $code in
        0)
            say "preflight: check command passed before the work was done: $check"
            say "a check that is already green is vacuous, or the work already exists."
            exit 1
            ;;
        1)
            exit 0
            ;;
        *)
            say "preflight: harness error: check command could not run (exit $code): $check"
            say "127 = command not found, 126 = not executable, 2 = usage/syntax error."
            say "this is not a red; the check never made an assertion."
            exit 2
            ;;
    esac
}

postflight() {
    # check-cmd, tree-cmd, at least one check path, and the sha.
    [ $# -ge 4 ] || usage
    check=$1
    tree=$2
    shift 2

    # The sha is the last argument; everything before it is a check path.
    # The `for` list is expanded once, so appending to "$@" inside is safe.
    n=$#
    i=0
    sha=
    for arg in "$@"; do
        i=$((i + 1))
        if [ "$i" -eq "$n" ]; then
            sha=$arg
        else
            set -- "$@" "$arg"
        fi
    done
    shift "$n"  # drop the originals; "$@" is now the check paths

    sh -c "$check"
    if [ $? -ne 0 ]; then
        say "postflight: check command failed: $check"
        exit 1
    fi

    sh -c "$tree"
    if [ $? -ne 0 ]; then
        say "postflight: whole-tree check failed: $tree"
        exit 1
    fi

    touched=$(git diff --name-only "$sha" -- "$@")
    if [ $? -ne 0 ]; then
        say "postflight: could not diff against $sha"
        exit 1
    fi
    if [ -n "$touched" ]; then
        say "postflight: check files modified since $sha:"
        printf '%s\n' "$touched" | sed 's/^/slice-gate:   /' >&2
        say "the implementing agent may not edit the check that judges it."
        exit 1
    fi

    # Fact five: git diff sees only tracked files, so it misses a file agent B
    # ADDS under a check path — which a globbing test harness would execute.
    # git status --porcelain, scoped to the same paths, sees additions.
    dirty=$(git status --porcelain -- "$@")
    if [ $? -ne 0 ]; then
        say "postflight: could not read git status for the check paths"
        exit 1
    fi
    if [ -n "$dirty" ]; then
        say "postflight: files added or changed under check paths (git status --porcelain):"
        printf '%s\n' "$dirty" | sed 's/^/slice-gate:   /' >&2
        say "the implementing agent may not add files beside the check that judges it."
        exit 1
    fi

    exit 0
}

[ $# -ge 1 ] || usage
command=$1
shift

case "$command" in
    preflight)  preflight "$@" ;;
    postflight) postflight "$@" ;;
    *)          say "unknown subcommand: $command"; usage ;;
esac
