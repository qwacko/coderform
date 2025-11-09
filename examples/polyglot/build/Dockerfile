# build/Dockerfile

ARG UBUNTU_VERSION=latest
ARG PACKAGES=""
ARG RUN_INSTALL_AT_BUILD=true

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

# Copy scripts to /tmp for execution and inspection
COPY install.sh /tmp/install.sh
COPY startup.sh /tmp/startup.sh
RUN chmod +x /tmp/install.sh /tmp/startup.sh

# Conditionally run installation script during build (based on RUN_INSTALL_AT_BUILD)
ARG RUN_INSTALL_AT_BUILD
RUN if [ "$RUN_INSTALL_AT_BUILD" = "true" ]; then \
      echo "Running install script during Docker build..."; \
      bash /tmp/install.sh; \
    else \
      echo "Skipping install script during build (will run at startup)"; \
    fi

USER ${USER}
WORKDIR /home/${USER}