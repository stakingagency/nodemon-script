#!/bin/bash
set -e

export GOPATH=$HOME/go
export PATH=$PATH:/usr/local/go/bin

SCRIPT_PATH="$( cd -- "$(dirname "${BASH_SOURCE[0]}")" >/dev/null 2>&1 ; pwd -P )"
source $SCRIPT_PATH/variables.cfg
WORKDIR="$CUSTOM_HOME/nodemon"
if ! [ -d "$WORKDIR" ]; then mkdir -p $WORKDIR; fi


// clone and build nodemon

LATEST_VERSION=$(curl -s https://api.github.com/repos/stakingagency/nodemon/releases/latest | jq -r .tag_name)
cd $GOPATH/src/github.com/stakingagency
git clone https://github.com/stakingagency/nodemon --branch=$LATEST_VERSION --single_branch --depth=1
cd nodemon/cmd/nodemon
go build -v
mv nodemon $WORKDIR
cd $SCRIPT_PATH


// generate the config file

echo "{
  \"telegramID\": $TELEGRAM_ID,
  \"server\": \"$NODEMON_SERVER\"
}" > $WORKDIR/config.json


// generate the service

sudo echo "[Unit]
Description=NodeMon
After=network-online.target

[Service]
User=$CUSTOM_USER
WorkingDirectory=$WORKDIR
ExecStart=$WORKDIR/nodemon
StandardOutput=journal
StandardError=journal
Restart=always
RestartSec=3
LimitNOFILE=4096

[Install]
WantedBy=multi-user.target" > /etc/systemd/system/nodemon.service

sudo systemctl enable nodemon
sudo systemctl start nodemon

