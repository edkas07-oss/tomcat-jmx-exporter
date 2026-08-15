#!/bin/bash
###############################################################################
# Smoke test: starts Tomcat with an ephemeral certificate and verifies that the
# JMX Exporter serves metrics over HTTPS. No test secret is retained.
###############################################################################
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

# shellcheck source=../CONFIG
source "${PROJECT_ROOT}/CONFIG"
PROJECT_VERSION="$(<"${PROJECT_ROOT}/VERSION")"
TEST_DIR="$(mktemp -d /tmp/tomcat-jmx-exporter-test.XXXXXX)"
CONTAINER_NAME="tomcat-jmx-exporter-test-$$"
PASSWORD_FILE="${TEST_DIR}/keystore-password"
KEYSTORE_FILE="${TEST_DIR}/keystore.p12"
CERTIFICATE_FILE="${TEST_DIR}/certificate.pem"
PRIVATE_KEY_FILE="${TEST_DIR}/private-key.pem"

cleanup() {
    podman rm --force "${CONTAINER_NAME}" >/dev/null 2>&1 || true
    rm -rf -- "${TEST_DIR}"
}
trap cleanup EXIT

printf '%s\n' 'jmx-exporter-test-only' > "${PASSWORD_FILE}"
chmod 0600 "${PASSWORD_FILE}"

openssl req -x509 -newkey rsa:2048 -nodes \
    -keyout "${PRIVATE_KEY_FILE}" \
    -out "${CERTIFICATE_FILE}" \
    -days 1 \
    -subj '/CN=localhost' \
    -addext 'subjectAltName=DNS:localhost,IP:127.0.0.1' \
    >/dev/null 2>&1

openssl pkcs12 -export \
    -inkey "${PRIVATE_KEY_FILE}" \
    -in "${CERTIFICATE_FILE}" \
    -name tomcat-jmx-exporter \
    -passout "file:${PASSWORD_FILE}" \
    -out "${KEYSTORE_FILE}"

podman run --detach \
    --name "${CONTAINER_NAME}" \
    --publish 127.0.0.1::9404 \
    --volume "${PROJECT_ROOT}/examples/jmx-exporter.yml:/etc/tomcat-jmx-exporter/config.yml:ro" \
    --volume "${KEYSTORE_FILE}:/run/secrets/tomcat-jmx-exporter/keystore.p12:ro" \
    --volume "${PASSWORD_FILE}:/run/secrets/tomcat-jmx-exporter/keystore-password:ro" \
    "${IMAGE_NAME}:${PROJECT_VERSION}" \
    >/dev/null

METRICS_PORT="$(podman port "${CONTAINER_NAME}" 9404/tcp | awk -F: 'NR == 1 {print $NF}')"

for attempt in $(seq 1 30); do
    if curl --fail --silent \
        --cacert "${CERTIFICATE_FILE}" \
        "https://localhost:${METRICS_PORT}/metrics" \
        --output "${TEST_DIR}/metrics.txt"; then
        break
    fi

    if [[ "${attempt}" -eq 30 ]]; then
        podman logs "${CONTAINER_NAME}" >&2
        echo "Metrics endpoint did not become ready." >&2
        exit 1
    fi
    sleep 1
done

grep -q '^jmx_scrape_duration_seconds ' "${TEST_DIR}/metrics.txt"
grep -q '^jvm_memory_heap_used_bytes ' "${TEST_DIR}/metrics.txt"

echo "Smoke test passed: HTTPS /metrics and local JVM collection are operational."
