events {}
http {
    server {
        listen 80;
        listen [::]:80;
        location / {
            proxy_pass http://${backend_ip}:8080;
        }
    }
}

