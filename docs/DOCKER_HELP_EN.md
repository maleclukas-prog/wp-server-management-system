# WSMS Docker Help (EN)

This document collects the most useful Docker and Docker Compose commands for WSMS testing.

## 1. Where to run commands

Work from the project directory:

```bash
cd /path/to/wp-server-management-system
```

Note: `/path/to/wp-server-management-system` is a placeholder. Replace it with your local repository path.

Check Docker health:

```bash
docker version
docker info
```

Important:

- To ensure all commands shown by `wp-help` work correctly, install ClamAV (WSMS security modules rely on antivirus components).
- WSMS is an author-driven personal server management system and includes solutions used in the author's own environment.

## 2. Quick Docker test (recommended)

Run a full Ubuntu installer smoke test with a safe WordPress fixture:

```bash
bash tests/run_docker_smoke_test.sh
```

If you want to inspect the container in VS Code after the run (Containers view), keep it instead of auto-removing it:

```bash
WSMS_DOCKER_KEEP_CONTAINER=1 bash tests/run_docker_smoke_test.sh
```

Use a stable debug container name:

```bash
WSMS_DOCKER_KEEP_CONTAINER=1 WSMS_DOCKER_CONTAINER_NAME=wsms-smoke-debug bash tests/run_docker_smoke_test.sh
```

Remove the kept debug container when done:

```bash
docker rm -f wsms-smoke-debug
```

What this test does:

- builds image from `tests/docker/Dockerfile`,
- prepares a safe WP fixture from `tests/fixtures/wordpress/public_html`,
- runs `installers/install_wsms.sh`,
- validates key install artifacts (scripts, aliases, crontab).

## 2.1 Runtime behavior smoke test (backup/cleanup/logging)
## 2.2 SSL Certificate Expiry in Fleet Status

Each entry in the fleet status (`wp-status`) shows the number of days until the SSL certificate expires for the actual WordPress domain (resolved automatically from the WP config, not just the SITES nickname).

Example: `SSL: 74 d` means the certificate expires in 74 days. `SSL: N/A` means the certificate is unreachable or missing.

This logic is covered by Docker smoke tests.
Run extended runtime verification (inside Docker):

```bash
bash tests/run_docker_runtime_smoke_test.sh
```

Keep debug container for inspection:

```bash
WSMS_DOCKER_KEEP_CONTAINER=1 WSMS_DOCKER_CONTAINER_NAME=wsms-runtime-smoke-debug bash tests/run_docker_runtime_smoke_test.sh
```

This runtime smoke test:

- installs WSMS in a clean Ubuntu container,
- executes selected runtime scripts (`wp-help`, lite backup, full backup, retention list/clean),
- seeds old backup files and verifies emergency cleanup keeps exactly 2 newest copies,
- executes `wp-hosts-sync` twice and verifies marker-block idempotency in `/etc/hosts`,
- validates that `wp-fleet-status-monitor` output contains SSL status field (`SSL:`),
- verifies user-visible output markers,
- verifies log persistence in `~/logs/wsms/retention/retention.log` and `~/logs/wsms/sync/nas-sync.log`.

## 2.2 Full modules smoke test (20/20 scripts)

Run complete module coverage in Docker (all deployed runtime scripts):

```bash
bash tests/run_docker_all_modules_smoke_test.sh
```

What it adds on top of standard smoke tests:

- executes all runtime modules installed by WSMS,
- records PASS/WARN/FAIL for each script,
- stores per-script output in `/tmp/wsms-all-modules/*.out` inside the test container,
- prints a final matrix and pass/fail counters.

## 2.3 Complete test map (what to run, when)

Use this matrix to avoid missing checks:

1. `bash tests/test_suite.sh`
	Scope: repository-wide syntax + docs format + required files + uninstaller behavior regression.
	Run when: before every commit/PR.
2. `bash tests/run_docker_smoke_test.sh`
	Scope: installer smoke path in Ubuntu container.
	Run when: installer, shell aliases, cron, generated runtime layout changed.
3. `bash tests/run_docker_runtime_smoke_test.sh`
	Scope: runtime behavior (backup/retention/logging/NAS missing config path).
	Run when: runtime module logic changed.
4. `bash tests/run_docker_all_modules_smoke_test.sh`
	Scope: all deployed runtime modules (full coverage matrix with PASS/WARN/FAIL).
	Run when: release prep or broad refactor across many modules.
5. `bash tests/test_uninstaller_legacy_cleanup.sh`
	Scope: legacy v4.2 shell block cleanup behavior.
	Run when: uninstall logic changes.

Recommended minimum daily sequence:

```bash
bash tests/test_suite.sh
bash tests/run_docker_smoke_test.sh
```

Recommended before release:

```bash
bash tests/test_suite.sh
bash tests/run_docker_smoke_test.sh
bash tests/run_docker_runtime_smoke_test.sh
bash tests/run_docker_all_modules_smoke_test.sh
```

## 3. Same flow via Docker Compose

```bash
docker compose -f tests/docker/compose.yaml up --build --abort-on-container-exit
```

Cleanup after run:

```bash
docker compose -f tests/docker/compose.yaml down --remove-orphans
```

## 4. Manual image build and run

Build:

```bash
docker build -t wsms-smoke-test -f tests/docker/Dockerfile .
```

Run:

```bash
docker run --rm wsms-smoke-test
```

Open interactive shell in container:

```bash
docker run --rm -it --entrypoint bash wsms-smoke-test
```

## 5. Common issues and quick fixes

### Problem: No such file or directory

Usually command is run outside repo.

Fix:

```bash
cd /path/to/wp-server-management-system
pwd
```

### Problem: Permission denied / Operation not permitted

Do not run ad-hoc bind mounts outside project. Use the wrapper script:

```bash
bash tests/run_docker_smoke_test.sh
```

### Problem: Out of disk space

```bash
docker system df
docker image prune -f
docker container prune -f
docker builder prune -f
```

## 6. CI integration (GitHub Actions)

Workflow file:

- `.github/workflows/ci.yml`

It runs:

1. `bash tests/test_suite.sh`
2. smoke image build
3. smoke container run

## 7. What this test validates

Yes:

- WSMS installer path,
- runtime script generation,
- directory/log setup,
- alias and crontab configuration,
- WordPress filesystem-based checks.

No:

- real MySQL database behavior,
- full WordPress runtime with real traffic,
- production performance testing.

## 8. Recommended daily sequence

```bash
cd /path/to/wp-server-management-system
bash tests/test_suite.sh
bash tests/run_docker_smoke_test.sh
```

If both steps are green, confidence is high that installer changes are safe.

For runtime behavior checks after script changes, run additionally:

```bash
bash tests/run_docker_runtime_smoke_test.sh
```

## 8.1 Quick decision tree (what changed -> what to run)

1. I changed only documentation (`*.md`).

```bash
bash tests/test_suite.sh
```

2. I changed installer flow, aliases, cron, or generated layout.

```bash
bash tests/test_suite.sh
bash tests/run_docker_smoke_test.sh
```

3. I changed runtime module logic (`installers/*` deploy blocks for scripts).

```bash
bash tests/test_suite.sh
bash tests/run_docker_smoke_test.sh
bash tests/run_docker_runtime_smoke_test.sh
```

4. I changed many modules or prepare a release.

```bash
bash tests/test_suite.sh
bash tests/run_docker_smoke_test.sh
bash tests/run_docker_runtime_smoke_test.sh
bash tests/run_docker_all_modules_smoke_test.sh
```

5. I changed uninstaller behavior.

```bash
bash tests/test_uninstaller_legacy_cleanup.sh
bash tests/test_suite.sh
```

## 9. Two-workstation routine (Office iMac + Remote MacBook)

Use this same routine in any project (WSMS, Python, and others):

1. Open the project directory.
1. Sync only through Git before coding:

```bash
git fetch --all --prune
git pull --ff-only
```

1. Run local checks:

```bash
bash tests/test_suite.sh
bash tests/run_docker_smoke_test.sh
```

1. Commit and push only after green results.
1. Verify CI status in GitHub before switching machines.
1. On the second machine, repeat the same sequence before continuing.

Practical rule: treat iCloud as file transport, and GitHub as the source of truth and disaster recovery point.

## 10. Technical internals (how Docker tests work)

Execution flow:

1. Image is built from `tests/docker/Dockerfile` (`ubuntu:22.04`).
2. Repository is copied into `/workspace` in the image.
3. Default container command runs `tests/docker/run-install-smoke.sh`.
4. Runtime/all-modules wrappers override command to run:
	 - `/workspace/tests/docker/run-runtime-behavior-smoke.sh`
	 - `/workspace/tests/docker/run-all-modules-smoke.sh`

Container-level technical details:

- apt retries/timeouts are configured in Dockerfile (`/etc/apt/apt.conf.d/99ci-retries`).
- test user `tester` is created with passwordless sudo for deterministic setup.
- safe WordPress fixture is copied to:
	- `/var/www/site1/public_html`
	- `/var/www/site2/public_html`
- installer is executed as `tester` from `/home/tester/workspace`.

Useful environment variables in wrappers:

- `IMAGE_NAME` (default: `wsms-smoke-test`)
- `WSMS_DOCKER_KEEP_CONTAINER` (`1` keeps container for inspection)
- `WSMS_DOCKER_CONTAINER_NAME` (debug container name)

Artifacts and logs:

- all-modules report: `/tmp/wsms-all-modules/report.txt`
- all-modules per-script outputs: `/tmp/wsms-all-modules/*.out`
- runtime logs validated in tests:
	- `~/logs/wsms/retention/retention.log`
	- `~/logs/wsms/sync/nas-sync.log`

Exit behavior:

- wrappers and smoke scripts use `set -euo pipefail`.
- any failed assertion returns non-zero and fails the test.
- in all-modules smoke, WARN does not fail run; FAIL does.
