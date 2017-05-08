# rkt-vagrant
Vagrant file for using rkt and acbuild in projects instead of docker for mac/windows or the docker toolbox.

# usage
## provision vm
provision vagrant vm
```
vagrant up
```
this command will create a new private pgpkey for you, which you will need to sign appc images images created with acbuild.
Your secret key is gitignored so it will not be pushed to any git repository, the corresponding public key in the `.pgpkeys` directory should be added to 
your git repository to be imported by others using the repository.

all public keys found in `.gpgkeys`will be trusted when provisioning the vagrant vm. 
To trust new public keys just reprovision it using `vagrant up --provision`.


then ssh into it and start using rkt to run containers and acbuild to build container images.

## example
```
vagrant ssh
sudo -i # some acbuild commands require root permissions
acbuild begin
acbuild dep add quay.io/coreos/alpine-sh
acbuild run -- apk update
acbuild run -- apk add nginx
acbuild port add http tcp 80
acbuild mount add html /usr/share/nginx/html
acbuild set-exec /usr/sbin/nginx
acbuild set-name example.com/nginx
acbuild write nginx.aci
acbuild end

gpg --output nginx.aci.asc --detach-sign nginx.aci

rkt run ubuntu-nginx.aci
```

# known issues
the `acbuild run` command does not work when building an image while inside a directory shared between virtualbox vm and host.
