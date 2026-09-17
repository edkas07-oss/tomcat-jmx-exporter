# AGENTS.md — Developer & AI Agent Guidelines for Tomcat JMX Exporter

## 🎯 Repository Purpose
This repository produces a hardened derived Apache Tomcat container image with an embedded **Prometheus JMX Exporter Java Agent**. It exposes JVM and Tomcat internal runtime metrics strictly over HTTPS TLS without modifying base image ownership or enabling insecure remote JMX ports.

## 🏛️ Architecture Rules & Non-Negotiables
1. **Zero Secret Leakage:** Keystores, passwords, and TLS private keys MUST NEVER be built into the container image; they must be mounted dynamically at runtime via secrets mounts.
2. **Server-Side HTTPS Metrics:** Metrics are exposed exclusively on Port `9404` over HTTPS server-side TLS.
3. **Pinned Upstream Artifacts:** JMX Exporter Java Agent version and SHA-256 checksums are strictly pinned in `CONFIG` and validated during the build.
4. **Two-Tier Storage Standard:** Tomcat application logs (`catalina.out`) are mapped to the `tomcat_logs` Podman Named Volume (`/usr/local/tomcat/logs:z`).
5. **Auto-Healing Invariant:** Operates with `--restart=on-failure:5` supervised by `systemd --user podman-restart.service` ([TM-ADR-0021](file:///home/eddywiyatno/git/devops-handbook/docs/adr/tomcat-monitoring/adr-records/TM-ADR-0021.md)).

## 🛠️ Build & Validation Commands
- **Build Image:** `./scripts/build.sh`
- **Smoke Test Suite:** `./scripts/test.sh`
- **Local Container Run:** `./scripts/run.sh`
- **Container Cleanup:** `./scripts/clean.sh`
