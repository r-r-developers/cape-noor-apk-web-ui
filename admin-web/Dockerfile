FROM nginx:alpine

# Copy admin web files
COPY . /usr/share/nginx/html/

# Copy nginx configuration
COPY nginx.conf /etc/nginx/conf.d/default.conf

# Create a simple startup script that allows API URL injection
RUN echo '#!/bin/sh\n\
if [ -n "$API_BASE_URL" ]; then\n\
  sed -i "s|http://localhost:8080/api|$API_BASE_URL|g" /usr/share/nginx/html/config.js\n\
fi\n\
exec nginx -g "daemon off;"\n\
' > /docker-entrypoint.sh && chmod +x /docker-entrypoint.sh

EXPOSE 80

ENTRYPOINT ["/docker-entrypoint.sh"]
