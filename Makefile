# read PKG_VERSION from VERSION file
include VERSION

# set default docker build image name

OPENTELEMETRY_PATH = $(CURDIR)/third_party/opentelemetry-operations-collector
BUILD_IMAGE ?= gcp-fcos-agent
BUILD_IMAGE_NAME ?= $(BUILD_IMAGE)-build

.EXPORT_ALL_VARIABLES:

.DEFAULT_GOAL := presubmit

.PHONY: clean-dist
clean-dist:
	rm -rf dist/

.PHONY: package-tarball
package-tarball:
	bash ./.build/tar/generate_tar.sh
	chmod -R a+rwx ./dist/

.PHONY: build-tarball
build-tarball: clean-dist build package-tarball

# --------------------
#  Create build image
# --------------------

.PHONY: docker-build-image
docker-build-image:
	podman build -t $(BUILD_IMAGE_NAME) $(OPENTELEMETRY_PATH)/.build

# --------------------
#  Create runtime image
# --------------------

.PHONY: docker-build-runtime
docker-build-runtime:
	podman build -t $(BUILD_IMAGE) .

.PHONY: tag-release
tag-release:
	VER=${cat VERSION | grep -Po '(?<=PKG_VERSION=)\d.\d.\d'}
	git tag -a v$(VER)
	git push origin v$(VER)

# -------------------------------------------
#  Run targets inside the docker build image
# -------------------------------------------

# Usage:   make TARGET=<target> docker-run
# Example: make TARGET=build-goo docker-run
.PHONY: docker-run
docker-run:
ifndef TARGET
	$(error "TARGET is undefined")
endif
	podman run -e PKG_VERSION -e ARCH -v $(OPENTELEMETRY_PATH):/mnt:rw,z -w /mnt $(BUILD_IMAGE_NAME) /bin/bash -c "make $(TARGET)"
