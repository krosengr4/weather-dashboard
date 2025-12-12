FROM nginx:alpine

COPY index.html
copy Assets/

EXPOSE 80
