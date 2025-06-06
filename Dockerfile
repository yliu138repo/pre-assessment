FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY main.go go.mod ./
RUN go build -o /app/go-server

FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/go-server .
EXPOSE 8080
CMD ["./go-server"]
