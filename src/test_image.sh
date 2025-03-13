#!/bin/bash

docker create -t -i --name test-container ${DOCKERHUB_USERNAME}/debian-slim-python:${PYTHON_VERSION}-${ARCH}
docker start test-container
docker exec -i test-container python3 < src/test_image.py
