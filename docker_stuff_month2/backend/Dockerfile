FROM nginxinc/nginx-unprivileged:1.30.4-alpine

COPY backend/default.conf /etc/nginx/conf.d/default.conf
COPY pages/site/ /usr/share/nginx/html/

HEALTHCHECK --interval=30s --timeout=3s --start-period=15s --retries=5 \
  CMD wget -q --spider http://127.0.0.1:8080/ || exit 1

EXPOSE 8080

