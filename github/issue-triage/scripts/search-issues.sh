#!/usr/bin/env bash
#
# search-issues.sh — read-only issue candidate search for the issue-triage skill.
#
# Wraps `gh search issues` with the correct, tested invocation so the caller does
# not have to reconstruct it (and trip over its two syntax gotchas):
#   1. The repo goes in the `--repo owner/name` FLAG. Putting `repo:owner/name`
#      inside the query makes gh treat the whole string as one literal phrase.
#   2. There is NO `--state` flag here. `gh search issues` searches BOTH open and
#      closed by default; `--state` only accepts `open` or `closed` (not `all`).
#
# Output: one compact line per issue (number, state, title, labels) so the caller
# pulls only lightweight fields into context — never full bodies. Read full bodies
# for a small finalist set afterward with `gh issue view <n>`.
#
# Usage:
#   scripts/search-issues.sh <owner/repo> <term> [<term> ...]
#   LIMIT=80 scripts/search-issues.sh rstudio/shiny updateSelectInput selected
#
# Example output:
#   #4381	[open]	OpenTelemetry traces on server starting up	{Priority: Low}
#
# Read-only: performs no writes. Requires `gh` authenticated with read access.

set -euo pipefail

if ! command -v gh >/dev/null 2>&1; then
  echo "error: gh (GitHub CLI) is not installed or not on PATH" >&2
  exit 127
fi

if [ "$#" -lt 2 ]; then
  echo "usage: $(basename "$0") <owner/repo> <term> [term ...]" >&2
  exit 2
fi

repo="$1"
shift
limit="${LIMIT:-50}"

gh search issues "$@" \
  --repo "$repo" \
  --limit "$limit" \
  --json number,title,state,labels,url \
  --jq '.[] | "#\(.number)\t[\(.state)]\t\(.title)\t{\([.labels[].name] | join(", "))}"'
