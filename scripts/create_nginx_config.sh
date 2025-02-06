#!/bin/bash

# Function to create a default Nginx configuration.
create_nginx_config() {
    HOST_NGINX_CONF="config/nginx.conf"
    if [ ! -f "$HOST_NGINX_CONF" ]; then
        log "Creating default Nginx config..."
        cat << EOF > "$HOST_NGINX_CONF"
user nginx;
worker_processes auto;
error_log /var/log/nginx/error.log warn;
pid /var/run/nginx.pid;

events {
    worker_connections 1024;
}

http {
    include /etc/nginx/mime.types;
    default_type application/octet-stream;

    log_format main '\$remote_addr - \$remote_user [\$time_local] "\$request" '
                    '\$status \$body_bytes_sent "\$http_referer" '
                    '"\$http_user_agent" "\$http_x_forwarded_for"';

    access_log /var/log/nginx/access.log main;

    sendfile on;
    keepalive_timeout 65;

    server {
        listen 80;
        server_name localhost;

        location / {
            root /usr/share/nginx/html;
            index index.html index.htm;
            autoindex on;
        }

        add_header X-Frame-Options "SAMEORIGIN";
        add_header X-Content-Type-Options "nosniff";
        add_header X-XSS-Protection "1; mode=block";
    }
}
EOF
        sudo chmod 644 "$HOST_NGINX_CONF"
        log "Nginx config created."
    else
        log "Nginx config already exists at $HOST_NGINX_CONF."
    fi
}
