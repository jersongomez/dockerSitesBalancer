FROM 	centos:6.6
MAINTAINER Site Decameron <jerson.gomez@decameron.com> <fabian.acero@decameron.com>

# Install packages
RUN 	yum install -y postgresql-server
RUN 	yum install -y mysql-server tar

# Remove pre-install database
RUN rm -rf /var/lib/mysql/*

# Add MYSQL configuration
RUN mkdir -p /etc/mysql/conf.d
RUN echo -e '\n!includedir /etc/mysql/conf.d'
ADD ./persistence/scripts/my.cnf /etc/mysql/conf.d/my.conf
ADD ./persistence/scripts/mysqld_charset.cnf /etc/mysql/conf.d/mysqld_charset.cnf

# Add MySQL scripts
ADD ./persistence/scripts/mysql-user-creation.sh /tmp/mysql-user-creation.sh
RUN chmod 755 /tmp/*.sh

# Expose ENV
ENV		MYSQL_USER admin
ENV		MYSQL_PASS D3c4m3r0n

# Add VOLUMEs to allow backup of config and databases
VOLUME ["/etc/mysql","/var/lib/mysql"]

# CONFIGURACION DE MYSQL
RUN		service mysqld start && chkconfig mysqld on
RUN 	sh /tmp/mysql-user-creation.sh


