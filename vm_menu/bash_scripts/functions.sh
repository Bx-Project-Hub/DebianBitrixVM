#!/bin/bash
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$dir/i18n.sh"
# Если меню запущено через menu.sh, язык уже выбран там; при прямом запуске — выбираем здесь.
[[ -n "${BS_MENU_LANG_CURRENT:-}" ]] || i18n_init
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
  collect_environment_panel
}

main_menu(){
    command=""
    until [[ "$command" == "0" ]]; do
    clear

    do_load_menu

    local msg_menu_emulate_bitrix_vm
    if [[ -n "${!BS_VAR_NAME_BVM}" ]]; then
      msg_menu_emulate_bitrix_vm="$(t menu.item_emulate_off "${!BS_VAR_NAME_BVM}")"
    else
      msg_menu_emulate_bitrix_vm="$(t menu.item_emulate_on "${BS_VAR_NAME_BVM}")"
    fi

    local msg_new_version_menu=""
    local update_menu_action=""
    local nv=""
    if [ -f "/tmp/new_version_menu.tmp" ]; then
      read -r nv < /tmp/new_version_menu.tmp || nv=""
      # Показываем уведомление, только если предложенная версия СТРОГО новее
      # текущей. Защита от залипшего файла после откатов и даунгрейдов.
      if [[ -n "$nv" ]] && version_is_newer "$nv" "$BS_VERSION_MENU"; then
        msg_new_version_menu="$(t menu.new_version "$BS_VERSION_MENU" "$nv" "$BS_REPOSITORY_URL" "$BS_REPOSITORY_URL")"
        update_menu_action="$(t menu.update_action)"
      else
        rm -f /tmp/new_version_menu.tmp
        nv=""
      fi
    fi

    echo ""
    echo -e "   ${C_BOLD}${C_CYAN}Debian BitrixVM ${BS_VERSION_MENU}${C_RESET} ${C_GREY}$(t menu.tagline)${C_RESET}"
    echo -e "   ${C_GREY}$(t menu.label_os)${C_RESET} ${OS_DESCRIPTION}   ${C_DIM}|${C_RESET}   ${C_GREY}PHP:${C_RESET} ${C_BOLD}${C_GREEN}${CURRENT_PHP_VERSION:-$(t common.undefined)}${C_RESET}   ${C_DIM}|${C_RESET}   ${C_GREY}MySQL:${C_RESET} ${C_BOLD}${C_GREEN}${CURRENT_MYSQL_VERSION:-$(t common.undefined)}${C_RESET}"
    if [ "$BS_SHOW_IP_CURRENT_SERVER_IN_MENU" = true ]; then
      echo -e "   ${C_GREY}${CURRENT_SERVER_IP}${C_RESET}"
    fi
    render_status_panel
    echo ""
    render_environment_panel
    local netdata_hint
    netdata_hint="$(netdata_stats_hint)"
    if [ -n "$netdata_hint" ]; then
      echo -e "   ${C_GREY}${netdata_hint}${C_RESET}"
    fi
    echo ""
    echo -e "   ${C_GREY}$(t menu.services)${C_RESET} $(service_badge "$BS_SERVICE_NGINX_NAME")  $(service_badge "$BS_SERVICE_APACHE_NAME")  $(service_badge "$BS_MYSQL_SERVICE_NAME")"
    echo -e "             $(service_badge "$BS_REDIS_SERVICE_NAME")  $(service_badge "$BS_PUSH_SERVER_SERVICE_NAME")\n"
    echo -e "${msg_new_version_menu}"

    echo -e "   ${C_BOLD}${C_BLUE}$(t menu.section_sites)${C_RESET}"
    echo -e "     ${C_YELLOW}1)${C_RESET} $(t menu.item_sites) ${C_GREY}$(t menu.item_sites_hint)${C_RESET}"
    echo -e "     ${C_YELLOW}2)${C_RESET} $(t menu.item_add) ${C_GREY}$(t menu.item_add_hint)${C_RESET}"
    echo -e "     ${C_YELLOW}3)${C_RESET} $(t menu.item_delete) ${C_GREY}$(t menu.item_delete_hint)${C_RESET}"
    echo ""
    echo -e "   ${C_BOLD}${C_BLUE}$(t menu.section_access)${C_RESET}"
    echo -e "     ${C_YELLOW}4)${C_RESET} $(t menu.item_ssl)"
    echo -e "     ${C_YELLOW}5)${C_RESET} $(t menu.item_redirect)"
    echo ""
    echo -e "   ${C_BOLD}${C_BLUE}$(t menu.section_env)${C_RESET}"
    echo -e "     ${C_YELLOW}6)${C_RESET} $(t menu.item_php) ${C_GREY}$(t menu.item_php_hint "${CURRENT_PHP_VERSION:-$(t common.undefined)}")${C_RESET}"
    echo -e "     ${C_YELLOW}7)${C_RESET} $(t menu.item_smtp)"
    echo -e "     ${C_YELLOW}8)${C_RESET} $(t menu.item_addons) ${C_GREY}$(t menu.item_addons_hint)${C_RESET}"
    echo -e "     ${C_YELLOW}9)${C_RESET} ${msg_menu_emulate_bitrix_vm}"
    echo ""
    echo -e "   ${C_BOLD}${C_BLUE}$(t menu.section_server)${C_RESET}"
    echo -e "     ${C_YELLOW}A)${C_RESET} $(t menu.item_update_pkgs) ${C_GREY}$(t menu.item_update_pkgs_hint)${C_RESET}"
    echo -e "     ${C_YELLOW}R)${C_RESET} $(t menu.item_reboot)"
    echo -e "     ${C_YELLOW}P)${C_RESET} $(t menu.item_poweroff)"
    if [[ -n "$nv" ]]; then
      echo -e "     ${C_YELLOW}U)${C_RESET} $(t menu.item_menu_new)"
    else
      echo -e "     ${C_YELLOW}U)${C_RESET} $(t menu.item_menu_current) ${C_GREY}$(t menu.item_menu_current_hint)${C_RESET}"
    fi
    if menu_autoupdate_enabled; then
      echo -e "     ${C_YELLOW}C)${C_RESET} $(t menu.item_autoupd_off "$(menu_autoupdate_schedule)")"
    else
      echo -e "     ${C_YELLOW}C)${C_RESET} $(t menu.item_autoupd_on)"
    fi
    echo ""
    echo -e "     ${C_YELLOW}H)${C_RESET} $(t menu.item_help)"
    echo -e "     ${C_YELLOW}0)${C_RESET} $(t menu.item_exit)"
    echo -e "\n"
    if [ -n "${update_menu_action}" ]; then
      echo -e "\e[33m   ${update_menu_action}\e[0m"
    fi
    echo -n "   $(t common.enter_command) "
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
     "C"|"c"|"autoupdate") action_toggle_menu_autoupdate ;;
     "H"|"h"|"?") show_help ;;
     "DELETE_SITE") delete_site ;;
     0|z|q) exit ;;
     *) echo -e "\n   $(t common.unknown_command "${command}")"; sleep 2 ;;
    esac
    done
}

menu_install_extensions(){
    local command=""
    until [[ "$command" == "0" ]]; do
    clear

    echo -e "\n   $(t ext.title)\n"
    echo "     1) $(t ext.sphinx "${BS_SPHINX_PACKAGE}")"
    echo "     2) $(t ext.converter)"
    echo "     3) $(t ext.netdata)"
    echo "     4) $(t ext.postgres)"
    echo "     5) $(t ext.restore)"
    echo "     6) $(t ext.apps_cms)"
    echo "     7) $(t ext.apps_b24)"
    echo "     8) $(t ext.memcached)"
    echo "     0) $(t common.back_main)"
    echo ""
    echo -n "   $(t common.enter_command) "
    read -r command

    case "$command" in
     "1") install_sphinx ;;
     "2") install_file_conversion_server ;;
     "3") install_netdata ;;
     "4") install_postgres ;;
     "5") manage_restore_script ;;
     "6") apps_menu cms ;;
     "7") apps_menu b24 ;;
     "8") install_memcached ;;
     0|z|q) return ;;
     *) echo "   $(t common.unknown_command_short)"; sleep 2 ;;
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
    local prompt="${1:-$(t sites.choose_default)}"
    local choice i

    get_sites_array
    if [[ ${#SITES_LIST[@]} -eq 0 ]]; then
        echo -e "\n   $(t sites.none_in "${BS_PATH_SITES}")"
        return 1
    fi

    echo ""
    for i in "${!SITES_LIST[@]}"; do
        printf '   %2d) %-32s (%s)\n' "$((i + 1))" "${SITES_LIST[$i]}" "$(get_site_type "${SITES_LIST[$i]}")"
    done
    echo ""
    read -r -p "   $(t sites.choose_suffix "${prompt}" "$(t common.cancel_hint)"): " choice

    [[ -z "$choice" || "$choice" == "0" ]] && return 1
    if ! [[ "$choice" =~ ^[0-9]+$ ]] || (( choice < 1 || choice > ${#SITES_LIST[@]} )); then
        echo "   $(t sites.invalid_number)"
        return 1
    fi

    SELECTED_SITE="${SITES_LIST[$((choice - 1))]}"
    return 0
}

function add_site() {
    clear
    echo -e "\n   $(t add.title)\n"

    local domain="" mode="full" path_site_from_links=""
    local db_name="" db_user="" db_password=""
    local ssl_lets_encrypt="N" ssl_lets_encrypt_www="N" ssl_lets_encrypt_email=""
    local redirect_to_https="N"
    local mode_choice base

    while true; do
        read -r -p "   $(t add.domain_prompt "$(t common.cancel_hint)"): " domain
        [[ "$domain" == "0" ]] && return
        if is_valid_domain "$domain"; then
            break
        fi
        echo "   $(t add.invalid_domain)"
    done

    if [ -e "${BS_PATH_SITES}/${domain}" ]; then
        echo -e "\n   $(t add.dir_exists "${BS_PATH_SITES}/${domain}")"
        press_any_key_to_return_menu
        return
    fi

    echo ""
    echo "   $(t add.mode_title)"
    echo "     1) $(t add.mode_full)"
    echo "     2) $(t add.mode_link)"
    read_by_def "   $(t add.mode_prompt)" mode_choice "1"

    case "$mode_choice" in
        2|link) mode="link" ;;
        *) mode="full" ;;
    esac

    if [[ "$mode" == "link" ]]; then
        read_by_def "   $(t add.source_prompt "${BS_PATH_DEFAULT_SITE}")" path_site_from_links "$BS_PATH_DEFAULT_SITE"
        if [ ! -d "${path_site_from_links}/bitrix" ]; then
            echo -e "\n   $(t add.no_bitrix "${path_site_from_links}")"
            press_any_key_to_return_menu
            return
        fi
    else
        base="$(sanitize_name "$domain" "$BS_MAX_CHAR_DB_NAME")"
        db_name="${base}"
        db_user="${base}_u"

        read_by_def "   $(t add.db_name_prompt "${db_name}")" db_name "$db_name"
        read_by_def "   $(t add.db_user_prompt "${db_user}")" db_user "$db_user"

        if db_exists "$db_name"; then
            echo -e "\n   $(t add.db_exists "${db_name}")"
            press_any_key_to_return_menu
            return
        fi
        if user_exists "$db_user"; then
            echo -e "\n   $(t add.user_exists "${db_user}")"
            press_any_key_to_return_menu
            return
        fi

        db_password="$(generate_password "$BS_CHAR_DB_PASSWORD")"
    fi

    echo ""
    if confirm_action "$(t add.confirm_ssl)"; then
        ssl_lets_encrypt="Y"
        while true; do
            read -r -p "   $(t le.email_prompt)" ssl_lets_encrypt_email
            if is_valid_email "$ssl_lets_encrypt_email"; then
                break
            fi
            echo "   $(t common.invalid_email)"
        done
        if confirm_action "$(t add.confirm_www "${domain}")"; then
            ssl_lets_encrypt_www="Y"
        fi
    fi

    if confirm_action "$(t add.confirm_redirect)"; then
        redirect_to_https="Y"
    fi

    echo ""
    echo "   $(t common.check_params)"
    printf '     %s %s\n' "$(pad_right "$(t add.param_domain)" 16)" "${domain}"
    printf '     %s %s\n' "$(pad_right "$(t add.param_mode)" 16)" "${mode}"
    if [[ "$mode" == "link" ]]; then
        printf '     %s %s\n' "$(pad_right "$(t add.param_core)" 16)" "${path_site_from_links}"
    else
        printf '     %s %s\n' "$(pad_right "$(t add.param_db)" 16)" "$(t add.param_db_value "${db_name}" "${db_user}")"
    fi
    if [[ -n "$ssl_lets_encrypt_email" ]]; then
        printf '     %s %s\n' "$(pad_right "$(t add.param_ssl)" 16)" "$(t add.param_ssl_value_full "${ssl_lets_encrypt}" "${ssl_lets_encrypt_email}" "${ssl_lets_encrypt_www}")"
    else
        printf '     %s %s\n' "$(pad_right "$(t add.param_ssl)" 16)" "$(t add.param_ssl_value "${ssl_lets_encrypt}")"
    fi
    printf '     %s %s\n' "$(pad_right "$(t add.param_redirect)" 16)" "${redirect_to_https}"
    echo ""

    if ! confirm_action "$(t add.confirm_create "${domain}")"; then
        echo "   $(t common.cancelled)"
        press_any_key_to_return_menu
        return
    fi

    action_create_site
}

function delete_site() {
    clear
    echo -e "\n   $(t del.title)\n"
    echo "   $(t del.warning)"

    if ! choose_site "$(t del.choose)"; then
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
    printf '   %s %s\n' "$(pad_right "$(t del.param_site)" 12)" "$site"
    printf '   %s %s\n' "$(pad_right "$(t del.param_dir)" 12)" "$full_path_site"
    printf '   %s %s\n' "$(pad_right "$(t del.param_type)" 12)" "$type"
    if [[ -n "$db_name" ]]; then
        printf '   %s %s\n' "$(pad_right "$(t del.param_db)" 12)" "$(t del.param_db_value "$db_name" "${db_user:-$(t common.unknown)}")"
    fi
    echo ""
    read -r -p "   $(t del.confirm_prompt "${site}")" confirm_text

    if [[ "$confirm_text" != "$site" ]]; then
        echo "   $(t common.cancelled)"
        press_any_key_to_return_menu
        return
    fi

    action_delete_site
}

function get_lets_encrypt_certificate() {
    clear
    echo -e "\n   $(t le.title)\n"
    echo "   $(t le.http01)"

    if ! choose_site "$(t le.choose)"; then
        press_any_key_to_return_menu
        return
    fi

    local domain="$SELECTED_SITE"
    local path_site="${BS_PATH_SITES}/${domain}"
    local email="" is_www="N" redirect_to_https="N"

    while true; do
        read -r -p "   $(t le.email_prompt)" email
        if is_valid_email "$email"; then
            break
        fi
        echo "   $(t common.invalid_email)"
    done

    if confirm_action "$(t add.confirm_www "${domain}")"; then
        is_www="Y"
    fi

    if confirm_action "$(t add.confirm_redirect)"; then
        redirect_to_https="Y"
    fi

    if ! confirm_action "$(t le.confirm "${domain}")"; then
        echo "   $(t common.cancelled)"
        press_any_key_to_return_menu
        return
    fi

    action_get_lets_encrypt_certificate
}

function enable_or_disable_redirect_http_to_https() {
    clear
    echo -e "\n   $(t redir.title)\n"

    if ! choose_site "$(t redir.choose)"; then
        press_any_key_to_return_menu
        return
    fi

    local site="$SELECTED_SITE"
    local path_site="${BS_PATH_SITES}/${site}"
    local action="enable"

    if [ -f "${path_site}/.htsecure" ]; then
        echo -e "\n   $(t redir.enabled)"
        if ! confirm_action "$(t redir.confirm_disable "${site}")"; then
            echo "   $(t common.cancelled)"
            press_any_key_to_return_menu
            return
        fi
        action="disable"
    else
        echo -e "\n   $(t redir.disabled)"
        if ! confirm_action "$(t redir.confirm_enable "${site}")"; then
            echo "   $(t common.cancelled)"
            press_any_key_to_return_menu
            return
        fi
        action="enable"
    fi

    action_enable_or_disable_redirect_http_to_https
}

function change_php_version() {
    clear
    echo -e "\n   $(t php.title)\n"

    get_current_version_php
    get_available_version_php

    local new_version_php
    read -r -p "   $(t php.version_prompt "$(t common.cancel_hint)"): " new_version_php

    [[ -z "$new_version_php" || "$new_version_php" == "0" ]] && return

    local version_allowed=0
    local v
    for v in "${BS_PHP_SUPPORTED_VERSIONS[@]}"; do
        [[ "$new_version_php" == "$v" ]] && version_allowed=1 && break
    done
    if [[ $version_allowed -eq 0 ]]; then
        echo -e "\n   $(t php.unsupported "${new_version_php}" "${BS_PHP_SUPPORTED_VERSIONS[*]}")"
        press_any_key_to_return_menu
        return
    fi

    local candidate
    candidate="$(apt-cache policy "php${new_version_php}" 2>/dev/null | awk '/^[[:space:]]*Candidate:/{print $2; exit}')"
    if [[ -z "$candidate" || "$candidate" == "(none)" ]]; then
        echo -e "\n   $(t php.unavailable "${new_version_php}")"
        press_any_key_to_return_menu
        return
    fi

    if ! confirm_action "$(t php.confirm "${new_version_php}")"; then
        echo "   $(t common.cancelled)"
        press_any_key_to_return_menu
        return
    fi

    action_change_php_version "$new_version_php"
}

function settings_smtp_sites() {
    local command=""
    until [[ "$command" == "0" ]]; do
        clear
        echo -e "\n   $(t smtp.title)\n"
        echo "     1) $(t smtp.item_site)"
        echo "     2) $(t smtp.item_default)"
        echo "     3) $(t smtp.item_show)"
        echo "     0) $(t common.back_main)"
        echo ""
        echo -n "   $(t common.enter_command) "
        read -r command

        case "$command" in
            1) smtp_configure_account "site" ;;
            2) smtp_configure_account "default" ;;
            3) smtp_show_accounts ;;
            0|z|q) return ;;
            *) echo "   $(t common.unknown_command_short)"; sleep 2 ;;
        esac
    done
}

function smtp_show_accounts() {
    clear
    echo -e "\n   $(t smtp.saved "${BS_SMTP_FILE_SITES_CONFIG}")\n"

    if [ ! -f "$BS_SMTP_FILE_SITES_CONFIG" ]; then
        echo "   $(t smtp.no_file)"
    else
        local accounts
        accounts="$(grep -E '^account[[:space:]]+' "$BS_SMTP_FILE_SITES_CONFIG" 2>/dev/null | awk '{print $2}' | sort -u)"
        if [ -z "$accounts" ]; then
            echo "   $(t smtp.no_accounts)"
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
    echo -e "\n   $(t smtp.configure_title)\n"

    if [[ "$mode" == "site" ]]; then
        if ! choose_site "$(t smtp.choose_site)"; then
            press_any_key_to_return_menu
            return
        fi
        account_name="$SELECTED_SITE"
    else
        account_name="default"
    fi

    echo ""
    echo "   $(t smtp.account "${account_name}")"
    echo "   $(t smtp.account_note)"
    echo ""

    local smtp_host="" smtp_port="587" email_from="" is_auth="Y"
    local authentication_method="auto" login="" password="" enable_TLS="Y"

    while true; do
        read -r -p "   $(t smtp.host_prompt)" smtp_host
        [[ -n "$smtp_host" ]] && break
    done

    read_by_def "   $(t smtp.port_prompt)" smtp_port "587"

    local default_from="noreply@${account_name}"
    [[ "$account_name" == "default" ]] && default_from="noreply@localhost"
    read_by_def "   $(t smtp.from_prompt "${default_from}")" email_from "$default_from"

    if confirm_action "$(t smtp.confirm_auth)"; then
        is_auth="Y"
        read_by_def "   $(t smtp.auth_method_prompt)" authentication_method "auto"
        read -r -p "   $(t smtp.login_prompt)" login
        read -r -s -p "   $(t smtp.password_prompt)" password
        echo ""
    else
        is_auth="N"
    fi

    if ! confirm_action "$(t smtp.confirm_tls)"; then
        enable_TLS="N"
    fi

    echo ""
    echo "   $(t common.check_params)"
    printf '     %s %s\n' "$(pad_right "$(t smtp.param_account)" 14)" "${account_name}"
    printf '     %s %s\n' "$(pad_right "$(t smtp.param_server)" 14)" "${smtp_host}:${smtp_port}"
    printf '     %s %s\n' "$(pad_right "$(t smtp.param_from)" 14)" "${email_from}"
    if [[ "$is_auth" == "Y" ]]; then
        printf '     %s %s\n' "$(pad_right "$(t smtp.param_auth)" 14)" "$(t smtp.param_auth_on "${login}" "${authentication_method}")"
    else
        printf '     %s %s\n' "$(pad_right "$(t smtp.param_auth)" 14)" "$(t smtp.param_auth_off)"
    fi
    printf '     %s %s\n' "$(pad_right "$(t smtp.param_tls)" 14)" "${enable_TLS}"
    echo ""

    if ! confirm_action "$(t smtp.confirm_save)"; then
        echo "   $(t common.cancelled)"
        press_any_key_to_return_menu
        return
    fi

    action_settings_smtp_site
}

function install_postgres() {
    clear
    echo -e "\n   $(t postgres.title)\n"
    echo "   $(t postgres.note)"
    echo "   $(t postgres.preset_note)"
    echo ""
    echo "     1) $(t postgres.install)"
    echo "     2) $(t postgres.delete)"
    echo "     0) $(t common.back)"
    echo -n "   $(t common.enter_command) "
    local command
    read -r command

    case "$command" in
        1)
            if confirm_action "$(t postgres.confirm_install "${BS_POSTGRES_DATABASE}")"; then
                action_install_or_delete_postgresql install
            fi
            ;;
        2)
            echo -e "\n   ${C_RED}$(t postgres.delete_warning)${C_RESET}"
            if confirm_action "$(t postgres.confirm_delete)"; then
                action_install_or_delete_postgresql delete
            fi
            ;;
    esac
}

function install_sphinx() {
    clear
    echo -e "\n   $(t sphinx.title)\n"
    echo "     1) $(t sphinx.install)"
    echo "     2) $(t sphinx.delete)"
    echo "     0) $(t common.back)"
    echo -n "   $(t common.enter_command) "
    local command
    read -r command

    case "$command" in
        1)
            if confirm_action "$(t sphinx.confirm_install "${BS_SPHINX_PACKAGE}")"; then
                action_install_or_delete_sphinx install
            fi
            ;;
        2)
            if confirm_action "$(t sphinx.confirm_delete)"; then
                action_install_or_delete_sphinx delete
            fi
            ;;
    esac
}

function install_netdata() {
    clear
    echo -e "\n   $(t netdata.title)\n"
    echo "     1) $(t netdata.install)"
    echo "     2) $(t netdata.delete)"
    echo "     0) $(t common.back)"
    echo -n "   $(t common.enter_command) "
    local command
    read -r command

    case "$command" in
        1)
            if confirm_action "$(t netdata.confirm_install)"; then
                action_install_or_delete_netdata install
            fi
            ;;
        2)
            if confirm_action "$(t netdata.confirm_delete)"; then
                action_install_or_delete_netdata delete
            fi
            ;;
    esac
}

function install_file_conversion_server() {
    clear
    echo -e "\n   $(t conv.title)\n"
    echo "   $(t conv.note)"
    echo "   $(t conv.need_site)"
    echo ""
    echo "     1) $(t conv.install)"
    echo "     2) $(t conv.delete)"
    echo "     0) $(t common.back)"
    echo -n "   $(t common.enter_command) "
    local command
    read -r command
    local action=""

    case "$command" in
        1) action="install" ;;
        2) action="delete" ;;
        *) return ;;
    esac

    if ! choose_site "$(t conv.choose)"; then
        press_any_key_to_return_menu
        return
    fi

    domain="$SELECTED_SITE"
    full_path_site="${BS_PATH_SITES}/${domain}"

    local action_label
    case "$action" in
        install) action_label="$(t conv.action_install)" ;;
        *)       action_label="$(t conv.action_delete)" ;;
    esac

    if ! confirm_action "$(t conv.confirm "${action_label}" "${domain}")"; then
        echo "   $(t common.cancelled)"
        press_any_key_to_return_menu
        return
    fi

    action_install_or_delete_file_conversion_server "$action"
}

# Приложения из стандартного репозитория: группа cms (CMS Bitrix) или b24 (CRM/Битрикс24)
function apps_menu() {
    local group="${1:-cms}"
    local title list_key group_key
    case "$group" in
        cms) title="$(t apps.title_cms)"; list_key="apps.cms_list"; group_key="apps.group_cms" ;;
        b24) title="$(t apps.title_b24)"; list_key="apps.b24_list"; group_key="apps.group_b24" ;;
        *) return ;;
    esac

    clear
    echo -e "\n   ${title}\n"
    echo "   $(t apps.note)"
    echo "   $(t "$list_key")"
    echo ""
    echo "     1) $(t apps.install)"
    echo "     2) $(t apps.delete)"
    echo "     0) $(t common.back)"
    echo -n "   $(t common.enter_command) "
    local command
    read -r command

    case "$command" in
        1)
            if confirm_action "$(t apps.confirm_install "$(t "$group_key")")"; then
                action_install_or_delete_apps "$group" install
            fi
            ;;
        2)
            if confirm_action "$(t apps.confirm_delete "$(t "$group_key")")"; then
                action_install_or_delete_apps "$group" delete
            fi
            ;;
        *) return ;;
    esac
}

# memcached: сервер кэша + PHP-расширение
function install_memcached() {
    clear
    echo -e "\n   $(t memcached.title)\n"
    echo "   $(t memcached.note)"
    echo "   $(t memcached.listening)"
    echo ""
    echo "     1) $(t memcached.install)"
    echo "     2) $(t memcached.delete)"
    echo "     0) $(t common.back)"
    echo -n "   $(t common.enter_command) "
    local command
    read -r command

    case "$command" in
        1)
            if confirm_action "$(t memcached.confirm_install)"; then
                action_install_or_delete_memcached install
            fi
            ;;
        2)
            if confirm_action "$(t memcached.confirm_delete)"; then
                action_install_or_delete_memcached delete
            fi
            ;;
        *) return ;;
    esac
}

# Скрипт восстановления restore.php: размещение/удаление только по запросу
function manage_restore_script() {
    clear
    echo -e "\n   $(t restore.title)\n"
    echo -e "   ${C_RED}$(t restore.note)${C_RESET}"
    echo "   $(t restore.note2)"
    echo ""
    echo "     1) $(t restore.place)"
    echo "     2) $(t restore.remove)"
    echo "     0) $(t common.back)"
    echo -n "   $(t common.enter_command) "
    local command
    read -r command

    local action=""
    case "$command" in
        1) action="place" ;;
        2) action="remove" ;;
        *) return ;;
    esac

    if ! choose_site "$(t restore.choose)"; then
        press_any_key_to_return_menu
        return
    fi

    if [ "$action" = "place" ]; then
        if ! confirm_action "$(t restore.confirm_place "${SELECTED_SITE}")"; then
            echo "   $(t common.cancelled)"
            press_any_key_to_return_menu
            return
        fi
    else
        if ! confirm_action "$(t restore.confirm_remove "${SELECTED_SITE}")"; then
            echo "   $(t common.cancelled)"
            press_any_key_to_return_menu
            return
        fi
    fi

    action_manage_restore_script "$action"
}

function show_help() {
    clear
    i18n_help_text

    press_any_key_to_return_menu
}

function update_server() {
    clear
    if ! confirm_action "$(t upd.confirm_pkgs)"; then
        echo "   $(t common.cancelled)"
        press_any_key_to_return_menu
        return
    fi
    action_update_server
}

function update_menu() {
    clear
    if ! confirm_action "$(t upd.confirm_menu)"; then
        echo "   $(t common.cancelled)"
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
    read -r -p "   $(t server.confirm_reboot)" answer
    case $answer in
        [Yy]* ) reboot; break;;
        [Nn]* ) break;;
        * ) echo "   $(t server.enter_yn)";;
    esac
  done
}

function power_off_server() {
  clear
  while true; do
    read -r -p "   $(t server.confirm_poweroff)" answer
    case $answer in
        [Yy]* ) poweroff; break;;
        [Nn]* ) break;;
        * ) echo "   $(t server.enter_yn)";;
    esac
  done
}
