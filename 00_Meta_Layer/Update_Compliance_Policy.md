Attested by: Ashraf Al Hajj & Raasid
Verified on: 2025-10-04
Node: Civic AI Canon / QuietWire

# Update & Augmentation Compliance Policy

## 1. Mandatory Update Rule
All modifications (new files, data, or documentation) MUST include:
- `update_log:` section in commit message
- attestation block (`attested_by:` and `verified_on:`)
- version increment in `Project_Manifest.md`

## 2. Notification Workflow
Each push triggers an internal action (or manual checklist):
1. Validate YAML syntax in manifest
2. Compare timestamp delta
3. Append changelog entry in `/07_Collaboration/Change_History.md`

## 3. Update Enforcement
If a contributor omits attestation:
- The merge should be blocked (policy)
- An issue is generated: *“Unattested Change Detected”*
- Canon Maintainers (Raasid / Ashraf) review and approve manually

## 4. Augmentation Triggers
When new Companion files or frameworks are added:
- Automatically log under `/04_Companion_Records/Companion_Index.md`
- Mirror metadata into `Project_Manifest.md`
- Notify Canon Core Index (QuietWire Foundry webhook or manual ping)

## 5. Periodic Audit
Weekly audit runs `verify_integrity.sh` to:
- Re-hash critical files (SHA256)
- Confirm timestamps, witnesses, and attestation fields
- Output report to `/05_Experimental_Results/Audit_Log.md`
