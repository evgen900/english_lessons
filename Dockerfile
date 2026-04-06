FROM nginx:1.27-alpine

WORKDIR /usr/share/nginx/html

COPY . .

EXPOSE 80

HEALTHCHECK --interval=30s --timeout=3s --start-period=5s --retries=3 \
  CMD wget -qO- http://127.0.0.1:80/ >/dev/null || exit 1
