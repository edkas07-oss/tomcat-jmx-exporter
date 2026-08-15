#!/bin/bash
###############################################################################
# Downloads and verifies the pinned Java Agent, then builds the derived image.
###############################################################################
set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_ROOT="$(dirname "${SCRIPT_DIR}")"

# shellcheck source=../CONFIG
source "${PROJECT_ROOT}/CONFIG"
PROJECT_VERSION="$(<"${PROJECT_ROOT}/VERSION")"
ARTIFACT_DIR="${PROJECT_ROOT}/.artifacts"
ARTIFACT_FILE="${ARTIFACT_DIR}/jmx_prometheus_javaagent.jar"
DOWNLOAD_URL="https://github.com/prometheus/jmx_exporter/releases/download/${JMX_EXPORTER_VERSION}/jmx_prometheus_javaagent-${JMX_EXPORTER_VERSION}.jar"

verify_artifact() {
    printf '%s  %s\n' "${JMX_EXPORTER_SHA256}" "${ARTIFACT_FILE}" | sha256sum -c -
}

mkdir -p "${ARTIFACT_DIR}"

if [[ ! -f "${ARTIFACT_FILE}" ]] || ! verify_artifact >/dev/null 2>&1; then
    echo "Downloading JMX Exporter ${JMX_EXPORTER_VERSION}..."
    curl --proto '=https' --tlsv1.2 --location --fail --show-error --silent \
        "${DOWNLOAD_URL}" \
        --output "${ARTIFACT_FILE}.part"
    mv "${ARTIFACT_FILE}.part" "${ARTIFACT_FILE}"
fi

verify_artifact

echo "Building ${IMAGE_NAME}:${PROJECT_VERSION} from ${BASE_IMAGE}..."
podman build \
    --pull=never \
    --build-arg BASE_IMAGE="${BASE_IMAGE}" \
    --build-arg IMAGE_PROJECT="$(<"${PROJECT_ROOT}/PROJECT")" \
    --build-arg IMAGE_VERSION="${PROJECT_VERSION}" \
    --build-arg JMX_EXPORTER_VERSION="${JMX_EXPORTER_VERSION}" \
    --build-arg JMX_EXPORTER_SHA256="${JMX_EXPORTER_SHA256}" \
    --tag "${IMAGE_NAME}:${PROJECT_VERSION}" \
    --tag "${IMAGE_NAME}:latest" \
    "${PROJECT_ROOT}"

echo "Build completed: ${IMAGE_NAME}:${PROJECT_VERSION}"
