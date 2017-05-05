#!/bin/bash

cd /vagrant

apt-get update && apt-get install -y rkt acbuild rng-tools expect

echo 'HRNGDEVICE=/dev/urandom' >> /etc/default/rng-tools

NAME="Carly Container"
EMAIL="carly@example.com"

GPGBATCH="$(cat <<EOF
%echo Generating a default key
Key-Type: RSA
Key-Length: 2048
Subkey-Type: RSA
Subkey-Length: 2048
Name-Real: $NAME
Name-Comment: ACI signing key
Name-Email: $EMAIL
Expire-Date: 0
Passphrase: rkt
%pubring rkt.pub
%secring rkt.sec
%commit
%echo done
EOF
)"

echo "$GPGBATCH"
echo "$GPGBATCH" > gpg-batch
gpg --batch --gen-key gpg-batch

HASH="$(gpg --no-default-keyring --secret-keyring ./rkt.sec --keyring ./rkt.pub --list-keys | awk '{print NR-1 "," $0}' | grep '3, *' | awk '{print $2;}')"

/usr/bin/expect <<EOF
spawn echo "$HASH"
spawn gpg --yes --no-default-keyring --secret-keyring ./rkt.sec --keyring ./rkt.pub --edit-key $HASH trust quit

expect "Your decision?"
send "5\r"

expect "Do you really want to set this key to ultimate trust? (y/N)"
send "y\r"

EOF

gpg --no-default-keyring --armor --secret-keyring ./rkt.sec --keyring ./rkt.pub --export $EMAIL > pubkeys.gpg
gpg --export-secret-keys --secret-keyring ./rkt.sec --keyring ./rkt.pub  $HASH > secret.asc


