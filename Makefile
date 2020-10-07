BINARY            = keyserver
GITHUB_USERNAME   = terra-project
DOCKER_REPO       = quay.io/terra_project
VERSION           = v0.2.1
GOARCH            = amd64
ARTIFACT_DIR      = build
PORT 							= 3000

COMMIT=$(shell git rev-parse HEAD)
BRANCH=$(shell git rev-parse --abbrev-ref HEAD)

# Symlink into GOPATH
FLAG_PATH=github.com/${GITHUB_USERNAME}/${BINARY}/cmd
DOCKER_TAG=${VERSION}
DOCKER_IMAGE=${DOCKER_REPO}/${BINARY}

# Setup the -ldflags option for go build here, interpolate the variable values
LDFLAGS = -ldflags "-X ${FLAG_PATH}.Version=${VERSION} -X ${FLAG_PATH}.Commit=${COMMIT} -X ${FLAG_PATH}.Branch=${BRANCH}"

# Build the project
all: clean linux darwin windows

# Build and Install project into GOPATH using current OS setup
install:
	go install ${LDFLAGS} ./...

test:
	go test -v ./api/...

# Build binary for Linux
linux: clean
	GOOS=linux GOARCH=${GOARCH} go build ${LDFLAGS} -o ${ARTIFACT_DIR}/${BINARY}-linux-${GOARCH} . ;

# Build binary for MacOS
darwin:
	GOOS=darwin GOARCH=${GOARCH} go build ${LDFLAGS} -o ${ARTIFACT_DIR}/${BINARY}-darwin-${GOARCH} . ;

# Build binary for Windows
windows:
	GOOS=windows GOARCH=${GOARCH} go build ${LDFLAGS} -o ${ARTIFACT_DIR}/${BINARY}-windows-${GOARCH}.exe . ;

# Install golang dependencies

# Build the docker image and give it the appropriate tags
docker:
	docker build \
		--build-arg BINARY=${BINARY} \
		--build-arg GITHUB_USERNAME=${GITHUB_USERNAME} \
		--build-arg GOARCH=${GOARCH} \
		-t ${DOCKER_IMAGE}:${DOCKER_TAG} \
		.
	docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:latest
	docker tag ${DOCKER_IMAGE}:${DOCKER_TAG} ${DOCKER_IMAGE}:${BRANCH}

# Push the docker image to the configured repo
docker-push:
	docker push ${DOCKER_IMAGE}:${DOCKER_TAG}
	docker push ${DOCKER_IMAGE}:${BRANCH}
	docker push ${DOCKER_IMAGE}:latest

# Run the docker image as a server exposing the service port, mounting configuration from this repo
docker-run:
	docker run -p ${PORT}:${PORT} -v ${BINARY}.yaml:/root/.${BINARY}.yaml -it ${DOCKER_IMAGE}:${DOCKER_TAG} ${BINARY} serve

# Remove all the built binaries
clean:
	rm -rf ${ARTIFACT_DIR}/*

.PHONY: linux darwin fmt clean
