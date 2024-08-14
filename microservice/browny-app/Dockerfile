# Start from a Debian base image
FROM debian:latest

# Set the working directory
WORKDIR /var/www/html

# Install Apache2 and update the system
RUN apt-get update && apt-get install -y apache2

# Set the ServerName directive globally to avoid the warning
RUN echo "ServerName localhost" >> /etc/apache2/apache2.conf

# Copy your application files into the container
COPY . ./

# Expose port 80 for HTTP traffic
EXPOSE 80

# Start Apache in the foreground
CMD ["apachectl", "-D", "FOREGROUND"]
