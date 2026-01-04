# python-ubuntu-image

A Debian Slim Docker image with the latest Python version built with optimisations
and the latest openSSL.

# Images

The images can be accessed using `docker pull <image name>`.

| Python  | Image name                           |
| ------- | ------------------------------------ |
| 3.13.11 | ursamajorlab/debian-slim-python:3.13 |
| 3.14.2  | ursamajorlab/debian-slim-python:3.14 |
| 3.13.2  | ursamajorlab/debian-slim-python:3.15 |

The images are also accessible by using the major.minor.revision tag
`ursamajorlab/debian-slim-python:<full-python-version>`,
e.g. ursamajorlab/debian-slim-python:3.14.2

# Rationale

Other images are either relying on the outdated Python provided by the distro,
or building it from source against an outdated version of openSSL.

The Dockerfile of these versions also often consists of a single stage, which
makes the code harder to read and tend to leave behind some unnecessary files
(dev headers for packages, etc).

Here, we build Python from source against the latest openSSL version, making
sure to use the RPATH correctly to link to the right version.

# Contribute

Feel free to suggest improvements and submit PR, always much appreciated :)
