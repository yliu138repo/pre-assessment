#!/bin/bash
sudo yum update -y
sudo amazon-linux-extras install -y docker
sudo service docker start
sudo systemctl enable docker

# Run the golang based HTTP server on port 8080
sudo docker run -d --restart always --name web_server -p 8080:8080 -e LISTEN_PORT=8080 \
leoliu1988/go-server:v1.0.0