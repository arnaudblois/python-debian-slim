#!/bin/bash

# Build the corresponding image
docker buildx build . \
  --file ./src/Dockerfile \
  --tag ${DOCKERHUB_USERNAME}/debian-slim-python:${PYTHON_VERSION}-${ARCH} \
  --platform=linux/${ARCH} \
  --build-arg PY_VERSION=${PYTHON_VERSION} \
  --build-arg CREATION_COMMIT_SHA="${GITHUB_SHA}" \
  --build-arg QUICK_BUILD="${QUICK_BUILD}" \
  --build-arg OPENSSL_VERSION="${OPENSSL_VERSION}" \
  --load  # Make sure to load the image into local context for testing.
