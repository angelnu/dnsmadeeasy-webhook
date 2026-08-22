FROM --platform=${BUILDPLATFORM:-linux/amd64} golang:1.26@sha256:26326682769ca980f8f1d3b1f52be2dd1c1d25270e3de3fe0c97d6bb65df3556 AS build

ARG TARGETPLATFORM
ARG BUILDPLATFORM
ARG TARGETOS
ARG TARGETARCH

WORKDIR /workspace
ENV GO111MODULE=on
ENV TEST_ASSET_PATH=/_out/kubebuilder/bin

RUN apt update -qq && apt install -qq -y git bash curl g++

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
FROM gcr.io/distroless/static:nonroot@sha256:1c2c046bc09ed40fad370b599a0b1ae7987f55b01e247cf27a7c27cd97e5bbc7
WORKDIR /
COPY --from=build /workspace/src/webhook /app/webhook
USER nonroot:nonroot

ENTRYPOINT ["/app/webhook"]

ARG IMAGE_SOURCE
LABEL org.opencontainers.image.source=$IMAGE_SOURCE
