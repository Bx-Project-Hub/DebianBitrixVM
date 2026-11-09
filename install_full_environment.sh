#!/usr/bin/env bash
set +x
set -euo pipefail
# Install full environment for Debian 12 / Debian 13 (основная цель — Debian 13 trixie)
# MASTER branch

# use curl
# bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)

# use wget
# bash <(wget -qO- https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)

# Проверка ОС и архитектуры до любых изменений
if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "Ошибка: скрипт нужно запускать от root." >&2
  exit 1
fi

if [[ ! -f /etc/os-release ]]; then
  echo "Ошибка: не удалось определить дистрибутив (/etc/os-release отсутствует)." >&2
  exit 1
fi

# shellcheck disable=SC1091
. /etc/os-release

if [[ "${ID:-}" != "debian" ]]; then
  echo "Ошибка: поддерживается только Debian 12/13. Обнаружено: ${PRETTY_NAME:-unknown}." >&2
  exit 1
fi

case "${VERSION_ID:-}" in
  12|13) ;;
  *)
    echo "Ошибка: поддерживаются Debian 12 (bookworm) и Debian 13 (trixie). Обнаружено: ${PRETTY_NAME:-unknown}." >&2
    exit 1
    ;;
esac

if [[ "$(dpkg --print-architecture)" != "amd64" ]]; then
  echo "Ошибка: репозитории MySQL/Percona собраны только для amd64." >&2
  echo "Текущая архитектура: $(dpkg --print-architecture)." >&2
  exit 1
fi

###################################################################
# Выбор СУБД: Oracle MySQL или Percona Server
###################################################################
DB_ENGINE="${DB_ENGINE:-}"

if [[ -z "$DB_ENGINE" ]]; then
  if [[ -t 0 ]]; then
    echo ""
    echo "Выберите СУБД:"
    echo "  1) MySQL 8.4 LTS (Oracle) — по умолчанию"
    echo "  2) Percona Server for MySQL 8.4 LTS"
    read -r -p "Введите 1 или 2 [1]: " _db_choice
    case "$_db_choice" in
      2|percona|Percona) DB_ENGINE="percona" ;;
      *) DB_ENGINE="mysql" ;;
    esac
  else
    DB_ENGINE="mysql"
  fi
fi

case "$DB_ENGINE" in
  mysql|percona) ;;
  *)
    echo "Ошибка: DB_ENGINE должен быть mysql или percona (получено: $DB_ENGINE)." >&2
    exit 1
    ;;
esac

# Если скрипт запущен из локальной копии репозитория — используем её,
# а не скачиваем vm_menu и custom_bitrix_setup.sh с GitHub.
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
LOCAL_SOURCE=""
if [[ -f "$SCRIPT_DIR/vm_menu/bash_scripts/config.sh" ]]; then
  LOCAL_SOURCE="$SCRIPT_DIR"
fi

echo "СУБД: $DB_ENGINE"
if [[ -n "$LOCAL_SOURCE" ]]; then
  echo "Источник установки: локальная копия $LOCAL_SOURCE"
else
  echo "Источник установки: GitHub ($BRANCH)"
fi

cat > /root/temp_install_full_environment.sh <<\END
#!/usr/bin/env bash
set +x
set -euo pipefail

###################################################################
# Функция генерации пароля
###################################################################
generate_password() {
    local length=${1:-24}
    local specials='-_+=@%.,:'
    local all_chars="abcdefghijklmnopqrstuvwxyzABCDEFGHIJKLMNOPQRSTUVWXYZ0123456789${specials}"

    local password=""
    local i
    for ((i = 0; i < length; i++)); do
        password+="${all_chars:RANDOM % ${#all_chars}:1}"
    done

    printf '%s' "$password"
}

export -f generate_password

BRANCH="master"
REPO_URL="https://github.com/Bx-Project-Hub/DebianBitrixVM.git"

# Передаются из внешнего скрипта
DB_ENGINE="${DB_ENGINE:-mysql}"
LOCAL_SOURCE="${LOCAL_SOURCE:-}"

DB_NAME="sitemanager"
DB_USER="bitrix0"

DIR_NAME_MENU="vm_menu"
DEST_DIR_MENU="/root"

FULL_PATH_MENU_FILE="$DEST_DIR_MENU/$DIR_NAME_MENU/menu.sh"

apt update -y
apt upgrade -y
apt install -y perl wget curl ansible python3-apt python3-cryptography git ssl-cert cron locales locales-all poppler-utils catdoc libreoffice-nogui imagemagick debconf-utils lsb-release ca-certificates apt-transport-https gnupg2 unzip rsync nftables pwgen make build-essential certbot python3-certbot-dns-cloudflare

# Set locales
locale-gen ru_RU.UTF-8
bash -c 'echo "LANG=ru_RU.UTF-8" > /etc/default/locale'
bash -c 'echo "LC_ALL=ru_RU.UTF-8" >> /etc/default/locale'
bash -c 'echo "LC_ALL=\"ru_RU.UTF-8\"" >> /etc/environment'

source /etc/default/locale
export LC_ALL="ru_RU.UTF-8"

# Доставляем на сервер скрипты установки, меню и вендорные файлы ДО запуска
# custom_bitrix_setup.sh: тогда установка берёт push-server, конфиги PHP,
# скрипты Bitrix и ключи репозиториев из локального каталога /root/vendor,
# а не с чужих сайтов.
VENDOR_DIR_MENU="/root/vendor"

if [[ -n "$LOCAL_SOURCE" && -d "$LOCAL_SOURCE/vm_menu" ]]; then
    echo "Локальный исходник: $LOCAL_SOURCE"
    rm -rf "$DEST_DIR_MENU/$DIR_NAME_MENU" "$VENDOR_DIR_MENU"
    rsync -a --delete "$LOCAL_SOURCE/vm_menu/" "$DEST_DIR_MENU/$DIR_NAME_MENU/"
    [[ -d "$LOCAL_SOURCE/vendor" ]] && rsync -a --delete "$LOCAL_SOURCE/vendor/" "$VENDOR_DIR_MENU/"
    SETUP_SCRIPT="$LOCAL_SOURCE/repositories/bitrix-gt/custom_bitrix_setup.sh"
else
    echo "Клонируем репозиторий проекта: $REPO_URL"
    rm -rf "$DEST_DIR_MENU/DebianBitrixVM"
    git clone --branch=$BRANCH --depth 1 --filter=blob:none --sparse $REPO_URL "$DEST_DIR_MENU/DebianBitrixVM"
    cd "$DEST_DIR_MENU/DebianBitrixVM"
    git sparse-checkout set "$DIR_NAME_MENU" "vendor" "repositories/bitrix-gt"
    rm -rf "$DEST_DIR_MENU/$DIR_NAME_MENU" "$VENDOR_DIR_MENU"
    mv -f "$DIR_NAME_MENU" "$DEST_DIR_MENU"
    mv -f "vendor" "$VENDOR_DIR_MENU"
    SETUP_SCRIPT="$DEST_DIR_MENU/DebianBitrixVM/repositories/bitrix-gt/custom_bitrix_setup.sh"
fi

# Проверяем целостность вендорных файлов (если контрольные суммы есть)
if [[ -f "$VENDOR_DIR_MENU/CHECKSUMS.sha256" ]]; then
    echo "Проверка вендорных файлов (SHA256)..."
    ( cd "$VENDOR_DIR_MENU" && sha256sum -c CHECKSUMS.sha256 --quiet ) \
        || { echo "Ошибка: контрольные суммы вендорных файлов не совпадают." >&2; exit 1; }
fi

# Запускаем скрипт установки окружения Bitrix (custom_bitrix_setup.sh).
# Он создаёт и выполняет /root/run.sh, а сгенерированные пароли сохраняет
# в /root/.bitrix_env.
if [[ -f "$SETUP_SCRIPT" ]]; then
    DB_ENGINE="$DB_ENGINE" BS_VENDOR_DIR="$VENDOR_DIR_MENU" bash "$SETUP_SCRIPT"
else
    echo "Ошибка: не найден custom_bitrix_setup.sh ($SETUP_SCRIPT)" >&2
    exit 1
fi

rm -rf "$DEST_DIR_MENU/DebianBitrixVM"

if [[ ! -f /root/.bitrix_env ]]; then
    echo "Ошибка: /root/.bitrix_env не создан — установка окружения Bitrix не завершилась." >&2
    echo "Смотрите /root/recipe.log." >&2
    exit 1
fi

# shellcheck disable=SC1091
. /root/.bitrix_env

if [[ ! -f /root/run.sh ]]; then
    echo "Ошибка: /root/run.sh не найден!" >&2
    exit 1
fi

# Дополнительно: проверяем наличие пароля root MySQL, созданного на этапе установки
# (custom_bitrix_setup.sh записывает его в /root/.my.cnf и задаёт через debconf).
if [[ ! -f /root/.my.cnf ]]; then
  echo "Ошибка: не найден /root/.my.cnf с паролем root MySQL." >&2
  exit 1
fi

if ! mysql --defaults-file=/root/.my.cnf -e "SELECT 1" >/dev/null 2>&1; then
  echo "Ошибка: не удаётся подключиться к MySQL с данными из /root/.my.cnf." >&2
  exit 1
fi

site_user_password=$(generate_password 24)

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

# Переключаем PHP по умолчанию на версию из конфигурации меню (по умолчанию 8.3)
source "$DEST_DIR_MENU/$DIR_NAME_MENU/bash_scripts/config.sh"

PHP_DEFAULT="${BS_PHP_VERSION_DEFAULT:-8.3}"
if [[ -x "/usr/bin/php${PHP_DEFAULT}" ]]; then
  update-alternatives --set php "/usr/bin/php${PHP_DEFAULT}"
  if [[ -x "/usr/bin/phar${PHP_DEFAULT}" ]]; then
    update-alternatives --set phar "/usr/bin/phar${PHP_DEFAULT}"
  fi
  if [[ -x "/usr/bin/phar.phar${PHP_DEFAULT}" ]]; then
    update-alternatives --set phar.phar "/usr/bin/phar.phar${PHP_DEFAULT}"
  fi
else
  echo "Внимание: PHP ${PHP_DEFAULT} не найден, альтернативы не изменены." >&2
fi

# Отключаем ненужные модули Apache
a2dismod --force negotiation filter

# Ссылка на меню:
ln -sfn "$FULL_PATH_MENU_FILE" "$DEST_DIR_MENU/menu.sh"

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

###################################################################
# Итоговая проверка
###################################################################
echo "Проверка окружения:"
echo "  ОС:     $(. /etc/os-release && echo "$PRETTY_NAME")"
echo "  PHP:    $(php -r 'echo PHP_VERSION;' 2>/dev/null || echo 'не определена')"
echo "  MySQL:  $(mysql --defaults-file=/root/.my.cnf -N -B -e 'SELECT VERSION();' 2>/dev/null || echo 'не определён')"
echo "  Nginx:  $(nginx -v 2>&1 | sed 's#nginx/##; s#nginx version: ##' || echo 'не установлен')"
echo "  Apache: $(apache2 -v 2>/dev/null | awk -F'[ /]' '/Server version/{print $4"/"$5}' || echo 'не установлен')"
echo "  Node:   $(node -v 2>/dev/null || echo 'не установлен')"
for s in mysql nginx apache2 "redis-server" "push-server"; do
  echo "  ${s}: $(systemctl is-active "$s" 2>/dev/null || true)"
done
echo -e "\nПароль root MySQL: /root/.my.cnf"
echo -e "\n";

END

DB_ENGINE="$DB_ENGINE" LOCAL_SOURCE="$LOCAL_SOURCE" bash /root/temp_install_full_environment.sh

rm /root/temp_install_full_environment.sh
rm /root/run.sh
