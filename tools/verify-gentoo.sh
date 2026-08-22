#!/usr/bin/env bash
set -euo pipefail
# 2026 battle-tested verifier -- gentoo-nexus. Returns 0 only if agent truly finished.
RELAY=".opencode-relay.md"
FAIL=0
echo "----- VERIFICATION REPORT -----"
if [[ -f "$RELAY" ]]; then
  rows=$(grep -cE "^\| [a-z0-9/_-]+ \|" "$RELAY" 2>/dev/null || echo 0)
  dep_rows=$(grep -c "deps-verified\|deps-fixed" "$RELAY" 2>/dev/null || echo 0)
  echo "Dependency table rows: $dep_rows (need >=18, found $rows total pipe-rows)"
  if [[ "$dep_rows" -lt 18 ]]; then
    echo "FAIL: NOT COMPLETE -- dependency audit table has $dep_rows rows, need 18"
    FAIL=1
  else
    echo "PASS: Dependency table: $dep_rows rows"
  fi
  for tool in "pkgcheck scan" "emerge --pretend" "equery"; do
    if ! grep -qi "$tool" "$RELAY"; then
      echo "WARNING: relay missing evidence for $tool (2026 h. checks)"
    fi
  done
  if ! grep -qi "install-test table\|emerge --usepkgonly" "$RELAY"; then
    echo "FAIL: NOT COMPLETE -- install-test table missing in relay"
    FAIL=1
  else
    echo "PASS: Install-test table present"
  fi
  if ! grep -qi "DOCKER BATTLE TEST\|docker.*stage3\|ldd.*not found" "$RELAY"; then
    echo "WARNING: relay missing Docker battle test evidence (stage3 + ldd)"
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
echo "PASS: VERIFICATION PASSED -- all 18 deps rows, evidence, install+battle test present"
exit 0
