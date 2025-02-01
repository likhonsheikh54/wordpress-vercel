#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to log messages
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Function to log errors
error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" >&2
}

# Function to log warnings
warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Check if required commands are available
for cmd in wget unzip jq curl; do
    if ! command -v $cmd &> /dev/null; then
        error "$cmd could not be found. Please install it and try again."
        exit 1
    fi
done

# Check if Vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    error "Vercel CLI is not installed. Please install it using 'npm install -g vercel' and try again."
    exit 1
fi

# Set variables
WP_VERSION=$(curl -s https://api.wordpress.org/core/version-check/1.7/ | jq -r '.offers[0].version')
WP_DOWNLOAD_URL="https://wordpress.org/wordpress-${WP_VERSION}.zip"
PROJECT_DIR="wordpress-vercel"

# Create project directory
log "Creating project directory: $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Download and extract WordPress
log "Downloading WordPress ${WP_VERSION}"
wget "$WP_DOWNLOAD_URL" -O wordpress.zip
unzip wordpress.zip
mv wordpress/* .
rm -rf wordpress wordpress.zip

# Create necessary directories
mkdir -p api public

# Move WordPress files to public directory
log "Setting up file structure for Vercel"
mv wp-admin wp-includes wp-content public/

# Configure wp-config.php
log "Configuring wp-config.php"
mv wp-config-sample.php api/wp-config.php
sed -i "s/define( 'DB_NAME', '.*' );/define( 'DB_NAME', getenv('MYSQL_DATABASE') );/" api/wp-config.php
sed -i "s/define( 'DB_USER', '.*' );/define( 'DB_USER', getenv('MYSQL_USER') );/" api/wp-config.php
sed -i "s/define( 'DB_PASSWORD', '.*' );/define( 'DB_PASSWORD', getenv('MYSQL_PASSWORD') );/" api/wp-config.php
sed -i "s/define( 'DB_HOST', '.*' );/define( 'DB_HOST', getenv('MYSQL_HOST') );/" api/wp-config.php

# Add additional configurations
cat << EOF >> api/wp-config.php

define('WP_HOME', 'https://' . \$_SERVER['HTTP_HOST']);
define('WP_SITEURL', 'https://' . \$_SERVER['HTTP_HOST']);
define('FORCE_SSL_ADMIN', true);
define('AUTOMATIC_UPDATER_DISABLED', true);
define('DISABLE_WP_CRON', true);

if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    \$_SERVER['HTTPS'] = 'on';
}

if (!defined('ABSPATH')) {
    define('ABSPATH', dirname(__FILE__) . '/../public/');
}

require_once(ABSPATH . 'wp-settings.php');
EOF

# Create index.php
log "Creating index.php"
cat << EOF > api/index.php
<?php
require_once(__DIR__ . '/wp-config.php');
EOF

# Create php.ini
log "Creating php.ini"
cat << EOF > api/php.ini
opcache.memory_consumption=256
opcache.max_accelerated_files=10000
opcache.file_cache='/tmp'
opcache.file_cache_only=0
opcache.file_cache_consistency_checks=0
session.save_path='/tmp'
session.auto_start=0
EOF

# Create vercel.json
log "Creating vercel.json"
cat << EOF > vercel.json
{
  "version": 2,
  "framework": null,
  "functions": {
    "api/**/*.php": {
      "runtime": "vercel-php@0.6.0"
    }
  },
  "routes": [
    { "src": "/wp-admin/(.*)", "dest": "/public/wp-admin/\$1" },
    { "src": "/wp-content/(.*)", "dest": "/public/wp-content/\$1" },
    { "src": "/wp-includes/(.*)", "dest": "/public/wp-includes/\$1" },
    { "src": "/(.*)\\.php$", "dest": "/api/index.php" },
    { "src": "/(.*)", "dest": "/api/index.php" }
  ],
  "env": {
    "PHP_VERSION": "8.1"
  }
}
EOF

# Create .vercelignore
log "Creating .vercelignore"
cat << EOF > .vercelignore
.git
.github
.gitignore
README.md
node_modules
EOF

# Create .gitignore
log "Creating .gitignore"
cat << EOF > .gitignore
.vercel
node_modules
.env
.env.local
.DS_Store
public/wp-content/uploads/*
public/wp-content/cache/*
public/wp-content/upgrade/*
EOF

# Remove unnecessary files
log "Removing unnecessary files"
rm -rf public/wp-content/plugins/hello.php
rm -rf public/wp-content/themes/twenty*
rm -rf license.txt readme.html

# Test PHP setup
log "Testing PHP setup"
if php -l api/index.php; then
    log "PHP syntax check passed"
else
    error "PHP syntax check failed"
    exit 1
fi

# Validate JSON
log "Validating vercel.json"
if jq empty vercel.json > /dev/null 2>&1; then
    log "vercel.json is valid JSON"
else
    error "vercel.json is not valid JSON"
    exit 1
fi

# Vercel project setup and deployment
log "Setting up Vercel project"
if vercel link --yes; then
    log "Vercel project linked successfully"
else
    error "Failed to link Vercel project"
    exit 1
fi

log "Deploying to Vercel"
if vercel deploy --prod; then
    log "Deployment to Vercel completed successfully"
else
    error "Deployment to Vercel failed"
    exit 1
fi

log "WordPress setup and deployment completed successfully!"

#!/bin/bash

set -e

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Function to log messages
log() {
    echo -e "${GREEN}[$(date +'%Y-%m-%d %H:%M:%S')] $1${NC}"
}

# Function to log errors
error() {
    echo -e "${RED}[$(date +'%Y-%m-%d %H:%M:%S')] ERROR: $1${NC}" >&2
}

# Function to log warnings
warn() {
    echo -e "${YELLOW}[$(date +'%Y-%m-%d %H:%M:%S')] WARNING: $1${NC}"
}

# Check if required commands are available
for cmd in wget unzip jq curl; do
    if ! command -v $cmd &> /dev/null; then
        error "$cmd could not be found. Please install it and try again."
        exit 1
    fi
done

# Check if Vercel CLI is installed
if ! command -v vercel &> /dev/null; then
    error "Vercel CLI is not installed. Please install it using 'npm install -g vercel' and try again."
    exit 1
fi

# Set variables
WP_VERSION=$(curl -s https://api.wordpress.org/core/version-check/1.7/ | jq -r '.offers[0].version')
WP_DOWNLOAD_URL="https://wordpress.org/wordpress-${WP_VERSION}.zip"
PROJECT_DIR="wordpress-vercel"

# Create project directory
log "Creating project directory: $PROJECT_DIR"
mkdir -p "$PROJECT_DIR"
cd "$PROJECT_DIR"

# Clean up existing directories
log "Cleaning up existing directories"
rm -rf public api

# Create necessary directories
mkdir -p api public

# Download and extract WordPress
log "Downloading WordPress ${WP_VERSION}"
wget "$WP_DOWNLOAD_URL" -O wordpress.zip
unzip wordpress.zip
mv wordpress/* .
rm -rf wordpress wordpress.zip

# Move WordPress files to public directory
log "Setting up file structure for Vercel"
mv wp-admin wp-includes wp-content public/

# Configure wp-config.php
log "Configuring wp-config.php"
mv wp-config-sample.php api/wp-config.php
sed -i "s/define( 'DB_NAME', '.*' );/define( 'DB_NAME', getenv('MYSQL_DATABASE') );/" api/wp-config.php
sed -i "s/define( 'DB_USER', '.*' );/define( 'DB_USER', getenv('MYSQL_USER') );/" api/wp-config.php
sed -i "s/define( 'DB_PASSWORD', '.*' );/define( 'DB_PASSWORD', getenv('MYSQL_PASSWORD') );/" api/wp-config.php
sed -i "s/define( 'DB_HOST', '.*' );/define( 'DB_HOST', getenv('MYSQL_HOST') );/" api/wp-config.php

# Add additional configurations
cat << EOF >> api/wp-config.php

define('WP_HOME', 'https://' . \$_SERVER['HTTP_HOST']);
define('WP_SITEURL', 'https://' . \$_SERVER['HTTP_HOST']);
define('FORCE_SSL_ADMIN', true);
define('AUTOMATIC_UPDATER_DISABLED', true);
define('DISABLE_WP_CRON', true);

if (isset(\$_SERVER['HTTP_X_FORWARDED_PROTO']) && \$_SERVER['HTTP_X_FORWARDED_PROTO'] === 'https') {
    \$_SERVER['HTTPS'] = 'on';
}

if (!defined('ABSPATH')) {
    define('ABSPATH', dirname(__FILE__) . '/../public/');
}

require_once(ABSPATH . 'wp-settings.php');
EOF

# Create index.php
log "Creating index.php"
cat << EOF > api/index.php
<?php
require_once(__DIR__ . '/wp-config.php');
EOF

# Create php.ini
log "Creating php.ini"
cat << EOF > api/php.ini
opcache.memory_consumption=256
opcache.max_accelerated_files=10000
opcache.file_cache='/tmp'
opcache.file_cache_only=0
opcache.file_cache_consistency_checks=0
session.save_path='/tmp'
session.auto_start=0
EOF

# Create vercel.json
log "Creating vercel.json"
cat << EOF > vercel.json
{
  "version": 2,
  "framework": null,
  "functions": {
    "api/**/*.php": {
      "runtime": "vercel-php@0.6.0"
    }
  },
  "routes": [
    { "src": "/wp-admin/(.*)", "dest": "/public/wp-admin/\$1" },
    { "src": "/wp-content/(.*)", "dest": "/public/wp-content/\$1" },
    { "src": "/wp-includes/(.*)", "dest": "/public/wp-includes/\$1" },
    { "src": "/(.*)\\.php$", "dest": "/api/index.php" },
    { "src": "/(.*)", "dest": "/api/index.php" }
  ],
  "env": {
    "PHP_VERSION": "8.1"
  }
}
EOF

# Create .vercelignore
log "Creating .vercelignore"
cat << EOF > .vercelignore
.git
.github
.gitignore
README.md
node_modules
EOF

# Create .gitignore
log "Creating .gitignore"
cat << EOF > .gitignore
.vercel
node_modules
.env
.env.local
.DS_Store
public/wp-content/uploads/*
public/wp-content/cache/*
public/wp-content/upgrade/*
EOF

# Remove unnecessary files
log "Removing unnecessary files"
rm -rf public/wp-content/plugins/hello.php
rm -rf public/wp-content/themes/twenty*
rm -rf license.txt readme.html

# Test PHP setup
log "Testing PHP setup"
if php -l api/index.php; then
    log "PHP syntax check passed"
else
    error "PHP syntax check failed"
    exit 1
fi

# Validate JSON
log "Validating vercel.json"
if jq empty vercel.json > /dev/null 2>&1; then
    log "vercel.json is valid JSON"
else
    error "vercel.json is not valid JSON"
    exit 1
fi

# Vercel project setup and deployment
log "Setting up Vercel project"
if vercel link --yes; then
    log "Vercel project linked successfully"
else
    error "Failed to link Vercel project"
    exit 1
fi

log "Deploying to Vercel"
if vercel deploy --prod; then
    log "Deployment to Vercel completed successfully"
else
    error "Deployment to Vercel failed"
    exit 1
fi

log "WordPress setup and deployment completed successfully!"

