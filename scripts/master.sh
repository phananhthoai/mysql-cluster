#!/usr/bin/env bash
set -ex
IP_MASTER=${IP_MASTER:-}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-root}
MYSQL_SLAVE_PASSWORD=${MYSQL_SLAVE_PASSWORD:-slave}
NAME_NET=$(ip route list | grep 'default' | grep -Eo 'dev [a-z0-9]+' | awk '{print $2}')
ENDIP=$(ip addr show $NAME_NET | grep 'inet ' | sed -E 's/\s+inet ([0-9.]+)\/[0-9]+ .*/\1/g' | head -n 1 | sed -E 's/^([0-9].+)([{.}])([0-9]+)$/\3/g')
# If use docker run mysql no need use service mysql start
sudo service mysql start

while :; 
do
  if nc -z localhost 3306
  then
    break
  else
    sleep 1
  fi
done

echo "CREATE USER root@\"%\" IDENTIFIED BY \"$MYSQL_ROOT_PASSWORD\"" | sudo mysql

if [ -z $(echo 'select Host from mysql.user where User="slave"' | sudo mysql) ]; then
  echo "CREATE USER \"slave\"@\"%\" IDENTIFIED BY \"$MYSQL_SLAVE_PASSWORD\"" | sudo mysql
  echo "GRANT REPLICATION SLAVE ON *.* TO \"slave\"@\"%\"" | sudo mysql
  echo "FLUSH PRIVILEGES;" | sudo mysql
fi

sudo sed -i -E "s/^#server-id += [0-9]$/server-id           =$ENDIP/g" /etc/mysql/mariadb.conf.d/50-server.cnf

sudo service mysql restart
