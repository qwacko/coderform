# Base Ubuntu image - runtimes installed during startup
FROM ubuntu:22.04

ARG ADDITIONAL_PACKAGES=""

# Install base dependencies (required for runtime installers and Coder)
RUN apt-get update && \
    apt-get install -y \
        curl \
        wget \
        git \
        build-essential \
        ca-certificates \
        gnupg \
        lsb-release \
        software-properties-common \
        sudo \
        jq \
        socat \
        vim \
        htop \
        tmux \
        iputils-ping \
        ${ADDITIONAL_PACKAGES} \
        && rm -rf /var/lib/apt/lists/*

# Create coder user
RUN useradd -m -s /bin/bash coder && \
    echo "coder ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/coder && \
    chmod 0440 /etc/sudoers.d/coder

USER coder
WORKDIR /home/coder
