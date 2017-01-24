FROM 	centos:6.6

# Install packages
#RUN 	yum install -y postgresql-server
RUN 	yum install -y mysql-server tar

# Map databases directory
RUN mkdir -p /var/databases
COPY ./persistence/databases /var/databases

# Remove pre-install database
#RUN rm -rf /var/lib/mysql/*

# Add MYSQL configuration
#RUN mkdir -p /etc/mysql/conf.d
#RUN echo -e '\n!includedir /etc/mysql/conf.d'
#ADD ./persistence/scripts/my.cnf /etc/mysql/conf.d/my.conf
#ADD ./persistence/scripts/mysqld_charset.cnf /etc/mysql/conf.d/mysqld_charset.cnf

# Add MySQL scripts
#ADD ./persistence/scripts/mysql-user-creation.sh /mysql-user-creation.sh
#RUN chmod 755 /*.sh

# Expose ENV
#ENV		MYSQL_USER admin
#ENV		MYSQL_PASS D3c4m3r0n

# Add VOLUMEs to allow backup of config and databases
#VOLUME ["/etc/mysql","/var/lib/mysql"]

#EXPOSE 3306
#ENTRYPOINT ["/mysql-user-creation.sh"]
# mysql -uroot -e "CREATE USER 'fabian.acero'@localhost IDENTIFIED BY 'fabian.acero'";
# mysql -uroot -e "CREATE USER 'fabian.acero'@'%' IDENTIFIED BY 'fabian.acero'"
# mysql -uroot -e "GRANT ALL PRIVILEGES ON *.* TO 'fabian.acero'@'%' WITH GRANT OPTION"
# mysql -uroot -e "FLUSH PRIVILEGES"
CMD ["/bin/bash"]