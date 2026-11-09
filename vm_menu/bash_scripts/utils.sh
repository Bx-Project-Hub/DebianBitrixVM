#!/bin/bash

declare -A ARR_ALL_DIR_SITES_DATA

# Генерация пароля.
# Символы подобраны так, чтобы пароль безопасно проходил через shell,
# SQL, .settings.php и .my.cnf: без кавычек, обратных слэшей, $, #, !, &, ;, |, пробелов.
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

# Определение ОС (Debian 12/13) для шапки меню и проверок совместимости.
function get_os_info() {
  OS_NAME=""
  OS_VERSION=""
  OS_CODENAME=""

  if [ -f /etc/os-release ]; then
    # shellcheck disable=SC1091
    . /etc/os-release
    OS_NAME="${NAME:-Debian}"
    OS_VERSION="${VERSION_ID:-}"
    OS_CODENAME="${VERSION_CODENAME:-}"
  fi

  OS_DESCRIPTION="${OS_NAME} ${OS_VERSION} (${OS_CODENAME:-unknown})"
}

# Проверка, что запущено на поддерживаемой версии Debian.
function check_supported_os() {
  get_os_info
  local v
  for v in "${BS_SUPPORTED_OS_VERSIONS[@]}"; do
    if [[ "${OS_VERSION}" == "$v" ]]; then
      return 0
    fi
  done
  return 1
}

# Массив каталогов сайтов (публичный, для меню).
# В отличие от find -type d -o -type l, учитывает приоритет операторов и не ломается на пробелах.
function get_sites_array() {
  SITES_LIST=()

  [ -d "$BS_PATH_SITES" ] || return 0

  local entry name
  while IFS= read -r entry; do
    name="$(basename "$entry")"
    [[ "$name" == "." || "$name" == ".." ]] && continue
    [[ "$name" == .* ]] && continue

    local excluded=0
    local ex
    for ex in "${BS_EXCLUDED_DIRS_SITES[@]}"; do
      [[ "$name" == "$ex" ]] && excluded=1 && break
    done
    [[ $excluded -eq 1 ]] && continue

    SITES_LIST+=("$name")
  done < <(find "$BS_PATH_SITES" -mindepth 1 -maxdepth 1 \( -type d -o -type l \) | sort)
}

# Тип сайта: full (ядро) или link (символические ссылки на общее ядро).
function get_site_type() {
  local site="$1"
  local path_site="$BS_PATH_SITES/$site"

  if [ -L "$path_site/local" ] || [ -L "$path_site/bitrix" ]; then
    printf 'link'
  else
    printf 'full'
  fi
}

# Чтение имени БД и пользователя из .settings.php сайта.
function get_site_db_data() {
  local path_site="$1"
  SITE_DB_NAME=""
  SITE_DB_USER=""

  if [ -f "$path_site/.settings.php" ] && command -v php >/dev/null 2>&1; then
    # shellcheck disable=SC2016
    SITE_DB_NAME="$(php -r '$s = include $argv[1]; echo $s["connections"]["value"]["default"]["database"] ?? "";' "$path_site/.settings.php" 2>/dev/null)"
    # shellcheck disable=SC2016
    SITE_DB_USER="$(php -r '$s = include $argv[1]; echo $s["connections"]["value"]["default"]["login"] ?? "";' "$path_site/.settings.php" 2>/dev/null)"
  fi
}

list_sites(){
  ARR_ALL_DIR_SITES_DATA=()
  ARR_ALL_DIR_SITES=()
  echo -e "   $(t sites.in_path "${BS_PATH_SITES}")\n"

  fill_array() {
    local index=0
    local tmp_dir
    get_sites_array
    for tmp_dir in "${SITES_LIST[@]}"; do
      ARR_ALL_DIR_SITES+=("$tmp_dir")
      ARR_ALL_DIR_SITES_DATA["${index}_dir"]="$tmp_dir"
      ARR_ALL_DIR_SITES_DATA[$index,is_default]="$(t common.no)"
      ARR_ALL_DIR_SITES_DATA[$index,is_https]="$(t common.no)"
      ARR_ALL_DIR_SITES_DATA[$index,type]="$(get_site_type "$tmp_dir")"
      ARR_ALL_DIR_SITES_DATA[$index,doc_root]="$BS_PATH_SITES/$tmp_dir"

      if [[ "$tmp_dir" == "$BS_DEFAULT_SITE_NAME" ]]; then
        ARR_ALL_DIR_SITES_DATA[$index,is_default]="$(t common.yes)"
      fi

      if [[ -f "$BS_PATH_SITES/$tmp_dir/.htsecure" ]]; then
        ARR_ALL_DIR_SITES_DATA[$index,is_https]="$(t common.yes)"
      fi

      ((index++))
    done

    TOTAL_SITES="$index"
  }

  print_line() {
    printf "   +"
    for _ in {1..26}; do printf "-"; done
    printf "+"
    for _ in {1..12}; do printf "-"; done
    printf "+"
    for _ in {1..10}; do printf "-"; done
    printf "+"
    for _ in {1..12}; do printf "-"; done
    printf "+"
    for _ in {1..44}; do printf "-"; done
    printf "+\n"
  }

  print_table() {
    print_line
    printf "   | %-26s | %-12s | %-10s | %-12s | %-44s |\n" "$(t sites.col_dir)" "$(t sites.col_type)" "$(t sites.col_default)" "$(t sites.col_https)" "$(t sites.col_docroot)"
    print_line

    local index=0
    while [[ -n "${ARR_ALL_DIR_SITES_DATA["${index}_dir"]:-}" ]]; do
      printf "   | %-26s | %-12s | %-10s | %-12s | %-44s |\n" \
        "${ARR_ALL_DIR_SITES_DATA["${index}_dir"]}" \
        "${ARR_ALL_DIR_SITES_DATA[$index,type]:-}" \
        "${ARR_ALL_DIR_SITES_DATA[$index,is_default]:-}" \
        "${ARR_ALL_DIR_SITES_DATA[$index,is_https]:-}" \
        "${ARR_ALL_DIR_SITES_DATA[$index,doc_root]:-}"
      print_line
      ((index++))
    done

    if [[ ${TOTAL_SITES:-0} -eq 0 ]]; then
      echo "   $(t sites.none)"
    else
      echo -e "\n   $(t sites.type_note)"
    fi
  }

  fill_array
  print_table
  get_current_version_php
}

press_any_key_to_return_menu(){
    echo -e "\n";
    read -r -p "   $(t common.press_enter)" _
}

# Запрос подтверждения действия (y/n, по умолчанию — нет).
function confirm_action() {
    local message="${1:-$(t common.confirm_default)}"
    local answer
    read -r -p "   ${message} (y/N): " answer
    [[ "$answer" =~ ^[YyNn]?$ ]] || return 1
    [[ "$answer" =~ ^[Yy]$ ]]
}

# Проверка, что меню запущено от root.
function require_root() {
    if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
        echo "$(t common.need_root)" >&2
        echo "$(t common.need_root_hint)" >&2
        exit 1
    fi
}

read_by_def(){
    local message=${1}   
    local var_name=${2}  
    local def_val=${3}   
    local user_input     

    read -r -p "$message" user_input

    if [[ -z "$user_input" ]]; then
        printf -v "$var_name" "%s" "$def_val"
    else
        printf -v "$var_name" "%s" "$user_input"
    fi
}

function load_bitrix_vm_version() {
  unset $BS_VAR_NAME_BVM
  if test -f "$BS_VAR_PATH_FILE_BVM"; then
      source "${BS_VAR_PATH_FILE_BVM}"
  fi
}

function get_interfaces() {
  ip -o -4 addr list | grep -v ' lo ' | awk '{print $2, $4}'
}

function get_ip_current_server() {
  while true; do
    interfaces=$(get_interfaces)
    if [ -n "$interfaces" ]; then
        break
    fi
  done

  CURRENT_SERVER_IP="$(t status.interfaces)"

  while read -r line; do
      iface=$(echo "$line" | awk '{print $1}')
      ip=$(echo "$line" | awk '{print $2}' | cut -d'/' -f1)
      CURRENT_SERVER_IP+="          $iface → $ip\n"
  done <<< "$interfaces"
}

############################################################
# Цвета и панель состояния сервера (шапка меню)
############################################################

# ANSI-цвета. Отключаются, если вывод не в терминал, задан NO_COLOR
# или в конфигурации BS_USE_COLOR=false.
if [ -t 1 ] && [ -z "${NO_COLOR:-}" ] && [ "${BS_USE_COLOR:-true}" = true ]; then
    C_RESET=$'\e[0m'
    C_BOLD=$'\e[1m'
    C_DIM=$'\e[2m'
    C_RED=$'\e[31m'
    C_GREEN=$'\e[32m'
    C_YELLOW=$'\e[33m'
    C_BLUE=$'\e[34m'
    C_MAGENTA=$'\e[35m'
    C_CYAN=$'\e[36m'
    C_GREY=$'\e[90m'
else
    C_RESET=""; C_BOLD=""; C_DIM=""; C_RED=""; C_GREEN=""
    C_YELLOW=""; C_BLUE=""; C_MAGENTA=""; C_CYAN=""; C_GREY=""
fi

# Цвет по порогу: <70 — зелёный, 70–89 — жёлтый, >=90 — красный.
function severity_color() {
    local value="${1:-0}"
    [[ "$value" =~ ^[0-9]+$ ]] || { printf '%s' "$C_GREEN"; return; }
    if (( value >= 90 )); then
        printf '%s' "$C_RED"
    elif (( value >= 70 )); then
        printf '%s' "$C_YELLOW"
    else
        printf '%s' "$C_GREEN"
    fi
}

function get_cpu_count() {
    local n
    n="$(nproc 2>/dev/null || getconf _NPROCESSORS_ONLN 2>/dev/null)"
    printf '%s' "${n:-1}"
}

# Три значения load average: "0.14 0.09 0.05"
function get_load_average() {
    [ -r /proc/loadavg ] || { printf '%s %s %s' "$(t common.na)" "$(t common.na)" "$(t common.na)"; return; }
    awk '{print $1, $2, $3}' /proc/loadavg
}

# Загрузка CPU в процентах за окно BS_CPU_SAMPLE_MS (по разнице счётчиков /proc/stat).
# Пустая строка, если замер невозможен.
function get_cpu_usage_percent() {
    [ -r /proc/stat ] || return 0
    local sample_ms="${BS_CPU_SAMPLE_MS:-200}"
    local first second
    first="$(awk '/^cpu /{busy=$2+$3+$4+$7+$8+$9; idle=$5+$6; print busy, busy+idle}' /proc/stat)"
    if (( sample_ms > 0 )); then
        sleep "$(awk -v ms="$sample_ms" 'BEGIN{printf "%.3f", ms/1000}')"
    fi
    second="$(awk '/^cpu /{busy=$2+$3+$4+$7+$8+$9; idle=$5+$6; print busy, busy+idle}' /proc/stat)"

    awk -v a="$first" -v b="$second" 'BEGIN{
        split(a, x, " "); split(b, y, " ");
        dt = y[2] - x[2]; di = y[1] - x[1];
        if (dt <= 0) exit;
        printf "%d", (di * 100) / dt
    }'
}

# Память: "1.2 / 5.8 ГБ (21%)"
function get_memory_usage() {
    [ -r /proc/meminfo ] || { printf '%s' "$(t common.na)"; return; }
    local gb
    gb="$(t common.gb)"
    awk -v na="$(t common.na)" -v gb="$gb" '/^MemTotal:/{t=$2} /^MemAvailable:/{a=$2} END{
        if (t == 0) { printf "%s", na; exit }
        used = t - a;
        printf "%.1f / %.1f %s (%d%%)", used/1048576, t/1048576, gb, (used*100)/t
    }' /proc/meminfo
}

# Процент занятости корневого раздела
function get_disk_usage_percent_root() {
    df -P / 2>/dev/null | awk 'NR==2{gsub("%","",$5); print $5}'
}

# Диск: "8.4G / 28G (30%)"
function get_disk_usage_root() {
    df -Ph / 2>/dev/null | awk 'NR==2{printf "%s / %s (%s)", $3, $2, $5}'
}

# Аптайм: "3 ч 28 мин"
function get_uptime_short() {
    local s d h m
    s="$(awk '{print int($1)}' /proc/uptime 2>/dev/null)"
    [ -z "$s" ] && { printf '%s' "$(t common.na)"; return; }
    d=$(( s / 86400 )); h=$(( (s % 86400) / 3600 )); m=$(( (s % 3600) / 60 ))
    if (( d > 0 )); then
        t common.dhms "$d" "$h" "$m"
    elif (( h > 0 )); then
        t common.hm "$h" "$m"
    else
        t common.m "$m"
    fi
}

# Повторить символ N раз (устойчиво к N=0 и к многобайтным символам вроде «─»)
function repeat_char() {
    local n="${1:-0}" ch="${2:-─}" buf=""
    (( n <= 0 )) && return 0
    printf -v buf '%*s' "$n" ""
    printf '%s' "${buf// /$ch}"
}

# Строка панели: $1 — «чистый» текст (для расчёта ширины), $2 — цветной вариант
function status_panel_row() {
    local plain="$1" colored="${2:-$1}"
    local width="${BS_STATUS_PANEL_WIDTH:-52}"
    local inner=$(( width - 2 ))
    local pad=$(( inner - ${#plain} ))
    (( pad < 0 )) && pad=0
    printf '   %s│%s %s%*s %s│%s\n' "$C_DIM" "$C_RESET" "$colored" "$pad" "" "$C_DIM" "$C_RESET"
}

# Панель состояния сервера. Данные собираются в do_load_menu (collect_status_panel).
function render_status_panel() {
    [ "${BS_STATUS_PANEL:-true}" = true ] || return 0
    [ -n "${STATUS_PANEL_READY:-}" ] || return 0

    panel_top "$(t status.title)"

    # Подписи выравниваются по ширине 11 символов: plain-строка нужна для расчёта
    # ширины панели, colored — тот же текст с ANSI-цветами.
    local l_load l_cpu l_mem l_disk l_uptime
    printf -v l_load '%-11s' "$(t status.load)"
    printf -v l_cpu '%-11s' "CPU"
    printf -v l_mem '%-11s' "$(t status.mem)"
    printf -v l_disk '%-11s' "$(t status.disk)"
    printf -v l_uptime '%-11s' "$(t status.uptime)"

    local load_plain="${l_load}${STATUS_LOAD}   ${STATUS_CPU_COUNT} CPU"
    status_panel_row "$load_plain" \
        "${C_GREY}${l_load}${C_RESET}${C_BOLD}${STATUS_LOAD}${C_RESET}   ${C_GREY}${STATUS_CPU_COUNT} CPU${C_RESET}"

    local cpu_plain="${l_cpu}${STATUS_CPU_PCT}%"
    status_panel_row "$cpu_plain" \
        "${C_GREY}${l_cpu}${C_RESET}$(severity_color "$STATUS_CPU_PCT")${C_BOLD}${STATUS_CPU_PCT}%${C_RESET}"

    local mem_plain="${l_mem}${STATUS_MEM}"
    status_panel_row "$mem_plain" \
        "${C_GREY}${l_mem}${C_RESET}$(severity_color "${STATUS_MEM_PCT:-0}")${STATUS_MEM}${C_RESET}"

    local disk_plain="${l_disk}${STATUS_DISK}"
    status_panel_row "$disk_plain" \
        "${C_GREY}${l_disk}${C_RESET}$(severity_color "${STATUS_DISK_PCT:-0}")${STATUS_DISK}${C_RESET}"

    local uptime_plain="${l_uptime}${STATUS_UPTIME}"
    status_panel_row "$uptime_plain" \
        "${C_GREY}${l_uptime}${C_RESET}${STATUS_UPTIME}"

    panel_bottom
}

# Собираем данные панели (вызывается из do_load_menu раз за отрисовку).
function collect_status_panel() {
    [ "${BS_STATUS_PANEL:-true}" = true ] || return 0

    STATUS_LOAD="$(get_load_average)"
    STATUS_CPU_COUNT="$(get_cpu_count)"
    STATUS_CPU_PCT="$(get_cpu_usage_percent)"
    [ -n "$STATUS_CPU_PCT" ] || STATUS_CPU_PCT="$(t common.na)"

    STATUS_MEM="$(get_memory_usage)"
    STATUS_MEM_PCT="$(printf '%s' "$STATUS_MEM" | sed -n 's/.*(\([0-9]\+\)%).*/\1/p')"

    STATUS_DISK="$(get_disk_usage_root)"
    [ -n "$STATUS_DISK" ] || STATUS_DISK="$(t common.na)"
    STATUS_DISK_PCT="$(get_disk_usage_percent_root)"

    STATUS_UPTIME="$(get_uptime_short)"

    STATUS_PANEL_READY=1
}

############################################################
# Панель «Установлено»: сайты, сертификаты, push&pull, дополнения
############################################################

# Срок действия сертификата Let's Encrypt для домена — в днях. Пусто, если нет.
function get_site_ssl_days() {
    local domain="$1"
    local pem="/etc/letsencrypt/live/${domain}/cert.pem"

    [ -r "$pem" ] || return 0

    local end_date end_epoch now_epoch
    end_date="$(openssl x509 -in "$pem" -noout -enddate 2>/dev/null | cut -d= -f2)"
    [ -n "$end_date" ] || return 0

    end_epoch="$(date -d "$end_date" +%s 2>/dev/null)" || return 0
    now_epoch="$(date +%s)"

    printf '%s' "$(( (end_epoch - now_epoch) / 86400 ))"
}

# Цвет по остатку дней сертификата
function ssl_days_color() {
    local days="${1:-}"
    [[ "$days" =~ ^-?[0-9]+$ ]] || { printf '%s' "$C_GREY"; return; }
    if (( days < 14 )); then
        printf '%s' "$C_RED"
    elif (( days < 30 )); then
        printf '%s' "$C_YELLOW"
    else
        printf '%s' "$C_GREEN"
    fi
}

# Версия push-server из package.json установленного пакета
function get_push_server_version() {
    local f="/opt/push-server/package.json"
    [ -r "$f" ] || return 0
    awk -F'"' '/"version"/{print $4; exit}' "$f" 2>/dev/null
}

# Установленные дополнения (по наличию unit-файлов)
function get_installed_addons() {
    local addons=()
    local units
    units="$(systemctl list-unit-files --no-legend 2>/dev/null)"

    printf '%s' "$units" | grep -q '^sphinxsearch\.service' && addons+=("Sphinx")
    printf '%s' "$units" | grep -q '^netdata\.service'      && addons+=("Netdata")
    if printf '%s' "$units" | grep -q '^rabbitmq-server\.service'; then
        addons+=("RabbitMQ")
    fi

    if (( ${#addons[@]} == 0 )); then
        printf ''
    else
        # Внимание: ${array[*]} с многосимвольным IFS склеивает только по первому
        # символу (","), поэтому собираем строку вручную — с пробелом после запятой.
        local out="" item
        for item in "${addons[@]}"; do
            [ -n "$out" ] && out+=", "
            out+="$item"
        done
        printf '%s' "$out"
    fi
}

# Собираем данные панели «Установлено»
function collect_environment_panel() {
    [ "${BS_STATUS_PANEL_SITES:-true}" = true ] || return 0

    local max_sites="${BS_STATUS_MAX_SITES:-5}"

    get_sites_array
    ENV_SITES_TOTAL="${#SITES_LIST[@]}"
    ENV_SITES_LINES=()

    local site type ssl_days shown=0 is_default
    for site in "${SITES_LIST[@]}"; do
        (( shown >= max_sites )) && break
        type="$(get_site_type "$site")"
        ssl_days="$(get_site_ssl_days "$site")"
        is_default=0
        [ "$site" = "${BS_DEFAULT_SITE_NAME:-}" ] && is_default=1
        ENV_SITES_LINES+=("${site}|${type}|${ssl_days}|${is_default}")
        shown=$(( shown + 1 ))
    done
    ENV_SITES_REST=$(( ENV_SITES_TOTAL - shown ))

    local push_version push_state
    push_version="$(get_push_server_version)"
    push_state="$(get_service_state "$BS_PUSH_SERVER_SERVICE_NAME")"
    ENV_PUSH="${push_version:-?}|${push_state}"

    ENV_ADDONS="$(get_installed_addons)"

    ENV_PANEL_READY=1
}

# Универсальный верх панели
function panel_top() {
    local title="$1"
    local width="${BS_STATUS_PANEL_WIDTH:-52}"
    local fill=$(( width - ${#title} ))
    (( fill < 2 )) && fill=2
    local left=$(( fill / 2 ))
    local right=$(( fill - left ))

    printf '   %s┌%s%s%s%s%s%s┐%s\n' \
        "$C_DIM" "$(repeat_char "$left")" "$C_RESET" \
        "${C_BOLD}${C_CYAN}${title}${C_RESET}" \
        "$C_DIM" "$(repeat_char "$right")" "$C_RESET"
}

# Универсальный низ панели
function panel_bottom() {
    local width="${BS_STATUS_PANEL_WIDTH:-52}"
    printf '   %s└%s┘%s\n' "$C_DIM" "$(repeat_char "$width")" "$C_RESET"
}

# Панель «Установлено»: домены, сертификаты, push&pull, дополнения
function render_environment_panel() {
    [ "${BS_STATUS_PANEL_SITES:-true}" = true ] || return 0
    [ -n "${ENV_PANEL_READY:-}" ] || return 0

    panel_top "$(t env.title)"

    status_panel_row "$(t env.sites "${ENV_SITES_TOTAL}")" "$(t env.sites "${C_BOLD}${ENV_SITES_TOTAL}${C_RESET}")"

    local line site type ssl_days is_default type_plain type_colored domain_padded
    for line in "${ENV_SITES_LINES[@]}"; do
        IFS='|' read -r site type ssl_days is_default <<< "$line"
        domain_padded="$(printf '%-22.22s' "$site")"

        type_plain="${type}"
        type_colored="${C_GREY}${type}${C_RESET}"
        if [ "${is_default:-0}" = "1" ]; then
            type_plain="${type} · $(t env.default)"
            type_colored="${C_GREY}${type} · ${C_CYAN}$(t env.default)${C_RESET}"
        fi

        if [[ "$ssl_days" =~ ^-?[0-9]+$ ]]; then
            ssl_plain="$(t env.ssl_days "$ssl_days")"
            ssl_colored="$(ssl_days_color "$ssl_days")$(t env.ssl_days "$ssl_days")${C_RESET}"
        else
            ssl_plain="$(t env.no_ssl)"
            ssl_colored="${C_GREY}$(t env.no_ssl)${C_RESET}"
        fi

        status_panel_row "  ${domain_padded} ${type_plain}   ${ssl_plain}" \
            "  ${C_BOLD}${domain_padded}${C_RESET} ${type_colored}   ${ssl_colored}"
    done

    if (( ${ENV_SITES_REST:-0} > 0 )); then
        status_panel_row "  $(t env.and_more "${ENV_SITES_REST}")" "  ${C_GREY}$(t env.and_more "${ENV_SITES_REST}")${C_RESET}"
    fi

    if (( ENV_SITES_TOTAL == 0 )); then
        status_panel_row "  $(t env.no_sites)" "  ${C_GREY}$(t env.no_sites)${C_RESET}"
    fi

    local push_version push_state push_color
    IFS='|' read -r push_version push_state <<< "${ENV_PUSH:-?|not-found}"
    case "$push_state" in
        active)          push_color="$C_GREEN" ;;
        inactive|failed) push_color="$C_RED" ;;
        *)               push_color="$C_YELLOW" ;;
    esac
    status_panel_row "Push&Pull  ${push_version}  ${push_state}" \
        "${C_GREY}Push&Pull${C_RESET}  ${push_version}  ${push_color}${push_state}${C_RESET}"

    if [ -n "${ENV_ADDONS:-}" ]; then
        status_panel_row "$(t env.addons "${ENV_ADDONS}")" \
            "${C_GREY}$(t env.addons "${ENV_ADDONS}")${C_RESET}"
    else
        status_panel_row "$(t env.addons_none)" \
            "${C_GREY}$(t env.addons_none)${C_RESET}"
    fi

    panel_bottom
}

function get_current_version_php() {
    local version=""

    if command -v php >/dev/null 2>&1; then
        version="$(php -r 'echo PHP_MAJOR_VERSION, ".", PHP_MINOR_VERSION;' 2>/dev/null)"
    fi

    echo -e "\n   $(t php.current "${version:-$(t common.undefined)}")"
}

function get_available_version_php() {
    echo -e "\n   $(t php.available)\n"

    local versions
    versions="$(apt-cache search --names-only '^php8\.[0-9]+$' 2>/dev/null | awk '{print $1}' | sort -V -u)"

    if [[ -z "$versions" ]]; then
        echo "   $(t php.cant_list)"
        echo "   $(t php.check_repo)"
    else
        local version
        for version in $versions; do
            printf '   - %s\n' "${version#php}"
        done
    fi

    echo -e "\n"
}

# Состояние systemd-сервиса: active / inactive / not-found
function get_service_state() {
    local service="$1"
    local state

    state="$(systemctl is-active "$service" 2>/dev/null)"
    if [[ -z "$state" || "$state" == "unknown" ]]; then
        state="not-found"
    fi

    printf '%s' "$state"
}

# Цветной бейдж сервиса для шапки меню: "nginx=active" (зелёный) / "mysql=failed" (красный)
function service_badge() {
    local name="$1"
    local state color

    state="$(get_service_state "$name")"
    case "$state" in
        active)            color="$C_GREEN" ;;
        inactive|failed)   color="$C_RED" ;;
        *)                 color="$C_YELLOW" ;;
    esac

    printf '%s%s%s=%s%s%s' "$C_GREY" "$name" "$C_RESET" "$color" "$state" "$C_RESET"
}

# Версия MySQL-сервера (с указанием Percona, если используется Percona Server)
function get_mysql_version() {
    command -v "$BS_MYSQL_CMD" >/dev/null 2>&1 || return 0

    local out version
    out="$("$BS_MYSQL_CMD" --version 2>/dev/null)"
    version="$(printf '%s' "$out" | sed -E 's/.*Distrib ([0-9.]+).*/\1/; s/^mysql  Ver ([0-9.]+).*/\1/' | head -n1)"

    if printf '%s' "$out" | grep -qi percona; then
        printf '%s (Percona)' "$version"
    else
        printf '%s' "$version"
    fi
}

# Состояние PHP-модуля Apache (загружен ли mod_php соответствующей версии)
# В Debian файлы называются php8.3.load / php8.3.conf,
# в других сборках встречается php8.3_module.load — поддерживаем оба варианта.
function get_active_php_module() {
    local module
    for module in "${BS_PATH_APACHE}/mods-enabled"/php[0-9]*.load; do
        [[ -e "$module" ]] || continue
        basename "$module" | sed -E 's/^php([0-9.]+)(_module)?\.load$/\1/'
        return 0
    done
    return 1
}
