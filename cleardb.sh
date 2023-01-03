#!/usr/bin/env bash

sudo apt purge mariadb* -y
sudo apt autoremove --purge -y
sudo rm -rf /etc/mysql/ /var/run/mysqld
sudo rm -rf /etc/lib/mysql
