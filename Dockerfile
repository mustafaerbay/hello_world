#specific nginx version prefered
FROM nginx:1.25.3
RUN apt-get update && apt-get upgrade -y && apt-get clean
RUN apt-get remove curl -y && \
    rm -rf /etc/nginx/conf.d/*.conf && \
    chown -R nginx:nginx /var/cache/nginx/ && \
    touch /var/run/nginx.pid && \
    chown nginx:nginx /var/run/nginx.pid
COPY --chown=nginx:nginx static/custom.conf /etc/nginx/conf.d
COPY --chown=nginx:nginx static/index.html /usr/share/nginx/html

USER nginx
