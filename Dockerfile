FROM nginx:latest
RUN apt remove -y curl && \
    rm -rf /etc/nginx/conf.d/*.conf && \
    chown -R nginx:nginx /var/cache/nginx/ && \
    touch /var/run/nginx.pid && \
    chown nginx:nginx /var/run/nginx.pid
COPY --chown=nginx:nginx static/custom.conf /etc/nginx/conf.d
COPY --chown=nginx:nginx static/index.html /usr/share/nginx/html

USER nginx
