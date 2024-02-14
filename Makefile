# Minimal notebook. For testing with a reference.
MINIMAL_NOTEBOOK_IMAGE := quay.io/jupyter/minimal-notebook:python-3.11
MINIMAL_CONTAINER_NAME := testminimal

# Test container being developed.
TEST_IMAGE_TAG := marble.v1
TEST_CONTAINER_NAME := testmarblecontatiner

DOCKER_REPO ?= marbleclimate/marble-jupyter-images
TAG ?= v1.1.0
DEPLOYMENT_IMAGE = $(DOCKER_REPO):$(TAG)

DOCKER_FLAGS ?= 

runminimal:
	docker run -d -p 10000:8888 --name ${MINIMAL_CONTAINER_NAME} ${MINIMAL_NOTEBOOK_IMAGE}

stopminimal:
	docker stop ${MINIMAL_CONTAINER_NAME}

minimaltoken:
	docker logs ${MINIMAL_CONTAINER_NAME} 2>&1 | grep "token"

sshminimal:
	docker exec -it ${MINIMAL_CONTAINER_NAME} bash

build:
	docker build $(DOCKER_FLAGS) --tag ${TEST_IMAGE_TAG} . 

run:
	docker run -d --rm -p 10001:8888 -v "${PWD}/jupyter_bokeh_tests":/home/jovyan/work/jupyter_bokeh_tests --name ${TEST_CONTAINER_NAME} ${TEST_IMAGE_TAG}

stop:
	docker stop ${TEST_CONTAINER_NAME}

build-deploy:
	docker build $(DOCKER_FLAGS) --tag $(DEPLOYMENT_IMAGE) . 

deploy:
	docker image push $(DEPLOYMENT_IMAGE)

token:
	echo "Token:" $(shell docker logs ${TEST_CONTAINER_NAME} 2>&1 | grep token | head -n 1 | cut -d "=" -f 2)

ssh:
	docker exec -it ${TEST_CONTAINER_NAME} bash


.SILENT: token build build-deploy sshminimal ssh
