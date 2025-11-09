# build/Dockerfile

ARG UBUNTU_VERSION=latest
ARG PACKAGES=""

FROM ubuntu:${UBUNTU_VERSION}

# Install base dependencies plus packages from modules
RUN apt-get update && \
    apt-get install -y \
      bash \
      ca-certificates \
      curl \
      git \
      jq \
      socat \
      sudo \
      tmux \
      vim \
      wget \
      unzip \
      ${PACKAGES} \
    && rm -rf /var/lib/apt/lists/*

# Add a new user
ARG USER=coder
RUN useradd --groups sudo --shell /bin/bash ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USER} && \
    chmod 0440 /etc/sudoers.d/${USER}

# Copy and run installation script (if exists)
COPY install.sh /tmp/install.sh 2>/dev/null || true
RUN [ -f /tmp/install.sh ] && bash /tmp/install.sh || true

USER ${USER}
WORKDIR /home/${USER}