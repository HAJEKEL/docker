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

-v for volume. It forces docker to start the container around your volume, which is the directory you have acces to and want to develop. It behaves like a shared virtual drive that you cant easily access from outside of docker. Therefore, bind mounts are more applicable here as they will be acceccible outside and inside the container.

Here, -v tells docker to mount the subsequent absolute path with the specified name after the colon.

Files you make inside the container, or changes, will be available on the host computer, however, since you are a root user inside the container, you will need root perimissions to be able to access the new files/changes.

To make a bind mount, you run (it for interactive and terminal):

docker run -it -v <absol_path_on_host>:<absol_path_in_cont>

When you create files in the absol_path_in_cont, it will also be visible in absol_path_on_host. However, the new files cant be accessed by host as its created as root inside the container. We need to make a new user in the docker file that is compatible with the host user to change this.

## Crafting a Dockerfile

With the docker basics above we managed to get a container up and running, however graphical programs wont run, network communication can behave strangely, any files created on a shared volume are locked.

These things can be prevented by making changes to the docker run command and the dockerfile:

### Users

By default files created inside the docker container are locked on the host because it was created by root. By default all docker containers run as root. We can change this, and run it as a user that is compatible with the host user.

In linux each user has a name and a user ID (UID). If we setup the docker container to run as a user that has the same UID as the host, files created inside the docker container will be accessible by the host. When a file is created, linux stores the UID of the user that created it.

Lets take a look, run:

ls -l (list long, this will show you the usernames that created the files in the cwd)

ls -ln (list long number, this will show you the UID's of the users that created the filew in the cwd)

To create a user in docker that is compatible with our host we need:

ARG USERNAME=ros
ARG USER_UID=1000
ARG USER_GID=$USER_UID

Here, the USERNAME can be any arbitrary name, as it does not influence the acceccibility of the files for the host. The UID and the GID must be the same as the host's UID and GID to allow the host to access files created inside the docker container.

For the docker container to use the non-root user we need to create the non-root user that is compatible with the host. We also create a config and a home directory and change the ownership to the newly created user.

RUN groupadd --gid $USER_GID $USERNAME \
    && USERADD -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && mkdir /home/$USERNAME/.config && chown $USER_UID:$USER_GID /home/$USERNAME/.config

We can now rebuild the container inside the direcotry containing the docker file:

docker image build -t my_image .

To run the docker container we run, similar to before, with options it (interactive, terminal to type in). Additionally we use the created user with the same UID as the host:
docker run -it --user ros -v $PWD/source:/my_source_code my_image

### Set up sudo and Dockerfile writing

We use apt-get because its designed to be in scripts and apt is not. We need to run apt-get update each time because we delete the apt/lists each time wit rm -rf /var/lib/apt/lists/_ to safe space.
Install -y automatically answers yes to yes/no answers, as we cant interact with it during the build. We use \ such that each seperate command is on a new line for overview in version control.
RUN apt-get update \
 && apt-get install -y sudo \
 && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
 && chmod 0440 /etc/sudoers.d/$USERNAME \
 && rm -rf /var/lib/apt/lists/_

## Networking

Docker allows for complex network configurations. We dont need this for ros, we just change the run command:

docker run -it --user ros --network=host --ipc=host -v $PWD/source:/my_source_code my_image

Here we refer the network to be the same as the host's network stack and with ipc we share memmory with the host. In this mode, the container shares the network namespace with the host, meaning it will see all the network interfaces and services like ports as the host does. IPC stands for inter-process communication, allowing shared memory between the container and the host system. It's particularly useful in scenarios where you have processes in the container that need to communicate efficiently with processes on the host or in other containers.

## Entrypoint script

A docker file allows you to specify an entrypoint and a command. For this we create a bash script that sets up the runtime environment, for scripts to source, variables to set, etc. . This will be an executable wrapper and arguments passed to it will be executed as if you had typed them in directly but with the extra context that we provided. This script is the entrypoint.

We should place the script in the same directory as the dockerfile. It enables error signals, sources the ros installation, prints what is passed to it and the executes it.

set -e

source /opt/ros/noetic/setup.bash

echo "Provided arguments: $@"

exec $@

We also add to the dockerfile:
COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
To have a working terminal we run:
CMD ["bash"]

Now we can run the run command as follows:

docker run -it --user ros --network=host --ipc=host -v $PWD/source:/my_source_code my_image roscore

This would run the roscore using our entrypoint

## Graphics

As we made a user that has the same UID as the host, we dont need to change X permissions. The ros user that we created allows us to run the container as a user that has permission to access X and thus has graphics access.

In case you want to run the container as default root you can run:
xhost +local:root

This way the root user also has access to the graphics. (Run: xhost -local:root to remove persmissions)

We need to add the X11 as a volume with the run command:

-v /tmp/.X11-unix:/tmp/.X11-unix:rw

We also need to add a display to put the graphics on, we use the same as the host uses:

--env=DISPLAY

The whole command:

docker run -it --user ros --network=host --ipc=host -v $PWD/source:/my_source_code -v /tmp/.X11-unix:/tmp/.X11-unix:rw --env=DISPLAY my_image roscore

### Graphics option nvidia

In order to make the graphics work, we need to add the option --device=/dev/dri:/dev/dri:

docker run -it --user=ros --network=host --ipc=host --device=/dev/dri:/dev/dri -v $PWD:/my_source_code -v /tmp/.X11-unix:/tmp/.X11-unix:rw --env=DISPLAY my_image /my_source_code/start_ros.sh

This allows the Docker container to access the host's Direct Rendering Manager (DRM) interface.

### Warnings

We can also set the XDG_RUNTIME_DIR environment variable to store user-specific non-essential runtime files (like sockets, named pipes, etc.).

--env=XDG_RUNTIME_DIR=/tmp/runtime-$(id -u)

full command:

docker run -it --user=ros --network=host --ipc=host --device=/dev/dri:/dev/dri -v $PWD:/my_source_code -v /tmp/.X11-unix:/tmp/.X11-unix:rw --env=XDG_RUNTIME_DIR=/tmp/runtime-$(id -u) --env=DISPLAY my_image /my_source_code/start_ros.sh

### autocompletion

You can pass `echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> /ros/.bashrc` to your RUN command inside Dockerfile.

RUN echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> /home/ros/.bashrc

### Multiple terminals to work with ROS

1. Use docker exec to Open Additional Shells
   You can open additional bash shells in a running container. First, start your container in the background by adding -d (detach) to your docker run command. Then use docker exec to open new terminals into the container:

Start the container in detached mode:

docker run -d -it --user=ros --network=host --ipc=host --device=/dev/dri:/dev/dri -v $PWD:/my_source_code -v /tmp/.X11-unix:/tmp/.X11-unix:rw --env=XDG_RUNTIME_DIR=/tmp/runtime-$(id -u) --env=DISPLAY my_image /my_source_code/start_ros.sh

Find your container ID:

docker ps

Open a new terminal in the container:

docker exec -it [container-id] bash

## Shell script for extra terminal

I made a shell script called terminal.sh to get another terminal inside the docker container
