#!/bin/bash
###############################################################################
#
# Project : Tomcat JMX Exporter
# File    : entrypoint.sh
#
# Validates the runtime contract, injects JMX Exporter into the Tomcat JVM,
# then delegates startup to the entrypoint supplied by the base Tomcat image.
#
###############################################################################
set -euo pipefail

readonly AGENT_JAR=/opt/jmx-exporter/jmx_prometheus_javaagent.jar
readonly CONFIG_FILE="${JMX_EXPORTER_CONFIG:-/etc/tomcat-jmx-exporter/config.yml}"
readonly KEYSTORE_FILE="${JMX_EXPORTER_KEYSTORE:-/run/secrets/tomcat-jmx-exporter/keystore.p12}"
readonly PASSWORD_FILE="${JMX_EXPORTER_KEYSTORE_PASSWORD_FILE:-/run/secrets/tomcat-jmx-exporter/keystore-password}"
readonly EXPORTER_PORT="${JMX_EXPORTER_PORT:-9404}"

die() {
    echo "[ERROR] $1" >&2
    exit 1
}

require_readable_file() {
    local file="$1"
    local description="$2"

    [[ -f "${file}" && -r "${file}" ]] \
        || die "${description} tidak ditemukan atau tidak dapat dibaca: ${file}"
}

validate_port() {
    [[ "${EXPORTER_PORT}" =~ ^[0-9]+$ ]] \
        && (( EXPORTER_PORT >= 1 && EXPORTER_PORT <= 65535 )) \
        || die "JMX_EXPORTER_PORT harus berada pada rentang 1-65535."
}

configure_java_agent() {
    local password

    require_readable_file "${AGENT_JAR}" "JMX Exporter Java Agent"
    require_readable_file "${CONFIG_FILE}" "Konfigurasi JMX Exporter"
    require_readable_file "${KEYSTORE_FILE}" "TLS keystore"
    require_readable_file "${PASSWORD_FILE}" "File password TLS keystore"
    validate_port

    IFS= read -r password < "${PASSWORD_FILE}" || true
    [[ -n "${password}" ]] || die "File password TLS keystore tidak boleh kosong."

    export JMX_EXPORTER_KEYSTORE_PASSWORD="${password}"
    export CATALINA_OPTS="${CATALINA_OPTS:+${CATALINA_OPTS} }-javaagent:${AGENT_JAR}=0.0.0.0:${EXPORTER_PORT}:${CONFIG_FILE}"

    echo "JMX Exporter"
    echo "------------"
    echo "Mode        : Java Agent (local JVM)"
    echo "Metrics     : HTTPS 0.0.0.0:${EXPORTER_PORT}/metrics"
    echo "TLS         : Server-side TLS"
    echo "Config      : ${CONFIG_FILE}"
    echo
}

main() {
    configure_java_agent
    exec /entrypoint.sh "$@"
}

main "$@"

