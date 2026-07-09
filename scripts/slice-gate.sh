#!/usr/bin/env bash
# slice-gate.sh — the machine witness for a slice.
#
# Run by the orchestrator, never by a subagent. Decides by exit code alone; no
# model is in the decision path. It reads, it runs commands, it reports. It does
# not commit, does not retry, and does not modify the tree.
#
#   slice-gate.sh preflight  <check-cmd>
#       0  the check fails, as it must before the work exists
#       1  the check passes — vacuous check, or the work is already done
#
#   slice-gate.sh postflight <check-cmd> <tree-cmd> <check-paths...> <agent-a-sha>
#       0  check green, whole-tree green, and agent A's check files untouched
#       1  any one of those three is false
#
# No `set -e`: every command's exit status is inspected deliberately, and a
# swallowed status here would be a false green.

usage() {
    cat >&2 <<'EOF'
usage:
  slice-gate.sh preflight  <check-cmd>
  slice-gate.sh postflight <check-cmd> <tree-cmd> <check-paths...> <agent-a-sha>
EOF
    exit 1
}

say() {
    printf 'slice-gate: %s\n' "$1" >&2
}

preflight() {
    [ $# -eq 1 ] || usage
    check=$1

    sh -c "$check"
    if [ $? -eq 0 ]; then
        say "preflight: check command passed before the work was done: $check"
        say "a check that is already green is vacuous, or the work already exists."
        exit 1
    fi
    exit 0
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
