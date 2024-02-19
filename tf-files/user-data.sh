#!/bin/bash
sudo apt-get update -y
sudo apt-get upgrade -y
sudo apt-get install git -y
sudo apt-get install python3 python3-pip python3-venv -y
sudo apt-get install python3.8-dev default-libmysqlclient-dev -y
cd /home/ubuntu/
TOKEN=${user-data-git-token}
git clone https://$TOKEN@github.com/MTalhaKumcu/awsproje2.git
python3 -m venv venv
source venv/bin/activate
cd /home/ubuntu/awsproje2
#cd /home/ubuntu/Strategy-to-improve-Cloud-Failover-Scenario-with-AWS
sudo pip3 install -r requirements.txt
cd /home/ubuntu/awsproje2/src
#python3 -m pip install Django
#fatih hoca
sed -i "s/'database_name'/'${rds_db_name}'/g" settings.py
sed -i "s/'user_name'/'${db_username}'/g" settings.py
sed -i "s/'database_endpoint'/'${db_endpoint}'/g" settings.py
sed -i "s/'bucket_id'/'${content_bucket_name}'/g" settings.py
sed -i "s/'bucket_region'/'${content_bucket_region}'/g" settings.py
cd /home/ubuntu/awsproje2/src
sed -i "s/'your DB password without any quotes'/'${db_password}'/g" .env
python3 manage.py collectstatic --noinput
python3 manage.py makemigrations
python3 manage.py migrate
python3 manage.py runserver 0.0.0.0:80


