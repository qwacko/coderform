# build/Dockerfile

ARG UBUNTU_VERSION=latest
ARG ADDITIONAL_PACKAGES=

FROM ubuntu:${UBUNTU_VERSION}

# Install dependencies
RUN apt-get update && \
    apt-get install -y \
      curl git sudo vim wget tmux jq socat ${ADDITIONAL_PACKAGES} \
    && rm -rf /var/lib/apt/lists/*

# Add a new user
ARG USER=coder
RUN useradd --groups sudo --shell /bin/bash ${USER} && \
    echo "${USER} ALL=(ALL) NOPASSWD:ALL" >/etc/sudoers.d/${USER} && \
    chmod 0440 /etc/sudoers.d/${USER}


COPY install-runtimes.sh /home/${USER}/install-runtimes.sh
RUN chown ${USER}:${USER} /home/${USER}/install-runtimes.sh
RUN chmod +x /home/${USER}/install-runtimes.sh
RUN su - ${USER} -c "/home/${USER}/install-runtimes.sh"

USER ${USER}
WORKDIR /home/${USER}