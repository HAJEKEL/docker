# Docker Guide for Development and Usage

This comprehensive guide covers Docker installation, container management, image handling, and advanced Docker configurations. It includes explanations for each step to ensure a thorough understanding of the processes involved.

## Installation

### Docker Installation on Ubuntu

For detailed instructions, refer to the [Docker Installation Guide](https://docs.docker.com/engine/install/ubuntu/).

**Installation Script:**

```bash
curl -fsSL https://get.docker.com -o get-docker.sh
sudo sh ./get-docker.sh --dry-run
```

**Post-Installation Configuration:**

- Create a Docker group and add your user to avoid needing to use `sudo` with Docker commands:
  ```bash
  sudo groupadd docker
  sudo usermod -aG docker $USER
  ```
- Check Docker server status:
  ```bash
  systemctl is-enabled docker
  ```

### Running Your First Container

- Verify installation by running a simple Docker container:
  ```bash
  docker run hello-world
  ```

## Docker Commands and Management

### Image Management

- **List Docker Images:**
  ```bash
  docker image ls
  ```
- **Download an Image:**
  ```bash
  docker image pull [image_name]
  ```

### Container Management

- **Run a Container:**
  ```bash
  docker container run -it [image_name]
  ```
- **Open Terminal in Running Container:**
  ```bash
  docker container exec -it [container_name] /bin/bash
  ```
- **List Active Containers:**
  ```bash
  docker container ls
  ```
- **List All Containers (Including Inactive):**
  ```bash
  docker ps -a
  ```
- **Remove Specific Container:**
  ```bash
  docker container rm [container_name]
  ```
- **Clean Up Inactive Containers:**
  ```bash
  docker container prune
  ```

### Building and Running Custom Images

- **Build an Image with Dockerfile:**
  ```bash
  docker image build -t my_image .
  ```
- **Run the Custom Image:**
  ```bash
  docker run -it [image_name]
  ```

### Mounting Volumes

- **Bind Mounts for Code Development:**
  ```bash
  docker run -it -v $PWD/source:/my_source_code my_image
  ```
  - Bind mounts are useful for development as they allow easy access to files both inside and outside the Docker container.

## Crafting an Optimized Dockerfile

### User Management in Docker

- To avoid permission issues with files created inside the Docker container, it's essential to align the user inside the container with the host user.
- **Creating a Compatible User:**

  - This ensures files created in the container are accessible on the host.

  ```Dockerfile
  ARG USERNAME=ros
  ARG USER_UID=1000
  ARG USER_GID=$USER_UID

  RUN groupadd --gid $USER_GID $USERNAME \
      && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
      && mkdir /home/$USERNAME/.config \
      && chown $USER_UID:$USER_GID /home/$USERNAME/.config
  ```

### Sudo Setup in Dockerfile

- **Installing and Configuring Sudo:**
  - The setup enables the created user to execute sudo commands without a password.
  ```Dockerfile
  RUN apt-get update \
   && apt-get install -y sudo \
   && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME \
   && chmod 0440 /etc/sudoers.d/$USERNAME \
   && rm -rf /var/lib/apt/lists/_
  ```

## Advanced Docker Configuration

### Networking and IPC

- **Configuration for Networking and IPC:**
  - These settings allow the container to share the host's network and memory space, necessary for certain applications, particularly those requiring network or graphical capabilities.
  ```bash
  docker run -it --user ros --network=host --ipc=host -v $PWD/source:/my_source_code my_image
  ```

### Entrypoint Script

- **Implementing an Entrypoint Script:**
  - An entrypoint script sets up the environment within the container, ensuring that necessary scripts are sourced and variables are set.
  ```Dockerfile
  COPY entrypoint.sh /entrypoint.sh
  ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
  CMD ["bash"]
  ```

### Graphics in Docker

- **Running Containers with Graphics Support:**
  - The setup allows graphical applications to run within Docker containers.
  ```bash
  docker run -it --user ros --network=host --ipc=host -v $PWD/source:/my_source_code -v /tmp/.X11-unix:/tmp/.X11-unix:rw --env=DISPLAY my_image roscore
  ```
  - This command mounts the X11 Unix socket, allowing Docker containers to display GUI applications on the host's screen. The `--env=DISPLAY` sets the environment variable so that the container knows where to send the display output.

### NVIDIA Graphics Support

- **Running Containers with NVIDIA Graphics:**
  - For containers that require access to NVIDIA graphics, use the `--device` flag:
  ```bash
  docker run -it --user=ros --network=host --ipc=host --device=/dev/dri:/dev/dri -v $PWD:/my_source_code -v /tmp/.X11-unix:/tmp/.X11-unix:rw --env=DISPLAY my_image /my_source_code/start_ros.sh
  ```
  - This allows the container to access the host's Direct Rendering Manager (DRM) interface, crucial for graphical rendering with NVIDIA hardware.

### Environment Variables for Graphics

- **Configuring Runtime Directories:**
  - Setting `XDG_RUNTIME_DIR` allows the container to store non-essential runtime files, like sockets and named pipes:
  ```bash
  --env=XDG_RUNTIME_DIR=/tmp/runtime-$(id -u)
  ```
  - Include this in your `docker run` command to ensure proper handling of these runtime files.

### Docker Autocompletion

- **Enabling Bash Autocompletion in Docker:**
  - To facilitate easier command usage, enable autocompletion by appending the ROS setup script to the `.bashrc` file of the created user:
  ```Dockerfile
  RUN echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> /home/ros/.bashrc
  ```

### Managing Multiple Terminals

- **Accessing Additional Terminals in a Running Container:**
  - It's often necessary to open multiple terminals for a single container, especially when working with complex applications like ROS:
  - Start the container in detached mode and use `docker exec` to attach new terminals:
    ```bash
    docker run -d -it --user=ros --network=host --ipc=host --device=/dev/dri:/dev/dri -v $PWD:/my_source_code -v /tmp/.X11-unix:/tmp/.X11-unix:rw --env=XDG_RUNTIME_DIR=/tmp/runtime-$(id -u) --env=DISPLAY my_image /my_source_code/start_ros.sh
    ```
  - To open a new terminal in the container:
    ```bash
    docker exec -it [container-id] bash
    ```

### Shell Script for Extra Terminal

- **Automating Additional Terminal Access:**
  - Create a shell script `terminal.sh` to simplify the process of opening new terminals in the Docker container. This script can streamline the workflow, especially in development environments.

---

This guide aims to provide a comprehensive understanding of Docker usage for development purposes, emphasizing practical steps and explanations for each procedure.
