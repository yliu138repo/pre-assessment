events {}

http {
    server {
        listen 80;
        server_name ${hostname};

        location /.well-known/acme-challenge/ {
            root /var/www/certbot;
        }

        location / {
            return 301 https://$${host}$${request_uri};
        }
    }

    server {
        listen 443 ssl;
        server_name ${hostname};

        ssl_certificate /etc/letsencrypt/live/${hostname}/fullchain.pem;
        ssl_certificate_key /etc/letsencrypt/live/${hostname}/privkey.pem;

        ssl_protocols TLSv1.2 TLSv1.3;
        ssl_ciphers HIGH:!aNULL:!MD5;
        ssl_prefer_server_ciphers on;

        location / {
            proxy_pass http://${backend_ip}:8080;
            proxy_set_header Host $${host};
            proxy_set_header X-Real-IP $${remote_addr};
            proxy_set_header X-Forwarded-For $${proxy_add_x_forwarded_for};
        }
    }
}