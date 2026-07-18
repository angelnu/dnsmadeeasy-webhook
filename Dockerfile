FROM --platform=${BUILDPLATFORM:-linux/amd64} golang:1.26@sha256:079e59808d2d252516e27e3f3a9c003740dee7f75e55aa71528766d52bcfc16a AS build

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
FROM gcr.io/distroless/static:nonroot@sha256:f7f8f729987ad0fdf6b05eeeae94b26e6a0f613bdf46feea7fc40f7bd72953e6
WORKDIR /
COPY --from=build /workspace/src/webhook /app/webhook
USER nonroot:nonroot

ENTRYPOINT ["/app/webhook"]

ARG IMAGE_SOURCE
LABEL org.opencontainers.image.source=$IMAGE_SOURCE
