#!/bin/bash
# WSMS vNext installer workspace entrypoint (EN)
# Planning phase: this file exists so vNext work can proceed without
# touching production installer paths under installers/.

set -euo pipefail

echo "WSMS vNext installer (EN) - planning workspace"
echo "Current behavior: delegates to installers/install_wsms.sh"
echo "Next step: replace this file with isolated vNext installer logic."

bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/installers/install_wsms.sh" "$@"
