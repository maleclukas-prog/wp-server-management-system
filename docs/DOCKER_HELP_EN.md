# WSMS Docker Help (EN)

This document collects the most useful Docker and Docker Compose commands for WSMS testing.

## 1. Where to run commands

Work from the project directory:

```bash
cd /Users/lukaszmalec/Documents/Work_grup_space/wp-server-management-system
```

Check Docker health:

```bash
docker version
docker info
```

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
cd /Users/lukaszmalec/Documents/Work_grup_space/wp-server-management-system
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
cd /Users/lukaszmalec/Documents/Work_grup_space/wp-server-management-system
bash tests/test_suite.sh
bash tests/run_docker_smoke_test.sh
```

If both steps are green, confidence is high that installer changes are safe.

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
