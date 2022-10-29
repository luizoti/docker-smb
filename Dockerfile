# https://wiki.alpinelinux.org/wiki/Alpine_Linux_package_management

FROM alpine:3.10

# Your system user
ARG USER='luiz'
# SMB and SYSTEM password
ARG PASS='smbpass'

# install sudo
RUN apk add --no-cache --update sudo

# install necessary packages
RUN sudo apk add samba-common-tools samba-client samba-server

# create user
RUN adduser -D -s /bin/ash -u 1000 ${USER}

# add user to root group
RUN addgroup ${USER} root
RUN echo ''${USER}' ALL=(ALL) NOPASSWD:ALL' >> /etc/sudoers
RUN echo -ne ""${PASS}"\n"${PASS}"\n" | sudo smbpasswd -a -s ${USER}
RUN echo -ne ""${PASS}"\n"${PASS}"\n" | sudo passwd ${USER}
USER ${USER}

COPY smb.conf /etc/samba/smb.conf

EXPOSE 445/tcp
EXPOSE 445/udp

EXPOSE 139/tcp
EXPOSE 139/udp

EXPOSE 137/tcp
EXPOSE 137/udp

EXPOSE 138/tcp
EXPOSE 138/udp

CMD ["sudo", "smbd", "--foreground", "--log-stdout", "--no-process-group"]
