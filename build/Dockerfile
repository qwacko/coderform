ARG NODE_BASE_IMAGE=node:24-bookworm
FROM ${NODE_BASE_IMAGE}

ARG USER=coder

# Install required packages
RUN apt-get update && \
    apt-get install -y \
    sudo \
    curl \
    git \
    && rm -rf /var/lib/apt/lists/*

# Create user
RUN useradd -m -s /bin/bash ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers.d/${USER} && \
    chmod 0440 /etc/sudoers.d/${USER}

# Set working directory
WORKDIR /home/${USER}

# Switch to user
USER ${USER}
