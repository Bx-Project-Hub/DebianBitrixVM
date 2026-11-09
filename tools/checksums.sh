#!/usr/bin/env bash
#
# Контрольные суммы файлов проекта (скрипты, конфиги, плейбуки, роли) и
# вендорных пакетов.
#
# Три манифеста:
#   CHECKSUMS.sha256          — корень: установщик, обновлятор, tools/, repositories/
#   vm_menu/CHECKSUMS.sha256  — всё меню: menu.sh, bash_scripts/, ansible/ (плейбуки,
#                               роли, конфиги, шаблоны)
#   vendor/CHECKSUMS.sha256   — вендорные пакеты и файлы (см. tools/vendor-fetch.sh)
#
# Использование:
#   tools/checksums.sh --update   # пересчитать все манифесты
#   tools/checksums.sh --check    # проверить все манифесты
#
# Проверки выполняются автоматически: при установке (install_full_environment.sh),
# при обновлении меню (update_menu.sh) и перед установкой вендорных .deb.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

if command -v sha256sum >/dev/null 2>&1; then
  sha256() { sha256sum "$@"; }
else
  sha256() { shasum -a 256 "$@"; }
fi

# Файлы корневого манифеста (пути относительно корня)
root_files() {
  {
    find "$ROOT/tools" -maxdepth 1 -type f \( -name '*.sh' -o -name '*.py' \) -print
    find "$ROOT/repositories" -type f -name '*.sh' -print
    printf '%s\n' "$ROOT/install_full_environment.sh" "$ROOT/update_menu.sh"
  } | sed "s|^$ROOT/||" | LC_ALL=C sort -u
}

# Файлы манифеста меню (всё, кроме вендорных файлов и самого манифеста)
menu_files() {
  ( cd "$ROOT/vm_menu" && find . -type f \
      -not -path './vendor/*' \
      -not -name 'CHECKSUMS.sha256' \
      -not -name '*.md' -print ) \
    | sed 's|^\./||' | LC_ALL=C sort
}

generate() {
  local dir="$1" file="$2"
  shift 2
  local tmp
  tmp="$(mktemp)"
  ( cd "$dir" && "$@" | while read -r f; do sha256 "$f"; done > "$tmp" )
  mv -f "$tmp" "$dir/$file"
  echo "→ $dir/$file: $(wc -l < "$dir/$file" | tr -d ' ') файлов"
}

check_manifest() {
  local dir="$1" file="$2"
  if [[ ! -f "$dir/$file" ]]; then
    echo "НЕТ МАНИФЕСТА: $dir/$file" >&2
    return 1
  fi
  ( cd "$dir" && sha256 -c "$file" --quiet ) || return 1
  echo "OK $dir/$file"
}

case "${1:---check}" in
  --update)
    generate "$ROOT" "CHECKSUMS.sha256" root_files
    generate "$ROOT/vm_menu" "CHECKSUMS.sha256" menu_files
    [[ -f "$ROOT/vendor/CHECKSUMS.sha256" ]] \
      && echo "→ vendor/CHECKSUMS.sha256: без изменений (обновляется tools/vendor-fetch.sh)"
    echo "Готово. Не забудьте добавить изменённые манифесты в коммит."
    ;;
  --check)
    rc=0
    check_manifest "$ROOT" "CHECKSUMS.sha256" || rc=1
    check_manifest "$ROOT/vm_menu" "CHECKSUMS.sha256" || rc=1
    check_manifest "$ROOT/vendor" "CHECKSUMS.sha256" || rc=1
    exit "$rc"
    ;;
  *)
    echo "usage: $0 --update | --check" >&2
    exit 2
    ;;
esac
