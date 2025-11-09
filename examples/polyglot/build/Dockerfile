# build/Dockerfile

ARG UBUNTU_VERSION=latest
ARG ADDITIONAL_PACKAGES=

FROM ubuntu:${UBUNTU_VERSION}

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
      bash \
      ca-certificates \
      build-essential \
      curl \
      git \
      jq \
      socat \
      sudo \
      tmux \
      vim \
      wget \
      unzip \
      ${ADDITIONAL_PACKAGES} \
    && rm -rf /var/lib/apt/lists/*

# Add a new user
ARG USER=coder
RUN useradd --groups sudo --shell /bin/bash ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USER} && \
    chmod 0440 /etc/sudoers.d/${USER}


# Copy the runtime installation script to /tmp
COPY install-runtimes.sh /tmp/install-runtimes.sh

USER ${USER}
WORKDIR /home/${USER}