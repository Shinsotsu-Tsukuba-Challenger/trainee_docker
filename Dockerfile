ARG ROS_DISTRO=humble
FROM osrf/ros:${ROS_DISTRO}-desktop-full

SHELL ["/bin/bash", "-c"]

ARG USERNAME=runner
ARG CACHE_PATH
ENV USER=$USERNAME \
    USERNAME=$USERNAME \
    GIT_PS1="${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w$(__git_ps1)\[\033[00m\](\t)\$ " \
    NO_GIT_PS1="${debian_chroot:+($debian_chroot)}\u@\h:\w \$ " \
    TRAINEE_WS=/home/$USERNAME/trainee

RUN set -eux; \
    if id -u ubuntu >/dev/null 2>&1; then \
        echo "Ubuntu user detected. Deleting ubuntu user..."; \
        pkill -u ubuntu || true; \
        deluser --remove-home ubuntu || true; \
    fi; \
    if getent group ubuntu >/dev/null 2>&1; then \
        delgroup ubuntu || true; \
    fi; \
    if id -u $USERNAME >/dev/null 2>&1; then \
        deluser --remove-home $USERNAME || true; \
    fi; \
    if getent group $USERNAME >/dev/null 2>&1; then \
        delgroup $USERNAME || true; \
    fi; \
    if id -u 1000 >/dev/null 2>&1; then \
        usermod -u 9999 $(id -un 1000) || true; \
    fi; \
    if getent group 1000 >/dev/null 2>&1; then \
        groupmod -g 9999 $(getent group 1000 | cut -d: -f1) || true; \
    fi; \
    groupadd -g 1000 $USERNAME && \
    useradd -m -s /bin/bash -u 1000 -g 1000 -d /home/$USERNAME $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    chown -R $USERNAME:$USERNAME /home/$USERNAME

RUN grep -lr 'http://packages.ros.org/ros2/ubuntu' /etc/apt/sources.list /etc/apt/sources.list.d/* | xargs rm -f || true && \
    rm -f /usr/share/keyrings/ros-archive-keyring.gpg /usr/share/keyrings/ros2-latest-archive-keyring.gpg /etc/apt/trusted.gpg.d/ros2.gpg || true && \
    curl -sSL https://raw.githubusercontent.com/ros/rosdistro/master/ros.key | gpg --dearmor -o /usr/share/keyrings/ros-archive-keyring.gpg && \
    echo "deb [arch=$(dpkg --print-architecture) signed-by=/usr/share/keyrings/ros-archive-keyring.gpg] http://packages.ros.org/ros2/ubuntu $(lsb_release -cs) main" \
      | tee /etc/apt/sources.list.d/ros2.list > /dev/null && \
    apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y \
      bash-completion \
      eog \
      git \
      terminator \
      vim \
      wget \
      wmctrl \
      xdotool \
      xterm

USER $USERNAME

RUN mkdir -m 700 ~/.ssh && \
    ssh-keyscan github.com > $HOME/.ssh/known_hosts

COPY $CACHE_PATH/ /tmp/

RUN mkdir -p /home/$USERNAME/trainee && \
    sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/trainee && \
    sudo chmod -R 755 /home/$USERNAME/trainee && \
    if [ -f /tmp/install.tar.gz ]; then \
        tar --numeric-owner -xzf /tmp/install.tar.gz -C /home/$USERNAME/trainee; \
    fi && \
    if [ -f /tmp/build.tar.gz ]; then \
        tar --numeric-owner -xzf /tmp/build.tar.gz -C /home/$USERNAME/trainee; \
    fi && \
    if [ -f /tmp/log.tar.gz ]; then \
        tar --numeric-owner -xzf /tmp/log.tar.gz -C /home/$USERNAME/trainee; \
    fi && \
    if [ -f /tmp/src.tar.gz ]; then \
        tar --numeric-owner -xzf /tmp/src.tar.gz -C /tmp; \
    fi

RUN --mount=type=ssh,uid=1000 \
    sudo chown -R $USERNAME:$USERNAME /home/$USERNAME/trainee && \
    sudo chmod -R 755 /home/$USERNAME/trainee && \
    source <(curl -s https://raw.githubusercontent.com/Shinsotsu-Tsukuba-Challenger/trainee/main/setup.sh) pc true /tmp/src && \
    sudo apt-get autoremove -y -qq && \
    sudo rm -rf /var/lib/apt/lists/* && \
    mkdir /home/$USERNAME/trainee/src/unko -p && \
    tar --numeric-owner -czf /home/$USERNAME/install.tar.gz -C /home/$USERNAME/trainee install && \
    tar --numeric-owner -czf /home/$USERNAME/build.tar.gz -C /home/$USERNAME/trainee build && \
    tar --numeric-owner -czf /home/$USERNAME/log.tar.gz -C /home/$USERNAME/trainee log && \
    tar --numeric-owner -czf /home/$USERNAME/src.tar.gz -C /home/$USERNAME/trainee src

RUN echo "source /etc/bash_completion" >> $HOME/.bashrc && \
    echo "if [ -f /etc/bash_completion.d/git-prompt ]; then" >> $HOME/.bashrc && \
    echo "    source /etc/bash_completion.d/git-prompt" >> $HOME/.bashrc && \
    echo "    export GIT_PS1_SHOWDIRTYSTATE=1" >> $HOME/.bashrc && \
    echo "    export PS1='${GIT_PS1}'" >> $HOME/.bashrc && \
    echo "else" >> $HOME/.bashrc && \
    echo "    export PS1='${NO_GIT_PS1}'" >> $HOME/.bashrc && \
    echo "fi" >> $HOME/.bashrc && \
    bash <(curl -s https://raw.githubusercontent.com/uhobeike/ros2_install_script/refs/heads/main/ros2_env_setup.sh)

WORKDIR $TRAINEE_WS
CMD ["/bin/bash", "-c", "source ~/.bashrc && /bin/bash"]