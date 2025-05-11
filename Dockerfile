ARG ROS_DISTRO=humble
FROM osrf/ros:${ROS_DISTRO}-desktop-full

SHELL ["/bin/bash", "-c"]

ARG USERNAME=runner
ENV USER=$USERNAME \
    USERNAME=$USERNAME \
    GIT_PS1="${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w$(__git_ps1)\[\033[00m\](\t)\$ " \
    NO_GIT_PS1="${debian_chroot:+($debian_chroot)}\u@\h:\w \$ " \
    TRAINEE_WS=/home/$USERNAME/trainee

# ユーザー作成
RUN set -eux; \
    # `ubuntu` ユーザーが存在する場合、削除
    if id -u ubuntu >/dev/null 2>&1; then \
        echo "Ubuntu user detected. Deleting ubuntu user..."; \
        pkill -u ubuntu || true; \
        deluser --remove-home ubuntu || true; \
    fi; \
    if getent group ubuntu >/dev/null 2>&1; then \
        delgroup ubuntu || true; \
    fi; \
    # `runner` ユーザーが既に存在する場合、削除
    if id -u $USERNAME >/dev/null 2>&1; then \
        deluser --remove-home $USERNAME || true; \
    fi; \
    if getent group $USERNAME >/dev/null 2>&1; then \
        delgroup $USERNAME || true; \
    fi; \
    # `1000:1000` が既に存在する場合の処理
    if id -u 1000 >/dev/null 2>&1; then \
        usermod -u 9999 $(id -un 1000) || true; \
    fi; \
    if getent group 1000 >/dev/null 2>&1; then \
        groupmod -g 9999 $(getent group 1000 | cut -d: -f1) || true; \
    fi; \
    # 新しい `runner` ユーザーを作成
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

# リポジトリのcloneおよびキャッシュディレクトリの作成
RUN git clone git@github.com:Shinsotsu-Tsukuba-Challenger/trainee.git $HOME/trainee && \
    mkdir -p /home/$USERNAME/trainee/install \
             /home/$USERNAME/trainee/build \
             /home/$USERNAME/trainee/log \
             /home/$USERNAME/cache/vcs_hashes

# リポジトリのセットアップ
RUN --mount=type=ssh,uid=1000 \
    --mount=type=cache,target=/home/$USERNAME/trainee/install,uid=1000 \
    --mount=type=cache,target=/home/$USERNAME/trainee/build,uid=1000 \
    --mount=type=cache,target=/home/$USERNAME/trainee/log,uid=1000 \
    --mount=type=cache,target=/home/$USERNAME/cache/vcs_hashes,uid=1000 \
    source <(curl -s https://raw.githubusercontent.com/Shinsotsu-Tsukuba-Challenger/trainee/main/setup.sh) pc /home/$USERNAME/cache/vcs_hashes && \
    sudo apt-get autoremove -y -qq && \
    sudo rm -rf /var/lib/apt/lists/*

# .bashrcの設定
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