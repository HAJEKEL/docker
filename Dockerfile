FROM osrf/ros:humble

RUN apt-get update && apt-get install -y vim && rm -rf /var/lib/apt/lists/*

COPY config/ /site_config/

