FROM ros:humble
#update, install vim, remove installation metadata
RUN apt-get update && apt-get install -y vim && rm -rf /var/lib/apt/lists/*
#Copy our own custom files into the image 
COPY config/ /site_config/

