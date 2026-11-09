#!/bin/bash
dir="$(dirname "$(readlink -f "$0")")"
dir_helpers="$dir/helpers"

# Меню должно работать в UTF-8 (русский интерфейс).
# Ansible иначе падает с "locale encoding is not UTF-8".
case "${LC_ALL:-${LANG:-}}" in
  *UTF-8*|*utf8*|*utf-8*) ;;
  *)
    export LC_ALL="C.UTF-8"
    export LANG="C.UTF-8"
    ;;
esac

# clear(1) без TERM ругается — подставляем безопасное значение
# (актуально при запуске из минимального окружения, cron, CI).
if [[ -z "${TERM:-}" ]]; then
  export TERM="xterm"
fi

source "$dir/bash_scripts/config.sh"
source "$dir/bash_scripts/functions.sh"

require_root

if ! check_supported_os; then
  echo "Внимание: меню рассчитано на Debian 12 и Debian 13." >&2
  echo "Текущая ОС: ${OS_NAME:-unknown} ${OS_VERSION:-unknown}." >&2
  echo "Продолжение через 5 секунд..." >&2
  sleep 5
fi

main_menu;














