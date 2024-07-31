FROM nginx:latest

RUN apt-get update && \
    apt-get install -y certbot python3-certbot-nginx cron && \
    mkdir -p /etc/nginx/ssl

COPY entrypoint.sh /entrypoint.sh

RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
