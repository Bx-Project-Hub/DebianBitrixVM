#!/bin/sh
#
# metadata_begin
# recipe: Bitrix Vanilla
# tags: debian11, debian12
# revision: 2
# description_ru: Рецепт установки окружения для Bitrix на Debian 11 / Debian 12 с MySQL 8
# description_en: Bitrix CMS installing recipe with MySQL 8
# metadata_end

# Использование:
# bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/custom_bitrix_setup.sh)

cat > /root/run.sh <<\END

set -x
LOG_PIPE=/tmp/log.pipe

if [[ -p "$LOG_PIPE" ]]; then
    echo "Очередь уже существует: $LOG_PIPE"
else
    echo "Создаём очередь: $LOG_PIPE"
    mkfifo "$LOG_PIPE"
fi

LOG_FILE=/root/recipe.log
touch ${LOG_FILE}
chmod 600 ${LOG_FILE}
tee < ${LOG_PIPE} ${LOG_FILE} &
exec > ${LOG_PIPE}
exec 2> ${LOG_PIPE}

###################################################################
# Функция генерации пароля (аналогичная есть в install_full_environment.sh)
###################################################################
generate_password() {
    local length=$1
    local specials='!@#$%^&*()-_=+[]|;:,.<>?/~'
    local all_chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789${specials}"

    local password=""
    for i in $(seq 1 $length); do
        local char=${all_chars:RANDOM % ${#all_chars}:1}
        password+=$char
    done

    echo $password
}

###################################################################
# Функции для установки MySQL 8.0 (интеграция install-mysql8.0.sh)
###################################################################
function InstallationFailed {
    echo "Ошибка установки MySQL! Прерывание." >&2
    exit 1
}

function Message {
    echo -e "$1"
}

function UpdateSoftwareList {
    apt-get update -qq || InstallationFailed
}

function GenerateMysqlRootPassword {
    if [ ! -f /root/.my.cnf ]; then
        echo "Генерация пароля для MySQL root..."
        MYSQL_PASSWORD=$(pwgen 16 1) || InstallationFailed
        echo -e "[client]\nuser = root\npassword = ${MYSQL_PASSWORD}\n" > /root/.my.cnf
    else
        echo "Файл /root/.my.cnf уже существует. Пропускаем генерацию MySQL root пароля."
    fi
}

function installMySQLRepository {
    # Добавляем ключ MySQL APT репозитория
    wget -q -O /etc/apt/trusted.gpg.d/RPM-GPG-KEY-mysql-2023.asc https://repo.mysql.com/RPM-GPG-KEY-mysql-2023 || InstallationFailed

    # Добавляем репозиторий
    echo "deb [arch=amd64] http://repo.mysql.com/apt/debian/ $(lsb_release -sc) mysql-8.0" > /etc/apt/sources.list.d/mysql.list
    UpdateSoftwareList
}

function SetRecommendedSettingsMySQL_8_0 {
    # Создадим директорию, если не существует
    mkdir -p /etc/mysql/mysql.conf.d

    cat <<EOF > /etc/mysql/mysql.conf.d/99-custom.cnf
[mysqld]
disable-log-bin
innodb-buffer-pool-size=128M
innodb-flush-log-at-trx-commit=2
innodb-flush-method=O_DIRECT
max-heap-table-size=32M
sql-mode=
tmp-table-size=32M
transaction-isolation=READ-COMMITTED
default-authentication-plugin=mysql_native_password
mysqlx=OFF
performance-schema=OFF

# Из Bitrix-окружения
innodb_strict_mode=off
EOF

    systemctl restart mysql.service || InstallationFailed
}

function MySQLSecureInstallation {
    mysql --defaults-file=/root/.my.cnf -e "DELETE FROM mysql.user WHERE User='';"
    
    # Проверяем, существует ли база данных 'test' перед удалением
    local DB_EXISTS
    DB_EXISTS=$(mysql --defaults-file=/root/.my.cnf -e "SHOW DATABASES LIKE 'test';" | grep -c "test")
    if [ "$DB_EXISTS" -eq 1 ]; then
        mysql --defaults-file=/root/.my.cnf -e "DROP DATABASE test;"
    fi

    mysql --defaults-file=/root/.my.cnf -e "DELETE FROM mysql.db WHERE db='test' OR db='test\_%';"
}

function installMySQL8 {
    apt-get install -y pwgen curl wget || InstallationFailed
    Message "Установка MySQL 8.0 из репозитория Oracle APT...\n"
    GenerateMysqlRootPassword

    # Настройка debconf для тихой установки
    if [ -f /root/.my.cnf ]; then
        local ROOT_PASS
        ROOT_PASS=$(awk '/password/{print $3}' /root/.my.cnf)
        echo "mysql-community-server mysql-community-server/re-root-pass password ${ROOT_PASS}" | debconf-set-selections
        echo "mysql-community-server mysql-community-server/root-pass password ${ROOT_PASS}" | debconf-set-selections
        echo "mysql-community-server mysql-server/default-auth-override select Use Legacy Authentication Method (Retain MySQL 5.x Compatibility)" | debconf-set-selections
    fi

    installMySQLRepository

    # Установка сервера MySQL
    apt-get install -qq -y mysql-server || InstallationFailed

    # Настройка
    SetRecommendedSettingsMySQL_8_0
    MySQLSecureInstallation

    echo "MySQL 8.0 успешно установлен."
}

###################################################################
# Установка пакетов ОС и LAMP/LEMP окружения
###################################################################
installPkg(){
    # Ставим пакетные зависимости, включая PHP, Apache, Nginx, etc.
    # Сначала устанавливаем MySQL 8.0
    installMySQL8

    # Теперь репозиторий sury для PHP 8.2 и т.д.
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/sury.gpg] https://ftp.mpi-inf.mpg.de/mirrors/linux/mirror/deb.sury.org/repositories/php $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/sury-php.list
    curl -s -o /etc/apt/trusted.gpg.d/sury.gpg https://ftp.mpi-inf.mpg.de/mirrors/linux/mirror/deb.sury.org/repositories/php/apt.gpg
    apt-get update -y

    export DEBIAN_FRONTEND="noninteractive"
    debconf-set-selections <<< 'exim4-config exim4/dc_eximconfig_configtype select internet site; mail is sent and received directly using SMTP'

    apt-get install -y \
        php8.2 php8.2-cli php8.2-common php8.2-gd php8.2-ldap \
        php8.2-mbstring php8.2-mysql php8.2-opcache php8.2-zip \
        php8.2-pspell php8.2-xml php-pear php8.2-apcu php8.2-curl \
        php-redis php-geoip php8.2-mcrypt php8.2-memcache \
        php8.2-dev php8.2-maxminddb php8.2-imagick php8.2-http \
        apache2 nginx nodejs npm redis exim4 exim4-config libnginx-mod-http-brotli-filter libnginx-mod-http-brotli-static
}

###################################################################
# Настройка и запуск Apache
###################################################################
dplApache(){
    mkdir -p /etc/systemd/system/apache2.service.d
    cat <<EOF > /etc/systemd/system/apache2.service.d/privtmp.conf
[Service]
PrivateTmp=false
EOF

    systemctl daemon-reload

    # Символические ссылки на общий php.ini для Bitrix
    ln -sf /etc/php/8.2/mods-available/zbx-bitrix.ini  /etc/php/8.2/apache2/conf.d/99-bitrix.ini
    ln -sf /etc/php/8.2/mods-available/zbx-bitrix.ini  /etc/php/8.2/cli/conf.d/99-bitrix.ini

    a2dismod --force autoindex
    a2enmod rewrite
    phpenmod xml

    systemctl stop apache2
    systemctl enable --now apache2
    systemctl start apache2
}

###################################################################
# Настройка и запуск Nginx
###################################################################
dplNginx(){
    grep -qxF "127.0.0.1 push httpd" /etc/hosts || echo "127.0.0.1 push httpd" >> /etc/hosts
    rm -f /etc/nginx/sites-enabled/default
    ln -s /etc/nginx/sites-available/rtc.conf /etc/nginx/sites-enabled/rtc.conf 2>/dev/null || true
    ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf 2>/dev/null || true

    systemctl stop nginx
    systemctl enable --now nginx
    systemctl start nginx
}

###################################################################
# Настройка Redis
###################################################################
dplRedis() {
    echo "pidfile /run/redis/redis-server.pid" >> /etc/redis/redis.conf || true
    echo "dir /var/lib/redis" >> /etc/redis/redis.conf || true

    # Проверяем текущее значение vm.overcommit_memory
    current_value=$(sysctl -n vm.overcommit_memory 2>/dev/null || echo 0)
    if [ "$current_value" -ne 1 ]; then
        echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf
        sysctl -w vm.overcommit_memory=1
    fi

    usermod -g www-data redis
    chown root:www-data /etc/redis/ /var/log/redis/ || true

    mkdir -p /etc/systemd/system/redis.service.d
    cat <<EOF > /etc/systemd/system/redis.service.d/custom.conf
[Service]
Group=www-data
PIDFile=/run/redis/redis-server.pid
EOF

    systemctl daemon-reload
    systemctl stop redis || systemctl stop redis-server || true
    systemctl enable --now redis || systemctl enable --now redis-server
    systemctl start redis || systemctl start redis-server
}

###################################################################
# Установка push-сервера
###################################################################
dplPush(){
    cd /opt || exit 1
    wget -q https://repo.bitrix.info/vm/push-server-0.3.0.tgz
    npm install --production ./push-server-0.3.0.tgz
    rm ./push-server-0.3.0.tgz
    ln -sf /opt/node_modules/push-server/etc/push-server /etc/push-server

    cd /opt/node_modules/push-server || exit 1
    cp etc/init.d/push-server-multi /usr/local/bin/push-server-multi
    mkdir -p /etc/sysconfig
    cp etc/sysconfig/push-server-multi /etc/sysconfig/push-server-multi
    cp etc/push-server/push-server.service /etc/systemd/system/
    ln -sf /opt/node_modules/push-server /opt/push-server
    useradd -g www-data bitrix 2>/dev/null || true

    cat <<EOF >> /etc/sysconfig/push-server-multi
GROUP=www-data
SECURITY_KEY="${PUSH_KEY}"
RUN_DIR=/tmp/push-server
REDIS_SOCK=/var/run/redis/redis.sock
WS_HOST=127.0.0.1
EOF

    /usr/local/bin/push-server-multi configs pub
    /usr/local/bin/push-server-multi configs sub

    mkdir -p /etc/tmpfiles.d
    echo 'd /tmp/push-server 0770 bitrix www-data -' > /etc/tmpfiles.d/push-server.conf
    systemd-tmpfiles --remove --create

    [[ ! -d /var/log/push-server ]] && mkdir /var/log/push-server
    chown bitrix:www-data /var/log/push-server

    sed -i 's|User=.*|User=bitrix|;s|Group=.*|Group=www-data|;s|ExecStart=.*|ExecStart=/usr/local/bin/push-server-multi systemd_start|;s|ExecStop=.*|ExecStop=/usr/local/bin/push-server-multi stop|' /etc/systemd/system/push-server.service
    systemctl daemon-reload
    systemctl stop push-server
    systemctl --now enable push-server
    systemctl start push-server
}

###################################################################
# Настройка MySQL и создание БД/пользователя
###################################################################
dplMYSQL() {
    # Создадим директорию для кастомных конфигов, если её нет
    mkdir -p /etc/mysql/my-bx.d

    # Добавим дополнительную опцию
    echo 'innodb_strict_mode=off' >> /etc/mysql/my-bx.d/zbx-custom.cnf

    # Создадим БД и пользователя для Bitrix
    mysql -e "CREATE DATABASE sitemanager; \
              CREATE USER 'bitrix0'@'localhost' IDENTIFIED BY '${DBPASS}'; \
              GRANT ALL PRIVILEGES ON sitemanager.* TO 'bitrix0'@'localhost'; \
              FLUSH PRIVILEGES;"

    systemctl stop mysql || true

    if systemctl list-units --type=service | grep -q "mysql.service"; then
        systemctl enable mysql --now
    else
        echo "Ошибка: сервис MySQL не найден!"
        exit 1
    fi

    systemctl start mysql
}

###################################################################
# Настройки фаервола (nftables)
###################################################################
nfTabl(){
    cat <<EOF > /etc/nftables.conf
#!/usr/sbin/nft -f

flush ruleset

table inet filter {
    chain input {
        type filter hook input priority 0; policy drop;
        iif "lo" accept comment "Accept any localhost traffic"
        ct state invalid drop comment "Drop invalid connections"
        ip protocol icmp limit rate 4/second accept
        ip6 nexthdr ipv6-icmp limit rate 4/second accept
        ct state { established, related } accept comment "Accept traffic originated from us"
        tcp dport 22 accept comment "ssh"
        tcp dport { 80, 443, 8893, 8894, 9010, 9011 } accept comment "web"
    }
    chain forward {
        type filter hook forward priority 0;
    }
    chain output {
        type filter hook output priority 0;
    }
}
EOF

    systemctl restart nftables
    systemctl enable nftables.service
}

###################################################################
# Развёртывание основных конфигураций
###################################################################
deployConfig() {
    # Скачиваем готовые конфиги (из документации Bitrix)
    wget -q 'https://dev.1c-bitrix.ru/docs/chm_files/debian.zip'
    unzip debian.zip && rm debian.zip
    rsync -a --exclude=php.d ./debian/ /etc/
    rsync -a ./debian/php.d/ /etc/php/8.2/mods-available/
    rsync -a ./debian/php.d/ /etc/php/7.4/mods-available/ 2>/dev/null || true

    mkdir -p /var/www/html/bx-site

    nfTabl
    dplApache
    dplNginx
    dplRedis
    dplPush
    dplMYSQL

    systemctl enable mysql --now
}

###################################################################
# Развёртывание файлов установщика Bitrix
###################################################################
deployInstaller() {
    cd /var/www/html/bx-site || exit 1
    wget -q 'https://www.1c-bitrix.ru/download/scripts/bitrixsetup.php'
    wget -q 'https://www.1c-bitrix.ru/download/scripts/restore.php'

    mkdir -p bitrix/php_interface
    dbconn > bitrix/php_interface/dbconn.php
    settings > bitrix/.settings.php

    chown -R www-data:www-data /var/www/html/bx-site
}

###################################################################
# Шаблон dbconn.php
###################################################################
dbconn() {
cat <<EOF
<?php
\$DBDebug = false;
\$DBDebugToFile = false;
mb_internal_encoding("UTF-8");

@ini_set("memory_limit", "1024M");

define("MYSQL_TABLE_TYPE", "INNODB");
define("BX_USE_MYSQLI", true);

\$DBType = "mysql";
\$DBHost = "localhost";

\$DBLogin = "bitrix0";
\$DBPassword = "${DBPASS}";
\$DBName = "sitemanager";

date_default_timezone_set("Etc/GMT-3");

define("BX_UTF", true);
define("DELAY_DB_CONNECT", true);
define("DBPersistent", false);
define("SHORT_INSTALL", true);
define("VM_INSTALL", true);
define("BX_DISABLE_INDEX_PAGE", true);
define('BX_CRONTAB_SUPPORT', true);
define("BX_COMPRESSION_DISABLED", true);
define("CACHED_b_file", 3600);
define("CACHED_b_file_bucket_size", 10);
define("CACHED_b_lang", 3600);
define("CACHED_b_option", 3600);
define("CACHED_b_lang_domain", 3600);
define("CACHED_b_site_template", 3600);
define("CACHED_b_event", 3600);
define("CACHED_b_agent", 3660);
define("CACHED_menu", 3600);
?>
EOF
}

###################################################################
# Шаблон .settings.php
###################################################################
settings() {
cat <<EOF
<?php
return array (
  'utf_mode' =>
  array (
    'value' => true,
    'readonly' => true,
  ),
  'cache_flags' =>
  array (
    'value' =>
    array (
      'config_options' => 3600,
      'site_domain' => 3600,
    ),
    'readonly' => false,
  ),
  'cookies' =>
  array (
    'value' =>
    array (
      'secure' => false,
      'http_only' => true,
    ),
    'readonly' => false,
  ),
  'exception_handling' =>
  array (
    'value' =>
    array (
      'debug' => false,
      'handled_errors_types' => 4437,
      'exception_errors_types' => 4437,
      'ignore_silence' => false,
      'assertion_throws_exception' => true,
      'assertion_error_type' => 256,
      'log' => array (
        'settings' =>
        array (
          'file' => '/var/log/php/exceptions.log',
          'log_size' => 1000000,
        ),
      ),
    ),
    'readonly' => false,
  ),
  'crypto' =>
  array (
    'value' =>
    array (
      'crypto_key' => "${PUSH_KEY}",
    ),
    'readonly' => true,
  ),
  'connections' =>
  array (
    'value' =>
    array (
      'default' =>
      array (
        'className' => '\\Bitrix\\Main\\DB\\MysqliConnection',
        'host' => 'localhost',
        'database' => 'sitemanager',
        'login'    => 'bitrix0',
        'password' => '${DBPASS}',
        'options' => 2,
      ),
    ),
    'readonly' => true,
  ),
  'pull_s1' => 'BEGIN GENERATED PUSH SETTINGS. DON\'T DELETE COMMENT!!!!',
  'pull' => Array(
    'value' =>  array(
        'path_to_listener' => "http://#DOMAIN#/bitrix/sub/",
        'path_to_listener_secure' => "https://#DOMAIN#/bitrix/sub/",
        'path_to_modern_listener' => "http://#DOMAIN#/bitrix/sub/",
        'path_to_modern_listener_secure' => "https://#DOMAIN#/bitrix/sub/",
        'path_to_mobile_listener' => "http://#DOMAIN#:8893/bitrix/sub/",
        'path_to_mobile_listener_secure' => "https://#DOMAIN#:8894/bitrix/sub/",
        'path_to_websocket' => "ws://#DOMAIN#/bitrix/subws/",
        'path_to_websocket_secure' => "wss://#DOMAIN#/bitrix/subws/",
        'path_to_publish' => 'http://127.0.0.1:8895/bitrix/pub/',
        'nginx_version' => '4',
        'nginx_command_per_hit' => '100',
        'nginx' => 'Y',
        'nginx_headers' => 'N',
        'push' => 'Y',
        'websocket' => 'Y',
        'signature_key' => '${PUSH_KEY}',
        'signature_algo' => 'sha1',
        'guest' => 'N',
    ),
  ),
  'pull_e1' => 'END GENERATED PUSH SETTINGS. DON\'T DELETE COMMENT!!!!',
);
EOF
}

###################################################################
# Основной блок выполнения
###################################################################
installPkg

# Генерация ключей и паролей
PUSH_KEY=$(pwgen 24 1)
DBPASS=$(generate_password 24)

deployConfig
deployInstaller

END
