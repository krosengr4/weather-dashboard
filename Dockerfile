# Use nginx alpine for a ligIhtweight image
# Note: Using amd64 image - for Pi deployment, we'll build ARM64 version
FROM nginx:alpine

# Copy static files to nginx html directory
COPY  index.html /usr/share/nginx/html/
COPY  Assets/ /usr/share/nginx/html/Assets/

# Expose port 80
EXPOSE 80

# nginx runs automatically as the default command
