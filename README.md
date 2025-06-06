# pre-assessment

# Part I
1. Compose the Dockerfile with multistages and alpine image to ensure minimal image size. Also make sure the container is run with non-root user to ensure security best practices. Refer to the [Dockerfile](./Dockerfile)
2. Run commands with [makefile](./Makefile) for ease with debugging and running
3. In the golang program provided, I found out the server is specifically bound to 127.0.0.1. This also fails the container with port-forwarding too. The code is modified to listen to all traffic by removing the specific IP address. Refer to [main.go](./main.go)
4. Test and run container locally and verify the connectivity by running `curl http://localhost:8080`

