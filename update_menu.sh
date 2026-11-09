#!/bin/bash
#
# Обновление меню Debian BitrixVM.
#
# Использование:
#   bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/update_menu.sh)
#   bash <(wget -qO- https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/update_menu.sh)
#
# Схема (безопасная):
#   1. клон делается во ВРЕМЕННЫЙ каталог, поэтому обновление не зависит от того,
#      что уже лежит в /root (раньше clone падал, если /root/DebianBitrixVM существовал,
#      но скрипт всё равно печатал «Menu updated!»);
#   2. скачанное меню проверяется (наличие menu.sh и config.sh + синтаксис bash);
#   3. новое меню кладётся рядом как vm_menu.new, только потом backup и подмена;
#   4. при любом сбое старое меню остаётся на месте или восстанавливается из backup,
#      а скрипт завершается с кодом 1 — без ложного «успеха».
#
set -o pipefail

if [[ ${EUID:-$(id -u)} -ne 0 ]]; then
  echo "Ошибка: обновление меню нужно запускать от root." >&2
  exit 1
fi

cat > /root/temp_update_menu.sh <<\END
#!/bin/bash
set -o pipefail

REPO_URL="https://github.com/Bx-Project-Hub/DebianBitrixVM.git"
BRANCH="master"

DIR_NAME_MENU="vm_menu"
DEST_DIR_MENU="/root"
FULL_PATH_MENU_FILE="$DEST_DIR_MENU/$DIR_NAME_MENU/menu.sh"
DEST_DIR_BACKUP_MENU="$DEST_DIR_MENU/backup_vm_menu"
NEW_DIR="$DEST_DIR_MENU/${DIR_NAME_MENU}.new"

fail() {
    echo "" >&2
    echo "Ошибка: $*" >&2
    echo "Текущее меню не изменено." >&2
    exit 1
}

apt-get update -y || fail "не удалось выполнить apt-get update"
if ! command -v git >/dev/null 2>&1; then
    apt-get install -y git || fail "не удалось установить git"
fi

# --- 1. Клон во временный каталог -------------------------------------------
TMP_DIR="$(mktemp -d)" || fail "не удалось создать временный каталог"
trap 'rm -rf "$TMP_DIR"' EXIT

git clone --depth 1 --filter=blob:none --sparse --branch "$BRANCH" "$REPO_URL" "$TMP_DIR/repo" \
    || fail "не удалось склонировать $REPO_URL"

cd "$TMP_DIR/repo" || fail "не удалось перейти в каталог клона"
git sparse-checkout set "$DIR_NAME_MENU" || fail "не удалось получить каталог $DIR_NAME_MENU"

# --- 2. Проверка скачанного меню --------------------------------------------
[ -f "$TMP_DIR/repo/$DIR_NAME_MENU/menu.sh" ] \
    || fail "в репозитории нет файла $DIR_NAME_MENU/menu.sh"
[ -f "$TMP_DIR/repo/$DIR_NAME_MENU/bash_scripts/config.sh" ] \
    || fail "в репозитории нет $DIR_NAME_MENU/bash_scripts/config.sh"
bash -n "$TMP_DIR/repo/$DIR_NAME_MENU/menu.sh" \
    || fail "скачанное меню не проходит проверку синтаксиса"
bash -n "$TMP_DIR/repo/$DIR_NAME_MENU/bash_scripts/config.sh" \
    || fail "скачанный config.sh не проходит проверку синтаксиса"

new_version="$(sed -n 's/^BS_VERSION_MENU="\(.*\)"$/\1/p' "$TMP_DIR/repo/$DIR_NAME_MENU/bash_scripts/config.sh" | head -n1)"

# --- 3. Раскладываем новое меню рядом ---------------------------------------
rm -rf "$NEW_DIR"
cp -a "$TMP_DIR/repo/$DIR_NAME_MENU" "$NEW_DIR" || fail "не удалось скопировать новое меню"
chmod -R +x "$NEW_DIR" || fail "не удалось выставить права на новое меню"

# --- 4. Backup текущего меню ------------------------------------------------
current_date="$(date "+%d.%m.%Y %H:%M:%S")"
full_path_backup_menu="$DEST_DIR_BACKUP_MENU/$current_date"

if [ -d "$DEST_DIR_MENU/$DIR_NAME_MENU" ]; then
    mkdir -p "$full_path_backup_menu" || fail "не удалось создать каталог backup"
    mv -f "$DEST_DIR_MENU/$DIR_NAME_MENU" "$full_path_backup_menu/$DIR_NAME_MENU" \
        || fail "не удалось переместить текущее меню в backup"
else
    full_path_backup_menu=""
fi

# --- 5. Подмена с откатом ---------------------------------------------------
if ! mv -f "$NEW_DIR" "$DEST_DIR_MENU/$DIR_NAME_MENU"; then
    if [ -n "$full_path_backup_menu" ] && [ -d "$full_path_backup_menu/$DIR_NAME_MENU" ]; then
        mv -f "$full_path_backup_menu/$DIR_NAME_MENU" "$DEST_DIR_MENU/$DIR_NAME_MENU"
        echo "Выполнен откат из backup: $full_path_backup_menu/$DIR_NAME_MENU" >&2
    fi
    fail "не удалось заменить меню"
fi

if [ ! -f "$FULL_PATH_MENU_FILE" ]; then
    rm -rf "$DEST_DIR_MENU/$DIR_NAME_MENU"
    if [ -n "$full_path_backup_menu" ] && [ -d "$full_path_backup_menu/$DIR_NAME_MENU" ]; then
        mv -f "$full_path_backup_menu/$DIR_NAME_MENU" "$DEST_DIR_MENU/$DIR_NAME_MENU"
        echo "Выполнен откат из backup: $full_path_backup_menu/$DIR_NAME_MENU" >&2
    fi
    fail "после установки файл $FULL_PATH_MENU_FILE не найден"
fi

# --- 6. Автозапуск по SSH и символическая ссылка ----------------------------
if ! grep -qF "$FULL_PATH_MENU_FILE" /root/.profile; then
  cat << INSTALL_MENU >> /root/.profile

if [ -n "\$SSH_CONNECTION" ]; then
  $FULL_PATH_MENU_FILE
fi

INSTALL_MENU
fi

ln -sfn "$FULL_PATH_MENU_FILE" "$DEST_DIR_MENU/menu.sh"

# Сбрасываем кеш проверки версии, иначе меню ещё сутки показывает старую версию
rm -f "/tmp/configs.tmp"
rm -f "/tmp/new_version_menu.tmp"

echo ""
echo "Меню обновлено до версии ${new_version:-?}"
if [ -n "$full_path_backup_menu" ]; then
    echo "Резервная копия предыдущего меню: $full_path_backup_menu/$DIR_NAME_MENU"
fi
echo "Запуск: /root/menu.sh"
echo ""

END

bash /root/temp_update_menu.sh
update_status=$?
rm -f /root/temp_update_menu.sh
exit $update_status

