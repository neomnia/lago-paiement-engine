# Dockerfile pour ClickHouse sur Railway
FROM clickhouse/clickhouse-server:24.3-alpine

# Configuration pour Railway (pas de root requis)
USER clickhouse

# Port exposé
EXPOSE 8123 9000

# Healthcheck
HEALTHCHECK --interval=30s --timeout=10s --start-period=60s --retries=3 \
  CMD wget --no-verbose --tries=1 --spider http://localhost:8123/ping || exit 1

# Démarrage du serveur
CMD ["/usr/bin/clickhouse-server", "--config-file=/etc/clickhouse-server/config.xml"]
