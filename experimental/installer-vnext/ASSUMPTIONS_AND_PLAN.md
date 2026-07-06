# WSMS vNext Installer - Assumptions and Plan

Status: planning only, no production deployment.

## Scope

This folder contains isolated installer copies for vNext work:

- install_wsms_vnext.sh
- install_wsms_pl_vnext.sh

Current production installers remain unchanged in installers/.

## High-Level Goal

Improve retention and emergency cleanup logic while preserving daily NAS sync and auditability.

## Confirmed Assumptions

1. Daily NAS sync remains enabled in cron and should not be removed.
2. NAS sync must log what was uploaded, already existed, and deleted.
3. Retention works per folder and per site/group (not global-only by default).
4. Databases are highest priority and should be deleted only as a last resort.
5. Emergency cleanup should be staged and re-check free space between stages.

## vNext Retention Stages (Target Behavior)

Trigger: free disk space below 20% (disk usage >= 80%).

Stage 1 (Emergency Keep-2):
- Keep 2 newest backups per site/group in each folder.
- Include DB backups per site.
- Re-check free space.

Stage 2 (Emergency Keep-1):
- Keep 1 newest backup per site/group in each folder.
- Keep 1 DB backup per site.
- Re-check free space.

Stage 3 (NAS Safety Gate):
- Validate local-vs-NAS coverage using logs plus remote filename checks.
- If missing coverage: run NAS sync and validate again.
- Re-check free space.

Stage 4 (Purge Escalation):
- If NAS coverage confirmed and still low space, allow aggressive local purge.
- DB backups must be last to remove.
- Re-check free space.

Stage 5 (Critical Alert):
- If still low space after staged cleanup, trigger critical alert and stop.

## Interactive Cleanup Menu (vNext)

Menu should be ordered by escalation, with clear names:

1. Standard retention cleanup
2. Emergency Keep-2 per site/group
3. Emergency Keep-1 per site/group
4. Housekeeping (logs/backups metadata)
5. Emergency Purge All (strong confirmation)

Optional future UX:
- Arrow-key menu via whiptail/dialog with fallback to plain text menu.

## Testing Strategy Before Any Replacement

1. Keep current installers untouched.
2. Implement logic only in vNext installers in this folder.
3. Export runtime scripts from vNext for review.
4. Run existing docker smoke tests + new targeted tests for staged retention.
5. Validate NAS coverage checks in controlled container scenario.
6. Replace production installers only after full pass.
7. Archive previous installers as backup snapshot.

## Container Feasibility (Server Simulation)

Yes, it is feasible to emulate your server in containers:

- Ubuntu app container: simulated WordPress roots, backups, cron behavior.
- NAS-mock container: SFTP endpoint and remote backup tree.
- Shared network between containers for sync tests.

This allows deterministic tests of:
- upload detection,
- local-vs-remote coverage validation,
- staged emergency retention behavior,
- cleanup escalation safety.

## Deployment Rule (Current)

No deployment now.
Only planning, implementation in isolated vNext, and tests.
