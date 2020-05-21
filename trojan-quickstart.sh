#!/bin/bash
set -euo pipefail

function prompt() {
    while true; do
        read -p "$1 [y/N] " yn
        case $yn in
            [Yy] ) return 0;;
            [Nn]|"" ) return 1;;
        esac
    done
}

if [[ $(id -u) != 0 ]]; then
    echo Please run this script as root.
    exit 1
fi

if [[ $(uname -m 2> /dev/null) != x86_64 ]]; then
    echo Please run this script on x86_64 machine.
    exit 1
fi

NAME=trojan
TMPDIR="$(mktemp -d)"
INSTALLPREFIX=/usr/local
SYSTEMDPREFIX=/etc/systemd/system
BINARYPATH="$INSTALLPREFIX/bin/$NAME"
CONFIGPATH="$INSTALLPREFIX/etc/$NAME/config.json"
SYSTEMDPATH="$SYSTEMDPREFIX/$NAME.service"

echo Entering temp directory $TMPDIR...
cd "$TMPDIR"

echo Downloading $NAME ...


PS3='This Node are Premium plan Only?'
options=("Yes" "No")
select opt in "${options[@]}"
do
    case $opt in
        "Yes")
			wget https://github.com/kot4ri/trojan-quickstart/raw/master/E/trojan-linux-amd64.tar.xz
			break
            ;;
        "No")
			wget https://github.com/kot4ri/trojan-quickstart/raw/master/C/trojan-linux-amd64.tar.xz
			break
            ;;
        *) echo "invalid option $REPLY";;
    esac
done

echo Unpacking $NAME ...
tar xf trojan-linux-amd64.tar.xz
cd "$NAME"

echo Installing $NAME to $BINARYPATH...
install -Dm755 "$NAME" "$BINARYPATH"

echo Installing $NAME server config to $CONFIGPATH...
if ! [[ -f "$CONFIGPATH" ]] || prompt "The server config already exists in $CONFIGPATH, overwrite?"; then
    install -Dm644 examples/server.json-example "$CONFIGPATH"
else
    echo Skipping installing $NAME server config...
fi

if [[ -d "$SYSTEMDPREFIX" ]]; then
    echo Installing $NAME systemd service to $SYSTEMDPATH...
    if ! [[ -f "$SYSTEMDPATH" ]] || prompt "The systemd service already exists in $SYSTEMDPATH, overwrite?"; then
        cat > "$SYSTEMDPATH" << EOF
[Unit]
Description=$NAME
Documentation=https://trojan-gfw.github.io/$NAME/config https://trojan-gfw.github.io/$NAME/
After=network.target network-online.target nss-lookup.target mysql.service mariadb.service mysqld.service

[Service]
Type=simple
StandardError=journal
ExecStart="$BINARYPATH" "$CONFIGPATH"
ExecReload=/bin/kill -HUP \$MAINPID
LimitNOFILE=51200
Restart=on-failure
RestartSec=1s

[Install]
WantedBy=multi-user.target
EOF

        echo Reloading systemd daemon...
        systemctl daemon-reload
    else
        echo Skipping installing $NAME systemd service...
    fi
fi

echo Deleting temp directory $TMPDIR...
rm -rf "$TMPDIR"

echo Done!
