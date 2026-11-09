#!/bin/bash
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

action_create_site(){
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_CREATE_SITE}")

  pb_redirect_http_to_https=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_ENABLE_OR_DISABLE_REDIRECT_HTTP_TO_HTTPS}")

  ansible-playbook "${pb}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
  -e "domain=${domain} \
  mode=${mode} \
  db_name=${db_name} \
  db_user=${db_user} \
  db_password=${db_password} \
  db_character_set_server=${BS_DB_CHARACTER_SET_SERVER} \
  db_collation_server=${BS_DB_COLLATION} \
  path_site_from_links=${path_site_from_links} \
  ssl_lets_encrypt=${ssl_lets_encrypt} \
  ssl_lets_encrypt_www=${ssl_lets_encrypt_www} \
  ssl_lets_encrypt_email=${ssl_lets_encrypt_email} \
  redirect_to_https=${redirect_to_https} \
  path_sites=${BS_PATH_SITES} \
  default_full_path_site=${BS_PATH_SITES}/${BS_DEFAULT_SITE_NAME} \
  site_links_resources=$(IFS=,; echo "${BS_SITE_LINKS_RESOURCES[*]}") \
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
  push_server_config=${BS_PUSH_SERVER_CONFIG} \
  pb_redirect_http_to_https=${pb_redirect_http_to_https} \
  ansible_run_playbooks_params=${BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS}"

  press_any_key_to_return_menu;
}

action_check_new_version_menu(){
  local file_temp_config="/tmp/configs.tmp"
  local file_new_version="/tmp/new_version_menu.tmp"

  if [[ -z ${BS_REPOSITORY_URL_FILE_VERSION} ]] || [[ -z ${BS_REPOSITORY_URL} ]] || [[ -z ${BS_CHECK_UPDATE_MENU_MINUTES} ]]; then
      rm -f "${file_new_version}"
      return;
  fi

  if [ -f "${file_temp_config}" ]; then
    current_time=$(date +%s)
    file_time=$(stat -c %Y "${file_temp_config}")
    diff=$((current_time - file_time))
    if [ ! $diff -lt $(($BS_CHECK_UPDATE_MENU_MINUTES * 60)) ]; then
      curl -m 5 -o "${file_temp_config}" -s ${BS_REPOSITORY_URL_FILE_VERSION} 2>/dev/null
    fi
    else
      curl -m 5 -o "${file_temp_config}" -s ${BS_REPOSITORY_URL_FILE_VERSION} 2>/dev/null
  fi

  if [ ! -f ${file_temp_config} ]; then
    rm -f "${file_new_version}"
    return;
  fi

  new_version=$(grep 'BS_VERSION_MENU' ${file_temp_config} | awk -F'=' '{ print $2 }' | tr -d '"')

  if [[ -z ${new_version} ]]; then
    rm -f "${file_new_version}"
    return;
  fi

  # Обновление предлагаем только если версия в репозитории СТРОГО НОВЕЕ локальной.
  # Сравнение «на равенство» недостаточно: если в репозитории лежит более старая
  # версия (например, локально 2.0.0, а в master 1.0.0), меню предлагало
  # «обновление» на понижение версии.
  if [[ ${new_version} == ${BS_VERSION_MENU} ]] || \
     [[ "$(printf '%s\n%s\n' "${BS_VERSION_MENU}" "${new_version}" | sort -V | tail -n1)" != "${new_version}" ]]; then
    rm -f "${file_new_version}"
    return;
  fi

  echo "${new_version}" > $file_new_version
}

function action_update_menu() {
    local menu_file
    menu_file="$(cd "${dir}/.." 2>/dev/null && pwd)/menu.sh"
    [[ -f "$menu_file" ]] || menu_file="$BS_PATH_MENU_FILE"

    local update_rc=0
    bash <(curl -sL "${BS_URL_SCRIPT_UPDATE_MENU}") || update_rc=$?

    if (( update_rc != 0 )); then
        echo ""
        echo "   Обновление не выполнено (код ${update_rc}). Текущее меню продолжает работать."
        press_any_key_to_return_menu
        return "$update_rc"
    fi

    if [[ ! -f "$menu_file" ]]; then
        echo ""
        echo "   Обновление выполнено, но файл меню не найден: ${menu_file}"
        echo "   Запустите меню вручную: /root/menu.sh"
        press_any_key_to_return_menu
        return 1
    fi

    # Не выходим в шелл: перезапускаем меню уже из обновлённой версии.
    echo ""
    echo "   Перезапуск меню..."
    sleep 1
    exec "$menu_file"
}

function action_update_server() {
    apt update -y
    apt upgrade -y
    press_any_key_to_return_menu;
}

function action_change_php_version() {
    local new_version_php="${1:-}"
    local path_php="/etc/php/${new_version_php}"

    if [[ -z "$new_version_php" ]]; then
        echo "Ошибка: не указана версия PHP."
        press_any_key_to_return_menu
        return 1
    fi

    if ! ls /etc/apt/sources.list.d/sury-php.list >/dev/null 2>&1; then
        echo "Ошибка: не подключён репозиторий deb.sury.org (/etc/apt/sources.list.d/sury-php.list)." >&2
        echo "Установите окружение через install_full_environment.sh." >&2
        press_any_key_to_return_menu
        return 1
    fi

    echo -e "\n   Установка PHP ${new_version_php}...\n"

    local install_php="${BS_PHP_INSTALL_TEMPLATE[*]}"
    install_php="${install_php//VER#0.0/${new_version_php}}"

    apt-get update -y >/dev/null 2>&1

    # shellcheck disable=SC2086
    if ! apt-get install -y ${install_php}; then
        echo -e "\n   Ошибка: не удалось установить PHP ${new_version_php}." >&2
        press_any_key_to_return_menu
        return 1
    fi

    mkdir -p "${BS_PATH_PHP_LOG}"
    chown "${BS_USER_SERVER_SITES}:${BS_GROUP_USER_SERVER_SITES}" "${BS_PATH_PHP_LOG}" 2>/dev/null
    chmod 0775 "${BS_PATH_PHP_LOG}" 2>/dev/null

    # Конфигурация Bitrix (php.d из debian.zip) для выбранной версии PHP
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    if wget -q -O "${tmp_dir}/debian.zip" "${BS_DOWNLOAD_BITRIX_CONFIGS}" \
       && unzip -o -q "${tmp_dir}/debian.zip" -d "${tmp_dir}" 2>/dev/null; then
        if [ -d "${tmp_dir}/debian/php.d" ]; then
            rsync -a --force "${tmp_dir}/debian/php.d/" "${path_php}/mods-available/"
        fi
    else
        echo "   Предупреждение: не удалось скачать конфигурацию Bitrix (debian.zip)."
    fi
    rm -rf "${tmp_dir}"

    ln -sf "${path_php}/mods-available/zbx-bitrix.ini" "${path_php}/apache2/conf.d/99-bitrix.ini"
    ln -sf "${path_php}/mods-available/zbx-bitrix.ini" "${path_php}/cli/conf.d/99-bitrix.ini"

    # Отключаем все ранее включённые mod_php, включаем выбранную версию
    local module
    for module in "${BS_PATH_APACHE}"/mods-enabled/php*_module.load; do
        [ -e "$module" ] || continue
        module="$(basename "$module" _module.load)"
        a2dismod -f "$module" >/dev/null 2>&1
    done

    if ! a2enmod "php${new_version_php}" >/dev/null 2>&1; then
        echo -e "\n   Ошибка: не удалось включить mod_php ${new_version_php} для Apache." >&2
        press_any_key_to_return_menu
        return 1
    fi

    update-alternatives --set php "/usr/bin/php${new_version_php}" >/dev/null 2>&1
    if [ -x "/usr/bin/phar${new_version_php}" ]; then
        update-alternatives --set phar "/usr/bin/phar${new_version_php}" >/dev/null 2>&1
    fi
    if [ -x "/usr/bin/phar.phar${new_version_php}" ]; then
        update-alternatives --set phar.phar "/usr/bin/phar.phar${new_version_php}" >/dev/null 2>&1
    fi

    systemctl restart "${BS_SERVICE_APACHE_NAME}"
    systemctl restart "${BS_SERVICE_NGINX_NAME}"

    echo -e "\n   Готово. Активная версия PHP: $(php -r 'echo PHP_VERSION;' 2>/dev/null || echo 'не определена')."
    press_any_key_to_return_menu
}
action_get_lets_encrypt_certificate(){
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_GET_LETS_ENCRYPT_CERTIFICATE}")

  ansible-playbook "${pb}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
  -e "domain=${domain} \
  path_site=${path_site} \
  email=${email} \
  is_www=${is_www} \
  default_full_path_site=${BS_PATH_SITES}/${BS_DEFAULT_SITE_NAME} \
  path_nginx_sites_conf=${BS_PATH_NGINX_SITES_CONF} \
  service_nginx_name=${BS_SERVICE_NGINX_NAME} \
  user_server_sites=${BS_USER_SERVER_SITES} \
  group_user_server_sites=${BS_GROUP_USER_SERVER_SITES} \
  permissions_sites_files=${BS_PERMISSIONS_SITES_FILES} \
  redirect_to_https=${redirect_to_https}"

  press_any_key_to_return_menu;
}

action_enable_or_disable_redirect_http_to_https(){
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_ENABLE_OR_DISABLE_REDIRECT_HTTP_TO_HTTPS}")

  ansible-playbook "${pb}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
  -e "path_site=${path_site} \
  user_server_sites=${BS_USER_SERVER_SITES} \
  group_user_server_sites=${BS_GROUP_USER_SERVER_SITES} \
  permissions_sites_files=${BS_PERMISSIONS_SITES_FILES} \
  domain=${site} \
  action=${action}"

  press_any_key_to_return_menu;
}

action_emulate_bitrix_vm(){
  clear;

  if [[ -n "${!BS_VAR_NAME_BVM}" ]]; then
      echo "   Эмуляция BitrixVM отключена (удалена переменная ${BS_VAR_NAME_BVM}).";
      sed -i "/export ${BS_VAR_NAME_BVM}/d" "$BS_VAR_PATH_FILE_BVM"
  else
      echo "export ${BS_VAR_NAME_BVM}=\"${BS_VAR_VALUE_BVM}\"" | tee -a "$BS_VAR_PATH_FILE_BVM" > /dev/null
      echo "   Эмуляция BitrixVM включена (${BS_VAR_NAME_BVM}=${BS_VAR_VALUE_BVM}).";
  fi

  systemctl restart "$BS_SERVICE_APACHE_NAME"
  press_any_key_to_return_menu;
}

# Удаление сайта.
# Переменные: site, full_path_site, type (full|link), db_name, db_user
action_delete_site(){
  local pb
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_DELETE_SITE}")

  ansible-playbook "${pb}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
  -e "site=${site} \
  full_path_site=${full_path_site} \
  type=${type} \
  db_name=${db_name:-} \
  db_user=${db_user:-} \
  user_server_sites=${BS_USER_SERVER_SITES} \
  path_nginx_sites_conf=${BS_PATH_NGINX_SITES_CONF} \
  path_apache_sites_conf=${BS_PATH_APACHE_SITES_CONF} \
  service_nginx_name=${BS_SERVICE_NGINX_NAME} \
  service_apache_name=${BS_SERVICE_APACHE_NAME}"

  press_any_key_to_return_menu;
}

# Sphinx: action = install | delete
action_install_or_delete_sphinx(){
  local sphinx_action="${1:-}"
  local pb
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_INSTALL_OR_DELETE_SPHINX}")

  case "$sphinx_action" in
    install) sphinx_action="INSTALL" ;;
    delete)  sphinx_action="DELETE" ;;
    *) echo "Ошибка: неизвестное действие для Sphinx: ${sphinx_action}" >&2; return 1 ;;
  esac

  ansible-playbook "${pb}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
  -e "sphinx_action=${sphinx_action} \
  sphinx_package=${BS_SPHINX_PACKAGE} \
  sphinx_service_name=${BS_SPHINX_SERVICE_NAME}"

  press_any_key_to_return_menu;
}

# Netdata: action = install | delete
action_install_or_delete_netdata(){
  local netdata_action="${1:-}"
  local pb
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_INSTALL_OR_DELETE_NETDATA}")

  case "$netdata_action" in
    install) netdata_action="INSTALL" ;;
    delete)  netdata_action="DELETE" ;;
    *) echo "Ошибка: неизвестное действие для Netdata: ${netdata_action}" >&2; return 1 ;;
  esac

  ansible-playbook "${pb}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
  -e "netdata_action=${netdata_action} \
  service_nginx_name=${BS_SERVICE_NGINX_NAME} \
  group_user_server_sites=${BS_GROUP_USER_SERVER_SITES}"

  press_any_key_to_return_menu;
}

# Сервер конвертации файлов (transformer): action = install | delete
# Переменные: domain, full_path_site
action_install_or_delete_file_conversion_server(){
  local file_conversion_server_action="${1:-}"
  local pb
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_INSTALL_OR_DELETE_FILE_CONVERSION_SERVER}")

  case "$file_conversion_server_action" in
    install) file_conversion_server_action="INSTALL" ;;
    delete)  file_conversion_server_action="DELETE" ;;
    *) echo "Ошибка: неизвестное действие для сервера конвертации: ${file_conversion_server_action}" >&2; return 1 ;;
  esac

  ansible-playbook "${pb}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
  -e "file_conversion_server_action=${file_conversion_server_action} \
  domain=${domain} \
  full_path_site=${full_path_site} \
  cluster_web_server='' \
  bx_transformer_bx_ansible_owner=${BS_USER_SERVER_SITES} \
  bx_transformer_bx_ansible_group=${BS_GROUP_USER_SERVER_SITES} \
  bx_transformer_bx_ansible_executer=${BS_USER_SERVER_SITES} \
  bx_transformer_cache_directory=${BS_TRANSFORMER_CACHE_DIR} \
  bx_transformer_rabbitmq_user=${BS_TRANSFORMER_RABBITMQ_USER} \
  bx_transformer_libreoffice_path=/usr/bin/libreoffice \
  bx_transformer_domains=[\"${domain}\"] \
  user_server_sites=${BS_USER_SERVER_SITES} \
  service_apache_name=${BS_SERVICE_APACHE_NAME}"

  press_any_key_to_return_menu;
}

# Настройка SMTP-аккаунта в общем /var/www/html/.msmtprc
# Переменные: account_name, smtp_host, smtp_port, email_from, is_auth,
# authentication_method, login, password, enable_TLS
action_settings_smtp_site(){
  local pb
  pb=$(realpath "$dir/${BS_PATH_ANSIBLE_PLAYBOOKS}/${BS_ANSIBLE_PB_SETTINGS_SMTP_SITES}")

  ansible-playbook "${pb}" $BS_ANSIBLE_RUN_PLAYBOOKS_PARAMS \
  -e "is_actions_account=Y \
  account_name=${account_name} \
  smtp_host=${smtp_host} \
  smtp_port=${smtp_port} \
  email_from=${email_from} \
  is_auth=${is_auth} \
  authentication_method=${authentication_method} \
  login=${login} \
  password=${password} \
  enable_TLS=${enable_TLS} \
  smtp_file_sites_config=${BS_SMTP_FILE_SITES_CONFIG} \
  smtp_file_user_config=${BS_SMTP_FILE_USER_CONFIG} \
  smtp_file_group_user_config=${BS_SMTP_FILE_GROUP_USER_CONFIG} \
  smtp_file_permissions_config=${BS_SMTP_FILE_PERMISSIONS_CONFIG} \
  smtp_file_user_log=${BS_SMTP_FILE_USER_LOG} \
  smtp_file_group_user_log=${BS_SMTP_FILE_GROUP_USER_LOG}"

  press_any_key_to_return_menu;
}
