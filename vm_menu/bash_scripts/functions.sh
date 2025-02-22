#!/bin/bash
dir="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

source "$dir/utils.sh"
source "$dir/actions.sh"

function do_load_menu() {
  action_check_new_version_menu &
  load_bitrix_vm_version
  if [ "$BS_SHOW_IP_CURRENT_SERVER_IN_MENU" = true ]; then
    get_ip_current_server
  fi
}

main_menu(){
    command=""
    until [[ "$command" == "0" ]]; do
    clear

    do_load_menu

    local msg_menu_emulate_bitrix_vm="Enable Bitrix VM emulation"
    if [[ -n "${!BS_VAR_NAME_BVM}" ]]; then
      msg_menu_emulate_bitrix_vm="Disable Bitrix VM emulation (version: ${!BS_VAR_NAME_BVM})"
    fi

    local msg_new_version_menu=""
    local update_menu_action=""
    if [ -f "/tmp/new_version_menu.tmp" ]; then
      local nv
      nv=$(cat /tmp/new_version_menu.tmp)
      msg_new_version_menu="\e[33m          New version of Debian 11/Debian 12 BitrixVM available.
          (Current version: ${BS_VERSION_MENU} → New version: ${nv}) 
          Please visit \e]8;;${BS_REPOSITORY_URL}\a${BS_REPOSITORY_URL}\e]8;;\a 
          or enter \"update_menu\" to update your menu.\n\e[0m"
      update_menu_action="Enter \"update_menu\" to update your menu."
    fi

    echo -e "\n\n          Welcome to the Debian 11/Debian 12 BitrixVM environment, version ${BS_VERSION_MENU}\n\n"
    if [ "$BS_SHOW_IP_CURRENT_SERVER_IN_MENU" = true ]; then
      echo -e "          Current server IP: ${CURRENT_SERVER_IP}\n"
    fi
    echo -e "${msg_new_version_menu}"
    echo "          1) List site directories"
    echo "          2) Add a site"
    echo "          3) Configure Let's Encrypt certificate"
    echo "          W) Get Let's Encrypt wildcard certificate";
    echo "          4) Enable or disable HTTP to HTTPS redirect"
    echo "          5) ${msg_menu_emulate_bitrix_vm}"
    echo "          6) Change PHP version"
    echo "          7) Configure SMTP settings"
    echo "          8) Install extensions"
    echo "          9) Update the server"
    echo "          R) Restart the server"
    echo "          P) Shut down the server"
    echo "          DELETE_SITE) Delete a site"
    if [ -n "${update_menu_action}" ]; then
      echo -e "\e[33m             ${update_menu_action}\e[0m"
    fi
    echo "          0) Exit"
    echo -e "\n\n"
    echo -n "Enter command: "
    read -r command

    case "$command" in
     "1") show_sites_dirs ;;
     "2") add_site ;;
     "3") get_lets_encrypt_certificate ;;
     "W") get_lets_encrypt_wildcard_certificate ;;
     "4") enable_or_disable_redirect_http_to_https ;;
     "5") action_emulate_bitrix_vm ;;
     "6") change_php_version ;;
     "7") settings_smtp_sites ;;
     "8") menu_install_extensions ;;
     "9") update_server ;;
     "R") reboot_server ;;
     "P") power_off_server ;;
     "DELETE_SITE") delete_site ;;
     "update_menu") update_menu ;;
     0|z) exit ;;
     *) echo "Error: Unknown command." ;;
    esac
    done
}

menu_install_extensions(){
    command=""
    until [[ "$command" == "0" ]]; do
    clear

    echo -e "\n          Menu -> Installing Extensions:\n"
    echo "          1) Install/Delete Sphinx"
    echo "          2) Install/Delete File Conversion Server (Transformer)"
    echo "          3) Install/Delete Netdata"
    echo "          0) Return to main menu"
    echo -e "\n\n"
    echo -n "Enter command: "
    read -r command

    case "$command" in
     "1") install_sphinx ;;
     "2") install_file_conversion_server ;;
     "3") install_netdata ;;
     0|z) main_menu ;;
     *) echo "Error: Unknown command." ;;
    esac
    done
}

# Function to sanitize and limit the length of names
sanitize_name() {
    local input="$1"
    local max_length="$2"
    local sanitized
    sanitized=$(echo "$input" | sed 's/-//g' | sed 's/\./_/g' | "${dir_helpers}/perl/translate.pl")
    sanitized=$(cut -c-"$max_length" <<< "$sanitized")
    sanitized=${sanitized%_}
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
