# bitrix-gt

Основано и переработано из **bitrix-gt** от **firstvds**.

В данном репозитории собраны скрипты для установки окружения Bitrix на **Debian 11** и **Debian 12**.  
Расширенный скрипт **`custom_bitrix_setup.sh`** добавляет **меню, аналогичное окружению для CentOS**, и включает автоматическую установку **MySQL 8** из официального репозитория Oracle.

## Доступные скрипты

### Основные скрипты

- **`bitrix_gt.sh`**  
  Установка **nginx + apache + php-fpm + mariadb** для **1С-Битрикс: Управление сайтом**.

- **`bitrix24_gt.sh`**  
  Установка **nginx + apache + php-fpm + mariadb + redis + push-server** для **Bitrix24**.

- **`bitrix_setup_vanilla.sh`**  
  Установка **nginx + apache + mariadb + redis + push-server**.  
  Воспроизводит официальное руководство [Настройка окружения для Debian 11](https://dev.1c-bitrix.ru/learning/course/index.php?COURSE_ID=32&CHAPTER_ID=05360&LESSON_PATH=3903.4862.20866.5360).

### Расширенный скрипт

- **`custom_bitrix_setup.sh`**  
  Кастомизированный скрипт установки Bitrix, основанный на уже имеющихся решениях. Отличается следующими особенностями:
  - **Меню, аналогичное окружению для CentOS**, что упрощает первичную настройку сервера.
  - **Автоматическая установка MySQL 8** из официального репозитория Oracle.
  - Оптимизирован для работы на **Debian 11** и **Debian 12**.
  - Воспроизводит официальное руководство [Настройка окружения для Debian 11](https://dev.1c-bitrix.ru/learning/course/index.php?COURSE_ID=32&CHAPTER_ID=05360&LESSON_PATH=3903.4862.20866.5360), но с дополнительными улучшениями и расширениями (Redis, push-сервер и т. д.).

## Альтернативные решения для развёртывания Bitrix

Если вам требуется другое окружение, вы можете также обратить внимание на:
- [ISPConfig сервер](https://github.com/Wladimir-N/ispconfig)
- [Bitrix Docker сервер](https://gitlab.com/bitrix-docker/server)

---

## Список пакетов и их назначение

Ниже перечислены пакеты, которые устанавливаются или упоминаются в двух основных скриптах для развёртывания окружения на Debian — **`install_full_environment.sh`** и **`custom_bitrix_setup.sh`**.

### 1. Ansible
**Назначение:** используется для финальной конфигурации окружения (запуск Ansible playbooks).

### 2. Apache2
**Назначение:** классический веб-сервер. Чаще всего Bitrix запускается на Apache, иногда совместно с Nginx.

### 3. apt-transport-https
**Назначение:** позволяет утилите `apt` скачивать пакеты по HTTPS.

### 4. build-essential
**Назначение:** базовый набор инструментов для компиляции (gcc, make и т. д.). Может понадобиться для сборки PHP-расширений или других библиотек.

### 5. ca-certificates
**Назначение:** набор корневых сертификатов (CA), необходим для корректной проверки SSL-сертификатов (https-запросы).

### 6. catdoc
**Назначение:** утилиты для конвертации документов Microsoft Word (.doc) в текст (бывает полезно при поисковой индексации в Bitrix).

### 7. cron
**Назначение:** планировщик заданий для системных скриптов и cron-агентов 1С-Битрикс.

### 8. curl / wget
**Назначение:** утилиты для скачивания файлов из интернета (репозитории, скрипты и т. д.).

### 9. debconf-utils
**Назначение:** позволяет автоматически «отвечать» на вопросы debconf (автоматизация установки пакетов в неинтерактивном режиме).

### 10. exim4 / exim4-config
**Назначение:** почтовый сервер (MTA). Используется для отправки системных уведомлений, писем с сайта и т. д.

### 11. git
**Назначение:** система контроля версий, используется для клонирования репозиториев (например, меню `vm_menu`).

### 12. gnupg2
**Назначение:** инструменты работы с GPG-ключами (подпись пакетов, добавление ключей репозиториев и пр.).

### 13. imagemagick
**Назначение:** набор утилит для обработки изображений (конвертация, сжатие). Может использоваться вместе с PHP Imagick.

### 14. libnginx-mod-http-brotli-filter / libnginx-mod-http-brotli-static
**Назначение:** модули Brotli для Nginx, обеспечивают дополнительное сжатие статики.

### 15. libreoffice
**Назначение:** офисный пакет, который вместе с `unoconv` позволяет конвертировать офисные файлы в PDF или другие форматы.

### 16. locales / locales-all
**Назначение:** пакеты локализации (генерация нужной локали, например `ru_RU.UTF-8`) для корректной работы с мультиязычными данными.

### 17. lsb-release
**Назначение:** утилита, позволяющая получить информацию о дистрибутиве (например, `lsb_release -sc`), используется для добавления репозиториев.

### 18. make
**Назначение:** часть базового комплекта для сборки (обычно идёт вместе с build-essential).

### 19. mysql-server (MySQL 8.0)
**Назначение:** основная СУБД для хранения данных Bitrix. Ставится из официального репозитория Oracle. Заменяет MariaDB.

### 20. nftables
**Назначение:** современная подсистема файрвола в Linux (замена iptables). Настраивается для фильтрации и открытия нужных портов.

### 21. nodejs / npm
**Назначение:** нужны для установки и запуска push-сервера (push-server для веб-сокетов, уведомлений Bitrix24).

### 22. perl
**Назначение:** язык Perl, используется во многих системных скриптах и пакетах.

### 23. PHP-пакеты (для PHP 8.2):
**php8.2 php8.2-cli php8.2-common php8.2-gd php8.2-ldap php8.2-mbstring php8.2-mysql php8.2-opcache php8.2-zip php8.2-pspell php8.2-xml php-pear php8.2-apcu php8.2-curl php-redis php-geoip php8.2-mcrypt php8.2-memcache php8.2-dev php8.2-maxminddb php8.2-imagick php8.2-http**  
**Назначение:**  
- *php8.2*: основной интерпретатор PHP 8.2  
- *php8.2-cli / php8.2-common*: базовый набор для запуска PHP-скриптов  
- *php8.2-gd / php8.2-imagick*: обработка изображений  
- *php8.2-ldap*: работа с LDAP (если нужно авторизовывать через LDAP)  
- *php8.2-mbstring*: корректная работа с многобайтными строками (必需 для Битрикс)  
- *php8.2-mysql*: драйвер для MySQL (mysqli, PDO)  
- *php8.2-opcache*: кеш байткода PHP (ускорение)  
- *php8.2-zip*: работа с zip-архивами  
- *php8.2-pspell*: проверка орфографии  
- *php8.2-xml*: XML-функциональность  
- *php-pear*: менеджер пакетов PEAR  
- *php8.2-apcu*: кеш объектов/данных в PHP  
- *php8.2-curl*: расширение cURL, HTTP-запросы из PHP  
- *php-redis*: расширение Redis для PHP  
- *php-geoip / php8.2-maxminddb*: определение геолокации по IP (GeoIP/MaxMind)  
- *php8.2-mcrypt / php8.2-memcache / php8.2-http / php8.2-dev*: дополнительные модули, необходимые для некоторых скриптов и сервисов

### 24. poppler-utils
**Назначение:** утилиты для работы с PDF (напр. `pdftotext`), полезно для индексирования документов.

### 25. pwgen
**Назначение:** утилита для генерации сильных случайных паролей.

### 26. redis
**Назначение:** in-memory хранилище Redis, используется для кеширования и сообщений (PUB/SUB) в Bitrix, а также совместно с push-сервером.

### 27. rsync
**Назначение:** синхронизация и копирование файлов и директорий (используется для копирования конфигов).

### 28. software-properties-common
**Назначение:** набор скриптов для управления репозиториями (включая `add-apt-repository` и т. д.).

### 29. ssl-cert
**Назначение:** инструменты для генерации самоподписанных сертификатов и работы с SSL.

### 30. unoconv
**Назначение:** конвертация офисных документов (вместе с LibreOffice).

### 31. unzip
**Назначение:** распаковка zip-архивов (для установки Bitrix-конфигов, пакетов и пр.).

---

**Примечание:**  
В процессе установки скрипты также могут подгружать дополнительные зависимости (например, вспомогательные библиотеки для cURL или PHP) — это часть стандартного процесса работы `apt-get`.

---

**© Bx-Project-Hub / DebianBitrixVM**  
