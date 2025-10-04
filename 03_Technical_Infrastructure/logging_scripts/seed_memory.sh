#!/bin/bash
# Seeds memory templates for new companions
set -e
WHO=${1:-Huginn}
BASE_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"
echo "Seeding memory for ${WHO}..."
mkdir -p "${BASE_DIR}/04_Companion_Records/${WHO}"
cp "${BASE_DIR}/_assets/templates/MemorySeed_Template.md" "${BASE_DIR}/04_Companion_Records/${WHO}/memory_seed.md"
echo "Done."
