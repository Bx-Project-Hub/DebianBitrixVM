#!/usr/bin/env bash
#
# Обновление вендорных (локальных) копий внешних артефактов.
#
# Зачем: установка не должна зависеть от доступности чужих сайтов
# (сторонний APT-репозиторий nginx-модулей, repo.bitrix.info, 1c-bitrix.ru,
# get.netdata.cloud и т. д.). Все нужные файлы лежат в vendor/ и проверяются
# по SHA256 перед использованием.
#
# Использование:
#   tools/vendor-fetch.sh            # скачать/обновить все артефакты и пересчитать CHECKSUMS.sha256
#   tools/vendor-fetch.sh --check    # только проверить контрольные суммы
#
# После обновления обязательно просмотрите diff vendor/ перед коммитом.

set -euo pipefail

ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
VENDOR="$ROOT/vendor"
CHECKSUMS="$VENDOR/CHECKSUMS.sha256"

# url|путь внутри vendor
ARTIFACTS=(
  "https://yogsottot.github.io/ppa/debian/pool/main/libn/libnginx-mod-http-zip/libnginx-mod-http-zip_1.3.0-2.gbp4aa963c~trixie_amd64.deb|deb/libnginx-mod-http-zip_1.3.0-2.gbp4aa963c~trixie_amd64.deb"
  "https://yogsottot.github.io/ppa/debian/pool/main/libn/libnginx-mod-http-zstd/libnginx-mod-http-zstd_0.1.1-2.gbp057a7d3~trixie_amd64.deb|deb/libnginx-mod-http-zstd_0.1.1-2.gbp057a7d3~trixie_amd64.deb"
  "https://repo.bitrix.info/vm/push-server-0.4.0.tgz|files/push-server-0.4.0.tgz"
  "https://dev.1c-bitrix.ru/docs/chm_files/debian.zip|files/bitrix-php-configs-debian.zip"
  "https://www.1c-bitrix.ru/download/scripts/bitrixsetup.php|files/bitrixsetup.php"
  "https://www.1c-bitrix.ru/download/scripts/restore.php|files/restore.php"
  "https://get.netdata.cloud/kickstart.sh|scripts/netdata-kickstart.sh"
  "https://packages.sury.org/php/apt.gpg|keys/sury-php.gpg"
  "https://repo.mysql.com/RPM-GPG-KEY-mysql-2023|keys/RPM-GPG-KEY-mysql-2023"
  "https://repo.mysql.com/RPM-GPG-KEY-mysql-2025|keys/RPM-GPG-KEY-mysql-2025"
  "https://repo.percona.com/apt/percona-release_latest.generic_all.deb|keys/percona-release_latest.generic_all.deb"
  "https://yogsottot.github.io/ppa/yogsottot.asc|keys/yogsottot.asc"
)

# sha256sum есть в Debian; в macOS — shasum -a 256
if command -v sha256sum >/dev/null 2>&1; then
  sha256() { sha256sum "$@"; }
else
  sha256() { shasum -a 256 "$@"; }
fi

check_sums() {
  if [[ ! -f "$CHECKSUMS" ]]; then
    echo "Нет $CHECKSUMS — сначала запустите без --check" >&2
    return 1
  fi
  ( cd "$VENDOR" && sha256 -c CHECKSUMS.sha256 )
}

if [[ "${1:-}" == "--check" ]]; then
  check_sums
  exit $?
fi

command -v curl >/dev/null || { echo "Нужен curl" >&2; exit 1; }

for entry in "${ARTIFACTS[@]}"; do
  url="${entry%%|*}"
  rel="${entry##*|}"
  dest="$VENDOR/$rel"
  mkdir -p "$(dirname "$dest")"
  printf '→ %s\n' "$rel"
  # --fail: не сохранять HTML-страницы ошибок вместо файлов
  curl -fsSL --retry 3 --retry-delay 2 -o "$dest.tmp" "$url"
  mv -f "$dest.tmp" "$dest"
done

echo "→ пересчёт контрольных сумм"
( cd "$VENDOR" && find deb files scripts keys -type f | sort | while read -r f; do sha256 "$f"; done > CHECKSUMS.sha256 )
check_sums >/dev/null
echo "Готово: $(wc -l < "$CHECKSUMS") файлов, контрольные суммы совпадают."
