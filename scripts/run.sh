#!/bin/bash
###############################################################################
# Runs one local instance with externally supplied config and TLS material.
#
# Usage:
#   ./scripts/run.sh CONFIG KEYSTORE PASSWORD_FILE [INSTANCE] [HTTP] [METRICS]
###############################################################################
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

# shellcheck source=../CONFIG
source "${PROJECT_ROOT}/CONFIG"
PROJECT_VERSION="$(<"${PROJECT_ROOT}/VERSION")"

usage() {
    echo "Usage: $0 CONFIG KEYSTORE PASSWORD_FILE [INSTANCE] [HTTP_PORT] [METRICS_PORT]" >&2
    exit 2
}

[[ $# -ge 3 && $# -le 6 ]] || usage

for supplied_file in "$1" "$2" "$3"; do
    [[ -f "${supplied_file}" && -r "${supplied_file}" ]] \
        || { echo "Required file is not readable: ${supplied_file}" >&2; exit 1; }
done

CONFIG_FILE="$(readlink -f "$1")"
KEYSTORE_FILE="$(readlink -f "$2")"
PASSWORD_FILE="$(readlink -f "$3")"
INSTANCE="${4:-${INSTANCE_NAME}}"
HTTP_PORT="${5:-${HTTP_HOST_PORT}}"
METRICS_PORT="${6:-${METRICS_HOST_PORT}}"

if podman container exists "${INSTANCE}"; then
    echo "Container already exists: ${INSTANCE}" >&2
    echo "Remove it explicitly before creating a replacement." >&2
    exit 1
fi

podman network exists "${NETWORK}" || podman network create "${NETWORK}" >/dev/null

podman run --detach \
    --name "${INSTANCE}" \
    --network "${NETWORK}" \
    --publish "${HTTP_PORT}:8080" \
    --publish "${METRICS_PORT}:9404" \
    --volume "${CONFIG_FILE}:/etc/tomcat-jmx-exporter/config.yml:ro" \
    --volume "${KEYSTORE_FILE}:/run/secrets/tomcat-jmx-exporter/keystore.p12:ro" \
    --volume "${PASSWORD_FILE}:/run/secrets/tomcat-jmx-exporter/keystore-password:ro" \
    "${IMAGE_NAME}:${PROJECT_VERSION}"

echo "Container : ${INSTANCE}"
echo "Tomcat   : http://localhost:${HTTP_PORT}"
echo "Metrics  : https://localhost:${METRICS_PORT}/metrics"
