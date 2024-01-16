#!/bin/bash
set -e

export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin

SCRIPT_PATH="$( cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 ; pwd -P )"
source variables.cfg
WORKDIR="$HOME/nodemon"
if ! [ -d "$WORKDIR" ]; then mkdir -p $WORKDIR; fi


# clone and build nodemon

LATEST_VERSION=$(curl -s https://api.github.com/repos/stakingagency/nodemon/releases/latest | jq -r .tag_name)
REPOPATH=$GOPATH/src/github.com/stakingagency
rm -rf $REPOPATH/nodemon
mkdir -p $REPOPATH && cd $REPOPATH
git clone https://github.com/stakingagency/nodemon --branch=$LATEST_VERSION --single-branch --depth=1
cd nodemon/cmd/nodemon
go build -v -ldflags "-X main.appVersion=$LATEST_VERSION"
mv nodemon $WORKDIR
cd $SCRIPT_PATH


# generate the config file

echo "{
  \"telegramID\": $TELEGRAM_ID,
  \"server\": \"$NODEMON_SERVER\"
}" > $WORKDIR/config.json


# generate the service

echo "[Unit]
Description=NodeMon
After=network-online.target

[Service]
User=$USER
WorkingDirectory=$WORKDIR
ExecStart=$WORKDIR/nodemon
StandardOutput=journal
StandardError=journal
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target" > nodemon.service

sudo mv nodemon.service /etc/systemd/system
sudo systemctl enable nodemon --now

