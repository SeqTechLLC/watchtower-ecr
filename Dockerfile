#
# Builder
#

FROM golang:alpine as builder

# use version (for example "v0.3.3") or "master"
ARG WATCHTOWER_VERSION=master

RUN apk add --no-cache \
    alpine-sdk \
    ca-certificates \
    git \
    tzdata

RUN git clone --branch "${WATCHTOWER_VERSION}" https://github.com/containrrr/watchtower.git

RUN \
  cd watchtower && \
  \
  GO111MODULE=on CGO_ENABLED=0 GOOS=linux go build -a -ldflags '-extldflags "-static"' . && \
  GO111MODULE=on go test ./... -v

RUN go get -u github.com/awslabs/amazon-ecr-credential-helper/ecr-login/cli/docker-credential-ecr-login

#
# watchtower
#

FROM alpine

# copy files from other container
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/ca-certificates.crt
COPY --from=builder /usr/share/zoneinfo /usr/share/zoneinfo
COPY --from=builder /go/watchtower/watchtower /watchtower
COPY --from=builder /go/bin/docker-credential-ecr-login /bin/docker-credential-ecr-login

ENTRYPOINT ["/watchtower"]
