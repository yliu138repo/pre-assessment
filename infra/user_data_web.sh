#!/bin/bash
sudo apt-get update -y
sudo apt-get install -y docker.io
sudo systemctl start docker
sudo systemctl enable docker

# Run the golang based HTTP server on port 8080
sudo docker run -d --name web_server -p 8080:8080 -e LISTEN_PORT=8080 \
leoliu1988/go-server:v1.0.0