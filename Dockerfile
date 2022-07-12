FROM nginx:latest
RUN rm -rf /etc/nginx/conf.d/*.conf
COPY static/custom.conf /etc/nginx/conf.d
COPY static/index.html /usr/share/nginx/html
