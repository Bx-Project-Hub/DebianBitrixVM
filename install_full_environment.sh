#!/usr/bin/env bash
set +x
set -euo pipefail
# Install full environment
# MASTER branch

# use curl
# bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)

# use wget
# bash <(wget -qO- https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)

cat > /root/temp_install_full_environment.sh <<\END
#!/usr/bin/env bash
set +x
set -euo pipefail

###################################################################
# Функция генерации пароля
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

export -f generate_password

BRANCH="master"
SETUP_BITRIX_DEBIAN_URL="https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/$BRANCH/repositories/bitrix-gt/custom_bitrix_setup.sh"
REPO_URL="https://github.com/Bx-Project-Hub/DebianBitrixVM.git"

DB_NAME="sitemanager"
DB_USER="bitrix0"

DIR_NAME_MENU="vm_menu"
DEST_DIR_MENU="/root"

FULL_PATH_MENU_FILE="$DEST_DIR_MENU/$DIR_NAME_MENU/menu.sh"

apt update -y
apt upgrade -y
apt install -y perl wget curl ansible git ssl-cert cron locales locales-all poppler-utils catdoc unoconv libreoffice imagemagick debconf-utils lsb-release ca-certificates apt-transport-https software-properties-common gnupg2 unzip rsync nftables pwgen make build-essential certbot python3-certbot-dns-cloudflare

# Set locales
locale-gen ru_RU.UTF-8
bash -c 'echo "LANG=ru_RU.UTF-8" > /etc/default/locale'
bash -c 'echo "LC_ALL=ru_RU.UTF-8" >> /etc/default/locale'
bash -c 'echo "LC_ALL=\"ru_RU.UTF-8\"" >> /etc/environment'

source /etc/default/locale
export LC_ALL="ru_RU.UTF-8"

# Запускаем скрипт установки окружения Bitrix (custom_bitrix_setup.sh)
bash -c "$(curl -sL $SETUP_BITRIX_DEBIAN_URL)"

if [[ -f /root/run.sh ]]; then
    source /root/run.sh
else
    echo "Ошибка: /root/run.sh не найден!" >&2
    exit 1
fi

# Дополнительно: устанавливаем root-пароль MySQL (переопределяем, если нужно)
root_pass=$(generate_password 24)
site_user_password=$(generate_password 24)

mysql -e "SET PASSWORD FOR 'root'@'localhost' = PASSWORD('${root_pass}');FLUSH PRIVILEGES;"

cat > /root/.my.cnf <<CONFIG_MYSQL_ROOT_MY_CNF
[client]
user=root
password="${root_pass}"
# socket=/var/lib/mysqld/mysqld.sock
CONFIG_MYSQL_ROOT_MY_CNF

# Клонируем репозиторий с меню vm_menu
git clone --branch=$BRANCH --depth 1 --filter=blob:none --sparse $REPO_URL "$DEST_DIR_MENU/DebianBitrixVM"
cd "$DEST_DIR_MENU/DebianBitrixVM"
git sparse-checkout set $DIR_NAME_MENU

# Переносим vm_menu в /root и чистим репозиторий
rm -rf $DEST_DIR_MENU/$DIR_NAME_MENU
mv -f $DIR_NAME_MENU $DEST_DIR_MENU
rm -rf "$DEST_DIR_MENU/DebianBitrixVM"

cd $DEST_DIR_MENU

chmod -R +x $DEST_DIR_MENU/$DIR_NAME_MENU

# Добавляем запуск меню в .profile, если работаем по SSH
if ! grep -qF "$FULL_PATH_MENU_FILE" /root/.profile; then
  cat << INSTALL_MENU >> /root/.profile

if [ -n "\$SSH_CONNECTION" ]; then
  $FULL_PATH_MENU_FILE
fi

INSTALL_MENU
fi

# Включаем нужные модули Apache
a2enmod remoteip
a2enmod rewrite
a2dismod --force autoindex

cat > /etc/apache2/mods-enabled/remoteip.conf <<CONFIG_APACHE2_REMOTEIP
<IfModule remoteip_module>
 RemoteIPHeader X-Forwarded-For
 RemoteIPInternalProxy 127.0.0.1
</IfModule>
CONFIG_APACHE2_REMOTEIP

# Переключаем PHP по умолчанию на 8.2
update-alternatives --set php /usr/bin/php8.2
update-alternatives --set phar /usr/bin/phar8.2
update-alternatives --set phar.phar /usr/bin/phar.phar8.2

# Отключаем ненужные модули Apache
a2dismod --force negotiation filter

# Ссылка на меню:
ln -s $FULL_PATH_MENU_FILE "$DEST_DIR_MENU/menu.sh"

# Дальнейшая настройка через ansible
source $DEST_DIR_MENU/$DIR_NAME_MENU/bash_scripts/config.sh

DOCUMENT_ROOT="${BS_PATH_SITES}/bx-site"

DELETE_FILES=(
  "$BS_PATH_APACHE_SITES_CONF/000-default.conf"
  "$BS_PATH_APACHE_SITES_ENABLED/000-default.conf"
)

ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_SETTINGS_SMTP_SITES}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
  -e "is_new_install_env=Y \
  account_name='' \
  smtp_file_sites_config=${BS_SMTP_FILE_SITES_CONFIG} \
  smtp_file_user_config=${BS_SMTP_FILE_USER_CONFIG} \
  smtp_file_group_user_config=${BS_SMTP_FILE_GROUP_USER_CONFIG} \
  smtp_file_permissions_config=${BS_SMTP_FILE_PERMISSIONS_CONFIG} \
  smtp_file_user_log=${BS_SMTP_FILE_USER_LOG} \
  smtp_file_group_user_log=${BS_SMTP_FILE_GROUP_USER_LOG} \
  smtp_path_wrapp_script_sh=${BS_SMTP_PATH_WRAPP_SCRIPT_SH}"

ansible-playbook "$DEST_DIR_MENU/$DIR_NAME_MENU/ansible/playbooks/${BS_ANSIBLE_PB_INSTALL_NEW_FULL_ENVIRONMENT}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
  -e "domain=default \
  db_name=${DB_NAME} \
  db_user=${DB_USER} \
  db_password=${DBPASS} \
  db_character_set_server=${BS_DB_CHARACTER_SET_SERVER} \
  db_collation_server=${BS_DB_COLLATION} \
  site_user_password=${site_user_password} \
  path_sites=${BS_PATH_SITES} \
  document_root=${DOCUMENT_ROOT} \
  delete_files=$(IFS=,; echo "${DELETE_FILES[*]}") \
  download_bitrix_install_files_new_site=$(IFS=,; echo "${BS_DOWNLOAD_BITRIX_INSTALL_FILES_NEW_SITE[*]}") \
  timeout_download_bitrix_install_files_new_site=${BS_TIMEOUT_DOWNLOAD_BITRIX_INSTALL_FILES_NEW_SITE} \
  user_server_sites=${BS_USER_SERVER_SITES} \
  group_user_server_sites=${BS_GROUP_USER_SERVER_SITES} \
  permissions_sites_dirs=${BS_PERMISSIONS_SITES_DIRS} \
  permissions_sites_files=${BS_PERMISSIONS_SITES_FILES} \
  service_nginx_name=${BS_SERVICE_NGINX_NAME} \
  path_nginx=${BS_PATH_NGINX} \
  path_nginx_sites_conf=${BS_PATH_NGINX_SITES_CONF} \
  path_nginx_sites_enabled=${BS_PATH_NGINX_SITES_ENABLED} \
  service_apache_name=${BS_SERVICE_APACHE_NAME} \
  path_apache=${BS_PATH_APACHE} \
  path_apache_sites_conf=${BS_PATH_APACHE_SITES_CONF} \
  path_apache_sites_enabled=${BS_PATH_APACHE_SITES_ENABLED} \
  smtp_path_wrapp_script_sh=${BS_SMTP_PATH_WRAPP_SCRIPT_SH} \
  bx_cron_agents_path_file_after_document_root=${BS_BX_CRON_AGENTS_PATH_FILE_AFTER_DOCUMENT_ROOT} \
  bx_cron_logs_path_dir=${BS_BX_CRON_LOGS_PATH_DIR} \
  bx_cron_logs_path_file=${BS_BX_CRON_LOGS_PATH_FILE} \
  push_server_config=${BS_PUSH_SERVER_CONFIG}"

echo -e "\n\n";
echo "Full environment installed";
echo -e "\n";
echo "Password for the user ${BS_USER_SERVER_SITES}:";
echo "${site_user_password}";
echo -e "\n";

END

bash /root/temp_install_full_environment.sh

rm /root/temp_install_full_environment.sh
rm /root/run.sh
