sed -i -e "s|LISTEN_PORT|${nginx_listen_port}|g" -e "s|SERVER_NAME|${nginx_server_name}|g" /etc/nginx/conf.d/custom.conf &&\
sed -i -e "s|ENV_INFO|${env_info}|g" /usr/share/nginx/html/index.html