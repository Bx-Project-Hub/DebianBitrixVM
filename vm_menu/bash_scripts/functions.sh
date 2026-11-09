#!/bin/bash
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$dir/utils.sh"
source "$dir/actions.sh"

function do_load_menu() {
  action_check_new_version_menu &
  load_bitrix_vm_version
  get_os_info
  CURRENT_PHP_VERSION="$(php -r 'echo PHP_MAJOR_VERSION, ".", PHP_MINOR_VERSION;' 2>/dev/null)"
  CURRENT_MYSQL_VERSION="$(get_mysql_version)"
  if [ "$BS_SHOW_IP_CURRENT_SERVER_IN_MENU" = true ]; then
    get_ip_current_server
  fi
  collect_status_panel
}

main_menu(){
    command=""
    until [[ "$command" == "0" ]]; do
    clear

    do_load_menu

    local msg_menu_emulate_bitrix_vm="Включить эмуляцию BitrixVM (переменная ${BS_VAR_NAME_BVM})"
    if [[ -n "${!BS_VAR_NAME_BVM}" ]]; then
      msg_menu_emulate_bitrix_vm="Выключить эмуляцию BitrixVM (текущая версия: ${!BS_VAR_NAME_BVM})"
    fi

    local msg_new_version_menu=""
    local update_menu_action=""
    if [ -f "/tmp/new_version_menu.tmp" ]; then
      local nv
      nv=$(cat /tmp/new_version_menu.tmp)
      msg_new_version_menu="\e[33m
          Доступна новая версия меню Debian BitrixVM.
          Текущая версия: ${BS_VERSION_MENU} → новая: ${nv}
          Ссылка: \e]8;;${BS_REPOSITORY_URL}\a${BS_REPOSITORY_URL}\e]8;;\a
          Обновить: команда \"update_menu\" или пункт \"U\" в меню.\n\e[0m"
      update_menu_action="Доступно обновление меню: введите \"update_menu\" или выберите пункт \"U\".";
    fi

    echo ""
    echo -e "   ${C_BOLD}${C_CYAN}Debian BitrixVM ${BS_VERSION_MENU}${C_RESET} ${C_GREY}— управление окружением Bitrix${C_RESET}"
    echo -e "   ${C_GREY}ОС:${C_RESET} ${OS_DESCRIPTION}   ${C_DIM}|${C_RESET}   ${C_GREY}PHP:${C_RESET} ${C_BOLD}${C_GREEN}${CURRENT_PHP_VERSION:-не определена}${C_RESET}   ${C_DIM}|${C_RESET}   ${C_GREY}MySQL:${C_RESET} ${C_BOLD}${C_GREEN}${CURRENT_MYSQL_VERSION:-не определена}${C_RESET}"
    if [ "$BS_SHOW_IP_CURRENT_SERVER_IN_MENU" = true ]; then
      echo -e "   ${C_GREY}${CURRENT_SERVER_IP}${C_RESET}"
    fi
    render_status_panel
    echo ""
    echo -e "   ${C_GREY}Сервисы:${C_RESET} $(service_badge "$BS_SERVICE_NGINX_NAME")  $(service_badge "$BS_SERVICE_APACHE_NAME")  $(service_badge "$BS_MYSQL_SERVICE_NAME")"
    echo -e "             $(service_badge "$BS_REDIS_SERVICE_NAME")  $(service_badge "$BS_PUSH_SERVER_SERVICE_NAME")\n"
    echo -e "${msg_new_version_menu}"

    echo -e "   ${C_BOLD}${C_BLUE}Сайты${C_RESET}"
    echo -e "     ${C_YELLOW}1)${C_RESET} Список сайтов ${C_GREY}(каталоги, тип, HTTPS, document root)${C_RESET}"
    echo -e "     ${C_YELLOW}2)${C_RESET} Создать сайт ${C_GREY}(собственное ядро или ссылки на общее ядро)${C_RESET}"
    echo -e "     ${C_YELLOW}3)${C_RESET} Удалить сайт ${C_GREY}(каталог, конфигурация, база данных)${C_RESET}"
    echo ""
    echo -e "   ${C_BOLD}${C_BLUE}Доступ и безопасность${C_RESET}"
    echo -e "     ${C_YELLOW}4)${C_RESET} Выпустить сертификат Let's Encrypt для сайта"
    echo -e "     ${C_YELLOW}5)${C_RESET} Включить или выключить редирект HTTP → HTTPS"
    echo ""
    echo -e "   ${C_BOLD}${C_BLUE}Окружение${C_RESET}"
    echo -e "     ${C_YELLOW}6)${C_RESET} Сменить версию PHP ${C_GREY}(текущая: ${CURRENT_PHP_VERSION:-не определена})${C_RESET}"
    echo -e "     ${C_YELLOW}7)${C_RESET} Настроить SMTP для отправки писем"
    echo -e "     ${C_YELLOW}8)${C_RESET} Установить или удалить дополнения ${C_GREY}(Sphinx, конвертер файлов, Netdata)${C_RESET}"
    echo -e "     ${C_YELLOW}9)${C_RESET} ${msg_menu_emulate_bitrix_vm}"
    echo ""
    echo -e "   ${C_BOLD}${C_BLUE}Сервер${C_RESET}"
    echo -e "     ${C_YELLOW}A)${C_RESET} Обновить пакеты системы ${C_GREY}(apt update && apt upgrade)${C_RESET}"
    echo -e "     ${C_YELLOW}R)${C_RESET} Перезагрузить сервер"
    echo -e "     ${C_YELLOW}P)${C_RESET} Выключить сервер"
    if [ -f "/tmp/new_version_menu.tmp" ]; then
      echo -e "     ${C_YELLOW}U)${C_RESET} Обновить меню до новой версии"
    else
      echo -e "     ${C_YELLOW}U)${C_RESET} Обновить меню ${C_GREY}(переустановить текущую версию)${C_RESET}"
    fi
    echo ""
    echo -e "     ${C_YELLOW}H)${C_RESET} Подробная справка по пунктам меню"
    echo -e "     ${C_YELLOW}0)${C_RESET} Выход"
    echo -e "\n"
    if [ -n "${update_menu_action}" ]; then
      echo -e "\e[33m   ${update_menu_action}\e[0m"
    fi
    echo -n "Введите команду: "
    read -r command

    case "$command" in
     "1") show_sites_dirs ;;
     "2") add_site ;;
     "3") delete_site ;;
     "4") get_lets_encrypt_certificate ;;
     "5") enable_or_disable_redirect_http_to_https ;;
     "6") change_php_version ;;
     "7") settings_smtp_sites ;;
     "8") menu_install_extensions ;;
     "9") action_emulate_bitrix_vm ;;
     "A"|"a") update_server ;;
     "R"|"r") reboot_server ;;
     "P"|"p") power_off_server ;;
     "U"|"u"|"update_menu") update_menu ;;
     "H"|"h"|"?") show_help ;;
     "DELETE_SITE") delete_site ;;
     0|z|q) exit ;;
     *) echo -e "\n   Ошибка: неизвестная команда \"${command}\". Введите H для справки."; sleep 2 ;;
    esac
    done
}

menu_install_extensions(){
    local command=""
    until [[ "$command" == "0" ]]; do
    clear

    echo -e "\n   Дополнительные компоненты\n"
    echo "     1) Sphinx — полнотекстовый поиск (пакет ${BS_SPHINX_PACKAGE})"
    echo "     2) Сервер конвертации файлов (LibreOffice + RabbitMQ + transformer)"
    echo "     3) Netdata — мониторинг ресурсов сервера"
    echo "     0) Вернуться в главное меню"
    echo ""
    echo -n "   Введите команду: "
    read -r command

    case "$command" in
     "1") install_sphinx ;;
     "2") install_file_conversion_server ;;
     "3") install_netdata ;;
     0|z|q) return ;;
     *) echo "   Ошибка: неизвестная команда."; sleep 2 ;;
    esac
    done
}

############################################################
# Интерактивные действия меню
############################################################

function show_sites_dirs() {
    clear
    list_sites
    press_any_key_to_return_menu
}

# Проверка доменного имени
function is_valid_domain() {
    [[ "$1" =~ ^([a-zA-Z0-9]([a-zA-Z0-9-]{0,61}[a-zA-Z0-9])?\.)+[a-zA-Z]{2,}$ ]]
}

# Проверка адреса e-mail
function is_valid_email() {
    [[ "$1" =~ ^[^@[:space:]]+@[^@[:space:]]+\.[a-zA-Z]{2,}$ ]]
}

# Выбор сайта из списка. Результат — в переменной SELECTED_SITE.
function choose_site() {
    local prompt="${1:-Выберите сайт}"
    local choice i

    get_sites_array
    if [[ ${#SITES_LIST[@]} -eq 0 ]]; then
        echo -e "\n   Сайты не найдены в ${BS_PATH_SITES}."
        return 1
    fi

    echo ""
    for i in "${!SITES_LIST[@]}"; do
        printf '   %2d) %-32s (%s)\n' "$((i + 1))" "${SITES_LIST[$i]}" "$(get_site_type "${SITES_LIST[$i]}")"
    done
    echo ""
    read -r -p "   ${prompt} (номер, 0 — отмена): " choice

    [[ -z "$choice" || "$choice" == "0" ]] && return 1
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#SITES_LIST[@]} )); then
        echo "   Ошибка: неверный номер."
        return 1
    fi

    SELECTED_SITE="${SITES_LIST[$((choice - 1))]}"
    return 0
}

function add_site() {
    clear
    echo -e "\n   Меню → Создание сайта\n"

    local domain="" mode="full" path_site_from_links=""
    local db_name="" db_user="" db_password=""
    local ssl_lets_encrypt="N" ssl_lets_encrypt_www="N" ssl_lets_encrypt_email=""
    local redirect_to_https="N"
    local mode_choice base

    while true; do
        read -r -p "   Домен сайта (например, example.ru; 0 — отмена): " domain
        [[ "$domain" == "0" ]] && return
        if is_valid_domain "$domain"; then
            break
        fi
        echo "   Ошибка: некорректный домен. Пример: example.ru"
    done

    if [ -e "${BS_PATH_SITES}/${domain}" ]; then
        echo -e "\n   Ошибка: каталог ${BS_PATH_SITES}/${domain} уже существует."
        press_any_key_to_return_menu
        return
    fi

    echo ""
    echo "   Режим создания:"
    echo "     1) full — собственное ядро Bitrix в каталоге сайта (для нового сайта)"
    echo "     2) link — символические ссылки на ядро существующего сайта (мультисайтовость)"
    read_by_def "   Выберите режим [1]: " mode_choice "1"

    case "$mode_choice" in
        2|link) mode="link" ;;
        *) mode="full" ;;
    esac

    if [[ "$mode" == "link" ]]; then
        read_by_def "   Путь к сайту-источнику ядра [${BS_PATH_DEFAULT_SITE}]: " path_site_from_links "$BS_PATH_DEFAULT_SITE"
        if [ ! -d "${path_site_from_links}/bitrix" ]; then
            echo -e "\n   Ошибка: в ${path_site_from_links} нет каталога bitrix."
            press_any_key_to_return_menu
            return
        fi
    else
        base="$(sanitize_name "$domain" "$BS_MAX_CHAR_DB_NAME")"
        db_name="${base}"
        db_user="${base}_u"

        read_by_def "   Имя базы данных [${db_name}]: " db_name "$db_name"
        read_by_def "   Пользователь базы данных [${db_user}]: " db_user "$db_user"

        if db_exists "$db_name"; then
            echo -e "\n   Ошибка: база данных ${db_name} уже существует."
            press_any_key_to_return_menu
            return
        fi
        if user_exists "$db_user"; then
            echo -e "\n   Ошибка: пользователь MySQL ${db_user} уже существует."
            press_any_key_to_return_menu
            return
        fi

        db_password="$(generate_password "$BS_CHAR_DB_PASSWORD")"
    fi

    echo ""
    if confirm_action "Выпустить сертификат Let's Encrypt после создания сайта?"; then
        ssl_lets_encrypt="Y"
        while true; do
            read -r -p "   E-mail для Let's Encrypt: " ssl_lets_encrypt_email
            if is_valid_email "$ssl_lets_encrypt_email"; then
                break
            fi
            echo "   Ошибка: некорректный e-mail."
        done
        if confirm_action "Выпустить сертификат также для www.${domain}?"; then
            ssl_lets_encrypt_www="Y"
        fi
    fi

    if confirm_action "Включить редирект HTTP → HTTPS?"; then
        redirect_to_https="Y"
    fi

    echo ""
    echo "   Проверьте параметры:"
    echo "     Домен:        ${domain}"
    echo "     Режим:        ${mode}"
    if [[ "$mode" == "link" ]]; then
        echo "     Ядро сайта:   ${path_site_from_links}"
    else
        echo "     База данных:  ${db_name} (пользователь ${db_user})"
    fi
    echo "     Let's Encrypt: ${ssl_lets_encrypt}${ssl_lets_encrypt_email:+ (${ssl_lets_encrypt_email}, www: ${ssl_lets_encrypt_www})}"
    echo "     HTTPS-редирект: ${redirect_to_https}"
    echo ""

    if ! confirm_action "Создать сайт ${domain}?"; then
        echo "   Отменено."
        press_any_key_to_return_menu
        return
    fi

    action_create_site
}

function delete_site() {
    clear
    echo -e "\n   Меню → Удаление сайта\n"
    echo "   Будут удалены каталог сайта, конфигурации Nginx/Apache и (для режима full) база данных."

    if ! choose_site "Какой сайт удалить"; then
        press_any_key_to_return_menu
        return
    fi

    local site="$SELECTED_SITE"
    local full_path_site="${BS_PATH_SITES}/${site}"
    local type db_name="" db_user=""
    local confirm_text

    type="$(get_site_type "$site")"

    if [[ "$type" == "full" ]]; then
        get_site_db_data "$full_path_site"
        db_name="$SITE_DB_NAME"
        db_user="$SITE_DB_USER"
    fi

    echo ""
    echo "   Сайт:      ${site}"
    echo "   Каталог:   ${full_path_site}"
    echo "   Тип:       ${type}"
    if [[ -n "$db_name" ]]; then
        echo "   База:      ${db_name} (пользователь ${db_user:-неизвестен})"
    fi
    echo ""
    read -r -p "   Для подтверждения введите имя сайта (${site}): " confirm_text

    if [[ "$confirm_text" != "$site" ]]; then
        echo "   Отменено."
        press_any_key_to_return_menu
        return
    fi

    action_delete_site
}

function get_lets_encrypt_certificate() {
    clear
    echo -e "\n   Меню → Сертификат Let's Encrypt\n"
    echo "   Сертификат выпускается по протоколу HTTP-01: домен должен уже указывать на этот сервер,"
    echo "   а порт 80 — быть доступен извне."

    if ! choose_site "Для какого сайта выпустить сертификат"; then
        press_any_key_to_return_menu
        return
    fi

    local domain="$SELECTED_SITE"
    local path_site="${BS_PATH_SITES}/${domain}"
    local email="" is_www="N" redirect_to_https="N"

    while true; do
        read -r -p "   E-mail для Let's Encrypt: " email
        if is_valid_email "$email"; then
            break
        fi
        echo "   Ошибка: некорректный e-mail."
    done

    if confirm_action "Выпустить сертификат также для www.${domain}?"; then
        is_www="Y"
    fi

    if confirm_action "Включить редирект HTTP → HTTPS?"; then
        redirect_to_https="Y"
    fi

    if ! confirm_action "Выпустить сертификат для ${domain}?"; then
        echo "   Отменено."
        press_any_key_to_return_menu
        return
    fi

    action_get_lets_encrypt_certificate
}

function enable_or_disable_redirect_http_to_https() {
    clear
    echo -e "\n   Меню → Редирект HTTP → HTTPS\n"

    if ! choose_site "Для какого сайта изменить редирект"; then
        press_any_key_to_return_menu
        return
    fi

    local site="$SELECTED_SITE"
    local path_site="${BS_PATH_SITES}/${site}"
    local action="enable"

    if [ -f "${path_site}/.htsecure" ]; then
        echo -e "\n   Сейчас редирект ВКЛЮЧЁН."
        if ! confirm_action "Выключить редирект HTTP → HTTPS для ${site}?"; then
            echo "   Отменено."
            press_any_key_to_return_menu
            return
        fi
        action="disable"
    else
        echo -e "\n   Сейчас редирект ВЫКЛЮЧЕН."
        if ! confirm_action "Включить редирект HTTP → HTTPS для ${site}?"; then
            echo "   Отменено."
            press_any_key_to_return_menu
            return
        fi
        action="enable"
    fi

    action_enable_or_disable_redirect_http_to_https
}

function change_php_version() {
    clear
    echo -e "\n   Меню → Смена версии PHP\n"

    get_current_version_php
    get_available_version_php

    local new_version_php
    read -r -p "   Введите версию PHP для установки (например, 8.3; 0 — отмена): " new_version_php

    [[ -z "$new_version_php" || "$new_version_php" == "0" ]] && return

    local version_allowed=0
    local v
    for v in "${BS_PHP_SUPPORTED_VERSIONS[@]}"; do
        [[ "$new_version_php" == "$v" ]] && version_allowed=1 && break
    done
    if [[ $version_allowed -eq 0 ]]; then
        echo -e "\n   Ошибка: версия ${new_version_php} не поддерживается меню (доступно: ${BS_PHP_SUPPORTED_VERSIONS[*]})."
        press_any_key_to_return_menu
        return
    fi

    local candidate
    candidate="$(apt-cache policy "php${new_version_php}" 2>/dev/null | awk '/^[[:space:]]*Candidate:/{print $2; exit}')"
    if [[ -z "$candidate" || "$candidate" == "(none)" ]]; then
        echo -e "\n   Ошибка: версия PHP ${new_version_php} недоступна в подключённых репозиториях."
        press_any_key_to_return_menu
        return
    fi

    if ! confirm_action "Установить PHP ${new_version_php} и переключить Apache на неё?"; then
        echo "   Отменено."
        press_any_key_to_return_menu
        return
    fi

    action_change_php_version "$new_version_php"
}

function settings_smtp_sites() {
    local command=""
    until [[ "$command" == "0" ]]; do
        clear
        echo -e "\n   Меню → SMTP\n"
        echo "     1) Настроить или обновить SMTP-аккаунт для сайта"
        echo "     2) Настроить общий аккаунт default (используется, если для сайта аккаунт не задан)"
        echo "     3) Показать сохранённые аккаунты"
        echo "     0) Вернуться в главное меню"
        echo ""
        echo -n "   Введите команду: "
        read -r command

        case "$command" in
            1) smtp_configure_account "site" ;;
            2) smtp_configure_account "default" ;;
            3) smtp_show_accounts ;;
            0|z|q) return ;;
            *) echo "   Ошибка: неизвестная команда."; sleep 2 ;;
        esac
    done
}

function smtp_show_accounts() {
    clear
    echo -e "\n   Сохранённые SMTP-аккаунты (${BS_SMTP_FILE_SITES_CONFIG}):\n"

    if [ ! -f "$BS_SMTP_FILE_SITES_CONFIG" ]; then
        echo "   Файл не найден. Аккаунты ещё не настраивались."
    else
        local accounts
        accounts="$(grep -E '^account[[:space:]]+' "$BS_SMTP_FILE_SITES_CONFIG" 2>/dev/null | awk '{print $2}' | sort -u)"
        if [ -z "$accounts" ]; then
            echo "   Аккаунты не найдены."
        else
            local account
            for account in $accounts; do
                echo "   - ${account}"
            done
        fi
    fi

    press_any_key_to_return_menu
}

# Режим: site — аккаунт с именем домена сайта, default — общий аккаунт.
function smtp_configure_account() {
    local mode="$1"
    local account_name=""

    clear
    echo -e "\n   Меню → SMTP → Настройка аккаунта\n"

    if [[ "$mode" == "site" ]]; then
        if ! choose_site "Для какого сайта настроить SMTP"; then
            press_any_key_to_return_menu
            return
        fi
        account_name="$SELECTED_SITE"
    else
        account_name="default"
    fi

    echo ""
    echo "   Аккаунт: ${account_name}"
    echo "   (это имя должно совпадать с доменом сайта: Apache передаёт его в msmtp-wrapper)"
    echo ""

    local smtp_host="" smtp_port="587" email_from="" is_auth="Y"
    local authentication_method="auto" login="" password="" enable_TLS="Y"

    while true; do
        read -r -p "   SMTP-сервер (например, smtp.yandex.ru): " smtp_host
        [[ -n "$smtp_host" ]] && break
    done

    read_by_def "   Порт SMTP [587]: " smtp_port "587"

    local default_from="noreply@${account_name}"
    [[ "$account_name" == "default" ]] && default_from="noreply@localhost"
    read_by_def "   Адрес отправителя [${default_from}]: " email_from "$default_from"

    if confirm_action "Требуется авторизация на SMTP-сервере?"; then
        is_auth="Y"
        read_by_def "   Метод авторизации (auto/plain/login/cram-md5) [auto]: " authentication_method "auto"
        read -r -p "   Логин: " login
        read -r -s -p "   Пароль: " password
        echo ""
    else
        is_auth="N"
    fi

    if ! confirm_action "Использовать TLS?"; then
        enable_TLS="N"
    fi

    echo ""
    echo "   Проверьте параметры:"
    echo "     Аккаунт:     ${account_name}"
    echo "     Сервер:      ${smtp_host}:${smtp_port}"
    echo "     От:          ${email_from}"
    if [[ "$is_auth" == "Y" ]]; then
        echo "     Авторизация: включена (логин ${login}, метод ${authentication_method})"
    else
        echo "     Авторизация: выключена"
    fi
    echo "     TLS:         ${enable_TLS}"
    echo ""

    if ! confirm_action "Сохранить настройки SMTP?"; then
        echo "   Отменено."
        press_any_key_to_return_menu
        return
    fi

    action_settings_smtp_site
}

function install_sphinx() {
    clear
    echo -e "\n   Меню → Sphinx (полнотекстовый поиск)\n"
    echo "     1) Установить Sphinx"
    echo "     2) Удалить Sphinx"
    echo "     0) Назад"
    echo -n "   Введите команду: "
    local command
    read -r command

    case "$command" in
        1)
            if confirm_action "Установить Sphinx (${BS_SPHINX_PACKAGE})?"; then
                action_install_or_delete_sphinx install
            fi
            ;;
        2)
            if confirm_action "Удалить Sphinx?"; then
                action_install_or_delete_sphinx delete
            fi
            ;;
    esac
}

function install_netdata() {
    clear
    echo -e "\n   Меню → Netdata (мониторинг)\n"
    echo "     1) Установить Netdata"
    echo "     2) Удалить Netdata"
    echo "     0) Назад"
    echo -n "   Введите команду: "
    local command
    read -r command

    case "$command" in
        1)
            if confirm_action "Установить Netdata?"; then
                action_install_or_delete_netdata install
            fi
            ;;
        2)
            if confirm_action "Удалить Netdata?"; then
                action_install_or_delete_netdata delete
            fi
            ;;
    esac
}

function install_file_conversion_server() {
    clear
    echo -e "\n   Меню → Сервер конвертации файлов\n"
    echo "   Компоненты: LibreOffice, RabbitMQ, transformer (служба обработки файлов)."
    echo "   Требуется установленный сайт с ядром Bitrix."
    echo ""
    echo "     1) Установить"
    echo "     2) Удалить"
    echo "     0) Назад"
    echo -n "   Введите команду: "
    local command
    read -r command
    local action=""

    case "$command" in
        1) action="install" ;;
        2) action="delete" ;;
        *) return ;;
    esac

    if ! choose_site "Для какого сайта выполнить действие"; then
        press_any_key_to_return_menu
        return
    fi

    domain="$SELECTED_SITE"
    full_path_site="${BS_PATH_SITES}/${domain}"

    if ! confirm_action "Выполнить «${action}» сервера конвертации для ${domain}?"; then
        echo "   Отменено."
        press_any_key_to_return_menu
        return
    fi

    action_install_or_delete_file_conversion_server "$action"
}

function show_help() {
    clear
    cat <<'HELP'

   Справка по меню Debian BitrixVM
   ==============================

   САЙТЫ
   1) Список сайтов — каталоги в /var/www/html, тип (full/link), признак
      «сайт по умолчанию», наличие HTTPS-редиректа и полный путь к document root.
      full — у сайта собственное ядро Bitrix; link — символические ссылки на
      общее ядро (каталоги local, bitrix, upload, images).

   2) Создать сайт — создаёт каталог, конфигурации Nginx и Apache, при режиме full
      базу данных и пользователя MySQL, генерирует .settings.php и dbconn.php,
      при необходимости переводит агенты Bitrix на CRON и выпускает сертификат.

   3) Удалить сайт — удаляет каталог сайта, конфигурации Nginx/Apache, а для
      режима full — базу данных и пользователя MySQL. Требуется ввести имя сайта.

   ДОСТУП И БЕЗОПАСНОСТЬ
   4) Сертификат Let's Encrypt — выпуск по HTTP-01. Домен должен указывать на
      сервер, порт 80 должен быть открыт.
   5) Редирект HTTP → HTTPS — включает или выключает перенаправление на HTTPS
      (файл-маркер .htsecure в каталоге сайта).

   ОКРУЖЕНИЕ
   6) Смена версии PHP — доустанавливает выбранную версию из репозитория
      deb.sury.org и переключает Apache и CLI (update-alternatives).
   7) SMTP — аккаунты в /var/www/html/.msmtprc. Apache передаёт имя аккаунта
      в msmtp-wrapper (обычно это домен сайта). Аккаунт default используется,
      если аккаунт сайта не найден.
   8) Дополнения — Sphinx, сервер конвертации файлов, Netdata.
   9) Эмуляция BitrixVM — переменная BITRIX_VA_VER в /etc/apache2/envvars
      (нужна некоторым решениям маркетплейса).

   СЕРВЕР
   A) Обновление пакетов — apt update && apt upgrade.
   R) Перезагрузка. P) Выключение. U) Обновление меню.

   ШАПКА МЕНЮ
   Панель «Состояние сервера» показывает load average, загрузку CPU, память,
   диск и аптайм. Значения окрашены по порогам: до 70% — зелёный,
   70–89% — жёлтый, от 90% — красный.
   Настройки в /root/vm_menu/bash_scripts/config.sh:
     BS_STATUS_PANEL        — вкл/выкл панель (true/false);
     BS_STATUS_PANEL_WIDTH  — ширина панели в символах;
     BS_CPU_SAMPLE_MS       — окно замера CPU в миллисекундах (0 — без замера);
     BS_USE_COLOR           — вкл/выкл цвета (можно отключить через NO_COLOR=1);
     BS_SHOW_IP_CURRENT_SERVER_IN_MENU — показывать интерфейсы и IP.

HELP

    press_any_key_to_return_menu
}

function update_server() {
    clear
    if ! confirm_action "Обновить пакеты системы (apt update && apt upgrade)?"; then
        echo "   Отменено."
        press_any_key_to_return_menu
        return
    fi
    action_update_server
}

function update_menu() {
    clear
    if ! confirm_action "Обновить меню (текущая версия сохранится в /root/backup_vm_menu)?"; then
        echo "   Отменено."
        press_any_key_to_return_menu
        return
    fi
    action_update_menu
}

# Function to sanitize and limit the length of names
sanitize_name() {
    local input="$1"
    local max_length="$2"
    local translator
    local sanitized

    translator="${dir_helpers:-${dir}/../helpers}/perl/translate.pl"

    if [[ -x "$translator" ]]; then
        sanitized="$(printf '%s' "$input" | sed 's/-//g' | sed 's/\./_/g' | "$translator")"
    else
        sanitized="$(printf '%s' "$input" | sed 's/-//g' | sed 's/\./_/g')"
    fi

    # Имя БД/пользователя MySQL: только строчные латинские буквы, цифры и _
    sanitized="$(printf '%s' "$sanitized" | tr '[:upper:]' '[:lower:]' | tr -cd 'a-z0-9_')"
    sanitized="$(cut -c-"$max_length" <<< "$sanitized")"
    sanitized="${sanitized%_}"
    sanitized="${sanitized#_}"

    if [[ -z "$sanitized" ]]; then
        sanitized="site_$(generate_random_hash)"
    fi

    printf "%s" "$sanitized"
}

# Function to check if a MySQL database exists
db_exists() {
    local db_name="$1"
    if ! $BS_MYSQL_CMD -e "USE ${db_name}" 2>/dev/null; then
        return 1
    fi
    return 0
}

# Function to check if a MySQL user exists
user_exists() {
    local db_user="$1"
    if ! $BS_MYSQL_CMD -e "SELECT 1 FROM mysql.user WHERE user = '${db_user}'" 2>/dev/null | grep -q 1; then
        return 1
    fi
    return 0
}

# Function to generate a random hash
generate_random_hash() {
    local hash_length=8
    local hash
    hash=$(openssl rand -hex "$hash_length")
    printf "%s" "$hash"
}

function reboot_server() {
  clear
  while true; do
    read -r -p $'   Do you really want to\e[33m RESTART \e[0mserver? (Y/N): ' answer
    case $answer in
        [Yy]* ) reboot; break;;
        [Nn]* ) break;;
        * ) echo "   Please enter Y or N.";;
    esac
  done
}

function power_off_server() {
  clear
  while true; do
    read -r -p $'   Do you really want to\e[33m SHUT DOWN \e[0mserver? (Y/N): ' answer
    case $answer in
        [Yy]* ) poweroff; break;;
        [Nn]* ) break;;
        * ) echo "   Please enter Y or N.";;
    esac
  done
}
