# 🚀 Tomcat JMX Exporter — Hardened Prometheus Telemetry Image

[![Base Image](https://img.shields.io/badge/Base-tomcat%3A9.0-blue.svg)](Containerfile)
[![JMX Exporter](https://img.shields.io/badge/JMX__Exporter-1.6.0-orange.svg)](https://github.com/prometheus/jmx_exporter)
[![License](https://img.shields.io/badge/License-Apache%202.0-blue.svg)](LICENSE)
[![Security](https://img.shields.io/badge/Security-HTTPS_TLS_9404-brightgreen.svg)](CONFIG)

A derived OCI container image integrating the **Prometheus JMX Exporter Java Agent** directly into the Apache Tomcat JVM. Built on top of `localhost/tomcat:9.0`, this image exposes JVM and Tomcat internal runtime metrics exclusively over HTTPS TLS without enabling remote JMX ports.

All exporter configurations, PKCS#12 TLS keystores, and credentials are provided dynamically at runtime via secrets mounts, ensuring zero credentials or certificates reside inside the container image.

---

## 📑 Table of Contents

- [🏛️ Architecture & Runtime Contract](#️-architecture--runtime-contract)
- [📋 Runtime Contracts & Specifications](#-runtime-contracts--specifications)
- [⚙️ Baseline Configuration (`CONFIG`)](#️-baseline-configuration-config)
- [🛠️ Build, Test, & Execution Commands](#️-build-test--execution-commands)
- [📂 Repository Structure](#-repository-structure)
- [📄 License, Ownership & Disclaimer](#-license-ownership--disclaimer)

---

## 🏛️ Architecture & Runtime Contract

```mermaid
flowchart LR
    subgraph SECRETS["Runtime Secrets & Configuration"]
        CFG["jmx-exporter.yml<br/>(/etc/tomcat-jmx-exporter/)"]
        KS["keystore.p12<br/>(/run/secrets/.../keystore.p12)"]
        PW["keystore-password<br/>(/run/secrets/.../keystore-password)"]
    end

    subgraph CONTAINER["tomcat-jmx-exporter Container"]
        JVM["Apache Tomcat 9.0 JVM"]
        AGENT["JMX Exporter Java Agent (1.6.0)"]
        LOGS["/usr/local/tomcat/logs:z"]
        JVM --- AGENT
    end

    subgraph STORAGE["Persistent Storage"]
        VOL[("Named Volume<br/>tomcat_logs")]
    end

    CFG --> AGENT
    KS --> AGENT
    PW --> AGENT
    LOGS --> VOL
    AGENT ==>|HTTPS /metrics (Port 9404)| PROM["Prometheus Scraper"]
    JVM ==>|HTTP Web (Port 8080)| CLIENTS["Application Clients"]
```

---

## 📋 Runtime Contracts & Specifications

| Component | Contract / Specification |
| :--- | :--- |
| **Base Image** | `localhost/tomcat:9.0` |
| **Output Image** | `localhost/tomcat-jmx-exporter:1.0.0` |
| **JMX Exporter Agent** | Java Agent version `1.6.0` (SHA-256 pinned in `CONFIG`) |
| **Metrics Endpoint** | `https://<container>:9404/metrics` (Server-side TLS) |
| **Exporter Config Path** | `/etc/tomcat-jmx-exporter/config.yml` |
| **TLS Keystore Path** | `/run/secrets/tomcat-jmx-exporter/keystore.p12` |
| **Keystore Password Path**| `/run/secrets/tomcat-jmx-exporter/keystore-password` |
| **Auto-Healing Policy** | `--restart=on-failure:5` supervised via `systemd --user podman-restart.service` ([TM-ADR-0021](file:///home/eddywiyatno/git/devops-handbook/docs/adr/tomcat-monitoring/adr-records/TM-ADR-0021.md)) |
| **Persistent Log Volume** | `tomcat_logs` (Named Volume) mounted to `/usr/local/tomcat/logs:z` |

---

## ⚙️ Baseline Configuration (`CONFIG`)

```bash
# Base image contract
BASE_IMAGE=localhost/tomcat:9.0

# Output image identity
IMAGE_NAME=localhost/tomcat-jmx-exporter

# Pinned upstream artifact
JMX_EXPORTER_VERSION=1.6.0
JMX_EXPORTER_SHA256=a95983fd96e865d2bcdf911cc500e7c82808c27ab9fd226bf96732b6c3d8c46e

# Local runtime defaults
NETWORK=devops-lab
INSTANCE_NAME=tomcat-jmx-exporter
HTTP_HOST_PORT=8080
METRICS_HOST_PORT=9404
LOG_VOLUME=tomcat_logs
```

### Persistent Logging Policy (Zero `/tmp`)
- **Named Volume Persistence:** Tomcat logs (`catalina.out`, `localhost.*.log`, `access_log`) reside on the Podman Named Volume `tomcat_logs` mounted to `/usr/local/tomcat/logs:z`.
- **Restart Resilience:** Data remains intact across container lifecycles, enabling the **Tomcat Diagnostic Service** to perform retrospective log evidence analysis upon failure.

---

## 🛠️ Build, Test, & Execution Commands

```bash
# Build the container image locally
./scripts/build.sh

# Run automated smoke test suite (creates ephemeral certs, verifies HTTPS /metrics)
./scripts/test.sh

# Run local standalone container
./scripts/run.sh \
  /path/to/jmx-exporter.yml \
  /path/to/keystore.p12 \
  /path/to/keystore-password \
  tomcat-app 8080 9404

# Stop and remove container
./scripts/clean.sh tomcat-app
```

---

## 📂 Repository Structure

```text
tomcat-jmx-exporter/
├── AGENTS.md                  Agent governance principles
├── CONFIG                     Metadata & pinned checksum SSOT
├── Containerfile              Multi-stage OCI build definition
├── LICENSE                    Apache License 2.0
├── PROJECT                    Script-readable project identifier
├── README.md                  Technical architecture documentation
├── VERSION                    Release version
├── entrypoint.sh              Runtime credential loading & JVM bootstrap
├── examples/
│   └── jmx-exporter.yml       Reference configuration template
└── scripts/
    ├── build.sh               Build script with SHA-256 verification
    ├── clean.sh               Container cleanup utility
    ├── run.sh                 Container runner
    └── test.sh                Automated smoke test suite
```

---

## 📄 License, Ownership & Disclaimer

### 👤 Author & Ownership
This repository, along with its associated architectures, automation components, and codebases, is designed, authored, and maintained by **Eddy Wiyatno** ([@edkas07-oss](https://github.com/edkas07-oss)).

### ⚖️ License
This project is licensed under the [Apache License 2.0](LICENSE) - see the [LICENSE](LICENSE) file for complete terms and conditions.

### 🛡️ Research & Development Disclaimer
> [!NOTE]
> All research, development, architectural design, prototyping, test fixtures, and validation suites in this repository were conducted and verified exclusively within **independent, personal laboratory environments** using personal hardware, network infrastructure, and self-hosted tooling. No confidential corporate assets, proprietary production data, or third-party enterprise infrastructure were utilized in the creation or publication of this project.
