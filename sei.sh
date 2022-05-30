#!/bin/bash

while true
do

# Logo

echo -e '\e[40m\e[91m'
echo -e '  ____                  _                    '
echo -e ' / ___|_ __ _   _ _ __ | |_ ___  _ __        '
echo -e '| |   |  __| | | |  _ \| __/ _ \|  _ \       '
echo -e '| |___| |  | |_| | |_) | || (_) | | | |      '
echo -e ' \____|_|   \__  |  __/ \__\___/|_| |_|      '
echo -e '            |___/|_|                         '
echo -e '    _                 _                      '
echo -e '   / \   ___ __ _  __| | ___ _ __ ___  _   _ '
echo -e '  / _ \ / __/ _  |/ _  |/ _ \  _   _ \| | | |'
echo -e ' / ___ \ (_| (_| | (_| |  __/ | | | | | |_| |'
echo -e '/_/   \_\___\__ _|\__ _|\___|_| |_| |_|\__  |'
echo -e '                                       |___/ '
echo -e '\e[0m'

sleep 2

# Menu

PS3='Select an action: '
options=(
"Install"
"Create Wallet"
"Faucet"
"Create Validator"
"Exit")
select opt in "${options[@]}"
do
case $opt in

"Install")
echo "============================================================"
echo "Install start"
echo "============================================================"


# set vars
if [ ! $NODENAME ]; then
	read -p "Enter node name: " NODENAME
	echo 'export NODENAME='$NODENAME >> $HOME/.bash_profile
fi
echo "export WALLET=wallet" >> $HOME/.bash_profile
echo "export CHAIN_ID=sei-testnet-1" >> $HOME/.bash_profile
source $HOME/.bash_profile

PEERS="67cd4f00052f81d4abbcc8013e300b302a3ffe6e@95.216.189.214:26656,5082637d2face9dd32c4ad7eff34d38df4244c9a@65.21.123.69:26641,4aaa57eb2ed8f839253193a893389338c081929b@80.82.215.233:26656,38b4d78c7d6582fb170f6c19330a7e37e6964212@194.163.189.114:46656,27aab76f983cd7c6558f1dfc50b919daaef14555@3.22.112.181:26656,585727dac5df8f8662a8ff42052a9584a1f7ee95@165.22.25.77:26656,dc882e58c0c51763a12423dfcac5815ef092bc29@65.108.202.114:26656"

sed -i.bak -e "s/^persistent_peers =./persistent_peers = "$PEERS"/" $HOME/.sei-chain/config/config.toml

# update
sudo apt update && sudo apt upgrade -y


# packages
sudo apt install curl tar wget clang pkg-config libssl-dev jq build-essential bsdmainutils git make ncdu gcc git jq chrony liblz4-tool -y

# install go
source $HOME/.bash_profile
    if go version > /dev/null 2>&1
    then
        echo -e '\n\e[40m\e[92mSkipped Go installation\e[0m'
    else
        echo -e '\n\e[40m\e[92mStarting Go installation...\e[0m'
        cd $HOME && ver="1.17.2"
        wget "https://golang.org/dl/go$ver.linux-amd64.tar.gz"
        sudo rm -rf /usr/local/go
        sudo tar -C /usr/local -xzf "go$ver.linux-amd64.tar.gz"
        sudo rm "go$ver.linux-amd64.tar.gz"
        echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profile
        echo "export PATH=$PATH:/usr/local/go/bin:$HOME/go/bin" >> $HOME/.bash_profilesource
        source $HOME/.bash_profile
        go version
    fi

# download binary
cd $HOME
git clone https://github.com/sei-protocol/sei-chain.git
cd sei-chain
git checkout 1.0.0beta
go build -o build/seid ./cmd/sei-chaind
chmod +x ./build/seid && mv ./build/seid /usr/local/bin/seid

# config
seid config chain-id $CHAIN_ID
seid config keyring-backend file

# init
seid init $NODENAME --chain-id $CHAIN_ID

# download genesis and addrbook
wget -qO $HOME/.sei-chain/config/genesis.json "https://raw.githubusercontent.com/sei-protocol/testnet/master/sei-testnet-1/genesis.json"
wget -qO $HOME/.sei-chain/config/addrbook.json "https://raw.githubusercontent.com/sei-protocol/testnet/master/sei-testnet-1/addrbook.json"

# set minimum gas price
sed -i -e "s/^minimum-gas-prices *=.*/minimum-gas-prices = \"0usei\"/" $HOME/.sei-chain/config/app.toml

# set peers and seeds
SEEDS=""
PEERS="585727dac5df8f8662a8ff42052a9584a1f7ee95@165.22.25.77:26656,2f047e234cb8b99fe8b9fee0059a5bc45042bc97@95.216.84.188:26656,bab4849cf3918c37b04cd3714984d1765616a4b2@49.12.76.255:36656,ab955dc7f70d8613ab4b554868d4658fd70b797b@217.79.180.194:26656,39c4bcaded0d1d886f2788ae955f1939406f3e7d@65.108.198.54:26696,9db58dba3b6354177fb428caccf5167c616ad4a1@167.235.28.18:26656,2f2804434afda302c86eb89eca27503e49a8a260@65.21.131.215:26696,38b4d78c7d6582fb170f6c19330a7e37e6964212@194.163.189.114:46656,7c5ee0d66a15013f0a771055378c5316331f17ba@95.216.101.84:25646,6f71bcbe347069fc4df9b607f6b843226e8deb71@95.217.221.201:26656"
sed -i -e "s/^seeds *=.*/seeds = \"$SEEDS\"/; s/^persistent_peers *=.*/persistent_peers = \"$PEERS\"/" $HOME/.sei-chain/config/config.toml

# enable prometheus
sed -i -e "s/prometheus = false/prometheus = true/" $HOME/.sei-chain/config/config.toml

# config pruning
pruning="custom"
pruning_keep_recent="100"
pruning_keep_every="0"
pruning_interval="10"

sed -i -e "s/^pruning *=.*/pruning = \"$pruning\"/" $HOME/.sei-chain/config/app.toml
sed -i -e "s/^pruning-keep-recent *=.*/pruning-keep-recent = \"$pruning_keep_recent\"/" $HOME/.sei-chain/config/app.toml
sed -i -e "s/^pruning-keep-every *=.*/pruning-keep-every = \"$pruning_keep_every\"/" $HOME/.sei-chain/config/app.toml
sed -i -e "s/^pruning-interval *=.*/pruning-interval = \"$pruning_interval\"/" $HOME/.sei-chain/config/app.toml

# reset
seid unsafe-reset-all


# create service
tee $HOME/seid.service > /dev/null <<EOF
[Unit]
Description=seid
After=network.target
[Service]
Type=simple
User=$USER
ExecStart=$(which seid) start
Restart=on-failure
RestartSec=10
LimitNOFILE=65535
[Install]
WantedBy=multi-user.target
EOF

sudo mv $HOME/seid.service /etc/systemd/system/

# start service
sudo systemctl daemon-reload
sudo systemctl enable seid
sudo systemctl restart seid

break
;;

"Create Wallet")
seid keys add $WALLET
echo "============================================================"
echo "Save address and mnemonic"
echo "============================================================"
WALLET_ADDRESS=$(seid keys show $WALLET -a)
VALOPER_ADDRESS=$(seid keys show $WALLET --bech val -a)
echo 'export WALLET_ADDRESS='${WALLET_ADDRESS} >> $HOME/.bash_profile
echo 'export VALOPER_ADDRESS='${VALOPER_ADDRESS} >> $HOME/.bash_profile
source $HOME/.bash_profile

break
;;

"Faucet")
curl -X POST -d '{"address": "'"$WALLET_ADDRESS"'", "coins": ["1000000usei"]}' http://3.22.112.181:8000

break
;;

"Create Validator")
seid tx staking create-validator \
  --amount 1000000usei \
  --from $WALLET \
  --commission-max-change-rate "0.01" \
  --commission-max-rate "0.2" \
  --commission-rate "0.07" \
  --min-self-delegation "1" \
  --pubkey  $(seid tendermint show-validator) \
  --moniker $NODENAME \
  --chain-id $CHAIN_ID
  
break
;;

"Exit")
exit
;;
*) echo "invalid option $REPLY";;
esac
done
done
