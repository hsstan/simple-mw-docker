# nginx on debian (bookworm-slim ATM)
FROM nginx:1.27.0

LABEL maintainer="hsstan"
LABEL org.opencontainers.image.source=https://github.com/hsstan/simple-mw-docker

#######################
# ENVIRONNEMENT SETUP #
#######################

# Database config
ENV DATABASE_NAME=my_wiki \
    DATABASE_TYPE=sqlite \
# Directories locations
    HTML_DIR=/var/www/html \
    DATA_DIR=/var/www/data \
# Files config
    MEDIAWIKI_CONFIG_FILE_CUSTOM=./config/mediawiki/LocalSettings.custom.php \
    MEDIAWIKI_CONFIG_FILE_BASE=./config/mediawiki/LocalSettings.php \
    NGINX_CONFIG_FILE_BASE=./config/nginx/nginx.conf \
    NGINX_CONFIG_FILE_CUSTOM=./config/nginx/default.conf \
# Media Wiki default admin password
    MEDIAWIKI_ADMIN_PASSWORD=mediawikipass \
# Media Wiki Version
    MEDIAWIKI_MAJOR_VERSION=1.42 \
    MEDIAWIKI_VERSION=1.42.1 \
    MEDIAWIKI_EXT_VERSION=REL1_42 \
# Php Version
    PHP_VERSION=8.2 \
# Debian warning message suppression
    DEBIAN_FRONTEND=noninteractive

#Keep it separated because it depends on other env variables
ENV WIKI_DIR=${HTML_DIR}/w

# Create directory for web site files and data files
RUN mkdir -p ${WIKI_DIR} && mkdir -p ${DATA_DIR}

# Volumes to store database and medias (images...) files
VOLUME ${DATA_DIR}

# We work in WikiMedia root directory
WORKDIR ${WIKI_DIR}

###################
# SOFTWARE SETUP  #
###################

# Requirement for next steps
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends \
    # Manages certificates
    ca-certificates \
    # web fetch and transfer data
    curl \
    # file encription
    gnupg \  
    && \
    # Cleanup
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# Requirement for mediawiki
RUN DEBIAN_FRONTEND=noninteractive apt-get update && apt-get install -y --no-install-recommends \
    # to work with HTTPASSWORD environ
    apache2-utils \
    # job scheduler
    cron \
    # image thumbnailing (or you can use inkscape)
    imagemagick \
    # render Scalable Vector Graphics
    librsvg2-bin \
    # to generate locales
    locales \
    # needed for scribunto ( not supported binary different from 5.1) 
    lua5.1 \
    mariadb-server \
    # memory caching (for performance)
    memcached \
    # PHP with needed extensions
      # for improved performance
      php${PHP_VERSION}-apcu \
      # Required by some extensions such as Extension:Math 
      php${PHP_VERSION}-curl \
      # Fast CGI process Manager
      php${PHP_VERSION}-fpm \
      # Unicode normalization
      php${PHP_VERSION}-intl \
      # image manipulation
      php${PHP_VERSION}-gd \
      # mysql - mariadb interaction
      php${PHP_VERSION}-mysql \
      # multibyte string handler
      php${PHP_VERSION}-mbstring \
      # sqlite interaction (PDO for sqlite)
      php${PHP_VERSION}-sqlite3 \
      # xmla handler
      php${PHP_VERSION}-xml \
    # Required for SyntaxHighlighting
    python3 \
    sqlite3 \
    # libapache2-mod-php
    && \
    apt-get clean && \
    rm -rf /var/lib/apt/lists/*

# generate link to avoid edit default.conf and www.conf on php upgrade
RUN ln -s /run/php/php${PHP_VERSION}-fpm.sock /run/php/php-fpm.sock

# generate locale (set locale is used by MediaWiki scripts)
RUN sed -i '/en_US.UTF-8/s/^# //g' /etc/locale.gen && locale-gen

ENV LANG=en_US.UTF-8 \
    LANGUAGE=en_US:en \
    LC_ALL=en_US.UTF-8

###################
# MEDIAWIKI SETUP #
###################

RUN curl -fSL "https://releases.wikimedia.org/mediawiki/${MEDIAWIKI_MAJOR_VERSION}/mediawiki-${MEDIAWIKI_VERSION}.tar.gz" -o mediawiki.tar.gz \
	&& tar -xz --strip-components=1 -f mediawiki.tar.gz \
	&& rm mediawiki.tar.gz \
	&& chown -R www-data:www-data skins cache

##########################
# FINALIZE CONFIGURATION #
##########################

# Nginx configuration
COPY config/nginx/nginx.conf /etc/nginx/nginx.conf
COPY config/nginx/default.conf /etc/nginx/conf.d/default.conf

# Configure PHP-fpm
COPY config/php-fpm/*.conf /etc/php/${PHP_VERSION}/fpm/pool.d/
COPY config/php-fpm/*.ini /etc/php/${PHP_VERSION}/fpm/conf.d/

# Configure Mediawiki - to do later
COPY ${MEDIAWIKI_CONFIG_FILE_BASE} ./LocalSettings.php
COPY ${MEDIAWIKI_CONFIG_FILE_CUSTOM} ./LocalSettings.custom.php

# Few default images
COPY ./assets/images/* ${HTML_DIR}/

# The files uploaded are in the data volume
RUN  mv ./images ./images.origin && ln -s /var/www/data/images ./images

# allow remote connections (to backup for instance)
RUN sed -i "s/bind-address            = 127.0.0.1/bind-address            = 0.0.0.0/" \
    /etc/mysql/mariadb.conf.d/50-server.cnf 

###########
# START ! #
###########

# Copy scripts file
COPY ./init/handle-htpassword-opt.sh \
     ./init/start.sh \
     ./init/mediawiki-init.sh \ 
     ./init/dump_for_mysql.py \
     # to
     /usr/local/bin/

RUN chmod a+x /usr/local/bin/*.sh

ENTRYPOINT ["start.sh"]
CMD ["nginx", "-g", "daemon off;"]