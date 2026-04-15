#!/usr/bin/env bash
# Usage: mongodb-test-matrix.sh [topology,...] [version,...] [-- test command...]
# All clusters start in parallel; tests run as each cluster becomes available.
# MONGODB_URI is exported for the test command.
# Default test: mongosh ping.
#
# Examples:
#   mongodb-test-matrix.sh
#   mongodb-test-matrix.sh replset 7.0,8.0
#   mongodb-test-matrix.sh replset 7.0,8.0 -- pytest tests/ -x

set -euo pipefail

TOPOLOGIES=${1:-standalone replset sharded}
VERSIONS=${2:-6.0 7.0 8.0 8.2}

shift 2 2>/dev/null || true
[[ "${1:-}" == "--" ]] && shift
TEST_CMD=("$@")

TOPOLOGIES=$(echo "$TOPOLOGIES" | tr ',' ' ')
VERSIONS=$(echo "$VERSIONS"    | tr ',' ' ')

TOTAL=0
for V in $VERSIONS;   do
for T in $TOPOLOGIES; do TOTAL=$((TOTAL+1)); done; done

WORKDIR=$(mktemp -d /tmp/mongodb-matrix-XXXXXX)
trap "rm -rf '$WORKDIR'" EXIT

# ── Start all clusters in parallel ──────────────────────────────────────────
for VERSION in $VERSIONS; do
  for TOPOLOGY in $TOPOLOGIES; do
    (
      echo "  [$(date '+%H:%M:%S')] ▶ Starting $TOPOLOGY $VERSION..."
      OUT=$(npx mongodb-runner start --topology "$TOPOLOGY" --version "$VERSION" 2>&1) && {
        ID=$(echo  "$OUT" | grep -o 'stop --id=[^ ]*' | cut -d= -f2)
        URI=$(echo "$OUT" | tail -1)
        TMP=$(mktemp "$WORKDIR/XXXXXX")
        printf 'OK\t%s\t%s\t%s\t%s\n' "$TOPOLOGY" "$VERSION" "$ID" "$URI" > "$TMP"
      } || {
        TMP=$(mktemp "$WORKDIR/XXXXXX")
        printf 'FAIL\t%s\t%s\t\t\n' "$TOPOLOGY" "$VERSION" > "$TMP"
      }
      mv "$TMP" "$WORKDIR/${TOPOLOGY}-${VERSION}.done"
    ) &
  done
done

# ── Process results as clusters become available ─────────────────────────────
PASS=0; FAIL=0; SKIP=0
DONE=0
while [[ $DONE -lt $TOTAL ]]; do
  for f in "$WORKDIR"/*.done; do
    [[ -f "$f" ]] || continue
    [[ -f "${f%.done}.tested" ]] && continue

    IFS=$'\t' read -r STATUS TOPOLOGY VERSION ID URI < "$f"
    touch "${f%.done}.tested"
    DONE=$((DONE+1))

    if [[ "$STATUS" == "FAIL" ]]; then
      echo "  [$(date '+%H:%M:%S')] ✗ $TOPOLOGY $VERSION failed to start — skipping"
      SKIP=$((SKIP+1))
      continue
    fi

    export MONGODB_URI="$URI"
    echo "  [$(date '+%H:%M:%S')] ✓ $TOPOLOGY $VERSION ready → $URI"
    echo "  [$(date '+%H:%M:%S')] ▶ Running test..."
    T0=$SECONDS

    if [[ ${#TEST_CMD[@]} -eq 0 ]]; then
      mongosh "$URI" --eval 'db.runCommand({ping:1})' --quiet \
        && { echo "  [$(date '+%H:%M:%S')] ✓ ping OK ($((SECONDS-T0))s)";     PASS=$((PASS+1)); } \
        || { echo "  [$(date '+%H:%M:%S')] ✗ ping failed ($((SECONDS-T0))s)"; FAIL=$((FAIL+1)); }
    else
      "${TEST_CMD[@]}" \
        && { echo "  [$(date '+%H:%M:%S')] ✓ Tests passed ($((SECONDS-T0))s)"; PASS=$((PASS+1)); } \
        || { echo "  [$(date '+%H:%M:%S')] ✗ Tests failed ($((SECONDS-T0))s)";  FAIL=$((FAIL+1)); }
    fi

    echo "  [$(date '+%H:%M:%S')] □ Stopping $TOPOLOGY $VERSION..."
    npx mongodb-runner stop --id="$ID"
    echo "  [$(date '+%H:%M:%S')] □ Stopped"
  done
  sleep 0.2
done

wait

echo ""
echo "  ══════════════════════════════════════════"
printf "  Results: %d passed, %d failed, %d skipped / %d total\n" \
  "$PASS" "$FAIL" "$SKIP" "$TOTAL"
echo "  ══════════════════════════════════════════"
