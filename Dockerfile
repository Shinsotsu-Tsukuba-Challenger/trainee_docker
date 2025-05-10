ARG ROS_DISTRO=humble
FROM osrf/ros:${ROS_DISTRO}-desktop-full

SHELL ["/bin/bash", "-c"]

ARG USERNAME
ENV USER=$USERNAME \
    USERNAME=$USERNAME \
    GIT_PS1="${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w$(__git_ps1)\[\033[00m\](\t)\$ " \
    NO_GIT_PS1="${debian_chroot:+($debian_chroot)}\u@\h:\w \$ " \
    TRAINEE_WS=/home/$USERNAME/trainee

# ユーザー作成
RUN set -eux; \
    # 既存の UID/GID を確認し、重複があれば削除
    if id -u $USERNAME >/dev/null 2>&1; then \
        echo "User $USERNAME already exists. Deleting..."; \
        deluser --remove-home $USERNAME; \
    fi; \
    if getent group $USERNAME >/dev/null 2>&1; then \
        echo "Group $USERNAME already exists. Deleting..."; \
        delgroup $USERNAME; \
    fi; \
    echo "Creating user: $USERNAME"; \
    groupadd -g 1000 $USERNAME && \
    useradd -m -s /bin/bash -u 1000 -g 1000 -d /home/$USERNAME $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    chown -R $USERNAME:$USERNAME /home/$USERNAME

# パッケージのインストール
RUN apt update && apt upgrade -y && \
    apt install -y \
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

# SSH設定
RUN mkdir -m 700 ~/.ssh && \
    ssh-keyscan github.com > $HOME/.ssh/known_hosts

# リポジトリのセットアップ
RUN --mount=type=ssh,uid=1000 source <(curl -s https://raw.githubusercontent.com/Shinsotsu-Tsukuba-Challenger/trainee/main/setup.sh) pc && \
    sudo apt-get autoremove -y -qq && \
    sudo rm -rf /var/lib/apt/lists/*

# .bashrcの設定
RUN echo "source /etc/bash_completion" >> $HOME/.bashrc && \
    echo "if [ -f /etc/bash_completion.d/git-prompt ]; then" >> $HOME/.bashrc && \
    echo "    export PS1='${GIT_PS1}'" >> $HOME/.bashrc && \
    echo "else" >> $HOME/.bashrc && \
    echo "    export PS1='${NO_GIT_PS1}'" >> $HOME/.bashrc && \
    bash <(curl -s https://raw.githubusercontent.com/uhobeike/ros2_humble_install_script/main/ros2_setting.sh)

WORKDIR $TRAINEE_WS
CMD ["/bin/bash"]