# Tomcat JMX Exporter

Image container turunan untuk menambahkan **Prometheus JMX Exporter Java Agent**
ke dalam JVM Apache Tomcat. Image ini menggunakan `localhost/tomcat:9.0`
sebagai image dasar dan tidak mengaktifkan JMX jarak jauh.

Endpoint metrics hanya disajikan melalui HTTPS dengan TLS sisi server.
Sertifikat klien tidak diperlukan. Konfigurasi exporter, TLS keystore, dan
password keystore selalu diberikan saat runtime sehingga tidak tersimpan di
image.

## Batas Tanggung Jawab Repository

Repository ini memiliki tanggung jawab terbatas:

- membangun image turunan Tomcat;
- mengunduh dan memverifikasi JMX Exporter Java Agent versi yang dipin;
- memasang Java Agent ke `CATALINA_OPTS`;
- memvalidasi kontrak file konfigurasi dan TLS pada startup; dan
- menyediakan proses build serta smoke test lokal.

Aturan metrics untuk setiap environment, Prometheus, Telegraf, dashboard,
alert, dan integrasi event merupakan tanggung jawab repository
`tomcat-monitoring`.

## Kontrak Runtime

| Komponen | Kontrak |
|---|---|
| Image dasar | `localhost/tomcat:9.0` |
| Image | `localhost/tomcat-jmx-exporter:1.0.0` |
| JMX Exporter | Java Agent `1.6.0`, checksum SHA-256 dipin di `CONFIG` |
| Endpoint metrics | `https://<container>:9404/metrics` |
| Konfigurasi exporter | `/etc/tomcat-jmx-exporter/config.yml` |
| TLS keystore | `/run/secrets/tomcat-jmx-exporter/keystore.p12` |
| Password keystore | `/run/secrets/tomcat-jmx-exporter/keystore-password` |
| Mode TLS | TLS sisi server, tanpa mTLS |

File konfigurasi harus menggunakan `${JMX_EXPORTER_KEYSTORE_PASSWORD}` pada
`httpServer.ssl.keyStore.password`. Entrypoint membaca nilai tersebut dari file
password dan tidak mencetaknya ke log.

## Struktur Repository

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

## Membangun Image

Image dasar harus sudah tersedia secara lokal.

```bash
./scripts/build.sh
```

Build script mengunduh artefak resmi JMX Exporter ke `.artifacts/`,
memverifikasi SHA-256, lalu membangun image dengan `--pull=never`.

## Pengujian Dasar (Smoke Test)

```bash
./scripts/test.sh
```

Test membuat certificate dan PKCS12 keystore sementara, menjalankan container,
lalu memastikan `/metrics` dapat diakses melalui HTTPS dan metrics JVM tersedia.
Seluruh material TLS pengujian dihapus setelah test selesai.

## Menjalankan Container Lokal

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

## Referensi Upstream

- <https://prometheus.github.io/jmx_exporter/>
- <https://prometheus.github.io/jmx_exporter/deployment/modes/>
- <https://prometheus.github.io/jmx_exporter/configuration/ssl/>
- <https://github.com/prometheus/jmx_exporter/releases/tag/1.6.0>
