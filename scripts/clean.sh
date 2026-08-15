#!/bin/bash
###############################################################################
# Menghapus satu container runtime lokal. Image hanya dihapus dengan --image.
###############################################################################
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

# shellcheck source=../CONFIG
source "${PROJECT_ROOT}/CONFIG"
PROJECT_VERSION="$(<"${PROJECT_ROOT}/VERSION")"
INSTANCE="${1:-${INSTANCE_NAME}}"

podman rm --force "${INSTANCE}" 2>/dev/null || true

if [[ "${2:-}" == "--image" ]]; then
    podman rmi "${IMAGE_NAME}:latest" 2>/dev/null || true
    podman rmi "${IMAGE_NAME}:${PROJECT_VERSION}" 2>/dev/null || true
fi

echo "Pembersihan selesai untuk container: ${INSTANCE}"
