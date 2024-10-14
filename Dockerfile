# === Build Yanic ===
FROM golang:alpine AS builder

WORKDIR /src
COPY . /src

RUN go build -o yanic .

# === Run Yanic ===
FROM alpine

# get binary from builder
COPY --from=builder /src/yanic /yanic

# create data directory for meshviewer json files
VOLUME /data
WORKDIR /data

CMD ["/yanic", "serve", "--config", "/etc/yanic/config.toml"]