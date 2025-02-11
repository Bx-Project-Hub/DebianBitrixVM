#!/bin/sh
#
# metadata_begin
# recipe: Bitrix Vanilla
# tags: debian11, debian12
# revision: 1
# description_ru: Рецепт установки меню Битрикс окружения на системах Debian 11, Debian 12 с MySQL 8
# description_en: Bitrix CMS installing recipe with MySQL 8
# metadata_end

# use
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

dbconn() {
cat <<-EOF
<?php
\$DBDebug = false;
\$DBDebugToFile = false;
mb_internal_encoding("UTF-8");

define("BX_FILE_PERMISSIONS", 0664);
define("BX_DIR_PERMISSIONS", 0775);
@umask(~(BX_FILE_PERMISSIONS | BX_DIR_PERMISSIONS) & 0777);
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
?>EOF
}

settings() {
	cat <<-EOF
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

get_mysql_repo_version() {
    local URL="https://dev.mysql.com/downloads/repo/apt/"
    local LATEST_VERSION

    # Получаем самую последнюю версию пакета mysql-apt-config
    LATEST_VERSION=$(curl -s "$URL" \
        | grep -oP 'mysql-apt-config_[0-9]+\.[0-9]+\.[0-9]+-[0-9]+_all\.deb' \
        | sort -V | tail -1)

    if [[ -z "$LATEST_VERSION" ]]; then
        echo "Не удалось определить последнюю версию mysql-apt-config"
        exit 1
    fi

    local DOWNLOAD_URL="https://dev.mysql.com/get/$LATEST_VERSION"
    echo "Скачиваем $LATEST_VERSION из $DOWNLOAD_URL"
    sudo -E wget -q "$DOWNLOAD_URL" -O "/tmp/$LATEST_VERSION"
    
    # Устанавливаем mysql-apt-config в неинтерактивном режиме
    sudo -E DEBIAN_FRONTEND=noninteractive dpkg -i "/tmp/$LATEST_VERSION"
    rm "/tmp/$LATEST_VERSION"

    # Настраиваем debconf для mysql-apt-config (выбираем mysql-8.0)
    echo "mysql-apt-config mysql-apt-config/select-server select mysql-8.0"       | sudo -E debconf-set-selections
    echo "mysql-apt-config mysql-apt-config/select-product select Ok"            | sudo -E debconf-set-selections
    echo "mysql-apt-config mysql-apt-config/select-tools select"                 | sudo -E debconf-set-selections
    echo "mysql-apt-config mysql-apt-config/select-preview select Disabled"      | sudo -E debconf-set-selections
    # Для Debian 12 (bookworm), если нужно явно указать:
    # echo "mysql-apt-config mysql-apt-config/repo-codename select bookworm"      | sudo -E debconf-set-selections
    # echo "mysql-apt-config mysql-apt-config/enable-repo select OK"             | sudo -E debconf-set-selections

    # Настраиваем debconf-параметры для тихой установки MySQL (пароль root)
    echo "Настройка debconf для тихой установки MySQL (mysql-server)..."
    local root_pass
    root_pass="$(generate_password 24)"  # Функция generate_password должна быть объявлена выше
    echo "mysql-server mysql-server/root-pass password ${root_pass}"     | sudo -E debconf-set-selections
    echo "mysql-server mysql-server/re-root-pass password ${root_pass}"  | sudo -E debconf-set-selections

    # Некоторые сборки MySQL 8.0 могут ещё спрашивать о методе шифрования пароля:
    # echo "mysql-server mysql-server/default-auth-override select Use Strong Password Encryption (RECOMMENDED)" \
    #     | sudo -E debconf-set-selections

    # Обновляем пакеты
    sudo -E apt-get update

    # Устанавливаем вспомогательные пакеты (для completeness)
    sudo -E apt-get install -y \
        lsb-release ca-certificates apt-transport-https software-properties-common \
        gnupg2 unzip rsync nftables pwgen make build-essential wget curl poppler-utils

    # Установка MySQL Server и клиента в тихом режиме
    sudo -E DEBIAN_FRONTEND=noninteractive apt-get install -y \
        mysql-server mysql-client libmysqlclient-dev

    echo "MySQL 8.0 установлен. Пароль root: ${root_pass}"
}


installPkg(){
get_mysql_repo_version
#apt update

echo "deb [signed-by=/etc/apt/trusted.gpg.d/sury.gpg] https://ftp.mpi-inf.mpg.de/mirrors/linux/mirror/deb.sury.org/repositories/php $(lsb_release -sc) main" | tee /etc/apt/sources.list.d/sury-php.list
curl -s -o /etc/apt/trusted.gpg.d/sury.gpg https://ftp.mpi-inf.mpg.de/mirrors/linux/mirror/deb.sury.org/repositories/php/apt.gpg
apt update
export DEBIAN_FRONTEND="noninteractive"
debconf-set-selections <<< 'exim4-config exim4/dc_eximconfig_configtype select internet site; mail is sent and received directly using SMTP'
apt install -y php8.2 php8.2-cli \
                    php8.2-common php8.2-gd php8.2-ldap \
                    php8.2-mbstring php8.2-mysql \
                    php8.2-opcache php8.2-zip \
                    php8.2-pspell php8.2-xml php-pear \
                    php8.2-apcu php8.2-curl php-redis \
                    php-geoip php8.2-mcrypt php8.2-memcache \
                    php8.2-dev php8.2-maxminddb php8.2-imagick \
                    php8.2-http apache2 nginx \
                    nodejs npm redis \
                    exim4 exim4-config
}

dplApache(){
mkdir -p /etc/systemd/system/apache2.service.d
cat <<EOF >> /etc/systemd/system/apache2.service.d/privtmp.conf
[Service]
PrivateTmp=false
EOF
systemctl daemon-reload
ln -sf /etc/php/8.2/mods-available/zbx-bitrix.ini  /etc/php/8.2/apache2/conf.d/99-bitrix.ini
ln -sf /etc/php/8.2/mods-available/zbx-bitrix.ini  /etc/php/8.2/cli/conf.d/99-bitrix.ini
a2dismod --force autoindex
a2enmod rewrite
phpenmod xml
systemctl stop apache2
systemctl enable --now apache2
systemctl start nginx
}

dplNginx(){
	grep -qxF "127.0.0.1 push httpd" /etc/hosts || echo "\n127.0.0.1 push httpd\n" >> /etc/hosts
	rm /etc/nginx/sites-enabled/default
	ln -s /etc/nginx/sites-available/rtc.conf /etc/nginx/sites-enabled/rtc.conf
	ln -s /etc/nginx/sites-available/default.conf /etc/nginx/sites-enabled/default.conf
	systemctl stop nginx
	systemctl enable --now nginx
	systemctl start nginx
}

dplRedis() {
  echo -e "pidfile /run/redis/redis-server.pid\ndir /var/lib/redis" >> /etc/redis/redis.conf

  # Проверяем текущее значение vm.overcommit_memory
  current_value=$(sysctl -n vm.overcommit_memory 2>/dev/null || echo 0)

  # Если значение не равно 1, то изменяем его
  if [ "$current_value" -ne 1 ]; then
    echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf
    sysctl -w vm.overcommit_memory=1
  fi

  usermod -g www-data redis
  chown root:www-data /etc/redis/ /var/log/redis/

  [[ ! -d /etc/systemd/system/redis.service.d ]] && mkdir /etc/systemd/system/redis.service.d
  echo -e '[Service]\nGroup=www-data\nPIDFile=/run/redis/redis-server.pid' > /etc/systemd/system/redis.service.d/custom.conf

  systemctl daemon-reload
  systemctl stop redis
  systemctl enable --now redis || systemctl enable --now redis-server
  systemctl start redis
}

dplPush(){
	cd /opt
	wget -q https://repo.bitrix.info/vm/push-server-0.3.0.tgz
	npm install --production ./push-server-0.3.0.tgz
	rm ./push-server-0.3.0.tgz
	ln -sf /opt/node_modules/push-server/etc/push-server /etc/push-server

	cd /opt/node_modules/push-server
	cp etc/init.d/push-server-multi /usr/local/bin/push-server-multi
	mkdir /etc/sysconfig
	cp etc/sysconfig/push-server-multi  /etc/sysconfig/push-server-multi
	cp etc/push-server/push-server.service  /etc/systemd/system/
	ln -sf /opt/node_modules/push-server /opt/push-server
	useradd -g www-data bitrix

	cat <<EOF >> /etc/sysconfig/push-server-multi
GROUP=www-data
SECURITY_KEY="${PUSH_KEY}"
RUN_DIR=/tmp/push-server
REDIS_SOCK=/var/run/redis/redis.sock
WS_HOST=127.0.0.1
EOF
	/usr/local/bin/push-server-multi configs pub
	/usr/local/bin/push-server-multi configs sub
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

dplMYSQL() {
	echo 'innodb_strict_mode=off' >> /etc/mysql/my-bx.d/zbx-custom.cnf
	mysql -e "CREATE DATABASE sitemanager;CREATE USER 'bitrix0'@'localhost' IDENTIFIED BY '${DBPASS}';GRANT ALL PRIVILEGES ON sitemanager.* TO 'bitrix0'@'localhost';FLUSH PRIVILEGES;"
	systemctl stop mysql
	
	if systemctl list-units --type=service | grep -q "mysql.service"; then
    systemctl --now enable mysql
else
    echo "Ошибка: сервис MySQL не найден!"
    exit 1
fi

	systemctl start mysql
}

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

deployConfig() {

	wget -q 'https://dev.1c-bitrix.ru/docs/chm_files/debian.zip'
    unzip debian.zip && rm debian.zip
    rsync -a --exclude=php.d ./debian/ /etc/
    rsync -a ./debian/php.d/ /etc/php/8.2/mods-available/
    rsync -a ./debian/php.d/ /etc/php/7.4/mods-available/
	mkdir -p /var/www/html/bx-site

	nfTabl
	dplApache
	dplNginx
	dplRedis
	dplPush
	dplMYSQL

  systemctl --now enable mysql
}

deployInstaller() {
	cd /var/www/html/bx-site
	wget -q 'https://www.1c-bitrix.ru/download/scripts/bitrixsetup.php'
	wget -q 'https://www.1c-bitrix.ru/download/scripts/restore.php'
	mkdir -p bitrix/php_interface
	dbconn > bitrix/php_interface/dbconn.php
	settings > bitrix/.settings.php
	chown -R www-data:www-data /var/www/html/bx-site
}

installPkg

PUSH_KEY=$(pwgen 24 1)
DBPASS=$(generate_password 24)

deployConfig
deployInstaller

END


