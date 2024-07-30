# trainee_docker
ROS 2 Humbleでトレーニー（trainee）を開発するためのDocker Imageのリポジトリです。

sshkeyの設定は[こちらのサイト](https://qiita.com/shizuma/items/2b2f873a0034839e47ce)を参照してください。

## Dockerの環境構築
### 1. dockerのインストール
```
sudo apt install docker.io
```

### 2. Dockerのコマンドをsudoなしで実行するための設定
* dockerグループに現在のユーザを追加

```
sudo gpasswd -a $USER docker
sudo reboot
```

PCを再起動すると  
sudoなしでDockerコマンドを使用できるようになります。

## コンテナを起動

### 1. GUIを使用するためにXサーバへのアクセス許可（.bashrcに記載しておくと楽です）
```
xhost +local:docker
```

### 2. コンテナ起動
```
docker run --rm -it \
           -u $(id -u):$(id -g) \
           --privileged \
           --net=host \
           --ipc=host \
           --env="DISPLAY=$DISPLAY" \
           --mount type=bind,source=/home/$USER/.ssh,target=/home/$USER/.ssh \
           --mount type=bind,source=/home/$USER/.gitconfig,target=/home/$USER/.gitconfig \
           --mount type=bind,source=/usr/share/zoneinfo/Asia/Tokyo,target=/etc/localtime \
           --name raspicat-sim \
           raspicat-sim:humble
```

* 備考
  * --rmを使用して、コンテナが終了した後に自動的にコンテナを削除することを指定（開発時はrmオプションを使用しない方が良いです）
  * --mountを使用して、ローカルの.sshディレクトリをコンテナの起動時にマウント

## 開発 & 実行方法

### 1. terminator
```
terminator
```
terminatorを起動すると新たなターミナルが起動します。

次の操作のためにターミナルを分割して3つにしてください。

* terminatorでよく使うコマンド
  * Ctrl+Shift+Eで縦に分割
  * Ctrl+Shift+Oで横に分割
  * Ctrl+Dで指定しているターミナルを削除

### 2. VSCode
[VSCodeで実行する方法](https://docs.google.com/presentation/d/1Y7u8vi9JRcFFUo7doA_QO3Hfe4nRgeKu4tgbwCCjXjU/edit?usp=sharing)

## 注意
`docker commit`を実行する前に、  
sshディレクトリのアンマウントを行いましょう。（セキュリティー対策）

### .sshディレクトリのアンマウント
```
sudo umount /home/$USER/.ssh 
```