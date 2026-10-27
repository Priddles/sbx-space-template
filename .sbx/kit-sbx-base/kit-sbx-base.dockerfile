# Base image for devcontainer and the sandbox
#
# Based on:
#  - https://docs.docker.com/ai/sandboxes/customize/author/build-an-agent/
#  - https://github.com/devcontainers/images/blob/main/src/base-debian/.devcontainer/Dockerfile
#  - https://github.com/devcontainers/features/blob/main/src/common-utils/main.sh

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
    ARG COMPLETE_ALIAS_VERSION=1.18.0
    ARG TZ=Australia/Sydney

    # Set locale so Unicode characters render correctly in locale-aware tools (e.g. tmux).
    ENV LANG=C.UTF-8

    # Add docker package registry
    RUN curl -fsSL https://download.docker.com/linux/debian/gpg | gpg --dearmor > /usr/share/keyrings/docker-archive-keyring.gpg \
        && echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/docker-archive-keyring.gpg] https://download.docker.com/linux/debian trixie stable" > /etc/apt/sources.list.d/docker.list

    RUN apt-get update && export DEBIAN_FRONTEND=noninteractive \
        && apt-get -y install --no-install-recommends \
        apt-transport-https \
        bash-completion \
        bzip2 \
        containerd.io \
        docker-buildx-plugin \
        docker-ce \
        docker-ce-cli \
        docker-compose-plugin \
        direnv \
        fzf \
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
        openssh-client \
        procps \
        python3 \
        python3-pip \
        ripgrep \
        rsync \
        socat \
        strace \
        sudo \
        unzip \
        vim-tiny \
        xz-utils \
        zip \
        zoxide

    # Mainly done to upgrade packages to avoid security issues.
    RUN export DEBIAN_FRONTEND=noninteractive \
        && apt-get upgrade -y \
        && apt-get autoremove -y \
        && apt-get clean -y \
        && rm -rf /var/lib/apt/lists/*

    # Set up locale
    RUN localedef -i en_AU -c -f UTF-8 -A /usr/share/locale/locale.alias en_AU.UTF-8
    ENV LANG=en_AU.UTF-8 \
        LC_ALL=en_AU.UTF-8 \
        TZ=${TZ}

    # Alias python -> python3
    RUN ln -sf python3 /usr/bin/python

    # Install go toolchain
    # Go and gotestsum name their release archives by dpkg architecture (amd64, arm64).
    RUN arch=$(dpkg --print-architecture) \
        && curl -fsSL https://go.dev/dl/go${GO_VERSION}.linux-${arch}.tar.gz | tar -xzf - -C /usr/local \
        && echo 'export PATH=$PATH:/usr/local/go/bin' > /etc/profile.d/go.sh \
        && mkdir -p /usr/local/gotestsum \
        && curl -fsSL https://github.com/gotestyourself/gotestsum/releases/download/v${GOTESTSUM_VERSION}/gotestsum_${GOTESTSUM_VERSION}_linux_${arch}.tar.gz \
        | tar -xzf - -C /usr/local/gotestsum \
        && ln -sf /usr/local/gotestsum/gotestsum /usr/local/go/bin/gotestsum

    # Bash completion for aliases (e.g. `dc` completes as `docker compose`).
    ADD https://github.com/cykerway/complete-alias.git#${COMPLETE_ALIAS_VERSION} /usr/local/share/complete-alias

    # Customise bashrc
    #
    # Interactive shell config lives in /etc/bash.bashrc.d so it is shared by every entrypoint and
    # leaves ~/.bashrc and ~/.bash_aliases free for personal config. It is sourced at the end of
    # the skeleton .bashrc, after bash-completion has loaded.
    COPY --chmod=644 ./files/bash.bashrc.d/ /etc/bash.bashrc.d/
    COPY ./files/skel/ /etc/skel/
    RUN chmod 755 /etc/bash.bashrc.d \
        && sed -i 's/^\(\s*\)#\(alias \)/\1\2/' /etc/skel/.bashrc \
        && printf '\n%s\n' \
            '# Image-wide interactive shell config' \
            'for f in /etc/bash.bashrc.d/*.sh; do [ -r "$f" ] && . "$f"; done; unset f' \
            >> /etc/skel/.bashrc

    # Create non-root user and setup sudo.
    RUN groupadd ${GROUPNAME} \
        && useradd -s /bin/bash -u 1000 -g ${GROUPNAME} -G sudo,docker -m ${USERNAME} \
        && mkdir -p /etc/sudoers.d \
        && echo "${USERNAME} ALL=(root) NOPASSWD:ALL" > /etc/sudoers.d/${USERNAME} \
        && chmod 0440 /etc/sudoers.d/${USERNAME}

FROM base AS user
    USER ${USERNAME}

    # Ensure user directories
    #
    # ~/workspace is the default mount location for sbx in clone mode.
    RUN mkdir -p \
        /home/${USERNAME}/.config /home/${USERNAME}/.config/git \
        /home/${USERNAME}/.local/bin /home/${USERNAME}/.local/share /home/${USERNAME}/.local/state \
        /home/${USERNAME}/.ssh \
        /home/${USERNAME}/workspace

    # Install nvm and node
    RUN curl -fsSL https://raw.githubusercontent.com/nvm-sh/nvm/v${NVM_VERSION}/install.sh | bash

    # Add GitHub's SSH keys to known hosts
    RUN curl -fsSL https://api.github.com/meta | jq -r '.ssh_keys[] | "github.com \(.)"' >> /home/${USERNAME}/.ssh/known_hosts

FROM user AS devcontainer
    ENTRYPOINT ["sleep", "infinity"]
    CMD []

FROM user AS sandbox
    RUN mkdir -p /home/${USERNAME}/.docker/sandbox/locks

    # Signal sandbox engine to start docker daemon.
    LABEL com.docker.sandboxes.start-docker=true

    # Persistent environment file. Sourced by every shell so exports appended to it survive across
    # commands. Completion scripts must never be added: it is sourced before every non-interactive
    # command, where COMP_WORDS and friends are unset.
    USER root
    RUN touch /etc/sandbox-persistent.sh \
        && chown ${USERNAME}:${GROUPNAME} /etc/sandbox-persistent.sh \
        && echo '[ -r /etc/sandbox-persistent.sh ] && . /etc/sandbox-persistent.sh' \
            | tee /etc/profile.d/sandbox-persistent.sh /home/${USERNAME}/.bashrc.sandbox >/dev/null \
        && cat /home/${USERNAME}/.bashrc.sandbox >> /etc/bash.bashrc \
        && cat /home/${USERNAME}/.bashrc.sandbox >> /home/${USERNAME}/.bashrc \
        && rm /home/${USERNAME}/.bashrc.sandbox
    USER ${USERNAME}
    ENV BASH_ENV=/etc/sandbox-persistent.sh \
        CLAUDE_ENV_FILE=/etc/sandbox-persistent.sh

    # TEMPLATE: Update to use chosen harness.
    ENTRYPOINT ["bash", "-l"]
    CMD []
