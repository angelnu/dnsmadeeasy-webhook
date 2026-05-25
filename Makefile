
# Image URL to use all building/pushing image targets
IMG ?= dnsmadeeasy-webhook:latest
TEST_K8S_VERSION ?= 1.26
TEST_ASSET_PATH=$(abspath ./_out)
KUBEBUILDER_ASSETS = $(shell GOBIN=$(TEST_ASSET_PATH) $(TEST_ASSET_PATH)/setup-envtest use $(TEST_K8S_VERSION).x -p path)

# Build manager binary
build: fmt vet
	cd src; go build -o ../bin/webhook main.go

# Download dependencies
download:
	cd src; go mod download

# Download dependencies
tidy: download
	cd src; go mod tidy

.PHONY: test
test: envtest
	@echo "Running integration tests..."
	cd src && \
	TEST_ASSET_ETCD="$(KUBEBUILDER_ASSETS)/etcd" \
	TEST_ASSET_KUBE_APISERVER="$(KUBEBUILDER_ASSETS)/kube-apiserver" \
	go test -v .

.PHONY: envtest
envtest: ## Download setup-envtest and binaries locally if missing
	@mkdir -p $(TEST_ASSET_PATH)
	@if [ ! -f $(TEST_ASSET_PATH)/setup-envtest ]; then \
		echo "Installing setup-envtest utility..."; \
		GOBIN=$(TEST_ASSET_PATH) go install sigs.k8s.io/controller-runtime/tools/setup-envtest@latest; \
	fi
	@echo "Fetching etcd and kube-apiserver binaries..."
	@GOBIN=$(TEST_ASSET_PATH) $(TEST_ASSET_PATH)/setup-envtest use $(TEST_K8S_VERSION).x --bin-dir $(TEST_ASSET_PATH)


# Run go fmt against code
fmt: tidy
	cd src; go fmt ./...

# Run go vet against code
vet: tidy
	cd src; go vet ./...

# Build the docker image
docker-build:
	docker build . -t ${IMG}

# Push the docker image
docker-push:
	docker push ${IMG}

# Build the OCI image with Podman
podman:
	podman build . -t ${IMG}

# Push the OCI image with Podman
podman-push:
	podman push ${IMG}