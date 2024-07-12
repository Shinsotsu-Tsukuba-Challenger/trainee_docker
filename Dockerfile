FROM osrf/ros:humble-desktop-full

SHELL ["/bin/bash", "-c"]

# 引数
ARG USERNAME="root"

# 環境変数の設定
ENV USER=$USERNAME \
    USERNAME=$USERNAME \
    GIT_PS1="${debian_chroot:+($debian_chroot)}\[\033[01;32m\]\u@\h\[\033[00m\]:\[\033[01;34m\]\w$(__git_ps1)\[\033[00m\](\t)\$ " \
    NO_GIT_PS1="${debian_chroot:+($debian_chroot)}\u@\h:\w \$ "

# ユーザに関する設定
RUN groupadd -g 1000 $USERNAME && \
    useradd -m -s /bin/bash -u 1000 -g 1000 -d /home/$USERNAME $USERNAME && \
    echo "$USERNAME ALL=(ALL) NOPASSWD:ALL" >> /etc/sudoers && \
    chown -R $USERNAME:$USERNAME /home/$USERNAME

# apt パッケージのインストール
RUN apt update && apt upgrade -y && \
    apt install -y \
    bash-completion \
    eog \
    git \
    terminator \
    vim \
    wget \
    xterm

# パッケージのインストール、依存関係の解決 
USER $USERNAME
RUN mkdir -p /home/$USERNAME/trainee_ws/src && \
    cd /home/$USERNAME/trainee_ws/src && \
    rosdep update && \
    rosdep install -r -y --from-paths --ignore-src ./ && \
    : "remove cache" && \
    sudo apt-get autoremove -y -qq && \
    sudo rm -rf /var/lib/apt/lists/*

# ワークスペースのビルド
WORKDIR /home/$USERNAME/trainee_ws/
RUN source /opt/ros/humble/setup.bash && \
    colcon build --symlink-install

# 設定の書き込み
RUN echo "source /home/$USERNAME/trainee_ws/install/setup.bash" >> $HOME/.bashrc && \
    echo "source /etc/bash_completion" >> $HOME/.bashrc && \
    echo "if [ -f /etc/bash_completion.d/git-prompt ]; then" >> $HOME/.bashrc && \
    echo "    export PS1='${GIT_PS1}'" >> $HOME/.bashrc && \
    echo "else" >> $HOME/.bashrc && \
    echo "    export PS1='${NO_GIT_PS1}'" >> $HOME/.bashrc && \
    echo "fi" >> $HOME/.bashrc && \
    bash <(curl -s https://raw.githubusercontent.com/uhobeike/ros2_humble_install_script/main/ros2_setting.sh)

WORKDIR /home/$USERNAME/trainee_ws/src
CMD ["/bin/bash"]