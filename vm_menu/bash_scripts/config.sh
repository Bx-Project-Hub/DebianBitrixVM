#!/bin/bash
# shellcheck disable=SC2034
#
# Настройки меню Debian BitrixVM.
# Значения по умолчанию рассчитаны на Debian 13 (trixie).
# При необходимости любую настройку можно изменить в этом файле.

# General settings
BS_VERSION_MENU="2.8.4"
BS_PATH_SITES="/var/www/html"
# Путь к установленному меню (используется для перезапуска после обновления)
BS_PATH_MENU_FILE="/root/vm_menu/menu.sh"
BS_DEFAULT_SITE_NAME="bx-site"
BS_PATH_DEFAULT_SITE="$BS_PATH_SITES/$BS_DEFAULT_SITE_NAME"
BS_USER_SERVER_SITES="www-data"
BS_GROUP_USER_SERVER_SITES="www-data"
BS_PERMISSIONS_SITES_DIRS="0775"
BS_PERMISSIONS_SITES_FILES="0664"

# Поддерживаемые версии Debian (основная цель — Debian 13 / trixie)
BS_SUPPORTED_OS_VERSIONS=("12" "13")
BS_TARGET_OS_VERSION="13"
BS_TARGET_OS_CODENAME="trixie"

# Directories excluded from site management
BS_EXCLUDED_DIRS_SITES=("temp" "tmp" "test" ".ssh")

# Default site resources links
BS_SITE_LINKS_RESOURCES=("local" "bitrix" "upload" "images")

# URLs for Bitrix setup files
# Только установщик bitrixsetup.php. restore.php сюда НЕ входит: скрипт
# восстановления опасен и размещается в каталоге сайта по явному запросу
# администратора (меню → Дополнения → restore.php), после чего удаляется.
BS_DOWNLOAD_BITRIX_INSTALL_FILES_NEW_SITE=(
  "https://www.1c-bitrix.ru/download/scripts/bitrixsetup.php"
)
BS_TIMEOUT_DOWNLOAD_BITRIX_INSTALL_FILES_NEW_SITE=30

# Скрипт восстановления: официальный источник (документация 1С-Битрикс)
BS_RESTORE_SCRIPT_URL="https://www.1c-bitrix.ru/download/files/scripts/restore.php"
BS_SHOW_IP_CURRENT_SERVER_IN_MENU=true

# Язык интерфейса меню
# auto — по локали системы: ru_* → русский, любая другая (включая C/C.UTF-8) → английский.
# Можно задать жёстко: BS_MENU_LANG="ru" или BS_MENU_LANG="en";
# переопределяется переменной окружения: BS_MENU_LANG=en /root/menu.sh
BS_MENU_LANG="${BS_MENU_LANG:-auto}"

# Оформление меню (шапка)
BS_USE_COLOR=true              # false — отключить ANSI-цвета (например, при выводе в лог)
BS_STATUS_PANEL=true           # панель состояния сервера в шапке меню
BS_STATUS_PANEL_WIDTH=52       # ширина панели в символах
BS_CPU_SAMPLE_MS=200           # окно замера загрузки CPU, мс (0 — не замерять, брать только load average)
BS_STATUS_PANEL_SITES=true     # панель «Установлено»: сайты, SSL, push&pull, дополнения
BS_STATUS_MAX_SITES=5          # сколько сайтов перечислять (остальные — «и ещё N»)

# Bitrix agent configurations
BS_BX_CRON_AGENTS_PATH_FILE_AFTER_DOCUMENT_ROOT="/bitrix/modules/main/tools/cron_events.php"
BS_BX_CRON_LOGS_PATH_DIR="/var/log/bitrix_cron_agents"
BS_BX_CRON_LOGS_PATH_FILE="agents_cron.log"

# PHP configurations (VER#0.0 will be replaced with the selected version)
# PHP 8.3 — рекомендуемая версия для Bitrix на Debian 13.
# Пакеты предоставляет репозиторий deb.sury.org (для Debian 13 доступны 8.2, 8.3, 8.4).
BS_PHP_VERSION_DEFAULT="8.3"
BS_PHP_SUPPORTED_VERSIONS=("8.2" "8.3" "8.4")
BS_PHP_INSTALL_TEMPLATE=(
  "libapache2-mod-phpVER#0.0"
  "phpVER#0.0"
  "phpVER#0.0-cli"
  "phpVER#0.0-common"
  "phpVER#0.0-gd"
  "phpVER#0.0-ldap"
  "phpVER#0.0-mbstring"
  "phpVER#0.0-mysql"
  "phpVER#0.0-opcache"
  "phpVER#0.0-curl"
  "phpVER#0.0-zip"
  "phpVER#0.0-pspell"
  "phpVER#0.0-xml"
  "phpVER#0.0-apcu"
  "phpVER#0.0-imagick"
  "phpVER#0.0-maxminddb"
  "phpVER#0.0-http"
  "phpVER#0.0-dev"
  # ВАЖНО: только версионные пакеты. Метапакеты php-redis/php-igbinary/php-pear
  # на deb.sury.org тянут САМУЮ НОВУЮ ветку (сейчас 8.5) и/или legacy 7.4,
  # из-за чего в системе появляются лишние PHP и /usr/bin/php переключается на них.
  # php-geoip для PHP 8 не собирается вовсе (последний билд — 7.4).
  "phpVER#0.0-redis"
  "phpVER#0.0-igbinary"
)
BS_DOWNLOAD_BITRIX_CONFIGS="https://dev.1c-bitrix.ru/docs/chm_files/debian.zip"
# Локальная копия в vendor (приоритетнее URL)
BS_VENDOR_BITRIX_CONFIGS="files/bitrix-php-configs-debian.zip"
BS_PATH_PHP="/etc/php"
BS_PATH_PHP_LOG="/var/log/php"

# Ansible settings
# Вендорные файлы: локальные копии внешних артефактов (см. vendor/ и tools/vendor-fetch.sh)
# Каталог лежит рядом с меню и обновляется вместе с ним
BS_VENDOR_DIR="/root/vm_menu/vendor"
BS_VENDOR_RAW_BASE="https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/vendor"

BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS="-i localhost, -c local -e ansible_python_interpreter=/usr/bin/python3 -e vendor_dir=${BS_VENDOR_DIR}"
BS_PATH_ANSIBLE_PLAYBOOKS="../ansible/playbooks"

# Ansible playbooks
BS_ANSIBLE_PB_CREATE_SITE="create_site.yaml"
BS_ANSIBLE_PB_GET_LETS_ENCRYPT_CERTIFICATE="get_lets_encrypt_certificate.yaml"
BS_ANSIBLE_PB_ENABLE_OR_DISABLE_REDIRECT_HTTP_TO_HTTPS="enable_or_disable_redirect_http_to_https.yaml"
BS_ANSIBLE_PB_INSTALL_NEW_FULL_ENVIRONMENT="install_new_full_environment.yaml"
BS_ANSIBLE_PB_SETTINGS_SMTP_SITES="settings_smtp_sites.yaml"
BS_ANSIBLE_PB_INSTALL_OR_DELETE_NETDATA="install_or_delete_netdata.yaml"
BS_ANSIBLE_PB_INSTALL_OR_DELETE_SPHINX="install_or_delete_sphinx.yaml"
BS_ANSIBLE_PB_INSTALL_OR_DELETE_FILE_CONVERSION_SERVER="install_or_delete_file_conversion_server.yaml"
BS_ANSIBLE_PB_DELETE_SITE="delete_site.yaml"
BS_ANSIBLE_PB_INSTALL_OR_DELETE_POSTGRESQL="install_or_delete_postgresql.yaml"
BS_ANSIBLE_PB_MANAGE_RESTORE_SCRIPT="manage_restore_script.yaml"

# MySQL settings
# На Debian 13 (trixie) Oracle поставляет только MySQL 8.4 LTS (mysql-8.4-lts):
# ветка 8.0 в репозитории для trixie отсутствует.
BS_MYSQL_VERSION_DEFAULT="8.4"
BS_MYSQL_SERVICE_NAME="mysql"
# Каталог, который подключают все варианты my.cnf (Oracle MySQL, Percona, mariadb-common)
BS_MYSQL_CNF_DIR="/etc/mysql/conf.d"
BS_MYSQL_REPO_KEY_URLS=(
  "https://repo.mysql.com/RPM-GPG-KEY-mysql-2023"
  "https://repo.mysql.com/RPM-GPG-KEY-mysql-2025"
)

# Выбор СУБД при установке: mysql (Oracle MySQL) или percona (Percona Server for MySQL 8.4 LTS)
# Значение по умолчанию можно переопределить: DB_ENGINE=percona bash install_full_environment.sh
BS_DB_ENGINE_DEFAULT="mysql"
BS_PERCONA_SERVER_REPO="ps-84-lts"
BS_PERCONA_TELEMETRY_REPO="telemetry"
BS_PERCONA_RELEASE_DEB_URL="https://repo.percona.com/apt/percona-release_latest.generic_all.deb"
BS_PERCONA_KEYRING="/usr/share/keyrings/percona-keyring.gpg"
# Телеметрия Percona по умолчанию отключается (true/false)
BS_PERCONA_DISABLE_TELEMETRY=true

# Redis settings
BS_REDIS_SERVICE_NAME="redis-server"
BS_REDIS_SOCKET="/var/run/redis/redis.sock"

# Database settings
BS_MAX_CHAR_DB_NAME=20
BS_MAX_CHAR_DB_USER=20
BS_CHAR_DB_PASSWORD=24
BS_DB_CHARACTER_SET_SERVER="utf8mb4"
BS_DB_COLLATION="utf8mb4_0900_ai_ci"

# NGINX settings
BS_SERVICE_NGINX_NAME="nginx"
BS_PATH_NGINX="/etc/${BS_SERVICE_NGINX_NAME}"
BS_PATH_NGINX_SITES_CONF="$BS_PATH_NGINX/sites-available"
BS_PATH_NGINX_SITES_ENABLED="$BS_PATH_NGINX/sites-enabled"

# Apache settings
BS_SERVICE_APACHE_NAME="apache2"
BS_PATH_APACHE="/etc/${BS_SERVICE_APACHE_NAME}"
BS_PATH_APACHE_SITES_CONF="$BS_PATH_APACHE/sites-available"
BS_PATH_APACHE_SITES_ENABLED="$BS_PATH_APACHE/sites-enabled"

# Bitrix VM emulation settings
BS_VAR_NAME_BVM="BITRIX_VA_VER"
BS_VAR_VALUE_BVM="99.99.99"
BS_VAR_PATH_FILE_BVM="/etc/apache2/envvars"

# SMTP settings
BS_SMTP_FILE_SITES_CONFIG="${BS_PATH_SITES}/.msmtprc"
BS_SMTP_FILE_USER_CONFIG="${BS_USER_SERVER_SITES}"
BS_SMTP_FILE_GROUP_USER_CONFIG="${BS_GROUP_USER_SERVER_SITES}"
BS_SMTP_FILE_PERMISSIONS_CONFIG="0600"
BS_SMTP_FILE_USER_LOG="${BS_USER_SERVER_SITES}"
BS_SMTP_FILE_GROUP_USER_LOG="${BS_GROUP_USER_SERVER_SITES}"
BS_SMTP_PATH_WRAPP_SCRIPT_SH="/usr/local/bin/msmtp_wrapper.sh"

# Menu update settings
BS_BRANCH_UPDATE_MENU="master"
BS_REPOSITORY_URL_FILE_VERSION="https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/${BS_BRANCH_UPDATE_MENU}/vm_menu/bash_scripts/config.sh"
BS_URL_SCRIPT_UPDATE_MENU="https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/${BS_BRANCH_UPDATE_MENU}/update_menu.sh"
BS_REPOSITORY_URL="https://github.com/Bx-Project-Hub/DebianBitrixVM/"
BS_CHECK_UPDATE_MENU_MINUTES=10

# MySQL binary name
BS_MYSQL_CMD="mysql"

# Push server settings
# 0.4.0 — актуальный tgz Bitrix: без нативного better-sqlite3 (стабильно на Node.js 20 из Debian 13).
BS_PUSH_SERVER_VERSION="0.4.0"
BS_PUSH_SERVER_CONFIG="/etc/sysconfig/push-server-multi"
BS_PUSH_SERVER_SERVICE_NAME="push-server"

# PostgreSQL settings (дополнение «PostgreSQL» в меню)
# Пресет конфигурации: auto — по объёму RAM, либо 2g|4g|8g|16g|32g|64g.
BS_POSTGRES_PRESET="auto"
BS_POSTGRES_DATABASE="bitrix"
BS_POSTGRES_USER="bitrix"

# Sphinx settings
BS_SPHINX_PACKAGE="sphinxsearch"
BS_SPHINX_SERVICE_NAME="sphinxsearch"

# Настройки сервиса конвертации файлов (transformer)
BS_TRANSFORMER_CACHE_DIR="${BS_PATH_SITES}/.cache"
BS_TRANSFORMER_RABBITMQ_USER="bitrix"
