#!/bin/bash

WEBROOT="/var/www"

USAGE="\nUsage: $(basename -- "$0") [COMMAND] domain.tld\n\nCommands:\n\n\tadd\n\tremove\n"

if [ "$(whoami)" != "root" ]; then

    echo ERROR: Insufficient permissions to use this command.

else

	if [ ! -z "$1" ] && [ ! -z "$2" ]; then
		if [ $1 == "add" ]; then
			echo "Adding $2..."

            sudo bash -c "cat << 'EOF' > /etc/nginx/conf.d/$2.conf
server {
    listen       80;
    server_name  $2 www.$2;

    location / {
        root   $WEBROOT/$2;
        index  index.php index.html index.htm;
    }

  location ~ \.php$ {
    fastcgi_index index.php;
    fastcgi_keep_conn on;
    include /etc/nginx/fastcgi_params;
    fastcgi_pass unix:/run/php/php7.2-fpm.sock;
    fastcgi_param SCRIPT_FILENAME $WEBROOT/$2\$fastcgi_script_name;
  }
}

EOF"
            sudo mkdir -p $WEBROOT/$2            

			sudo bash -c "cat << 'EOF' > $WEBROOT/$2/info.php
<?php phpinfo(); ?>
EOF"


			sudo bash -c "cat << 'EOF' > $WEBROOT/$2/index.php
<!DOCTYPE html>
<html>
<head>
<title><?php echo \$_SERVER['HTTP_HOST']; ?></title>
<link href='//fonts.googleapis.com/css?family=Open+Sans' rel='stylesheet' type='text/css'>
<style>
    body {
        font-family: 'Open Sans', sans-serif;
        background: #fff;
        color: #000;
    }
    html,body {
        height: 100%;
    }
    body {
        display: table; 
        margin: 0 auto;
    }
    .container {  
        height: 100%;
        display: table-cell;   
        vertical-align: middle;    
    }
    .cent {
         height: 50px;
        width: 100%;
        background-color: none;      
     }
</style>
</head>
<body>
<div class="container">
    <div class="cent"><h1><?php echo \$_SERVER['HTTP_HOST']; ?></h1></div>
</div>
</body>
</html>
EOF"

   			sudo chown -R www-data:sudo $WEBROOT/$2
			sudo chmod -R 775 $WEBROOT/$2
            sudo chmod -R g+s $WEBROOT/$2
            sudo chmod -R o-rwx $WEBROOT/$2
            sudo chmod -R 775 $WEBROOT/$2
			
            sudo systemctl restart nginx
            
            if [[ ${2} != *".local"* ]];then
               # DO CERBOT STUFF               
            else
                sudo bash -c "cat << 'EOF' >> /etc/hosts
127.0.0.1 $2
127.0.0.1 www.$2

EOF"
            fi              
 		fi 
		if [ $1 == "remove" ]; then
			echo "Removing $2..."
			sudo rm /etc/nginx/conf.d/$2.conf
			sudo rm -R $WEBROOT/$2
            sudo systemctl restart nginx
		fi 
	else
		printf "USAGE: \n $(basename $0) add domain.tld \n $(basename $0) remove domain.tld \n"      
	fi	
fi
