#!/usr/bin/env bash
# Runs every test under tests/ in a clean environment, without network where unshare allows it.
#
# Usage: tests/run.sh              run every test
#        tests/run.sh --self-test  check that each kind of broken test is reported
# Output: the tests' own lines, then `tests: N passed` or `tests: FAILED`.
# Exit status: 0 when every test passed; 1 otherwise.
set -euo pipefail

TESTS_DIR=$(dirname "$(realpath "$0")")

# run_test <file> <dir>: fails on a non-zero exit, a FAIL line, no OK line or no final END.
run_test() {
  local runner=(env -i "PATH=$PATH" "HOME=$HOME")
  local output
  local status=0

  if unshare -rn true 2>/dev/null; then
    runner=(unshare -rn "${runner[@]}")
  fi

  output=$("${runner[@]}" bash "$1" 2>&1) || status=$?
  printf '%s\n' "$output"

  if [ "$status" != 0 ] || grep -q '^FAIL:' <<<"$output" || ! grep -q '^OK:' <<<"$output" \
    || [ "$(tail -n1 <<<"$output")" != END ]; then
    echo "FAIL: test ${1#"$2"/}"
    return 1
  fi
}

# run_tests <dir>: every test, so one run lists every failure.
run_tests() {
  local test
  local count=0
  local failed=0

  while read -r test; do
    count=$((count + 1))

    if ! run_test "$test" "$1"; then
      failed=1
    fi
  done < <(find "$1" -name '*.sh' -not -name run.sh -not -name lib.sh | sort)

  if [ "$failed" != 0 ]; then
    echo "tests: FAILED"
    return 1
  fi

  echo "tests: $count passed"
}

self_test() {
  local dir
  local body
  local lib="source '$TESTS_DIR/lib.sh'"

  dir=$(mktemp -d)
  # shellcheck disable=SC2064  # expand now: the local is gone at EXIT
  trap "rm -rf '$dir'" EXIT

  for body in \
    'echo "OK: x"; echo "FAIL: x"; echo END' 'echo "OK: x"; echo END; exit 3' \
    'echo END' 'echo "OK: x"' \
    "$lib; test_a() { check_equals a 1 2; }; run_tests" \
    "$lib; test_a() { check_equals a 1 1; false; }; run_tests" \
    "$lib; test_a() { check_equals a 1 1; X=; check_unset X; }; run_tests" \
    "$lib; test_a() { check_equals a 1 1; check_status s 1 true; }; run_tests" \
    "$lib; test_a() { check_equals a 1 1; }; test_b() { check_equals b 1 2; }; run_tests"; do
    echo "$body" >"$dir/broken.sh"

    if run_tests "$dir" >/dev/null; then
      echo "self-test: a broken test passed: $body"
      exit 1
    fi
  done

  echo 'echo "OK: x"; echo END' >"$dir/broken.sh"

  if ! run_tests "$dir" >/dev/null; then
    echo "self-test: a good test failed"
    exit 1
  fi

  echo "self-test ok: a FAIL line, a non-zero exit, no OK line, no END, 5 lib.sh failures"
}

case "${1:-}" in
  --self-test)
    self_test
    ;;
  "")
    run_tests "$TESTS_DIR"
    ;;
  *)
    echo "run.sh: usage: tests/run.sh [--self-test]" >&2
    exit 1
    ;;
esac
