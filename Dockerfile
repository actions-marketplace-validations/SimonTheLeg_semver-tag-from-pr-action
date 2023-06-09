# syntax=docker/dockerfile:1.4
FROM golang:1.18.2-alpine3.16 AS alpine-upx

LABEL org.opencontainers.image.source https://github.com/simontheleg/semver-tag-from-pr-action

RUN apk update && apk add upx binutils

FROM alpine-upx AS builder

ARG outpath="/bin/action"
WORKDIR /build

COPY pkg pkg
COPY go.mod go.mod
COPY go.sum go.sum
COPY main.go main.go


# TODO figure out if dependencies could be cached for faster local development
RUN CGO_ENABLED=0 \
  go build \
  -trimpath \
  -ldflags '-w -s' \
  -o ${outpath}


# Strip any symbols
RUN strip ${outpath}
# Compress the compiled action
RUN upx -q -9 ${outpath}

FROM scratch

# Copy over SSL certificates from the first step - this is required
# as our code makes outbound SSL connections.
COPY --from=builder /etc/ssl/certs/ca-certificates.crt /etc/ssl/certs/

ARG outpath="/bin/action"
COPY --from=builder ${outpath} ${outpath}

ENTRYPOINT [ "/bin/action" ]