#!/usr/bin/env bash
set -euo pipefail
# 2026 battle-tested verifier -- gentoo-nexus. Returns 0 only if agent truly finished.
# Evidence must be FRESH: tied to this RUN_ID (copy-forward from previous relay fails).
RUN_ID="${RUN_ID:-}"
RELAY=".opencode-relay.md"
FAIL=0
echo "----- VERIFICATION REPORT -----"
if [[ -z "$RUN_ID" ]]; then
  echo "WARNING: RUN_ID not set; freshness check skipped (local run)"
fi
if [[ -f "$RELAY" ]]; then
  # relay must be for THIS run
  if [[ -n "$RUN_ID" ]] && ! grep -qx "run_id: $RUN_ID" "$RELAY"; then
    echo "FAIL: NOT COMPLETE -- relay is not for this run (expected run_id: $RUN_ID)"
    FAIL=1
  else
    echo "PASS: relay run_id matches this run"
  fi
  dep_rows=$(grep -c "deps-verified\|deps-fixed" "$RELAY" 2>/dev/null || echo 0)
  echo "Dependency table rows: $dep_rows (need >=18, need 18 rows deps-verified/deps-fixed)"
  if [[ "$dep_rows" -lt 18 ]]; then
    echo "FAIL: NOT COMPLETE -- dependency audit table has $dep_rows rows, need 18"
    FAIL=1
  else
    echo "PASS: Dependency table: $dep_rows rows"
  fi
  # Fresh evidence section must exist and mention this run's tools with PASS
  for tool in "pkgcheck scan" "emerge --pretend" "equery"; do
    if ! grep -qi "$tool.*PASS\|PASS.*$tool" "$RELAY"; then
      echo "FAIL: NOT COMPLETE -- relay missing fresh evidence for $tool (2026 h. checks, with PASS result)"
      FAIL=1
    fi
  done
  if ! grep -qi "install-test table\|emerge --usepkgonly" "$RELAY"; then
    echo "FAIL: NOT COMPLETE -- install-test table missing in relay"
    FAIL=1
  else
    echo "PASS: Install-test table present"
  fi
  if ! grep -qi "DOCKER BATTLE TEST\|docker.*stage3\|ldd.*not found" "$RELAY"; then
    echo "FAIL: NOT COMPLETE -- relay missing Docker battle test evidence (stage3 + ldd)"
    FAIL=1
  fi
else
  echo "FAIL: NOT COMPLETE -- $RELAY missing"
  FAIL=1
fi
bad=0
for eb in */*/*.ebuild; do
  [[ -f "$eb" ]] || continue
  if ! grep -q "^EAPI=" "$eb" 2>/dev/null; then echo "FAIL: $eb missing EAPI"; bad=$((bad+1)); fi
done
if [[ "$bad" -gt 0 ]]; then echo "FAIL: NOT COMPLETE -- $bad ebuilds malformed"; FAIL=1; fi
if [[ "$FAIL" -ne 0 ]]; then echo "FAIL: NOT COMPLETE -- agent must continue working"; exit 1; fi
echo "PASS: VERIFICATION PASSED -- all 18 deps rows, fresh evidence, install+battle test present"
exit 0
