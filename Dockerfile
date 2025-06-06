FROM golang:1.22-alpine AS builder
WORKDIR /app
COPY main.go go.mod ./
RUN go build -o /app/go-server
# multi-stage and use the alpine to minize the image size...
FROM alpine:latest
WORKDIR /app
COPY --from=builder /app/go-server .
EXPOSE 8080

RUN adduser -D myuser && \
chown -R myuser:myuser /app
USER myuser

CMD ["./go-server"]
