#!/bin/bash

dnf update -y

dnf install -y docker nfs-utils

systemctl enable --now docker

usermod -aG docker ec2-user

curl -SL https://github.com/docker/compose/releases/download/v2.37.0/docker-compose-linux-x86_64 -o /usr/local/bin/docker-compose
chmod +x /usr/local/bin/docker-compose
ln -s /usr/local/bin/docker-compose /usr/bin/docker-compose


mkdir -p /mnt/efs
echo "fs-0b380031a609d0fd1.efs.us-east-1.amazonaws.com:/ /mnt/efs nfs4 defaults,_netdev 0 0" >> /etc/fstab
mount -a


cat <<EOF > /mnt/efs/docker-compose.yml
version: "3.9"
services:
  wordpress:
    image: wordpress:latest
    ports:
      - 80:80
    restart: always
    environment:
      WORDPRESS_DB_HOST: Endpoint do RDS
      WORDPRESS_DB_USER: Usuário
      WORDPRESS_DB_PASSWORD: senha
      WORDPRESS_DB_NAME: Nome do banco
    volumes:
      - /mnt/efs/wordpress:/var/www/html
EOF

cat <<EOF > /etc/systemd/system/wordpress.service
[Unit]
Description=WordPress Docker Compose Service
Requires=docker.service
After=docker.service

[Service]
Type=oneshot
WorkingDirectory=/mnt/efs
ExecStart=/usr/bin/docker-compose up -d
ExecStop=/usr/bin/docker-compose down
RemainAfterExit=yes

[Install]
WantedBy=multi-user.target
EOF

systemctl daemon-reload
systemctl enable --now wordpress.service
