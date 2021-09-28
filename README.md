# docker-thanos

## Rebuild of Thanos Docker image on Alpine

This repository contains the files for producing a docker image which has [thanos](https://github.com/thanos-io/thanos/blob/main/README.md) installed.
This image can be started in different configuraitons depending on the value of the `THANOS_MODE` environment variable:

* [query](https://thanos.io/v0.5/components/query/)
* [store](https://thanos.io/v0.5/components/store/)
* [rule](https://thanos.io/v0.2/components/rule/)
* If no value is provided it defaults to [receive](https://thanos.io/tip/components/receive.md/)

## CI

There is a GitHub Actions pipeline in the DWP organisation which builds and deploys the image to docker hub. The image is then mirrored to ECS via the [mirror images pipeline](https://ci.dataworks.dwp.gov.uk/teams/dataworks/pipelines/mirror-docker-images) in AWS Concourse.

There is also a pipeline for this repo which creates the ECS repository in mgmt and mgmt-dev.

## Local building

When making changes, these should always be tested locally first by running this from the root:

`docker run -it $(docker build -q .)`
This will build and run a local version of this image, which you can then go in to and check it has the relevant packages installed.