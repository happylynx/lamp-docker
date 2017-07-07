# use: sudo docker run -it --rm -p 8080:80

FROM fedora:25

RUN dnf install -y --setopt=tsflags=nodocs httpd mariadb php
RUN dnf install -y --setopt=tsflags=nodocs mariadb-server
RUN dnf install -y --setopt=tsflags=nodocs findutils
RUN dnf install -y --setopt=tsflags=nodocs vim-enhanced less
# for `ps`
RUN dnf install -y --setopt=tsflags=nodocs procps-ng
RUN dnf install -y --setopt=tsflags=nodocs hostname
# RUN dnf clean all
RUN truncate -s 0 /etc/my.cnf.d/auth_gssapi.cnf
EXPOSE 3306
EXPOSE 80
ADD fs /
RUN chmod a+x /root/start.sh
CMD /root/start.sh
RUN echo cmd done