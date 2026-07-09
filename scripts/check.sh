#!/usr/bin/env bash
# check.sh — this repo's whole-tree check.
#
# Everything in adhd-workflow is markdown except install.sh and the gate, so the
# tree check is: both shell scripts parse, and the gate's own tests pass.
#
# Exits 0 only if every step passes.

set -o pipefail
cd "$(dirname "$0")/.." || exit 1

failed=0

step() {
    printf '\n==> %s\n' "$*"
    "$@" || failed=1
}

step bash -n install.sh
step bash -n scripts/slice-gate.sh
step bash tests/gate_test.sh

if [ "$failed" -ne 0 ]; then
    printf '\ncheck.sh: FAILED\n' >&2
    exit 1
fi

printf '\ncheck.sh: ok\n'
