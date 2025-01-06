sudo apt install docker.io -y

usermod -aG docker $user
 
docker run -d -p 8022:2222 -p 8080:80 lidashen/debian-php
