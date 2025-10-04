#!/bin/bash
set -euo pipefail
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
REPORT="${BASE_DIR}/05_Experimental_Results/Audit_Log.md"

echo "# Integrity Audit Report" > "$REPORT"
echo "" >> "$REPORT"
echo "**Run:** $(date -Iseconds)" >> "$REPORT"
echo "" >> "$REPORT"

missing=0
while IFS= read -r -d '' file; do
  if ! grep -q "Attested by:" "$file"; then
    echo "- MISSING attestation: ${file}" >> "$REPORT"
    missing=$((missing+1))
  fi
done < <(find "$BASE_DIR" -type f \( -name "*.md" -o -name "*.yaml" -o -name "*.yml" -o -name "*.cff" \) -print0)

echo "" >> "$REPORT"
echo "**Missing attestation count:** ${missing}" >> "$REPORT"
echo "" >> "$REPORT"
echo "_Policy: merges should be blocked if missing > 0._" >> "$REPORT"
