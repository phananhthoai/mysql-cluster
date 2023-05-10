#!/usr/bin/env bash
set -ex

if [ $(id -u) != 0 ]; then
  sudo ${0}
  exit 0
fi

IP_MASTER=${IP_MASTER:-}
MYSQL_ROOT_PASSWORD=${MYSQL_ROOT_PASSWORD:-root}
NAME_NET=$(ip route list | grep 'default' | grep -Eo 'dev [a-z0-9]+' | awk '{print $2}')
ENDIP=$(ip addr show $NAME_NET | grep 'inet ' | sed -E 's/\s+inet ([0-9.]+)\/[0-9]+ .*/\1/g' | head -n 1 | sed -E 's/^([0-9].+)([{.}])([0-9]+)$/\3/g')
MYSQL_SLAVE_PASSWORD=${MYSQL_SLAVE_PASSWORD:-slave}

# Input IP master change "dig +short master"
if [ -z $IP_MASTER ]; then
  IP_MASTER=$(dig +short master)
fi

# If use docker run mysql no need use service mysql start
service mysql start

while :; 
do
  if nc -z localhost 3306
  then
    break
  else
    sleep 3
  fi
done


while :; 
do
  if nc -z ${IP_MASTER} 3306
  then
    break
  else
    sleep 1
  fi
done

#echo "CHANGE MASTER TO MASTER_HOST=\"$IP_MASTER\",MASTER_USER=\"slave\", MASTER_PASSWORD=\"$MYSQL_SLAVE_PASSWORD\"" | mysql
printf 'CHANGE MASTER TO MASTER_HOST="%s",MASTER_USER="%s", MASTER_PASSWORD="%s"' ${IP_MASTER} slave ${MYSQL_SLAVE_PASSWORD} | mysql
sed -i -E "s/^#server-id += [0-9]$/server-id          =$ENDIP/g" /etc/mysql/mariadb.conf.d/50-server.cnf

echo "CREATE USER root@\"%\" IDENTIFIED BY \"$MYSQL_ROOT_PASSWORD\"" | mysql
echo "GRANT ALL PRIVILEGES ON *.* TO \"root\"@\"%\"" | mysql;
echo "FLUSH PRIVILEGES;" | mysql
service mysql restart

echo "START SLAVE" | mysql
echo "SHOW SLAVE STATUS\G" | mysql
