# use: sudo docker run -it --rm -p 8080:80 -p 3306:3306 -e DB_PASSWORD=a -e DB_NAME=wordpress -v ~/tmp/wp/html:/var/www/html:z -v ~/tmp/wp/db:/var/lib/mysql:z
# make sure that dirs mounted to
#  * /var/www/html
#  * /var/lib/mysql
# have rw addess for others
# inside container: /root/start.sh

FROM fedora:25

RUN dnf install -y --setopt=tsflags=nodocs httpd mariadb php
RUN dnf install -y --setopt=tsflags=nodocs mariadb-server
RUN dnf install -y --setopt=tsflags=nodocs findutils
RUN dnf install -y --setopt=tsflags=nodocs vim-enhanced less
# for `ps`
RUN dnf install -y --setopt=tsflags=nodocs procps-ng
RUN dnf install -y --setopt=tsflags=nodocs hostname
RUN dnf install -y --setopt=tsflags=nodocs sudo
# php mysql driver module
RUN dnf install -y --setopt=tsflags=nodocs php-mysqlnd
# RUN dnf clean all
RUN truncate -s 0 /etc/my.cnf.d/auth_gssapi.cnf
# on requirements on mariadb passwords
RUN truncate -s 0 /etc/my.cnf.d/cracklib_password_check.cnf
EXPOSE 3306
EXPOSE 80
ADD fs /
RUN chmod a+x /root/start.sh
CMD /root/start.sh
RUN echo cmd done