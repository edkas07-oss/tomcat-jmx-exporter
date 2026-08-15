# Tomcat JMX Exporter

Derived container image untuk menambahkan **Prometheus JMX Exporter Java Agent**
ke dalam JVM Apache Tomcat. Image ini menggunakan `localhost/tomcat:9.0`
sebagai base image dan tidak mengaktifkan remote JMX.

Endpoint metrics hanya disajikan melalui HTTPS dengan server-side TLS. Client
certificate tidak diperlukan. Konfigurasi exporter, TLS keystore, dan password
keystore selalu diberikan saat runtime sehingga tidak tersimpan di image.

## Repository Boundary

Repository ini memiliki tanggung jawab terbatas:

- membangun image turunan Tomcat;
- mengunduh dan memverifikasi JMX Exporter Java Agent versi yang dipin;
- memasang Java Agent ke `CATALINA_OPTS`;
- memvalidasi kontrak file konfigurasi dan TLS pada startup; dan
- menyediakan build serta smoke test lokal.

Metric rules untuk environment, Prometheus, Telegraf, dashboard, alert, dan
integrasi event merupakan tanggung jawab repository `tomcat-monitoring`.

## Runtime Contract

| Item | Contract |
|---|---|
| Base image | `localhost/tomcat:9.0` |
| Image | `localhost/tomcat-jmx-exporter:1.0.0` |
| JMX Exporter | Java Agent `1.6.0`, checksum SHA-256 dipin di `CONFIG` |
| Metrics endpoint | `https://<container>:9404/metrics` |
| Exporter config | `/etc/tomcat-jmx-exporter/config.yml` |
| TLS keystore | `/run/secrets/tomcat-jmx-exporter/keystore.p12` |
| Keystore password | `/run/secrets/tomcat-jmx-exporter/keystore-password` |
| TLS mode | Server-side TLS, tanpa mTLS |

File konfigurasi harus menggunakan `${JMX_EXPORTER_KEYSTORE_PASSWORD}` pada
`httpServer.ssl.keyStore.password`. Entrypoint membaca nilai tersebut dari file
password dan tidak mencetaknya ke log.

## Repository Structure

```text
tomcat-jmx-exporter/
├── CONFIG
├── Containerfile
├── PROJECT
├── README.md
├── VERSION
├── entrypoint.sh
├── examples/
│   └── jmx-exporter.yml
└── scripts/
    ├── build.sh
    ├── clean.sh
    ├── run.sh
    └── test.sh
```

## Build

Base image harus sudah tersedia secara lokal.

```bash
./scripts/build.sh
```

Build script mengunduh artifact resmi JMX Exporter ke `.artifacts/`,
memverifikasi SHA-256, lalu menjalankan build dengan `--pull=never`.

## Smoke Test

```bash
./scripts/test.sh
```

Test membuat certificate dan PKCS12 keystore sementara, menjalankan container,
lalu memastikan `/metrics` dapat diakses melalui HTTPS dan metric JVM tersedia.
Seluruh material TLS test dihapus setelah test selesai.

## Local Run

Siapkan config, PKCS12 keystore, dan file password, kemudian jalankan:

```bash
./scripts/run.sh \
  /path/to/jmx-exporter.yml \
  /path/to/keystore.p12 \
  /path/to/keystore-password \
  tomcat-app 8080 9404
```

Contoh file konfigurasi menunjukkan bentuk interface minimum. Gunakan metric
rules dari repository `tomcat-monitoring` untuk implementasi sebenarnya.

## Upstream Reference

- <https://prometheus.github.io/jmx_exporter/>
- <https://prometheus.github.io/jmx_exporter/deployment/modes/>
- <https://prometheus.github.io/jmx_exporter/configuration/ssl/>
- <https://github.com/prometheus/jmx_exporter/releases/tag/1.6.0>

