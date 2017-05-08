#!/bin/bash

echo "installing additional packages"
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
%no-protection
%pubring rkt.pub
%commit
%echo done
EOF
)"

cd /vagrant
if [ ! -e .pgpkeys/secret.key ]; then
    echo "creating new pgp key for signing images"
    echo "$GPGBATCH" > gpg-batch
    gpg --batch --gen-key gpg-batch
    rm gpg-batch

    HASH="$(gpg --no-default-keyring --keyring ./rkt.pub --list-keys | awk '{print NR-1 "," $0}' | grep '3, *' | awk '{print $2;}')"

    /usr/bin/expect <<EOF
log_user 0
spawn echo "$HASH"
spawn gpg --yes --no-default-keyring --keyring ./rkt.pub --edit-key $HASH trust quit
expect "Your decision?"
send "5\r"
expect "Do you really want to set this key to ultimate trust? (y/N)"
send "y\r"
EOF

    echo "exporting keys"
    mkdir -p .pgpkeys

    gpg --no-default-keyring --armor --keyring ./rkt.pub --export $EMAIL > .pgpkeys/pubkeys-$HASH.gpg
    gpg --export-secret-keys --keyring ./rkt.pub $HASH > .pgpkeys/secret.key

    echo "cleaning up"
    rm ./rkt.pub
    rm gpg-batch
fi

echo "importing secret key to .gpgkeys/secret.key"
gpg --import .pgpkeys/secret.key

echo "trusting all public keys found in .gpgkeys"
rkt trust --skip-fingerprint-review --root .pgpkeys/*.gpg


