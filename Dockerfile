FROM --platform=${BUILDPLATFORM:-linux/amd64} golang:1.25@sha256:698183780de28062f4ef46f82a79ec0ae69d2d22f7b160cf69f71ea8d98bf25d AS build

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

WORKDIR /workspace
ENV GO111MODULE=on
ENV TEST_ASSET_PATH=/_out/kubebuilder/bin

RUN apt update -qq && apt install -qq -y git bash curl g++

# Fetch binary early because to allow more caching
COPY scripts scripts
COPY testdata testdata
RUN ./scripts/fetch-test-binaries.sh

COPY src src

# Build
RUN cd src; go mod download

RUN cd src; CGO_ENABLED=0 GOOS=${TARGETOS} GOARCH=${TARGETARCH} go build -o webhook -ldflags '-w -extldflags "-static"' .

#Test
ARG TEST_ZONE_NAME
RUN  \
     if [ -n "$TEST_ZONE_NAME" ]; then \
       cd src; \
       CCGO_ENABLED=0 \
	     TEST_ASSET_ETCD=${TEST_ASSET_PATH}/etcd \
	     TEST_ASSET_KUBE_APISERVER=${TEST_ASSET_PATH}/kube-apiserver \
       TEST_ZONE_NAME="$TEST_ZONE_NAME" \
       go test -v .; \
     fi

# Use distroless as minimal base image to package the manager binary
# Refer to https://github.com/GoogleContainerTools/distroless for more details
FROM gcr.io/distroless/static:nonroot@sha256:2b7c93f6d6648c11f0e80a48558c8f77885eb0445213b8e69a6a0d7c89fc6ae4
WORKDIR /
COPY --from=build /workspace/src/webhook /app/webhook
USER nonroot:nonroot

ENTRYPOINT ["/app/webhook"]

ARG IMAGE_SOURCE
LABEL org.opencontainers.image.source=$IMAGE_SOURCE
