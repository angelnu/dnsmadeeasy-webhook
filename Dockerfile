FROM --platform=${BUILDPLATFORM:-linux/amd64} golang:1.26@sha256:672c944cfd07599b5f1bb179869270cdc94c6254e41db4d431259693cb286b82 AS build

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
FROM gcr.io/distroless/static:nonroot@sha256:18f4cc26c9ffa7f20a359298be7deadac5c607c8e03a02b8119f1a5fc2f82c99
WORKDIR /
COPY --from=build /workspace/src/webhook /app/webhook
USER nonroot:nonroot

ENTRYPOINT ["/app/webhook"]

ARG IMAGE_SOURCE
LABEL org.opencontainers.image.source=$IMAGE_SOURCE
