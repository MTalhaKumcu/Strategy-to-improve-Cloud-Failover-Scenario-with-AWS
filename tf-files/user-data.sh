#!/bin/bash
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install git -y
cd /home/ubuntu/
TOKEN=${user-data-git-token}
git clone https://$TOKEN@github.com/MTalhaKumcu/Strategy-to-improve-Cloud-Failover-Scenario-with-AWS.git
cd /home/ubuntu/Strategy-to-improve-Cloud-Failover-Scenario-with-AWS
sudo apt-get install python3 python3-pip python3-venv -y
sudo apt-get install python3.8-dev default-libmysqlclient-dev -y
sudo pip3 install mysqlclient
sudo pip3 install pymysql
sudo python3 -m pip install Django 
sudo python3 -m venv venv
source venv/bin/activate
sudo pip3 install -r requirements.txt
cd /home/ubuntu/Strategy-to-improve-Cloud-Failover-Scenario-with-AWS/src
sudo python3 manage.py collectstatic --noinput
sudo python3 manage.py makemigrations
sudo python3 manage.py migrate
sudo python3 manage.py runserver 0.0.0.0:80


