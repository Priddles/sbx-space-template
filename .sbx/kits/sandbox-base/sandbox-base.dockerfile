# Base image for devcontainer and the sandbox
#
# Based on:
#  - https://github.com/devcontainers/images/blob/main/src/base-debian/.devcontainer/Dockerfile
#  - https://github.com/devcontainers/features/blob/main/src/common-utils/main.sh
#  - https://docs.docker.com/ai/sandboxes/customize/author/build-an-agent/

FROM buildpack-deps:trixie-curl AS base
    # Non-root user
    ARG USERNAME=code \
        GROUPNAME=${USERNAME}
    # Tool and runtime versions
    ARG GO_VERSION=1.27.2 \
        GOTESTSUM_VERSION=1.13.0 \
        NVM_VERSION=0.40.8 \
        NODE_VERSION=lts/*
        # PYTHON3_VERSION = whatever is latest on apt

    # Set locale so Unicode characters render correctly in locale-aware tools (e.g. tmux).
    ENV LANG=C.UTF-8

    RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
        && apt-get -y install --no-install-recommends \
        apt-transport-https \
        bzip2 \
        git \
        htop \
        jq \
        less \
        locales \
        lsof \
        man-db \
        manpages \
        manpages-dev \
        ncdu \
        procps \
        python3 \
        strace \
        sudo \
        unzip \
        vim-tiny \
        xz-utils \
        zip

    # Mainly done to upgrade packages to avoid security issues
    RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
        && apt-get upgrade -y \
        && apt-get autoremove -y \
        && apt-get clean -y \
        && rm -rf /var/lib/apt/lists/*

    # Set up locale
    RUN localedef -i en_AU -c -f UTF-8 -A /usr/share/locale/locale.alias en_AU.UTF-8
    ENV LANG=en_AU.UTF-8 \
        LC_ALL=en_AU.UTF-8

    # Alias python -> python3
    RUN ln -sf python3 /usr/bin/python

    # Install go toolchain
    # FIXME: go and gotestsum hard-coded to arm64 variant.
    RUN curl -Sso- -L https://go.dev/dl/go${GO_VERSION}.linux-arm64.tar.gz | tar -xzf - -C /usr/local \
        && echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh
    RUN mkdir -p /usr/local/gotestsum \
        && curl -Sso- -L https://github.com/gotestyourself/gotestsum/releases/download/v${GOTESTSUM_VERSION}/gotestsum_${GOTESTSUM_VERSION}_linux_arm64.tar.gz \
        | tar -xzf - -C /usr/local/gotestsum \
        && ln -sf /usr/local/gotestsum/gotestsum /usr/local/go/bin/gotestsum

    # Create non-root user and setup sudo
    RUN groupadd ${GROUPNAME} \
        && useradd -s /bin/bash --uid 1000 --gid ${GROUPNAME} -m ${USERNAME}
    RUN mkdir -p /etc/sudoers.d \
        && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
        && chmod 0440 /etc/sudoers.d/${USERNAME}

FROM base AS user
    USER ${USERNAME}

    # Ensure user directories
    #
    # ~/workspace is the default mount location for sbx in clone mode.
    RUN mkdir -p \
        /home/${USERNAME}/.config \
        /home/${USERNAME}/.local/bin /home/${USERNAME}/.local/share /home/${USERNAME}/.local/state \
        /home/${USERNAME}/workspace

    # Install nvm and node
    RUN curl -Sso- -L https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash

FROM user AS devcontainer
    # Setup bash theme
    COPY --chown=${USERNAME}: ./files/bash_theme_snippet.sh /tmp/bash_theme_snippet.sh
    RUN cat /tmp/bash_theme_snippet.sh > /home/${USERNAME}/.bashrc \
        && chown ${USERNAME}:${GROUPNAME} /home/${USERNAME}/.bashrc \
        && rm /tmp/bash_theme_snippet.sh

    ENTRYPOINT ["sleep", "infinity"]
    CMD []

FROM user AS sandbox
    RUN mkdir -p /home/${USERNAME}/.docker/sandbox/locks

    # SETUP: Update to use chosen harness.
    ENTRYPOINT ["bash", "-l"]
    CMD []
