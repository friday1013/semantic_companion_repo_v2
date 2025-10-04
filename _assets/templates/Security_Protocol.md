# Security & Access Protocols

## 1. Access Control
- Repo: Read for public, Write for Canon maintainers.
- Sensitive nodes (Athena/Foundry): SSH key + Canon token authentication.

## 2. Data Transmission
- All communication via SSH-tunneled HTTPS.
- No external API calls outside attested systems.

## 3. Backups
- Daily snapshots of /04_Companion_Records and /05_Experimental_Results.
- Versioning through Git commits with attestation.

## 4. Verification
- Every commit includes `attested_by:`
- Use SHA256 checksums for file integrity.

## 5. Incident Handling
- Log anomalies in `/05_Experimental_Results/Observations_and_Findings.md`
- Severity tags: [minor] / [critical] / [ethical]
