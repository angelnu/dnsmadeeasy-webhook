FROM --platform=${BUILDPLATFORM:-linux/amd64} golang:1.26@sha256:f96cc555eb8db430159a3aa6797cd5bae561945b7b0fe7d0e284c63a3b291609 AS build

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

WORKDIR /workspace
ENV GO111MODULE=on
ENV TEST_ASSET_PATH=/_out/kubebuilder/bin

RUN apt-get update && apt-get install -y --no-install-recommends git bash curl g++ && rm -rf /var/lib/apt/lists/*

ARG TEST_ZONE_NAME
COPY Makefile Makefile
RUN  \
  if [ -n "$TEST_ZONE_NAME" ]; then \
  make envtest; \
  fi

COPY src src

# Build
RUN cd src; go mod download

RUN cd src; CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o webhook -ldflags '-w -extldflags "-static"' .

#Test
COPY testdata testdata
RUN  \
  if [ -n "$TEST_ZONE_NAME" ]; then \
  make test; \
  fi

# Use distroless as minimal base image to package the manager binary
# Refer to https://github.com/GoogleContainerTools/distroless for more details
FROM gcr.io/distroless/static:nonroot
WORKDIR /
COPY --from=build /workspace/src/webhook /app/webhook
USER nonroot:nonroot

ENTRYPOINT ["/app/webhook"]

ARG IMAGE_SOURCE
LABEL org.opencontainers.image.source=$IMAGE_SOURCE
