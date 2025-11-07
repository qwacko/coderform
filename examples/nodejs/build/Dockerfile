# build/Dockerfile

ARG NODE_BASE_IMAGE=node:24-bookworm
FROM ${NODE_BASE_IMAGE}

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
      curl git sudo vim wget tmux jq socat \
    && rm -rf /var/lib/apt/lists/*

# Add a new user
ARG USER=coder
RUN useradd --groups sudo --shell /bin/bash ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USER} && \
    chmod 0440 /etc/sudoers.d/${USER}

# Install PNPM
RUN npm install -g \
    pnpm


USER ${USER}
WORKDIR /home/${USER}