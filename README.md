# docker

## Install docker

Website: https://docs.docker.com/engine/install/ubuntu/

To get a shell script for the installation:
curl -fsSL https://get.docker.com -o get-docker.sh
To install
sudo sh ./get-docker.sh --dry-run

View docker images present on system:
docker image ls

Post install steps:

sudo groupadd docker

sudo usermod -aG docker $USER

confirm that the docker server is enabled:
systemctl is-enabled docker

# Run first container

docker run hello-world

## docker commands

Interact with docker images:
docker image ...
List all local docker images:
docker image ls
Download image from registry:
docker image pull
Interact with docker containers:
docker container ...

Run the docker container
docker container run -it ros:noetic
Open another terminal in the same container:
docker container exec -it [container_name] /bin/bash

Use exit to get out of your docker container.

You can use docker container ls or docker ps to list the active docker container instances. You can also run docker ps -a to see all
died docker instances from the past. You can remove old docker instances from this list with docker container rm [container_name]
We can also delete all the old ones at once using docker container prune

We can build the dockerimage with dockerfile including our files with COPY, installing extra software with RUN, and including a base docker image with FROM.

Buildt the docker file while in the directory where the docker file is located:
docker image build -t my_image .

View the newly created file with docker image list, should be slightly bigger than the FROM image that it was based on, depending on the COPY and RUN contents in the dockerfile.

Try to run it with options interactive, terminal to type in:
docker run -it [image_name]

When you want to use your own code inside a container you can mount
your code onto the container when you run the container like so:

docker run -it -v $PWD/source:/my_source_code my_image

Here, -v tells docker to mount the subsequent absolute path with the specified name after the colon.
