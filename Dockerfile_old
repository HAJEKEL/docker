#There are 2 different repos that have ros docker images
# without rviz, for commandline only interaction/short on space
#FROM ros:humble 
# rviz access
FROM osrf/ros:noetic-desktop-full 
#update, install vim and required ROS package, remove installation metadata
RUN apt-get update && apt-get install -y \
    vim \
    ros-noetic-ridgeback-desktop \
    ros-noetic-ridgeback-simulator \
    && rm -rf /var/lib/apt/lists/*
#Copy custom direcotry config into container directory site_config.
#Have to rebuild if you want to change this after build:
COPY config/ /site_config/ 

ARG USERNAME=ros
ARG USER_UID=1000
ARG USER_GID=$USER_UID
#Create a non-root user
RUN groupadd --gid $USER_GID $USERNAME \
    && useradd -s /bin/bash --uid $USER_UID --gid $USER_GID -m $USERNAME \
    && mkdir /home/$USERNAME/.config && chown $USER_UID:$USER_GID /home/$USERNAME/.config
# Set up sudo
RUN apt-get update \
    && apt-get install -y sudo \
    && echo $USERNAME ALL=\(root\) NOPASSWD:ALL > /etc/sudoers.d/$USERNAME\
    && chmod 0440 /etc/sudoers.d/$USERNAME \
    && rm -rf /var/lib/apt/lists/*

RUN echo "source /opt/ros/$ROS_DISTRO/setup.bash" >> /home/ros/.bashrc


COPY entrypoint.sh /entrypoint.sh

ENTRYPOINT ["/bin/bash", "/entrypoint.sh"]
# To have a working terminal we run: 
CMD ["bash"]
