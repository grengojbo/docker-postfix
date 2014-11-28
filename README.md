# Docker Postfix


### Installation

Use build automated by docker registry :

```sh
make run
```

Use build manually :

```sh
make build
make run
```

### Manage

```sh
make start
make stop
make restart
```

### Options

Add your domain key .private with :

	-v /path/to/domainkeys:/etc/opendkim/domainkeys

Add your ssl certificates .key and .crt with :

	-v /path/to/certs:/etc/postfix/certs

### Help

```sh
make help
```


### What make ?

#### Introduce to makefile

http://gl.developpez.com/tutoriel/outil/makefile/

#### Installation

Debian, Ubuntu : 

```sh
sudo apt-get install build-essential
```

CentOS, Red Hat, Fedora : 

```sh
yum install gcc gcc-c++ autoconf automake
```

#### Once installed check

```sh
make -v
```


### What docker ?

#### Introduce to docker

https://docs.docker.com/

#### Installation

https://docs.docker.com/installation/