#!/bin/bash
sudo apt update
sudo apt install -y nginx
sudo systemctl start nginx
sudo systemctl enable nginx
echo "<html lang="en">
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0">
    <title>Nginx Hoş Geldiniz</title>
</head>
<body>
    <header>
        <h1>Welcome!</h1>
    </header>
    
    <section>
        <p>Nginx Web Server</p>
    </section>

    <footer>
        <p>Thank you!</p>
    </footer>
</body>
</html>" | sudo tee /var/www/html/index.html
