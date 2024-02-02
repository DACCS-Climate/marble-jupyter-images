# Minimal notebook. For testing with a reference.
MINIMAL_NOTEBOOK_IMAGE := quay.io/jupyter/minimal-notebook:python-3.11
MINIMAL_CONTAINER_NAME := testminimal

# Test container being developed.
TEST_IMAGE_TAG := testmarble
TEST_CONTAINER_NAME := testmarblecontatiner

runminimal:
	docker run -d -p 10000:8888 --name ${MINIMAL_CONTAINER_NAME} ${MINIMAL_NOTEBOOK_IMAGE}

stopminimal:
	docker stop ${MINIMAL_CONTAINER_NAME}

minimaltoken:
	docker logs ${MINIMAL_CONTAINER_NAME} 2>&1 | grep "token"

sshminimal:
	docker exec -it ${MINIMAL_CONTAINER_NAME} bash

build:
	# docker build --no-cache --tag ${TEST_IMAGE_TAG} .
	docker build --tag ${TEST_IMAGE_TAG} .

run:
	docker run -d --rm -p 10001:8888 --name ${TEST_CONTAINER_NAME} ${TEST_IMAGE_TAG}

token:
	echo "Token:" $(shell docker logs ${TEST_CONTAINER_NAME} 2>&1 | grep token | head -n 1 | cut -d "=" -f 2)

ssh:
	docker exec -it ${TEST_CONTAINER_NAME} bash


.SILENT: token build sshminimal ssh
