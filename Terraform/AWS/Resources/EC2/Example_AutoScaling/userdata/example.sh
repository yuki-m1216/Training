#! /bin/bash
sudo yum update
sudo yum install -y httpd
sudo systemctl enable httpd
sudo systemctl start httpd
echo "<h1>hello world</h1>" | sudo tee /var/www/html/index.html
