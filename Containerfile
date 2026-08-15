###############################################################################
#
# Project : Tomcat JMX Exporter
# File    : Containerfile
#
# Builds a derived Tomcat image containing the Prometheus JMX Exporter Java
# Agent. Runtime rules and TLS material are supplied by the consuming project.
#
###############################################################################

ARG BASE_IMAGE=localhost/tomcat:9.0
FROM ${BASE_IMAGE}

ARG IMAGE_PROJECT
ARG IMAGE_VERSION
ARG JMX_EXPORTER_VERSION
ARG JMX_EXPORTER_SHA256

ENV PROJECT=${IMAGE_PROJECT} \
    VERSION=${IMAGE_VERSION} \
    JMX_EXPORTER_VERSION=${JMX_EXPORTER_VERSION} \
    JMX_EXPORTER_PORT=9404 \
    JMX_EXPORTER_CONFIG=/etc/tomcat-jmx-exporter/config.yml \
    JMX_EXPORTER_KEYSTORE=/run/secrets/tomcat-jmx-exporter/keystore.p12 \
    JMX_EXPORTER_KEYSTORE_PASSWORD_FILE=/run/secrets/tomcat-jmx-exporter/keystore-password

LABEL org.opencontainers.image.title="${IMAGE_PROJECT}" \
      org.opencontainers.image.description="Apache Tomcat with embedded Prometheus JMX Exporter instrumentation" \
      org.opencontainers.image.version="${IMAGE_VERSION}" \
      org.opencontainers.image.authors="Edkas07" \
      org.opencontainers.image.source="http://localhost:3000/gitadm/tomcat-jmx-exporter.git" \
      io.prometheus.jmx-exporter.version="${JMX_EXPORTER_VERSION}"

COPY .artifacts/jmx_prometheus_javaagent.jar /opt/jmx-exporter/jmx_prometheus_javaagent.jar

RUN printf '%s  %s\n' \
        "${JMX_EXPORTER_SHA256}" \
        /opt/jmx-exporter/jmx_prometheus_javaagent.jar \
        | sha256sum -c - \
    && chmod 0444 /opt/jmx-exporter/jmx_prometheus_javaagent.jar

COPY entrypoint.sh /jmx-exporter-entrypoint.sh
RUN chmod 0555 /jmx-exporter-entrypoint.sh

EXPOSE 9404

ENTRYPOINT ["/jmx-exporter-entrypoint.sh"]
