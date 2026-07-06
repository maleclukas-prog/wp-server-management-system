#!/bin/bash
# WSMS vNext installer workspace entrypoint (PL)
# Faza planowania: ten plik pozwala rozwijać vNext bez naruszania
# produkcyjnych ścieżek w installers/.

set -euo pipefail

echo "WSMS vNext installer (PL) - workspace planowania"
echo "Aktualne zachowanie: deleguje do installers/install_wsms_pl.sh"
echo "Kolejny krok: zastąpić ten plik niezależną logiką vNext."

bash "$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)/installers/install_wsms_pl.sh" "$@"
