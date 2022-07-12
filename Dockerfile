FROM nginx:latest
# ARG nginx_listen_port
# ARG nginx_server_name
# ARG env_info
ENV nginx_listen_port=${nginx_listen_port}
ENV nginx_server_name=${nginx_server_name}
ENV env_info=${env_info}

RUN rm -rf /etc/nginx/conf.d/*.conf
COPY custom.conf /etc/nginx/conf.d
COPY static/index.html /usr/share/nginx/html
# RUN sed -i -e "s|LISTEN_PORT|${nginx_listen_port}|g" -e "s|SERVER_NAME|${nginx_server_name}|g" /etc/nginx/conf.d/custom.conf &&\
#     sed -i -e "s|ENV_INFO|${env_info}|g" /usr/share/nginx/html/index.html
RUN cat /etc/nginx/conf.d/custom.conf
RUN cat /usr/share/nginx/html/index.html
COPY sed.sh  docker-entrypoint.d/sed.sh

