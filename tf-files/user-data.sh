#!/bin/bash
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install git -y
cd /home/ubuntu/
TOKEN=${user-data-git-token}
git clone https://$TOKEN@github.com/MTalhaKumcu/awsproje2.git
cd /home/ubuntu/awsproje2
sudo python3 -m pip install Django
sudo apt-get install python3 python3-pip python3-venv -y
sudo apt-get install python3.10-dev default-libmysqlclient-dev -y
sudo python3 -m venv venv
source venv/bin/activate
#cd /home/ubuntu/awsproje2
#cd /home/ubuntu/Strategy-to-improve-Cloud-Failover-Scenario-with-AWS
sudo pip3 install -r requirements.txt
cd /home/ubuntu/awsproje2/src
sudo python3 -m pip install Django
#fatih hoca
#sudo sed -i "s/'database_name'/'${rds_db_name}'/g" settings.py
#sudo sed -i "s/'user_name'/'${db_username}'/g" settings.py
#sudo sed -i "s/'database_endpoint'/'${db_endpoint}'/g" settings.py
#sudo sed -i "s/'bucket_id'/'${content_bucket_name}'/g" settings.py
#sudo sed -i "s/'bucket_region'/'${content_bucket_region}'/g" settings.py
cd /home/ubuntu/awsproje2/src
#sed -i "s/'your DB password without any quotes'/'${db_password}'/g" .env
sudo python3 manage.py collectstatic --noinput
sudo python3 manage.py makemigrations
sudo python3 manage.py migrate
sudo python3 manage.py runserver 0.0.0.0:80


