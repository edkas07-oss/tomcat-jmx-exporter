# 📦 Installation & Deployment Guide — Tomcat JMX Exporter

[![Base Image](https://img.shields.io/badge/Base-tomcat%3A9.0-blue.svg)](Containerfile)
[![JMX Exporter](https://img.shields.io/badge/JMX__Exporter-1.6.0-orange.svg)](https://github.com/prometheus/jmx_exporter)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Security](https://img.shields.io/badge/Security-HTTPS_TLS_9404-brightgreen.svg)](CONFIG)

This guide provides comprehensive instructions for building, deploying, configuring, and verifying the **Tomcat JMX Exporter** container image across Linux and Windows container hosts.

---

## 📑 Table of Contents

- [1. System & Container Engine Prerequisites](#1-system--container-engine-prerequisites)
- [2. Building the OCI Container Image](#2-building-the-oci-container-image)
- [3. Standalone Container Execution (Podman / Docker)](#3-standalone-container-execution-podman--docker)
- [4. Automated Fleet Deployment via `tmctl`](#4-automated-fleet-deployment-via-tmctl)
- [5. Storage Volumes & Secrets Configuration](#5-storage-volumes--secrets-configuration)
- [6. Post-Installation Verification & Metrics Scrape](#6-post-installation-verification--metrics-scrape)

---

## 1. System & Container Engine Prerequisites

### Supported Operating Systems
* **Linux:** Amazon Linux 2023, Ubuntu (20.04 / 22.04 / 24.04 LTS), Debian (11 / 12), RHEL / Rocky Linux (8 / 9).
* **Windows:** Windows Server 2019 / 2022 / 2025 (via Docker Engine / WSL2 / Linux Containers).

### Container Engine Runtimes
* **Podman:** Version 4.0+ (Rootless with SELinux `:z` label support).
* **Docker Engine:** Version 24.0+.

### Network Ports Required
* **Port 8080 (HTTP):** Apache Tomcat web application traffic and health checks.
* **Port 9404 (HTTPS/TLS):** Prometheus JMX Exporter TLS scrape endpoint.

---

## 2. Building the OCI Container Image

Build the container image using the automated build script:

```bash
# Clone repository
git clone git@github.com:edkas07-oss/tomcat-jmx-exporter.git
cd tomcat-jmx-exporter

# Build local container image
./scripts/build.sh
```

This downloads the verified `jmx_prometheus_javaagent-1.6.0.jar` (checked against the cryptographic SHA-256 hash pinned in `CONFIG`) and builds:
* `localhost/tomcat-jmx-exporter:1.0.0`
* `localhost/tomcat-jmx-exporter:latest`

---

## 3. Standalone Container Execution (Podman / Docker)

Run the container locally using the helper script:

```bash
# Start container with volume mounts and TLS secrets
./scripts/run.sh
```

Or execute directly via Podman:
```bash
podman run -d \
  --name tomcat-jmx-exporter \
  --net devops-lab \
  -p 8080:8080 \
  -p 9404:9404 \
  -v ./examples/jmx-exporter.yml:/etc/tomcat-jmx-exporter/config.yml:ro,z \
  -v /opt/tm-home/secrets/keystore.p12:/run/secrets/tomcat-jmx-exporter/keystore.p12:ro,z \
  -v /opt/tm-home/secrets/keystore-password:/run/secrets/tomcat-jmx-exporter/keystore-password:ro,z \
  -v tomcat_logs:/usr/local/tomcat/logs:z \
  localhost/tomcat-jmx-exporter:1.0.0
```

---

## 4. Automated Fleet Deployment via `tmctl`

In production fleets, the workload is provisioned declaratively using `tmctl`:

```bash
# Deploy Tomcat workload
tmctl stack deploy --target tomcat

# Check container status and port mapping
tmctl stack status
```

---

## 5. Storage Volumes & Secrets Configuration

### 1. Named Log Volume (`tomcat_logs`)
Tomcat logs (`catalina.out`, `localhost.*.log`) are stored on the dedicated named volume `tomcat_logs`, mounted to `/usr/local/tomcat/logs:z`. This enables retrospective log analysis by the **Tomcat Diagnostic Service** even if the container exits.

### 2. Runtime Secrets (Zero `/tmp` Hardening)
* **Keystore:** `/run/secrets/tomcat-jmx-exporter/keystore.p12` (PKCS#12 bundle containing server certificate and private key).
* **Password:** `/run/secrets/tomcat-jmx-exporter/keystore-password` (Plaintext secret file with `0600` permissions).

---

## 6. Post-Installation Verification & Metrics Scrape

Verify application responsiveness and HTTPS metrics endpoint:

```bash
# 1. Run automated test suite
./scripts/test.sh

# 2. Verify HTTP Tomcat web root
curl -I http://localhost:8080/

# 3. Verify HTTPS JMX Exporter metrics scrape (Server-side TLS)
curl -k https://localhost:9404/metrics | grep jvm_memory_bytes_used
```
