FROM alpine:latest

# Install Apache, PHP, Composer, and dependencies
RUN apk update && apk add --no-cache \
    apache2 \
    apache2-proxy \
    php83 \
    php83-fpm \
    php83-fileinfo \
    php83-gd \
    php83-opcache \
    php83-zip \
    php83-bcmath \
    php83-exif \
    php83-ftp \
    php83-iconv \
    php83-dom \
    php83-cli \
    php83-mysqli \
    php83-pdo \
    php83-pdo_mysql \
    php83-mbstring \
    php83-session \
    php83-tokenizer \
    php83-xml \
    php83-xmlwriter \
    php83-curl \
    php83-openssl \
    php83-phar \
    php83-ctype \
    php83-json \
    mysql-client \
    curl \
    unzip \
    git \
    composer \
    supervisor

# Enable Apache + PHP integration
RUN echo "LoadModule proxy_module modules/mod_proxy.so" >> /etc/apache2/httpd.conf \
    echo "LoadModule proxy_fcgi_module modules/mod_proxy_fcgi.so" >> /etc/apache2/httpd.conf && \
    echo "LoadModule rewrite_module modules/mod_rewrite.so" >> /etc/apache2/httpd.conf && \
    && echo "<FilesMatch \\.php\$>" >> /etc/apache2/httpd.conf \
    && echo "    SetHandler \"proxy:fcgi://127.0.0.1:9000\"" >> /etc/apache2/httpd.conf \
    && echo "</FilesMatch>" >> /etc/apache2/httpd.conf \
    mkdir -p /run/apache2 && chown apache:apache /run/apache2

# Set other essential Apache configurations
RUN echo "ServerName localhost" >> /etc/apache2/httpd.conf && \
    echo "DocumentRoot \"/var/www/html/public\"" >> /etc/apache2/httpd.conf && \
    echo "DirectoryIndex index.php index.html" >> /etc/apache2/httpd.conf

RUN echo '<Directory "/var/www/html/public">' >> /etc/apache2/httpd.conf \
    && echo '    Options Indexes FollowSymLinks' >> /etc/apache2/httpd.conf \
    && echo '    AllowOverride All' >> /etc/apache2/httpd.conf \
    && echo '    Require all granted' >> /etc/apache2/httpd.conf \
    && echo '</Directory>' >> /etc/apache2/httpd.conf

# Working directory → project root (mounted volume)
WORKDIR /var/www/html

# Install Laravel (latest)
RUN composer create-project laravel/laravel laravel-app

# Set Apache DocumentRoot to Laravel public directory
RUN sed -i 's#DocumentRoot ".*"#DocumentRoot "/var/www/html/public"#' /etc/apache2/httpd.conf

# Expose port
EXPOSE 80

# Copy configs + entrypoint
COPY supervisord.conf /etc/supervisord.conf
COPY entrypoint.sh /entrypoint.sh
RUN chmod +x /entrypoint.sh

ENTRYPOINT ["/entrypoint.sh"]
