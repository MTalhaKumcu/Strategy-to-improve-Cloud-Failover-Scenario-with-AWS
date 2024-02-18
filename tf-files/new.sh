#!/bin/bash
sudo apt update
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
echo "<html><body><h1>Hello, User!</h1></body></html>" | sudo tee /var/www/html/index.html
