# Repository Instructions

## Repository Purpose

Repository ini menghasilkan derived Apache Tomcat image dengan embedded JMX
Exporter Java Agent. Image menambahkan JVM dan Tomcat metrics endpoint melalui
HTTPS tanpa mengubah generic base-image ownership atau mengambil alih fungsi
monitoring platform.

## Source of Truth

- Baca `README.md` untuk usage dan verification contract yang dipublikasikan.
- Review `PROJECT`, `VERSION`, dan `CONFIG` bersama untuk image identity, base
  image, JMX Exporter version, SHA-256, network, port, dan runtime defaults.
- Review `Containerfile`, `entrypoint.sh`, `examples/jmx-exporter.yml`, dan
  `scripts/` sebelum mengubah build, startup, TLS, metrics, test, run, atau
  cleanup behavior.
- Base-image contract saat ini adalah `localhost/tomcat:9.0`; perubahan contract
  tersebut memerlukan keputusan yang disetujui.

## Repository Boundaries

- Repository memiliki derived-image layer, pinned JMX Exporter dependency,
  embedded-agent startup, HTTPS metrics interface, example configuration, dan
  local component verification.
- Generic Tomcat runtime tetap dimiliki repository `tomcat`.
- Jangan menambahkan environment-specific metrics rules, Prometheus, Telegraf,
  dashboard, alert rules, production certificate, alert routing, CI/CD
  orchestration, atau deployment automation ke repository ini.
- Monitoring integration dan delivery tetap menjadi tanggung jawab
  `tomcat-monitoring`.

## Working Rules

- Mulai dengan memeriksa Git status, source contract, scripts, dan perubahan
  pengguna yang beririsan dengan task.
- Kerjakan hanya approved scope dan pertahankan unrelated user changes.
- Gunakan `rg` atau `rg --files` untuk pencarian dan `apply_patch` untuk edit
  manual.
- Pin JMX Exporter version dan SHA-256; jangan mengubah dependency tanpa
  identity, integrity, compatibility, serta approval yang jelas.
- Jangan menyimpan downloaded JAR, generated certificate, private key,
  password, atau test artifact di Git.

## Approval Requirements

- Read-only inspection yang relevan dapat dilakukan tanpa approval tambahan.
- Source atau configuration change memerlukan approved implementation plan dan
  explicit scope.
- Download dependency atau local image build memerlukan approved implementation
  atau verification scope; network access tidak diasumsikan tersedia.
- Temporary self-cleaning component test boleh dijalankan hanya dalam approved
  verification scope.
- Persistent run, image publication, dan cleanup container atau image
  memerlukan target serta authorization terpisah. Cleanup image merupakan
  destructive action.

## Verification

- Jalankan shell syntax dan source validation yang tersedia sebelum build.
- Klaim build dan smoke test hanya berlaku jika current source dibangun lebih
  dahulu, lalu image hasil build tersebut diuji.
- Gunakan `scripts/test.sh` sebagai local component verification interface.
- Local component test membuktikan local HTTPS metrics endpoint dan minimum dua
  JVM metrics; test tersebut tidak membuktikan Prometheus, Telegraf, alerting,
  CI/CD, deployment, atau end-to-end topology.
- Catat command, source revision, expected result, actual result, dan evidence.
  Jangan menggunakan hasil test image lama untuk memverifikasi current source.

## Git and External State

- Jangan commit, push, membuat tag atau release, memublikasikan image, atau
  deploy tanpa authorization terpisah.
- Izin mengedit tidak mengizinkan build, test, persistent run, cleanup, commit,
  atau push secara otomatis.
- Jangan reset, checkout, atau menimpa perubahan pengguna.
- Perlakukan downloaded artifact, local image, container, network, registry,
  dan target runtime sebagai state yang terpisah dari source repository.

## Secrets and Sensitive Data

- Jangan menyimpan production certificate, private key, password, token,
  credential, generated JAR, atau generated test artifact di Git atau image
  layer yang dipublikasikan.
- Test certificate harus bersifat sementara, terisolasi, dan dibersihkan oleh
  verification flow.
- Gunakan placeholder untuk secret dan hentikan pekerjaan jika output atau
  build context berisiko mengekspos sensitive material.

## Documentation Handoff

- Perbarui `README.md` bila derived-image contract, configuration interface,
  atau local verification usage berubah.
- Catat implementasi, authorization, dan evidence pada Engineering Journal
  Tomcat Monitoring di DevOps Engineering Handbook.
- Buat atau tautkan ADR bila base-image contract, security boundary, atau
  monitoring architecture berubah secara signifikan.
- Promosikan prosedur reusable ke root How-to dan konsolidasikan current state
  ke project pages tanpa menduplikasi source.

## Stop Conditions

Berhenti dan minta direction jika base-image atau repository boundary tidak
jelas, dependency identity atau checksum belum ditetapkan, scope perlu
diperluas, required decision belum accepted, current source belum dapat
dihubungkan dengan image yang diuji, target destructive action tidak spesifik,
secret berisiko terekspos, akses belum disetujui, atau evidence tidak cukup
untuk klaim build maupun verification.
