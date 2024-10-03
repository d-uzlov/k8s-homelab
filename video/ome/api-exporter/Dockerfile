FROM golang:1.23 as builder

WORKDIR /app

COPY . ./

RUN CGO_ENABLED=0 go build

FROM alpine as runtime

WORKDIR /
COPY --from=builder /app/ome-api-exporter /ome-api-exporter

RUN chmod +x /ome-api-exporter
# RUN ls -la && false
CMD ["/ome-api-exporter", "/mnt/config.yaml"]
