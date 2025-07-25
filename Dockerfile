FROM php:8.3-fpm

# Instalar dependências do sistema
RUN apt-get update && apt-get install -y \
    git \
    curl \
    libpng-dev \
    libjpeg-dev \
    libwebp-dev \
    libfreetype6-dev \
    libonig-dev \
    libxml2-dev \
    libicu-dev \
    zip \
    unzip \
    libzip-dev \
    nginx \
    supervisor \
    && apt-get clean && rm -rf /var/lib/apt/lists/*

# Configurar e instalar extensões PHP
RUN docker-php-ext-configure gd --with-freetype --with-jpeg \
  && docker-php-ext-install -j$(nproc) pdo_mysql mbstring exif pcntl bcmath gd sockets zip intl

# Instalar Composer
COPY --from=composer:latest /usr/bin/composer /usr/local/bin/composer

# Definir diretório de trabalho
WORKDIR /var/www/html

# Copiar arquivos do projeto (agora o composer.json existe!)
COPY . .

# Instalar dependências do Composer
RUN composer install --optimize-autoloader --no-dev --no-interaction

# Configurar permissões (estas ainda são úteis para o build da imagem, mas serão sobrescritas pelo volume)
RUN chown -R www-data:www-data /var/www/html \
    && chmod -R 755 /var/www/html \
    && chmod -R 775 storage bootstrap/cache

# Copiar configurações
COPY docker/nginx/default.conf /etc/nginx/sites-available/default
COPY docker/supervisor/supervisord.conf /etc/supervisor/conf.d/supervisord.conf

# Adicionar o entrypoint.sh e torná-lo executável
# ASSUMindo que entrypoint.sh está em docker/app/
COPY docker/app/entrypoint.sh /usr/local/bin/docker-entrypoint.sh
RUN chmod +x /usr/local/bin/docker-entrypoint.sh

EXPOSE 80

# Mudar o CMD para usar o nosso entrypoint.sh
CMD ["/usr/local/bin/docker-entrypoint.sh", "/usr/bin/supervisord", "-c", "/etc/supervisor/conf.d/supervisord.conf"]