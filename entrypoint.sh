#!/bin/bash

DOMAIN=${DOMAIN}
EMAIL=${EMAIL}

cat <<EOF > /etc/nginx/conf.d/default.conf
server {
    listen 80;
    server_name ${DOMAIN};
    location / {
        root /usr/share/nginx/html;
        index index.html index.htm;
    }
}
EOF

nginx

certbot certonly --webroot -w /usr/share/nginx/html -d $DOMAIN --email $EMAIL --agree-tos --non-interactive

ln -sf /etc/letsencrypt/live/$DOMAIN/fullchain.pem /etc/nginx/ssl/nginx.crt
ln -sf /etc/letsencrypt/live/$DOMAIN/privkey.pem /etc/nginx/ssl/nginx.key

cat <<EOF > /etc/nginx/conf.d/default.conf
server {
    listen 80;
    server_name ${DOMAIN};
    location / {
        return 301 https://\$host\$request_uri;
    }
}

server {
    listen 443 ssl;
    server_name ${DOMAIN};

    ssl_certificate /etc/nginx/ssl/nginx.crt;
    ssl_certificate_key /etc/nginx/ssl/nginx.key;

    #PROXY-START/
    location ^~ / {
        proxy_pass https://registry-1.docker.io/;
        proxy_set_header Host registry-1.docker.io;
        proxy_set_header X-Real-IP \$remote_addr;
        proxy_set_header X-Forwarded-For \$proxy_add_x_forwarded_for;
        proxy_set_header X-Forwarded-Proto \$scheme;
        proxy_buffering off;
        proxy_request_buffering off;
        proxy_http_version 1.1;
        proxy_read_timeout 7200s;
        proxy_send_timeout 7200s;
        send_timeout 7200s;
        proxy_connect_timeout 7200s;
        proxy_set_header Authorization \$http_authorization;
        proxy_pass_header Authorization;
        proxy_intercept_errors on;
        recursive_error_pages on;
        error_page 301 302 307 = @handle_redirect;
    }

    location @handle_redirect {
        resolver 1.1.1.1;
        set \$saved_redirect_location '\$upstream_http_location';
        proxy_pass \$saved_redirect_location;
    }
    #PROXY-END/

    error_page 500 502 503 504 /50x.html;
    location = /50x.html {
        root /usr/share/nginx/html;
    }
}
EOF

nginx -s reload

echo "0 0 * * * /usr/bin/certbot renew --quiet && nginx -s reload" > /etc/cron.d/certbot-renew
cron

tail -f /var/log/nginx/access.log /var/log/nginx/error.log
