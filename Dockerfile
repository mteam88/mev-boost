# syntax=docker/dockerfile:1
FROM golang:1.20 as builder
ARG VERSION
ARG CGO_CFLAGS
WORKDIR /build

COPY go.mod ./
COPY go.sum ./

RUN go mod download

ADD . .
RUN --mount=type=cache,target=/root/.cache/go-build CGO_CFLAGS="$CGO_CFLAGS" GOOS=linux go build -trimpath -ldflags "-s -X 'github.com/flashbots/mev-boost/config.Version=$VERSION' -linkmode external -extldflags '-static'" -v -o mev-boost .

FROM alpine
RUN apk add --no-cache libstdc++ libc6-compat
WORKDIR /app
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/
COPY --from=builder /build/mev-boost /app/mev-boost
EXPOSE 18550
ENTRYPOINT ["/app/mev-boost"]
