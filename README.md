# docker-smb - Docker Standalone Samba Server

Can be used to quick setup a simple Samba container in host network mode. It will run as if on host, so it can be accessed from other computers on the same network.

# Motivation

After the `Ubuntu/Kubuntu 20.04` update, samba was updated to versions `4.11.+` , In version `4.11.0` support for SMB1 was removed, look [here](https://www.samba.org/samba/history/samba-4.11.0.html).

With this scenario, devices that need SMB1 cannot connect.

In my case the motivation for this container is that it became impossible to use Open PS2 Loader ([OPL](https://www.ps2-home.com/forum/viewtopic.php?t=3)) via SMB on Playstation 2 for using SMB1.

# Container

This container uses the `alpine 3.10` system as a base, so the installed samba version is below version `4.11.0`, maintaining support for SMB1.

Alpine is a good choice because both the base image and the final image after installing the samba are small, the base image of ubuntu 18 for example ends with a size around 150mb.

![alt text](https://github.com/luizoti/docker-smb/blob/master/Screenshot_20200531_161811.png "sizes reference")

# Newbie info?!

`Host` refers to the system installed on your machine.

`Container` refers to the container created by the docker

# Installation

Download the `install-samba.sh` script, and launch it:

```wget -O- "https://raw.githubusercontent.com/luizoti/docker-smb/master/install-samba.sh" | sudo bash```

# docker-compose.yml

You need to edit the folders and volumes that will be mounted in the container.

``` 
volumes:
  - /home/luiz/SMB/:/media/SMB:rw
  - /home/luiz/:/media/HOME:rw
```
The structure of volumes is:
 `folder_in_host:folder_in_conteiner:rw`
 
 # smb.conf

You need to setup the folders you want to share based on folders you previous setup in docker-compose.yml

On docker-compose.yml volume:
```
  - /home/luiz/SMB/:/media/SMB:rw
```

In smb.conf:
```
[PS2]
    comment = PS2
    path = "/media/SMB"

```
_____________________________________________________________________________________________________________________________

I tried to make this script as easy to use as possible.

What does this script do?
1. Install dependencies: git, curl docker, docker-compose e etc.
2. Clone repo.
3. Change user usarname, password, hostname and workdir in `docker-compose.yml`, `Dockerfile`, `docker-smb.service` and `smb.conf` based on host information, all this information, except the password is extracted directly from the system, the password is requested during installation.
4. Check if you want to use old `smb.conf` of your host or use repo config.
5. Install service.
