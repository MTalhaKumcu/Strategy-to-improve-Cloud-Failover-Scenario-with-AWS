#!/bin/bash
apt-get update -y
apt-get install git -y
apt-get install python3 -y
cd /home/ubuntu/
TOKEN=${user-data-git-token}
git clone https://$TOKEN@github.com/MTalhaKumcu/Strategy-to-improve-Cloud-Failover-Scenario-with-AWS.git
cd /home/ubuntu/blog_page_app
apt-get install python3.8-dev libmysqlclient-dev -y
pip3 install -r requirements.txt
cd /home/ubuntu/blog_page_app/src/cblog
sed -i "s/'database_name'/'${rds_db_name}'/g" settings.py
sed -i "s/'user_name'/'${db_username}'/g" settings.py
sed -i "s/'database_endpoint'/'${db_endpoint}'/g" settings.py
sed -i "s/'bucket_id'/'${content_bucket_name}'/g" settings.py
sed -i "s/'bucket_region'/'${content_bucket_region}'/g" settings.py
cd /home/ubuntu/blog_page_app/src
sed -i "s/'your DB password without any quotes'/'${db_password}'/g" .env
python3 manage.py collectstatic --noinput
python3 manage.py makemigrations
python3 manage.py migrate
python3 manage.py runserver 0.0.0.0:80