FROM debian:latest

# Install SSH server and other utilities
RUN apt-get update && \
    apt-get install -y openssh-server sudo nano nginx php-fpm supervisor bash-completion net-tools iproute2 && \
    rm -rf /var/lib/apt/lists/*

# Create a non-root user
RUN useradd -ms /bin/bash myuser
RUN echo "myuser:password" | chpasswd
RUN usermod -aG sudo myuser

# SSH configuration
RUN mkdir /var/run/sshd
RUN sed -i 's/#PermitRootLogin prohibit-password/PermitRootLogin no/' /etc/ssh/sshd_config
RUN sed -i 's/#PasswordAuthentication yes/PasswordAuthentication yes/' /etc/ssh/sshd_config
#Optional: Disable StrictHostKeyChecking (Not recommended for production)
#RUN sed -i 's/#StrictHostKeyChecking ask/StrictHostKeyChecking no/' /etc/ssh/ssh_config

# SSH port (using ARG for flexibility during build)
ARG SSH_PORT=2222
RUN sed -i "s/#Port 22/Port ${SSH_PORT}/g" /etc/ssh/sshd_config

# Expose the SSH port
EXPOSE ${SSH_PORT}

# Change the settings of nginx
RUN sed -i 's/index index.html/index index.html index.php/' /etc/nginx/sites-available/default
RUN sed -i '/server_name _;/a\
\  \n\
\tlocation ~ \.php$ {\n\
\t\tinclude snippets/fastcgi-php.conf;\n\
\t\tfastcgi_pass unix:/run/php/php8.2-fpm.sock;\n\
\t}' /etc/nginx/sites-available/default

COPY index.php /var/www/html
COPY index.html /var/www/html
COPY supervisord.conf /etc/supervisor/conf.d/supervisord.conf



# Copy SSH keys (Highly recommended for production)
#COPY id_rsa.pub /home/myuser/.ssh/authorized_keys
#RUN chown myuser:myuser /home/myuser/.ssh/authorized_keys
#RUN chmod 600 /home/myuser/.ssh/authorized_keys

# Start SSH service
CMD ["/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]
