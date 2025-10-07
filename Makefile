ifeq ($(MODE), prod)
    DOCKER_REPO ?= marbleclimate/marble-jupyter-image
    TAG ?= v1.2.0
    IMAGE_TAG := $(DOCKER_REPO):$(TAG)
    DEPLOY_IMAGE_TAG := $(DOCKER_REPO):$(TAG)
    CONTAINER_NAME := marblecontatiner
else ifeq ($(MODE), minimal)
	# Minimal notebook. For testing with a reference.
    IMAGE_TAG := quay.io/jupyter/minimal-notebook:python-3.11
    CONTAINER_NAME := testminimal
else
	# for local tests
    IMAGE_TAG := testmarble
    CONTAINER_NAME := testmarblecontatiner
endif


DOCKER_BUILD_FLAGS ?= 

build:
	docker build $(DOCKER_BUILD_FLAGS) --tag ${IMAGE_TAG} . 

run:
	docker run -d --rm -p 10001:8888 -v "${PWD}/jupyter_bokeh_tests":/home/jovyan/work/jupyter_bokeh_tests --name ${CONTAINER_NAME} ${IMAGE_TAG}

stop:
	docker stop ${CONTAINER_NAME}

deploy:
	docker image push $(DEPLOY_IMAGE_TAG)

token:
	echo "Token:" $(shell docker logs ${CONTAINER_NAME} 2>&1 | grep token | head -n 1 | cut -d "=" -f 2)

ssh:
	docker exec -it ${CONTAINER_NAME} bash


.SILENT: token build ssh stop
