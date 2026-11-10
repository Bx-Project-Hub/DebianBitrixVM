#!/bin/sh
#
# metadata_begin
# recipe: Bitrix Vanilla
# tags: debian12, debian13
# revision: 3
# description_ru: Рецепт установки окружения для Bitrix на Debian 12 / Debian 13 (MySQL 8.4 LTS, PHP 8.3)
# description_en: Bitrix CMS installing recipe for Debian 12 / Debian 13 (MySQL 8.4 LTS, PHP 8.3)
# metadata_end

# Использование:
# bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/repositories/bitrix-gt/custom_bitrix_setup.sh)
#
# Скрипт создаёт /root/run.sh и выполняет его.
# Переменная BITRIX_SETUP_NO_RUN=1 откладывает запуск (создаётся только /root/run.sh).

cat > /root/run.sh <<\END

set -x
# Без интерактивных вопросов debconf/apt (установка идёт в неинтерактивном режиме)
export DEBIAN_FRONTEND="noninteractive"

###################################################################
# Вендорные файлы проекта
#
# Все внешние артефакты (push-server, конфиги PHP от Bitrix, скрипты установки,
# ключи репозиториев) лежат в каталоге vendor проекта и проверяются по SHA256.
# Локальная копия имеет приоритет; если её нет (устаревшая установка) — файл
# скачивается из репозитория проекта, а не с чужого сайта.
###################################################################
BS_VENDOR_DIR="${BS_VENDOR_DIR:-/root/vm_menu/vendor}"
BS_VENDOR_RAW_BASE="https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/vendor"

# Сверка SHA256 вендорного файла с vendor/CHECKSUMS.sha256
vendor_verify() {  # vendor_verify <путь внутри vendor>
    local rel="$1" manifest="${BS_VENDOR_DIR}/CHECKSUMS.sha256"
    [ -f "$manifest" ] || return 0
    local expected actual
    expected="$(awk -v f="$rel" '$2 == f { print $1 }' "$manifest")"
    if [ -z "$expected" ]; then
        echo "vendor: в CHECKSUMS.sha256 нет записи для ${rel}" >&2
        return 1
    fi
    actual="$(sha256sum "${BS_VENDOR_DIR}/${rel}" | awk '{print $1}')"
    if [ "$expected" != "$actual" ]; then
        echo "vendor: SHA256 не совпадает для ${rel}" >&2
        return 1
    fi
    return 0
}

vendor_get() {  # vendor_get <путь внутри vendor> <куда положить; "-" = stdout>
    local rel="$1" dest="$2" src
    src="${BS_VENDOR_DIR}/${rel}"
    if [ -f "$src" ]; then
        vendor_verify "$rel" || return 1
        if [ "$dest" = "-" ]; then cat "$src"; else cp -f "$src" "$dest"; fi
        echo "vendor: ${rel} (локальная копия, SHA256 OK)"
        return 0
    fi
    echo "vendor: ${rel} (локальной копии нет, скачиваем из репозитория проекта)"
    if [ "$dest" = "-" ]; then
        curl -fsSL "${BS_VENDOR_RAW_BASE}/${rel}"
    else
        curl -fsSL -o "$dest" "${BS_VENDOR_RAW_BASE}/${rel}"
    fi
}

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
# Параметры окружения
###################################################################
# Версия PHP из репозитория deb.sury.org. Переопределяется переменной PHP_VERSION.
PHP_VERSION="${PHP_VERSION:-8.3}"

# Кодовое имя Debian (bookworm / trixie).
# Берём из /etc/os-release: lsb-release на чистой системе может быть не установлен.
OS_CODENAME=""
if [ -f /etc/os-release ]; then
    OS_CODENAME="$(. /etc/os-release && printf '%s' "${VERSION_CODENAME:-}")"
fi
if [ -z "$OS_CODENAME" ]; then
    OS_CODENAME="$(lsb_release -sc 2>/dev/null)"
fi

case "$OS_CODENAME" in
    trixie|bookworm) ;;
    *)
        echo "Предупреждение: скрипт рассчитан на Debian 12 (bookworm) и Debian 13 (trixie)."
        echo "Обнаружено: ${OS_CODENAME:-unknown}."
        ;;
esac

# На Debian 13 (trixie) Oracle публикует только MySQL 8.4 LTS:
# компонент mysql-8.0 в репозитории для trixie отсутствует.
if [ "$OS_CODENAME" = "trixie" ]; then
    MYSQL_COMPONENT="mysql-8.4-lts"
    MYSQL_VERSION="8.4"
else
    MYSQL_COMPONENT="mysql-8.0"
    MYSQL_VERSION="8.0"
fi

# Версия push-server Bitrix (0.4.0 — без нативного better-sqlite3, работает на Node.js 20)
PUSH_SERVER_VERSION="${PUSH_SERVER_VERSION:-0.4.0}"

# СУБД: mysql (Oracle MySQL) или percona (Percona Server for MySQL 8.4 LTS)
DB_ENGINE="${DB_ENGINE:-mysql}"
case "$DB_ENGINE" in
    mysql|percona) ;;
    *)
        echo "Ошибка: DB_ENGINE должен быть mysql или percona (получено: ${DB_ENGINE})." >&2
        exit 1
        ;;
esac

# Репозитории Percona (используются только при DB_ENGINE=percona)
PERCONA_SERVER_REPO="${PERCONA_SERVER_REPO:-ps-84-lts}"
PERCONA_TELEMETRY_REPO="${PERCONA_TELEMETRY_REPO:-telemetry}"
PERCONA_DISABLE_TELEMETRY="${PERCONA_DISABLE_TELEMETRY:-1}"

###################################################################
# Функция генерации пароля (без символов, ломающих shell/SQL/конфиги)
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

###################################################################
# Функции для установки MySQL (Oracle APT: 8.4 LTS на Debian 13, 8.0 — на Debian 12)
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
    apt-get install -y curl ca-certificates lsb-release gnupg2 || InstallationFailed

    # Ключи Oracle: держим оба (2023 — действующий, 2025 — новый)
    vendor_get keys/RPM-GPG-KEY-mysql-2023 /etc/apt/trusted.gpg.d/RPM-GPG-KEY-mysql-2023.asc || InstallationFailed
    vendor_get keys/RPM-GPG-KEY-mysql-2025 /etc/apt/trusted.gpg.d/RPM-GPG-KEY-mysql-2025.asc || true

    # Компонент выбирается по кодовому имени Debian (mysql-8.4-lts для trixie)
    echo "deb [arch=amd64] https://repo.mysql.com/apt/debian/ ${OS_CODENAME} ${MYSQL_COMPONENT}" > /etc/apt/sources.list.d/mysql.list
    UpdateSoftwareList
}

###################################################################
# Пресеты MySQL/Percona под объём оперативной памяти
###################################################################

# Объём RAM в мегабайтах
function detect_ram_mb {
    awk '/^MemTotal:/{printf "%d", $2/1024}' /proc/meminfo 2>/dev/null
}

# Выбор пресета. Порядок важен: берём первый, в который влезает RAM.
# MYSQL_PRESET=auto|2g|4g|8g|16g|32g|64g — можно задать принудительно.
function select_mysql_preset {
    local forced="${MYSQL_PRESET:-auto}"
    case "$forced" in
        2g|4g|8g|16g|32g|64g) printf '%s' "$forced"; return 0 ;;
    esac

    local ram_mb
    ram_mb="$(detect_ram_mb)"

    if   (( ram_mb < 3072  )); then printf '2g'
    elif (( ram_mb < 6144  )); then printf '4g'
    elif (( ram_mb < 12288 )); then printf '8g'
    elif (( ram_mb < 24576 )); then printf '16g'
    elif (( ram_mb < 49152 )); then printf '32g'
    else                            printf '64g'
    fi
}

# Параметры пресета (буферы, соединения, кеши). Формат: key=value, по одному на строку.
function mysql_preset_params {
    case "$1" in
        2g) cat <<'EOF'
innodb_buffer_pool_size=768M
innodb_buffer_pool_instances=1
max_connections=40
thread_cache_size=64
table_open_cache=2000
table_definition_cache=1000
tmp_table_size=64M
max_heap_table_size=64M
sort_buffer_size=2M
join_buffer_size=2M
read_buffer_size=512K
read_rnd_buffer_size=1M
innodb_redo_log_capacity=512M
innodb_log_buffer_size=32M
innodb_io_capacity=400
innodb_io_capacity_max=800
key_buffer_size=32M
EOF
        ;;
        4g) cat <<'EOF'
innodb_buffer_pool_size=1536M
innodb_buffer_pool_instances=2
max_connections=60
thread_cache_size=96
table_open_cache=4000
table_definition_cache=2000
tmp_table_size=96M
max_heap_table_size=96M
sort_buffer_size=2M
join_buffer_size=2M
read_buffer_size=1M
read_rnd_buffer_size=2M
innodb_redo_log_capacity=768M
innodb_log_buffer_size=64M
innodb_io_capacity=600
innodb_io_capacity_max=1200
key_buffer_size=48M
EOF
        ;;
        8g) cat <<'EOF'
innodb_buffer_pool_size=3072M
innodb_buffer_pool_instances=3
max_connections=80
thread_cache_size=128
table_open_cache=8000
table_definition_cache=3000
tmp_table_size=128M
max_heap_table_size=128M
sort_buffer_size=4M
join_buffer_size=4M
read_buffer_size=1M
read_rnd_buffer_size=2M
innodb_redo_log_capacity=1G
innodb_log_buffer_size=96M
innodb_io_capacity=1000
innodb_io_capacity_max=2000
key_buffer_size=64M
EOF
        ;;
        16g) cat <<'EOF'
innodb_buffer_pool_size=6144M
innodb_buffer_pool_instances=6
max_connections=85
thread_cache_size=128
table_open_cache=14336
table_definition_cache=4096
tmp_table_size=128M
max_heap_table_size=128M
sort_buffer_size=4M
join_buffer_size=4M
read_buffer_size=1M
read_rnd_buffer_size=2M
innodb_redo_log_capacity=2G
innodb_log_buffer_size=128M
innodb_io_capacity=2000
innodb_io_capacity_max=4000
key_buffer_size=96M
EOF
        ;;
        32g) cat <<'EOF'
innodb_buffer_pool_size=12288M
innodb_buffer_pool_instances=8
max_connections=200
thread_cache_size=256
table_open_cache=20000
table_definition_cache=5000
tmp_table_size=256M
max_heap_table_size=256M
sort_buffer_size=4M
join_buffer_size=4M
read_buffer_size=2M
read_rnd_buffer_size=4M
innodb_redo_log_capacity=4G
innodb_log_buffer_size=256M
innodb_io_capacity=3000
innodb_io_capacity_max=6000
key_buffer_size=128M
EOF
        ;;
        64g) cat <<'EOF'
innodb_buffer_pool_size=24576M
innodb_buffer_pool_instances=8
max_connections=300
thread_cache_size=256
table_open_cache=32768
table_definition_cache=8000
tmp_table_size=256M
max_heap_table_size=256M
sort_buffer_size=8M
join_buffer_size=8M
read_buffer_size=2M
read_rnd_buffer_size=4M
innodb_redo_log_capacity=8G
innodb_log_buffer_size=256M
innodb_io_capacity=4000
innodb_io_capacity_max=8000
key_buffer_size=128M
EOF
        ;;
        *)  cat <<'EOF'
innodb_buffer_pool_size=128M
innodb_buffer_pool_instances=1
max_connections=40
thread_cache_size=32
table_open_cache=1000
tmp_table_size=32M
max_heap_table_size=32M
innodb_redo_log_capacity=128M
EOF
        ;;
    esac
}

# Минимальный (аварийный) набор: используется, если пресет не дал серверу стартовать
function mysql_fallback_params {
    cat <<'EOF'
innodb_buffer_pool_size=128M
innodb_buffer_pool_instances=1
max_connections=40
thread_cache_size=32
table_open_cache=1000
tmp_table_size=32M
max_heap_table_size=32M
innodb_redo_log_capacity=128M
EOF
}

# Параметр журнала упреждающей записи зависит от версии:
# до 8.0.30 это innodb_log_file_size, начиная с 8.0.30 — innodb_redo_log_capacity.
function mysql_redo_param_supported {
    local major minor patch
    major="$(printf '%s' "$MYSQL_FULL_VERSION" | cut -d. -f1)"
    minor="$(printf '%s' "$MYSQL_FULL_VERSION" | cut -d. -f2)"
    patch="$(printf '%s' "$MYSQL_FULL_VERSION" | cut -d. -f3)"; patch="${patch%%[!0-9]*}"

    (( ${major:-8} > 8 )) && return 0
    (( ${major:-8} == 8 && ${minor:-0} > 0 )) && return 0
    (( ${minor:-0} == 0 && ${patch:-0} >= 30 )) && return 0
    return 1
}

# Записать конфигурацию MySQL/Percona с учётом объёма RAM.
# Возвращает 0 при успехе; при неудачном старте откатывается на минимальный набор.
function SetRecommendedSettingsMySQL {
    # Настройки Bitrix для MySQL/Percona.
    # Пишем в /etc/mysql/conf.d/ — этот каталог подключают ВСЕ варианты my.cnf
    # (Oracle MySQL, Percona Server, mariadb-common).
    local cnf_dir="/etc/mysql/conf.d"
    mkdir -p "$cnf_dir" /etc/mysql/my-bx.d

    # libreoffice-sdbc-mysql тянет mariadb-common, а тот регистрирует
    # /etc/mysql/my.cnf -> mariadb.cnf с приоритетом 500 и перекрывает
    # my.cnf выбранного сервера (приоритет 300). Возвращаем нужный конфиг.
    if [ -f /etc/mysql/mysql.cnf ]; then
        update-alternatives --install /etc/mysql/my.cnf my.cnf /etc/mysql/mysql.cnf 700 >/dev/null 2>&1 || true
        update-alternatives --set my.cnf /etc/mysql/mysql.cnf >/dev/null 2>&1 || true
    fi

    # Чистим файлы от предыдущих версий скрипта
    rm -f /etc/mysql/mysql.conf.d/99-bitrix.cnf /etc/mysql/mysql.conf.d/99-custom.cnf

    if [ "$MYSQL_VERSION" = "8.4" ]; then
        # MySQL 8.4: default_authentication_plugin удалён,
        # включать mysql_native_password нужно явно (совместимость с Bitrix и бэкапами)
        AUTH_SETTINGS='authentication_policy=mysql_native_password
mysql_native_password=ON'
    else
        AUTH_SETTINGS='default-authentication-plugin=mysql_native_password'
    fi

    # Полная версия сервера (8.4.11, 8.0.43 …) — от неё зависит выбор параметра
    # журнала упреждающей записи (innodb_redo_log_capacity появился в 8.0.30).
    if [ -z "${MYSQL_FULL_VERSION:-}" ]; then
        MYSQL_FULL_VERSION="$(mysqld --version 2>/dev/null \
            | sed -n 's/.*Ver[[:space:]]\+\([0-9][0-9.]*\).*/\1/p' | head -1)"
        MYSQL_FULL_VERSION="${MYSQL_FULL_VERSION:-$MYSQL_VERSION}"
    fi

    local preset ram_mb preset_params redo_filtered
    preset="$(select_mysql_preset)"
    ram_mb="$(detect_ram_mb)"

    preset_params="$(mysql_preset_params "$preset")"
    if ! mysql_redo_param_supported; then
        # Старые сборки MySQL 8.0 (< 8.0.30) не знают innodb_redo_log_capacity
        redo_filtered="$(printf '%s\n' "$preset_params" | grep -v '^innodb_redo_log_capacity=')"
        redo_filtered="${redo_filtered}
innodb_log_file_size=256M"
        preset_params="$redo_filtered"
    fi

    # --- 10: параметры, зависящие от RAM -------------------------------------
    {
        echo "[mysqld]"
        echo "# Сгенерировано автоматически: пресет ${preset} (RAM: ${ram_mb} МБ)."
        echo "# Переопределить: MYSQL_PRESET=2g|4g|8g|16g|32g|64g перед запуском установщика."
        printf '%s\n' "$preset_params"
    } > "${cnf_dir}/10-bitrix-memory.cnf"

    # --- 20: логирование -----------------------------------------------------
    cat <<'EOF' > "${cnf_dir}/20-bitrix-logging.cnf"
[mysqld_safe]
log-error=/var/log/mysql/error.log

[mysqld]
log-error=/var/log/mysql/error.log
general_log=0
slow_query_log=0
sync_binlog=0
EOF

    # --- 99: статичная база --------------------------------------------------
    cat <<EOF > "${cnf_dir}/99-bitrix.cnf"
[mysqld]
user=mysql
port=3306
bind-address=127.0.0.1
skip-name-resolve

disable-log-bin
max_connect_errors=1000000
back_log=512
open_files_limit=65535

max_allowed_packet=256M
net_read_timeout=120
net_write_timeout=120
connect_timeout=30

default_storage_engine=InnoDB
innodb_file_per_table=1
innodb_default_row_format=DYNAMIC

innodb_flush_log_at_trx_commit=2
innodb_flush_method=O_DIRECT
innodb_read_io_threads=8
innodb_write_io_threads=8
innodb_flush_neighbors=0
innodb_purge_threads=4
innodb_max_dirty_pages_pct=75
innodb_max_dirty_pages_pct_lwm=10
innodb_lru_scan_depth=1024
innodb_change_buffering=none

performance_schema=ON
transaction-isolation=READ-COMMITTED
innodb_strict_mode=off

character-set-server=utf8mb4
collation-server=utf8mb4_unicode_ci
sql-mode=""

local_infile=0
mysqlx=OFF

# Из Bitrix-окружения
${AUTH_SETTINGS}
EOF

    if systemctl restart mysql.service >/dev/null 2>&1 && [ "$(systemctl is-active mysql.service)" = "active" ]; then
        echo "MySQL: применён пресет ${preset} (RAM: ${ram_mb} МБ)."
        return 0
    fi

    # --- Откат: минимальный безопасный набор ---------------------------------
    echo "Внимание: MySQL не запустился с пресетом ${preset}. Откат на минимальный набор." >&2
    {
        echo "[mysqld]"
        echo "# Аварийный набор (пресет ${preset} не прошёл проверку старта)"
        mysql_fallback_params
    } > "${cnf_dir}/10-bitrix-memory.cnf"

    if systemctl restart mysql.service >/dev/null 2>&1 && [ "$(systemctl is-active mysql.service)" = "active" ]; then
        echo "MySQL: применён минимальный набор параметров. Проверьте /var/log/mysql/error.log и увеличьте RAM." >&2
        return 0
    fi

    InstallationFailed
}

function MySQLSecureInstallation {
    local anon

    # Удаляем анонимных пользователей.
    # В MySQL 8.x mysql.user — это view, поэтому DELETE запрещён: используем DROP USER.
    for anon in $(mysql --defaults-file=/root/.my.cnf -N -B -e "SELECT CONCAT(QUOTE(User), '@', QUOTE(Host)) FROM mysql.user WHERE User = '';" 2>/dev/null); do
        mysql --defaults-file=/root/.my.cnf -e "DROP USER ${anon};" 2>/dev/null || true
    done

    # Удаляем тестовую базу (если есть)
    mysql --defaults-file=/root/.my.cnf -e "DROP DATABASE IF EXISTS test;" 2>/dev/null || true
}

function installMySQL8 {
    apt-get install -y pwgen curl wget || InstallationFailed
    Message "Установка MySQL ${MYSQL_VERSION} из репозитория Oracle APT (${MYSQL_COMPONENT})...\n"
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
    SetRecommendedSettingsMySQL
    MySQLSecureInstallation

    echo "MySQL ${MYSQL_VERSION} успешно установлен."
}

###################################################################
# Установка Percona Server for MySQL 8.4 LTS (альтернатива Oracle MySQL)
###################################################################
function installPerconaRepository {
    apt-get install -y curl ca-certificates gnupg2 || InstallationFailed

    # percona-release содержит актуальный ключ /usr/share/keyrings/percona-keyring.gpg
    local pc_deb="/tmp/percona-release_latest.deb"
    vendor_get keys/percona-release_latest.generic_all.deb "$pc_deb" || InstallationFailed
    dpkg -i "$pc_deb" || apt-get install -f -y || InstallationFailed
    rm -f "$pc_deb"

    if [ ! -s /usr/share/keyrings/percona-keyring.gpg ]; then
        echo "Ошибка: не найден ключ Percona /usr/share/keyrings/percona-keyring.gpg" >&2
        InstallationFailed
    fi

    # PS 8.4 LTS. Репозиторий агента телеметрии пакет percona-release обычно
    # подключает сам (percona-telemetry-release.list) — добавляем только если его нет.
    cat > /etc/apt/sources.list.d/percona.list <<EOF
# Percona Server for MySQL 8.4 LTS
deb [signed-by=/usr/share/keyrings/percona-keyring.gpg] https://repo.percona.com/${PERCONA_SERVER_REPO}/apt ${OS_CODENAME} main
EOF
    if ! grep -rqs 'repo.percona.com/telemetry' /etc/apt/sources.list.d/; then
        echo "deb [signed-by=/usr/share/keyrings/percona-keyring.gpg] https://repo.percona.com/${PERCONA_TELEMETRY_REPO}/apt ${OS_CODENAME} main" >> /etc/apt/sources.list.d/percona.list
    fi

    UpdateSoftwareList
}

function installPerconaServer {
    apt-get install -y pwgen curl wget ca-certificates debconf-utils || InstallationFailed
    Message "Установка Percona Server 8.4 LTS (репозиторий ${PERCONA_SERVER_REPO})...\n"
    GenerateMysqlRootPassword

    local ROOT_PASS
    ROOT_PASS=$(awk '/password/{print $3}' /root/.my.cnf)
    echo "percona-server-server percona-server-server/root-pass password ${ROOT_PASS}" | debconf-set-selections
    echo "percona-server-server percona-server-server/re-root-pass password ${ROOT_PASS}" | debconf-set-selections

    installPerconaRepository

    DEBIAN_FRONTEND=noninteractive apt-get install -qq -y percona-server-server || InstallationFailed

    # Если root остался на socket-авторизации или без пароля — задаём пароль из .my.cnf
    if ! mysql --defaults-file=/root/.my.cnf -e "SELECT 1" >/dev/null 2>&1; then
        if mysql -u root -e "SELECT 1" >/dev/null 2>&1; then
            mysql -u root -e "ALTER USER 'root'@'localhost' IDENTIFIED BY '${ROOT_PASS}'; FLUSH PRIVILEGES;" || InstallationFailed
        else
            echo "Ошибка: не удалось подключиться к Percona Server под root." >&2
            InstallationFailed
        fi
    fi

    SetRecommendedSettingsMySQL
    MySQLSecureInstallation

    # Телеметрия Percona по умолчанию отключается
    if [ "${PERCONA_DISABLE_TELEMETRY:-1}" = "1" ]; then
        systemctl disable --now percona-telemetry-agent >/dev/null 2>&1 || true
        systemctl mask percona-telemetry-agent >/dev/null 2>&1 || true
        echo "Телеметрия Percona отключена (percona-telemetry-agent masked)."
    fi

    echo "Percona Server 8.4 LTS успешно установлен."
}

function installDatabase {
    case "$DB_ENGINE" in
        percona)
            if [ "$OS_CODENAME" != "trixie" ]; then
                echo "Предупреждение: Percona Server 8.4 проверен только для Debian 13 (trixie)."
            fi
            installPerconaServer
            ;;
        *)
            installMySQL8
            ;;
    esac
}

###################################################################
# Установка пакетов ОС и LAMP/LEMP окружения
###################################################################
installPkg(){
    # Ставим пакетные зависимости, включая PHP, Apache, Nginx, etc.
    # Сначала устанавливаем выбранную СУБД (MySQL или Percona Server)
    installDatabase

    # Теперь репозиторий sury для PHP (для Debian 13 — trixie)
    echo "deb [signed-by=/etc/apt/trusted.gpg.d/sury.gpg] https://packages.sury.org/php/ ${OS_CODENAME} main" | tee /etc/apt/sources.list.d/sury-php.list
    vendor_get keys/sury-php.gpg /etc/apt/trusted.gpg.d/sury.gpg
    apt-get update -y

    export DEBIAN_FRONTEND="noninteractive"
    debconf-set-selections <<< 'exim4-config exim4/dc_eximconfig_configtype select internet site; mail is sent and received directly using SMTP'

    apt-get install -y \
        "libapache2-mod-php${PHP_VERSION}" \
        "php${PHP_VERSION}" "php${PHP_VERSION}-cli" "php${PHP_VERSION}-common" \
        "php${PHP_VERSION}-gd" "php${PHP_VERSION}-ldap" "php${PHP_VERSION}-mbstring" \
        "php${PHP_VERSION}-mysql" "php${PHP_VERSION}-opcache" "php${PHP_VERSION}-zip" \
        "php${PHP_VERSION}-pspell" "php${PHP_VERSION}-xml" "php${PHP_VERSION}-apcu" \
        "php${PHP_VERSION}-curl" "php${PHP_VERSION}-mcrypt" "php${PHP_VERSION}-memcache" \
        "php${PHP_VERSION}-dev" "php${PHP_VERSION}-maxminddb" "php${PHP_VERSION}-imagick" \
        "php${PHP_VERSION}-http" \
        "php${PHP_VERSION}-redis" "php${PHP_VERSION}-igbinary" \
        "php${PHP_VERSION}-intl" "php${PHP_VERSION}-soap" "php${PHP_VERSION}-bcmath" \
        "php${PHP_VERSION}-imap" "php${PHP_VERSION}-ssh2" \
        apache2 nginx nodejs npm redis exim4 exim4-config \
        libnginx-mod-http-brotli-filter libnginx-mod-http-brotli-static \
        sudo
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

    # Каталог логов PHP (указывается в zbx-bitrix.ini)
    mkdir -p /var/log/php
    chown www-data:www-data /var/log/php
    chmod 0775 /var/log/php

    # Символические ссылки на общий php.ini для Bitrix
    ln -sf "/etc/php/${PHP_VERSION}/mods-available/zbx-bitrix.ini"  "/etc/php/${PHP_VERSION}/apache2/conf.d/99-bitrix.ini"
    ln -sf "/etc/php/${PHP_VERSION}/mods-available/zbx-bitrix.ini"  "/etc/php/${PHP_VERSION}/cli/conf.d/99-bitrix.ini"

    a2dismod --force autoindex
    a2enmod rewrite
    a2enmod "php${PHP_VERSION}"
    phpenmod xml

    # intl / soap / bcmath / imap / ssh2 — нужны Bitrix и типовым интеграциям.
    # Пакеты обычно включают модули сами, но после смены версии PHP или ручной
    # правки conf.d символические ссылки могут отсутствовать — включаем явно.
    phpenmod -v "${PHP_VERSION}" intl soap bcmath imap ssh2 2>/dev/null || true

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
    local redis_conf="/etc/redis/redis.conf"

    # Сохраняем штатный конфиг Debian (Redis 8), добавляем только нужное Bitrix.
    # phpredis и push-server обращаются к Redis по unix-socket.
    if ! grep -q '^unixsocket ' "$redis_conf" 2>/dev/null; then
        echo 'unixsocket /var/run/redis/redis.sock' >> "$redis_conf"
    fi
    if ! grep -q '^unixsocketperm ' "$redis_conf" 2>/dev/null; then
        echo 'unixsocketperm 770' >> "$redis_conf"
    fi
    if ! grep -q '^maxmemory-policy ' "$redis_conf" 2>/dev/null; then
        echo 'maxmemory-policy allkeys-lru' >> "$redis_conf"
    fi

    # Проверяем текущее значение vm.overcommit_memory
    current_value=$(sysctl -n vm.overcommit_memory 2>/dev/null || echo 0)
    if [ "$current_value" -ne 1 ]; then
        echo 'vm.overcommit_memory = 1' >> /etc/sysctl.conf
        sysctl -w vm.overcommit_memory=1
    fi

    # Каталоги /etc/redis, /var/log/redis, /var/lib/redis создаёт пакет redis-tools
    # с нужными правами — их владельцев не меняем.
    mkdir -p /etc/systemd/system/redis.service.d
    cat <<EOF > /etc/systemd/system/redis.service.d/custom.conf
[Service]
# Группа www-data нужна для доступа к unix-socket Redis (bitrix, push-server)
Group=www-data
# Каталог /run/redis: владелец redis, группа www-data, доступ только им
RuntimeDirectory=redis
RuntimeDirectoryMode=2770
# В Debian 13 юнит использует PrivateUsers=true — это ломает доступ к сокету
# для других пользователей, поэтому отключаем пространство имён пользователей.
PrivateUsers=false
PIDFile=/run/redis/redis-server.pid
EOF

    systemctl daemon-reload
    systemctl stop redis 2>/dev/null || systemctl stop redis-server 2>/dev/null || true
    systemctl enable --now redis 2>/dev/null || systemctl enable --now redis-server
    systemctl start redis 2>/dev/null || systemctl start redis-server
}

###################################################################
# Совместимость с RedHat-функциями, которые использует init-скрипт push-server
###################################################################
install_redhat_functions_compat() {
    mkdir -p /etc/rc.d/init.d
    cat <<'EOF' > /etc/rc.d/init.d/functions
# Минимальная замена /etc/rc.d/init.d/functions для Debian.
# Нужна скриптам Bitrix (push-server), которые вызывают status и killproc.

status() {
    local pidfile=""
    while [ $# -gt 0 ]; do
        case "$1" in
            -p) pidfile="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    [ -n "$pidfile" ] || return 4
    [ -f "$pidfile" ] || return 3
    local pid
    pid="$(cat "$pidfile" 2>/dev/null)"
    [ -n "$pid" ] || return 1
    kill -0 "$pid" 2>/dev/null || return 1
    return 0
}

killproc() {
    local pidfile=""
    while [ $# -gt 0 ]; do
        case "$1" in
            -p) pidfile="$2"; shift 2 ;;
            *) shift ;;
        esac
    done
    [ -n "$pidfile" ] || return 1
    local pid
    pid="$(cat "$pidfile" 2>/dev/null)"
    [ -n "$pid" ] || return 1
    kill "$pid" 2>/dev/null
    local i
    for i in $(seq 1 20); do
        kill -0 "$pid" 2>/dev/null || break
        sleep 0.5
    done
    kill -9 "$pid" 2>/dev/null
    rm -f "$pidfile"
    return 0
}
EOF
    chmod 0644 /etc/rc.d/init.d/functions
}

###################################################################
# Установка push-сервера
###################################################################
dplPush(){
    cd /opt || exit 1

    rm -rf /opt/node_modules
    vendor_get "files/push-server-${PUSH_SERVER_VERSION}.tgz" "push-server-${PUSH_SERVER_VERSION}.tgz" || {
        echo "Ошибка: не удалось скачать push-server-${PUSH_SERVER_VERSION}.tgz" >&2
        return 1
    }

    # npm 9 из Debian 13
    if ! npm install --production --no-audit --no-fund "./push-server-${PUSH_SERVER_VERSION}.tgz"; then
        echo "Ошибка: npm не смог установить push-server-${PUSH_SERVER_VERSION}." >&2
        return 1
    fi
    rm -f "./push-server-${PUSH_SERVER_VERSION}.tgz"
    ln -sfn /opt/node_modules/push-server/etc/push-server /etc/push-server

    cd /opt/node_modules/push-server || exit 1

    # push-server 0.4.0 содержит init-скрипт и systemd-юнит, рассчитанные на /etc/init.d
    install -m 0755 etc/init.d/push-server-multi /etc/init.d/push-server-multi
    mkdir -p /etc/sysconfig
    cp etc/sysconfig/push-server-multi /etc/sysconfig/push-server-multi
    cp etc/push-server/push-server.service /etc/systemd/system/
    ln -sfn /opt/node_modules/push-server /opt/push-server

    id -u bitrix >/dev/null 2>&1 || useradd -g www-data -M -s /usr/sbin/nologin bitrix

    install_redhat_functions_compat

    cat <<EOF >> /etc/sysconfig/push-server-multi
GROUP=www-data
SECURITY_KEY="${PUSH_KEY}"
RUN_DIR=/tmp/push-server
REDIS_SOCK=/var/run/redis/redis.sock
WS_HOST=127.0.0.1
IP_LIST='"127.0.0.1"'
EOF

    /etc/init.d/push-server-multi configs pub
    /etc/init.d/push-server-multi configs sub

    mkdir -p /etc/tmpfiles.d
    echo 'd /tmp/push-server 0770 bitrix www-data -' > /etc/tmpfiles.d/push-server.conf
    systemd-tmpfiles --remove --create

    [[ ! -d /var/log/push-server ]] && mkdir -p /var/log/push-server
    chown -R bitrix:www-data /var/log/push-server

    # Главный юнит: запуск от bitrix, группа www-data (доступ к redis-сокету)
    sed -i 's|^User=.*|User=bitrix|;s|^Group=.*|Group=www-data|' /etc/systemd/system/push-server.service

    systemctl daemon-reload
    systemctl stop push-server 2>/dev/null || true
    systemctl enable push-server
    if ! systemctl restart push-server; then
        echo "Предупреждение: push-server не запустился. Проверьте: journalctl -u push-server -n 50"
    fi
}

###################################################################
# Настройка MySQL и создание БД/пользователя
###################################################################
dplMYSQL() {
    # Перезапуск ДО создания пользователей: только после него применяется
    # authentication_policy из /etc/mysql/conf.d/99-bitrix.cnf. Иначе MySQL 8.4
    # создаёт учётки с caching_sha2_password, и часть legacy-кода Bitrix,
    # рассчитанного на mysql_native_password, ломается на подключении.
    systemctl enable mysql
    systemctl restart mysql

    # Плагин задаём явно — CREATE USER IF NOT EXISTS не меняет плагин
    # у уже существующей учётки, а ALTER ... IDENTIFIED BY без WITH оставляет прежний.
    # Пароль root читаем терпимо к формату: в .my.cnf он пишется как "password = ...".
    local root_pw
    root_pw="$(sed -n 's/^[[:space:]]*password[[:space:]]*=[[:space:]]*//p' /root/.my.cnf 2>/dev/null | head -1)"

    mysql --defaults-file=/root/.my.cnf -e "CREATE DATABASE IF NOT EXISTS sitemanager CHARACTER SET utf8mb4 COLLATE utf8mb4_0900_ai_ci; \
              CREATE USER IF NOT EXISTS 'bitrix0'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DBPASS}'; \
              ALTER USER 'bitrix0'@'localhost' IDENTIFIED WITH mysql_native_password BY '${DBPASS}'; \
              GRANT ALL PRIVILEGES ON sitemanager.* TO 'bitrix0'@'localhost'; \
              FLUSH PRIVILEGES;"

    # root тоже переводим на native, чтобы .my.cnf/скрипты и бэкапы работали
    # одинаково на MySQL 8.4 и Percona 8.4.
    if [ -n "${root_pw}" ]; then
        mysql --defaults-file=/root/.my.cnf -e \
            "ALTER USER 'root'@'localhost' IDENTIFIED WITH mysql_native_password BY '${root_pw}'; \
             FLUSH PRIVILEGES;" >/dev/null 2>&1 || true
    fi
}

###################################################################
# Настройки фаервола (nftables)
###################################################################
nfTabl(){
    apt-get install -y nftables || InstallationFailed

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
    # Скачиваем готовые конфиги Nginx/Apache (из документации Bitrix)
    local tmp_dir
    tmp_dir="$(mktemp -d)"
    cd "$tmp_dir" || exit 1

    vendor_get files/bitrix-php-configs-debian.zip debian.zip
    # unzip может вернуть 1 из-за предупреждения об обратных слэшах в архиве — это не ошибка
    unzip -o debian.zip >/dev/null 2>&1 || true
    rm -f debian.zip

    if [ ! -d ./debian ]; then
        echo "Ошибка: не удалось распаковать debian.zip с конфигурациями Bitrix." >&2
        cd / && rm -rf "$tmp_dir"
        return 1
    fi

    # Копируем конфиги Bitrix, но НЕ перезаписываем настройки MySQL и Redis:
    # на Debian 13 используются Oracle MySQL 8.4 и Redis 8, их штатные файлы важнее.
    rsync -a --exclude=php.d --exclude='mysql/my.cnf' --exclude='redis/redis.conf' ./debian/ /etc/
    rsync -a ./debian/php.d/ "/etc/php/${PHP_VERSION}/mods-available/"

    cd / || exit 1
    rm -rf "$tmp_dir"

    mkdir -p /var/www/html/bx-site

    nfTabl
    dplApache
    dplNginx
    dplRedis
    dplPush
    dplMYSQL

    systemctl enable mysql
}

###################################################################
# Развёртывание файлов установщика Bitrix
###################################################################
deployInstaller() {
    cd /var/www/html/bx-site || exit 1
    vendor_get files/bitrixsetup.php bitrixsetup.php || echo "Предупреждение: не удалось получить bitrixsetup.php"
    # restore.php намеренно не размещается: скрипт восстановления опасен и
    # добавляется в каталог сайта только по запросу из меню (Дополнения → 5).

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

# Сохраняем сгенерированные секреты для установщика окружения (install_full_environment.sh)
umask 077
cat > /root/.bitrix_env <<ENV_EOF
PUSH_KEY=${PUSH_KEY}
DBPASS=${DBPASS}
PHP_VERSION=${PHP_VERSION}
MYSQL_VERSION=${MYSQL_VERSION}
DB_ENGINE=${DB_ENGINE}
ENV_EOF
chmod 600 /root/.bitrix_env

END

# Запуск установки.
# install_full_environment.sh запускает этот режим по умолчанию и затем читает
# сгенерированные секреты из /root/.bitrix_env.
if [ "${BITRIX_SETUP_NO_RUN:-0}" = "1" ]; then
    echo "Скрипт установки создан: /root/run.sh (запуск отложен, BITRIX_SETUP_NO_RUN=1)."
else
    bash /root/run.sh
fi
