# 42-inception

Hive Helsinki project

☆ INFO ☆ ☆ ☆ ☆ ☆ ☆ ☆ ☆ ☆ ☆

Inception is a project about learning to use Docker and Docker Compose.
A small infrastructure with three isolated containers is implemented:

- MariaDB (database)
- php-fpm  (running WordPress)
- Nginx  (serving WordPress over HTTPS)

The goal is to build everything from scratch (no prebuilt images) and orchestrate the services with Docker Compose. 
The project is built inside a virtual machine. 

☆ KEY CONCEPTS ☆ ☆ ☆ ☆ ☆ ☆ ☆ ☆ ☆ ☆

- Containerization with Docker
- Docker Compose
- Networking between containers
- Data persistence with volumes
- TLS configuration for secure connections

☆ HOW IT WORKS ☆ ☆ ☆ ☆ ☆ ☆ ☆ ☆ ☆ ☆

- Each service runs in its own container, built from a custom Dockerfile.
- A docker-compose.yml file defines the whole infrastructure.
- Volumes ensure database and WordPress data persist across container restarts.
- Nginx is configured with TLS to serve WordPress securely.

☆ RUN THE PROJECT ☆ ☆ ☆ ☆ ☆ ☆ ☆ ☆ ☆ ☆

1. Since there's no official domain for my project, you'll have to fake one.
In the .env file, set the DOMAIN to what ever name you want.
Then in terminal, with your chosen domain name instead of yourdomain:
```
sudo echo "127.0.0.1 yourdomain" >> /etc/hosts
```
Also in .env, choose a name for you mariadb_user, mariadb_root, wp_user and wp_admin.

2. Write in one password per file in the secrets/ folder

3. Run in terminal:
```
make && make logs
```

4. When all three containers are ready (When you can count three big headers saying "[Container] setup completed"), press CTRL+C
5. The project is now up and running:)
Run the tester if you want to, with
```
chmod +x test_inception.sh
./test_inception.sh
```

To see the configured WordPress, go to a web browser and type in https://yourdomain (yourdomain is of course the name you chose for Domain in the .env file).
You can log in to WordPress with either your wp_user and it's wp_user_password you set, or with wp_admin and wp_admin_password
