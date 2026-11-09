# **Главное меню**

**Язык:** **RU** · [EN](README_en.md) · [UK](README_uk.md) · [KZ](README_kz.md) · [AZ](README_az.md) · [UZ](README_uz.md) · [TM](README_tm.md) · [TJ](README_tj.md) · [KA](README_ka.md)

![Главное меню](images/main_menu.png)
*Скриншот иллюстративный; актуальный состав пунктов меню — в разделе «Возможности меню» и в справке по клавише `H`.*

# **Информация**
Меню для управления окружением Bitrix на **Debian 12 и Debian 13**.  
Основная целевая платформа — **Debian 13 (trixie)**: проект предназначен для замены окружения CentOS 9 на современных Debian-машинах.

Окружение собрано по **официальной документации 1С-Битрикс** — курс [«Настройка окружения для Debian 13»](https://dev.1c-bitrix.ru/learning/course/index.php?COURSE_ID=32)
(пакеты, Nginx, PHP, Apache, MySQL/MariaDB, PostgreSQL, Redis, push-server) — и по официальным
системным требованиям к продуктам Bitrix. Структура автоматизации следует стандартной схеме
**Ansible** (`playbooks/` + `roles/` с `defaults`, `vars`, `tasks`, `meta`), используются только
модули `ansible.builtin`, без внешних коллекций.

---

# **Состав окружения**

| Компонент | Версия | Примечание |
|-----------|--------|------------|
| Debian | 13 (trixie) | поддерживается также 12 (bookworm) |
| PHP | 8.3 | смена на 8.2 / 8.4 из меню (deb.sury.org) |
| MySQL | 8.4 LTS | на Debian 12 — 8.0 (APT-репозиторий Oracle) |
| Percona Server | 8.4 LTS | альтернатива MySQL |
| Nginx | 1.26 | Debian + модули Brotli, zip, zstd |
| Apache | 2.4 | + mod_php |
| Redis | 8.0 | Debian |
| Node.js | 20 | + push-server 0.4.0 |
| Sphinx | 2.2.11 | устанавливается из меню |
| Почта | exim4 + msmtp | Debian |
| Firewall | nftables | Debian |

> **Важно про MySQL.** Для Debian 13 (trixie) Oracle публикует только ветку **8.4 LTS** — пакетов `mysql-8.0` для trixie нет. Окружение настраивает `mysql_native_password` для совместимости Bitrix и резервного копирования.

## Выбор СУБД: MySQL или Percona Server

При установке можно выбрать Oracle MySQL или **Percona Server for MySQL 8.4 LTS**. Оба варианта используют одинаковые сервис (`mysql.service`), каталог конфигурации (`/etc/mysql/conf.d/99-bitrix.cnf`) и режим авторизации (`mysql_native_password`), поэтому Bitrix работает одинаково.

```bash
# Интерактивный выбор (по умолчанию MySQL)
bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)

# Без вопросов — Percona Server 8.4 LTS
DB_ENGINE=percona bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)

# Без вопросов — Oracle MySQL 8.4 LTS
DB_ENGINE=mysql bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```

Особенности Percona:
- подключаются репозитории `ps-84-lts` и `telemetry` (агент телеметрии — жёсткая зависимость пакета `percona-server-server`);
- **телеметрия отключается** (сервис `percona-telemetry-agent` останавливается и маскируется);
- пакет `percona-server-server` предоставляет `mysql-server`, поэтому все команды и модули Ansible работают без изменений.

> Если `install_full_environment.sh` запущен из клона репозитория, меню и `custom_bitrix_setup.sh` берутся **из локальной копии**, а не с GitHub (удобно для отладки).

---

## Пресеты конфигурации MySQL/Percona под объём RAM

При установке параметры сервера БД подбираются автоматически по объёму оперативной памяти
(`MemTotal` из `/proc/meminfo`).

**Буферы и журналы**

| RAM,&nbsp;ГБ | Буферный пул | Temp-таблицы | Redo-журнал | Лог-буфер |
|---------|--------------|--------------|-------------|-----------|
| <3 | 768M | 64M | 512M | 32M |
| 3&#8209;6 | 1536M | 96M | 768M | 64M |
| 6&#8209;12 | 3072M | 128M | 1G | 96M |
| 12&#8209;24 | 6144M | 128M | 2G | 128M |
| 24&#8209;48 | 12288M | 256M | 4G | 256M |
| ≥48 | 24576M | 256M | 8G | 256M |

**Соединения и кеши**

| RAM,&nbsp;ГБ | Соединений | Кеш таблиц | Кеш потоков | IO |
|---------|------------|------------|-------------|----|
| <3 | 40 | 2000 | 64 | 400&nbsp;/&nbsp;800 |
| 3&#8209;6 | 60 | 4000 | 96 | 600&nbsp;/&nbsp;1200 |
| 6&#8209;12 | 80 | 8000 | 128 | 1000&nbsp;/&nbsp;2000 |
| 12&#8209;24 | 85 | 14336 | 128 | 2000&nbsp;/&nbsp;4000 |
| 24&#8209;48 | 200 | 20000 | 256 | 3000&nbsp;/&nbsp;6000 |
| ≥48 | 300 | 32768 | 256 | 4000&nbsp;/&nbsp;8000 |

Соответствие столбцов параметрам MySQL:

- **Буферный пул** — `innodb_buffer_pool_size` (и `innodb_buffer_pool_instances`);
- **Temp-таблицы** — `tmp_table_size` = `max_heap_table_size`;
- **Redo-журнал** — `innodb_redo_log_capacity`;
- **Лог-буфер** — `innodb_log_buffer_size`;
- **Соединений** — `max_connections`;
- **Кеш таблиц** — `table_open_cache` (и `table_definition_cache`);
- **Кеш потоков** — `thread_cache_size`;
- **IO** — `innodb_io_capacity` / `innodb_io_capacity_max`;
- **Прочие буферы** — `sort_buffer_size`, `join_buffer_size`, `read_buffer_size`,
  `read_rnd_buffer_size`, `key_buffer_size`.

Пресет выбирается по первому подходящему порогу; принудительно задаётся переменной:

```bash
# принудительно пресет под 8 ГБ
MYSQL_PRESET=8g DB_ENGINE=percona bash custom_bitrix_setup.sh
```

Допустимые значения: `2g`, `4g`, `8g`, `16g`, `32g`, `64g` (по умолчанию — `auto`).

### Какие файлы пишутся

Все файлы лежат в `/etc/mysql/conf.d/`:

- `10-bitrix-memory.cnf` — буферный пул, соединения, кеши, temp-таблицы, redo, IO;
- `20-bitrix-logging.cnf` — `log-error`, `general_log`, `slow_query_log`, `sync_binlog`;
- `99-bitrix.cnf` — `bind-address`, `skip-name-resolve`, движок, `sql_mode`, charset,
  аутентификация.

Файлы читаются по алфавиту, поэтому пресет (`10-`) применяется раньше базы (`99-`),
и параметры не дублируются между файлами.

### Совместимость версий

- `innodb_redo_log_capacity` поддерживается MySQL/Percona **8.0.30+** и 8.4; для более старых
  сборок автоматически подставляется `innodb_log_file_size`.
- `mysqlx=OFF`, `mysql_native_password` (8.4), `default-authentication-plugin` (8.0) —
  выбираются по версии сервера.
- Параметры `innodb_change_buffering`, `innodb_lru_scan_depth`, `innodb_max_dirty_pages_pct_lwm`,
  `innodb_flush_neighbors`, `local_infile` проверены на Percona 8.4.

### Защита от неудачного старта

После записи конфигурации сервер перезапускается и проверяется. Если MySQL не поднялся
(слишком большой буферный пул для имеющейся памяти), установщик **автоматически откатывается**
на минимальный набор (128M) и сообщает об этом — установка не прерывается, данные не теряются:

```
Внимание: MySQL не запустился с пресетом 64g. Откат на минимальный набор.
MySQL: применён минимальный набор параметров. Проверьте /var/log/mysql/error.log
```

---

## PostgreSQL для портала Bitrix

PostgreSQL ставится отдельно из меню: **пункт `8` → «Дополнительные компоненты» → `4`**.
MySQL при этом продолжает работать — портал сам выбирает СУБД при установке.

Что делает установка (по [официальной документации 1С-Битрикс](https://dev.1c-bitrix.ru/learning/course/index.php?COURSE_ID=32&LESSON_ID=32926&LESSON_PATH=3903.4862.20866.32912.32926)):

- ставит пакеты `postgresql`, `postgresql-contrib` (на Debian 13 это **PostgreSQL 17**) и
  расширение PHP `pgsql` + `pdo_pgsql` для активной версии PHP;
- переключает `/etc/postgresql/<версия>/main/pg_hba.conf` на парольную аутентификацию:
  `peer` и `scram-sha-256` → `password` (локальные и `host`-подключения, включая `::1/128`);
- задаёт пароль суперпользователя `postgres` и сохраняет его в `/root/.pgpass` (права `0600`);
- создаёт базу `bitrix` с `LC_CTYPE='C.UTF-8' TEMPLATE template0`, пользователя `bitrix`,
  выдаёт `GRANT ALL PRIVILEGES ON DATABASE` и `GRANT CREATE ON SCHEMA public`
  (на PostgreSQL 15+ схема `public` больше не даёт права на создание таблиц по умолчанию);
- включает расширение `pgcrypto` в базе портала;
- проверяет вход по паролю и наличие `pgcrypto`, печатает параметры для установщика Bitrix.

Параметры подключения для установщика портала:

| Параметр | Значение |
|---|---|
| Хост | `127.0.0.1` |
| Порт | `5432` |
| База | `bitrix` |
| Пользователь | `bitrix` |
| Пароль | выводится при установке, хранится в `/root/.postgres_bitrix_password` |

### Пресеты PostgreSQL под объём RAM

Как и для MySQL, `postgresql.conf` настраивается по `MemTotal` — пресеты `2g`…`64g`.

**Память**

| RAM,&nbsp;ГБ | Буферный пул | Кеш планировщика | work_mem | Обслуживание |
|---|---|---|---|---|
| <3 | 512MB | 1536MB | 4MB | 128MB |
| 3&#8209;6 | 1GB | 3GB | 6MB | 256MB |
| 6&#8209;12 | 2GB | 6GB | 8MB | 512MB |
| 12&#8209;24 | 4GB | 12GB | 12MB | 1GB |
| 24&#8209;48 | 8GB | 24GB | 16MB | 1GB |
| ≥48 | 16GB | 48GB | 24MB | 2GB |

**Соединения и буферы WAL**

| RAM,&nbsp;ГБ | Соединений | WAL-буфер | Temp-буфер |
|---|---|---|---|
| <3 | 40 | 16MB | 8MB |
| 3&#8209;6 | 60 | 16MB | 8MB |
| 6&#8209;12 | 80 | 16MB | 16MB |
| 12&#8209;24 | 85 | 16MB | 24MB |
| 24&#8209;48 | 200 | 16MB | 32MB |
| ≥48 | 300 | 16MB | 48MB |

Полные имена параметров: буферный пул — `shared_buffers`, кеш планировщика — `effective_cache_size`, обслуживание — `maintenance_work_mem`, соединения — `max_connections`, WAL-буфер — `wal_buffers`, temp-буфер — `temp_buffers`.

Постоянные параметры для всех пресетов: `checkpoint_completion_target=0.9`,
`random_page_cost=1.1` и `effective_io_concurrency=200` (SSD), `default_statistics_target=100`,
`log_min_duration_statement=1000`, `log_checkpoints=on`, `autovacuum=on`, `jit=off`,
`max_worker_processes` = число vCPU.

Пороги выбора пресета те же, что у MySQL: `<3`, `3–6`, `6–12`, `12–24`, `24–48`, `≥48` ГБ.
Принудительно — переменной `BS_POSTGRES_PRESET` в `config.sh` (`auto` | `2g` … `64g`):

```bash
# в файле /root/vm_menu/bash_scripts/config.sh
BS_POSTGRES_PRESET="8g"
BS_POSTGRES_DATABASE="bitrix"
BS_POSTGRES_USER="bitrix"
```

Файлы на сервере: параметры — `/etc/postgresql/<версия>/main/conf.d/99-bitrix.conf`,
пароли — `/root/.pgpass`, `/root/.postgres_superuser_password`, `/root/.postgres_bitrix_password`.

Удаление (пункт `8` → `4` → `2`) останавливает службу и удаляет пакеты `postgresql*`,
данные `/var/lib/postgresql`, конфигурацию `/etc/postgresql`, логи и сохранённые пароли.
**Вместе с PostgreSQL удаляются все его базы данных**, поэтому меню показывает предупреждение.

---

## Проверено на реальном сервере Debian 13

Установка прогнана на чистой Debian 13 (trixie), amd64, 4 vCPU / 5.8 ГБ RAM. Выбран `DB_ENGINE=percona`.

| Проверка | Результат |
|----------|-----------|
| ОС | Debian 13 (trixie), amd64 |
| PHP | 8.3.36, одна ветка |
| СУБД | Percona 8.4.11 |
| Конфиг MySQL | `my.cnf` → `mysql.cnf` |
| Nginx / Apache | 1.26.3 / 2.4.69 |
| Node.js / push | 20.19.2 / 0.4.0 |
| Сервисы | все 7 — **active** |
| Ansible | `ok=52 failed=0` |
| PostgreSQL | 17.11: установка и удаление из меню — `ok=26` / `ok=12`, `failed=0` |
| Сайт `full` | `example.ru` → `200` |
| Сайт `link` | `shop.example.ru` → `500` |
| Меню | сайты, PHP, SMTP — ОК |

Детали:

- Проверено `php -v`: **единственная** ветка PHP в системе, `/usr/bin/php → /usr/bin/php8.3`.
- СУБД: Percona Server 8.4.11-11, `authentication_policy=mysql_native_password`;
  `/etc/mysql/my.cnf → mysql.cnf`, настройки Bitrix — в `/etc/mysql/conf.d/99-bitrix.cnf`.
- Apache работает с `php8.3` в режиме `mpm_prefork`; push-server — единый сервис pub+sub.
- Сервисы `mysql`, `nginx`, `apache2`, `redis-server`, `push-server`, `exim4`, `nftables` — **active**.
- Ansible: `install_new_full_environment` — `ok=52 failed=0`; остальные 8 плейбуков — `--syntax-check` OK.
- Сайт `full` (`example.ru`): каталог, конфиги nginx+apache, БД, `.settings.php`, `dbconn.php`;
  `bitrixsetup.php` отдаёт `200`.
- Сайт `link` (`shop.example.ru`): симлинк `bitrix → ../example.ru/bitrix`, отдельные конфиги;
  страница отдаёт `500`, пока на основном сайте не установлено ядро Bitrix (ожидаемо).
- Меню: список сайтов, версии PHP, SMTP, справка — работают; смена версии PHP и Let's Encrypt
  требуют внешней сети и на стенде не запускались.

---

# **Возможности окружения**
- Полная автоматическая установка всех необходимых компонентов:  
  **Ansible, PHP 8.3, MySQL 8.4 LTS, Nginx, Apache, Redis, Push & Pull сервер.**
- Поддержка **композита**.
- Отдача статики **через Brotli**.
- Возможность **использовать собственные конфигурации Nginx**, не изменяя стандартные.
- Поддержка **полнотекстового поиска Sphinx**.
- Возможность **установки сервера конвертации документов (LibreOffice + RabbitMQ + transformer)**.
- Возможность **установки и мониторинга Netdata**.

---

# **Возможности меню**
- Просмотр списка сайтов с типом (собственное ядро или ссылки на общее ядро), признаком сайта по умолчанию и статусом HTTPS.
- Создание и удаление сайтов в режимах **ядра (full)** и **символической ссылки (link)**.
- Автоматический перевод агентов на **CRON** при создании сайта в режиме ядра.
- Выпуск **SSL-сертификатов Let’s Encrypt**.
- Управление редиректом **HTTP → HTTPS**.
- **Изменение версий PHP** (8.2 / 8.3 / 8.4).
- **Настройка SMTP** (общий аккаунт `default` и отдельный аккаунт для каждого сайта).
- **Установка и удаление дополнений**: Sphinx, сервер конвертации файлов, Netdata, **PostgreSQL** (с пресетами под объём RAM).
- **Обновление, перезагрузка и выключение сервера** через меню.
- Информирование о выходе новой версии меню.
- **Панель «Состояние сервера»** в шапке: load average, загрузка CPU, память, диск, аптайм
  и статус сервисов. Значения окрашены по порогам (зелёный / жёлтый / красный).
- **Панель «Установлено»**: сайты с типом (`full` / `link`) и пометкой `default`,
  срок действия сертификатов Let’s Encrypt, версия и состояние push&pull,
  установленные дополнения (Sphinx, Netdata, RabbitMQ).
- Цветное оформление меню (отключается настройкой или переменной `NO_COLOR`).
- **Два языка интерфейса — русский и английский** — выбираются автоматически по локали
  системы (`ru_*` → русский, любая другая → английский); можно задать принудительно
  переменной `BS_MENU_LANG`.
- Подробная справка по пунктам — клавиша `H` в меню.
- Обновление меню **всего одной командой**:
  ```bash
  update_menu
  ```

---

# **Установка**
### ⚠ **Важно:** Устанавливать и использовать меню **только от root-пользователя**.

### **Требования**
- Чистая Debian 12 или Debian 13 (рекомендуется Debian 13).
- Архитектура **amd64** (репозиторий MySQL от Oracle не содержит пакетов для других архитектур).
- Доступ в интернет, не менее 2 ГБ RAM (рекомендуется 4 ГБ и больше).
- Домен или IP, указывающий на сервер, — для выпуска сертификатов Let’s Encrypt.

#### **Полная установка окружения на Debian 12 / Debian 13**
##### Установка через `CURL`
```bash
apt install -y curl wget && bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```
##### Установка через `WGET`
```bash
apt install -y curl wget && bash <(wget -qO- https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```

---

# **Обновление меню**
Если вышла новая версия меню, обновить его можно **одной командой**:
```bash
update_menu
```
Меню также можно обновить вручную через `CURL` или `WGET`.  
При обновлении текущая версия **автоматически сохраняется в бэкапе** `/root/backup_vm_menu/ДД.ММ.ГГГГ ЧЧ:ММ:СС`.

#### **Обновление через `CURL`**
```bash
bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/update_menu.sh)
```
#### **Обновление через `WGET`**
```bash
bash <(wget -qO- https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/update_menu.sh)
```

---

# **Использование**
Меню устанавливается в **`/root/vm_menu`**, а для удобства создаётся **символическая ссылка**:
- `/root/menu.sh` → `/root/vm_menu/menu.sh`

Можно запускать меню командами:
```bash
./menu.sh   # Если находишься в /root
/root/menu.sh   # Если находишься в любой другой директории
```
Также путь к меню **автоматически прописывается в `.profile`**, так что оно запускается сразу при подключении по **SSH**.

---

# **Настройки**
Меню гибко настраивается.  
Все параметры можно изменить в файле:
```bash
/root/vm_menu/bash_scripts/config.sh
```
По умолчанию там уже всё настроено, но при необходимости можно подстроить окружение под свои задачи.

Ключевые параметры:

| Параметр | По умолчанию | Назначение |
|----------|--------------|------------|
| `BS_MENU_LANG` | `auto` | язык интерфейса: `auto`, `ru`, `en` |
| `BS_POSTGRES_PRESET` | `auto` | пресет PostgreSQL: `auto`, `2g`…`64g` |
| `BS_POSTGRES_DATABASE` | `bitrix` | имя базы PostgreSQL для портала |
| `BS_POSTGRES_USER` | `bitrix` | пользователь базы PostgreSQL |
| `BS_PATH_SITES` | `/var/www/html` | каталог сайтов |
| `BS_DEFAULT_SITE_NAME` | `bx-site` | сайт-источник ядра для `link` |
| `BS_USER_SERVER_SITES` | `www-data` | пользователь сайтов |
| `BS_PHP_VERSION_DEFAULT` | `8.3` | версия PHP по умолчанию |
| `BS_MYSQL_VERSION_DEFAULT` | `8.4` | версия MySQL |
| `BS_PUSH_SERVER_VERSION` | `0.4.0` | версия push-server |

Оформление шапки и панелей:

| Параметр | По умолчанию | Назначение |
|----------|--------------|------------|
| `BS_SHOW_IP_CURRENT_SERVER_IN_MENU` | `true` | интерфейсы и IP в шапке |
| `BS_STATUS_PANEL` | `true` | панель «Состояние сервера» |
| `BS_STATUS_PANEL_SITES` | `true` | панель «Установлено» |
| `BS_STATUS_MAX_SITES` | `5` | сколько сайтов перечислять |
| `BS_STATUS_PANEL_WIDTH` | `52` | ширина панелей, символов |
| `BS_CPU_SAMPLE_MS` | `200` | окно замера CPU, мс |
| `BS_USE_COLOR` | `true` | цвета (или `NO_COLOR=1`) |

### Язык интерфейса

Меню двуязычное: русский и английский. Язык выбирается автоматически по локали системы:

| Локаль | Язык меню |
|--------|-----------|
| `ru_RU.UTF-8` (или любая `ru_*`) | русский |
| любая другая, включая `C.UTF-8` и `en_US.UTF-8` | английский |

Принудительный выбор — переменной окружения или параметром `BS_MENU_LANG` в `config.sh`:

```bash
# английский интерфейс на сервере с русской локалью
BS_MENU_LANG=en /root/menu.sh

# русский интерфейс на сервере с английской локалью
BS_MENU_LANG=ru /root/menu.sh
```

Переводы строк хранятся в одном файле — `/root/vm_menu/bash_scripts/i18n.sh`: два словаря
(`MSG_RU`, `MSG_EN`) и функция `t`; любая строка интерфейса вызывается как `t key`.

### Панель «Состояние сервера»

В шапке меню выводится компактная панель:

```
   ┌──────────────── Состояние сервера ─────────────────┐
   │ Загрузка   0.06 0.02 0.00   4 CPU                  │
   │ CPU        3%                                      │
   │ Память     1,0 / 5,8 ГБ (17%)                      │
   │ Диск /     4,9G / 30G (18%)                        │
   │ Аптайм     58 мин                                  │
   └────────────────────────────────────────────────────┘
```

Данные берутся из `/proc` (`loadavg`, `stat`, `meminfo`, `uptime`) и `df`, без установки
дополнительных пакетов. Пороги подсветки: до **70%** — зелёный, **70–89%** — жёлтый,
**90% и выше** — красный. Если вывод направлен не в терминал или задан `NO_COLOR=1`,
цвета отключаются автоматически, чтобы не ломать логи.

### Панель «Установлено»

Вторая панель отвечает на вопрос «что уже развёрнуто», чтобы администратору не приходилось
держать это в голове:

```
   ┌─────────────────── Установлено ────────────────────┐
   │ Сайты (3)                                          │
   │   example.ru             full   SSL 59 дн.         │
   │   shop.example.ru        link   SSL 9 дн.          │
   │   bx-site                full · default   без SSL  │
   │ Push&Pull  0.4.0  active                           │
   │ Дополнения не установлены                          │
   └────────────────────────────────────────────────────┘
```

- **Сайты** — каталоги из `/var/www/html`, тип `full` / `link`, пометка `default` у сайта по умолчанию.
- **SSL** — остаток дней сертификата из `/etc/letsencrypt/live/<домен>/cert.pem`;
  меньше 30 дней — жёлтый, меньше 14 — красный. Сайты без сертификата помечены «без SSL».
- **Push&Pull** — версия из `/opt/push-server/package.json` и состояние сервиса.
- **Дополнения** — Sphinx, Netdata, RabbitMQ (определяются по наличию unit-файлов).

Список сайтов ограничен параметром `BS_STATUS_MAX_SITES` (по умолчанию 5), остальные
показываются строкой «… и ещё N». Панель отключается через `BS_STATUS_PANEL_SITES=false`.

---

# **Как устроены сайты**

Меню поддерживает два режима создания сайта:

- **`full` (ядро)** — в каталоге сайта создаётся собственное ядро Bitrix (`bitrix/`, `local/`, `upload/`, `images/`), отдельная база данных и пользователь MySQL, генерируются `.settings.php` и `dbconn.php`. Агенты Bitrix переводятся на CRON. Рекомендуется для нового сайта.
- **`link` (символические ссылки)** — каталоги `local`, `bitrix`, `upload`, `images` ссылаются на ядро существующего сайта. Используется для мультисайтовости: одно ядро — много доменов.

При создании сайта можно сразу:
- выпустить сертификат **Let’s Encrypt**;
- включить **редирект HTTP → HTTPS**.

Удаление сайта (пункт `3`) удаляет каталог, конфигурации Nginx/Apache, а для режима `full` — базу данных и пользователя MySQL. Для подтверждения нужно ввести имя сайта.

### Сертификаты Let’s Encrypt
Выпуск идёт по протоколу **HTTP-01**: домен должен уже указывать на сервер, порт 80 — быть доступен извне. При выпуске сертификата Nginx автоматически переключается на полученные файлы (блок с комментариями `MANAGED SSL CERTS` в конфигурации сайта).

### SMTP
Письма отправляются через `msmtp`. Настройки хранятся в `/var/www/html/.msmtprc` (права `0600`, владелец `www-data`).
- Аккаунт для сайта должен называться **так же, как домен сайта** — Apache передаёт домен в `msmtp-wrapper`.
- Аккаунт **`default`** используется, если для сайта аккаунт не найден.
- Просмотреть сохранённые аккаунты можно в пункте `7` → «Показать сохранённые аккаунты».

### Смена версии PHP
Пункт `6` устанавливает выбранную версию из репозитория deb.sury.org, подключает `mod_php` этой версии в Apache и переключает CLI через `update-alternatives`. Настройки Bitrix (`php.d` из документации 1С-Битрикс) применяются к новой версии автоматически.

### Дополнения
Пункт `8`:
- **Sphinx** — полнотекстовый поиск (пакет `sphinxsearch`, отдельный systemd-сервис).
- **Сервер конвертации файлов** — LibreOffice, RabbitMQ и служба `transformer` для сайта.
- **Netdata** — мониторинг. Доступен по адресу `https://<домен>/netdata/`, логин `admin`; пароль создаётся при установке и выводится в выводе Ansible (сохраняется в `/root/.netdata_web_password`).

---

# **Где смотреть логи и данные**

| Что | Где |
|-----|-----|
| Журнал установки окружения | `/root/recipe.log` |
| Ошибки PHP | `/var/log/php/error.log` |
| Исключения Bitrix | `/var/log/php/exceptions.log` |
| Логи Nginx | `/var/log/nginx/` |
| Логи Apache | `/var/log/apache2/` |
| CRON-логи агентов Bitrix | `/var/log/bitrix_cron_agents/` |
| Пароль root MySQL | `/root/.my.cnf` |
| Пароль пользователя сайтов | выводится в конце установки |

---

# **Обновления и новые возможности**
Меню автоматически **информирует о выходе новых версий**.  
Обновление можно выполнить командой:
```bash
update_menu
```
Если меню сломалось из-за экспериментов или изменений — просто **запусти обновление**, и оно **вернётся к рабочей версии**.

---

# **Частые вопросы и проблемы**

**Установка прервалась на MySQL.**  
Проверьте `/root/recipe.log`. Для Debian 13 используется компонент `mysql-8.4-lts`; ветки `mysql-8.0` для trixie в репозитории Oracle нет. Убедитесь, что архитектура — `amd64`.

**Сайт отдаёт 500, в логах Nginx «FastCGI sent in stderr …».**
Смотрите `/var/log/php/error.log` и `/var/log/apache2/error_<домен>_log`. Чаще всего причина — ошибка в `dbconn.php`/`.settings.php` или несовместимость старого кода с новой версией PHP.

**После смены версии PHP сайт перестал работать.**
Верните предыдущую версию пунктом `6` и проверьте `/var/log/php/error.log`. Для старого кода может потребоваться `short_open_tag=On` — он уже включён в конфигурации Bitrix.

**Let’s Encrypt не выпускает сертификат.**
Проверьте, что домен резолвится в этот сервер и порт 80 открыт: `curl -I http://<домен>/.well-known/acme-challenge/test`. Логи — `/var/log/letsencrypt/`.

**Не уходят письма.**
Проверьте `/var/www/html/.msmtprc`, журнал аккаунта (`/var/www/html/msmtp_<аккаунт>.log`) и тест: `echo test | msmtp -C /var/www/html/.msmtprc -a default`.

**Дополнения: Sphinx, Netdata, конвертер файлов.**

- *Sphinx* использует **RT-индекс** `bitrix`: `indexer` для него не нужен (сообщение «no indexes found» — норма).
  Проверка: `mysql -h 127.0.0.1 -P 9306 -e "SHOW TABLES;"` → таблица `bitrix`.
- *Netdata* ставится набором пакетов (`netdata`, `netdata-plugin-*`, `netdata-dashboard`), поэтому удаление
  убирает их все — иначе `dpkg` зацикливается на взаимных зависимостях и повторная установка падает.
- *Сервер конвертации*: служба `transformer` требует установленного **ядра Bitrix с модулем**
  `transformercontroller`. Если ядра нет, служба создаётся, но не запускается — в выводе будет предупреждение.
  После установки ядра через `bitrixsetup.php` повторите пункт `8 → 2`.

**Sphinx не запускается.**
`systemctl status sphinxsearch`, логи `/var/log/sphinxsearch/searchd.log`. Конфигурация — `/etc/sphinxsearch/sphinx.conf`.

**После установки в системе несколько версий PHP (`7.4`, `8.3`, `8.5`) и `/usr/bin/php` смотрит не туда.**
Причина — пакеты-**метапакеты** из `deb.sury.org`: `php-pear` требует `php-xml` и подтягивает PHP 7.4, а `php-redis`/`php-igbinary` ставят самую новую ветку (8.5). Установщик использует только версионные пакеты (`php8.3-redis`, `php8.3-igbinary`). Если лишние ветки уже появились:
```bash
apt-get purge -y php-pear php-redis php-geoip php-igbinary "php7.4-*" "php8.5-*"
apt-get install -y php8.3-redis php8.3-igbinary
readlink -f /usr/bin/php   # должно быть /usr/bin/php8.3
```

**Настройки Bitrix для MySQL «не применяются» (`sql_mode`, `innodb_buffer_pool_size` и т. п.).**
На Debian 12/13 `/etc/mysql/my.cnf` — это symlink, которым управляет `update-alternatives`. Установка `libreoffice-sdbc-mysql` приносит `mariadb-common`, а тот регистрирует `mariadb.cnf` с приоритетом **500** и переключает ссылку на себя. `mariadb.cnf` подключает `conf.d` и `mariadb.conf.d`, но **не** `mysql.conf.d`. Поэтому установщик пишет настройки в `/etc/mysql/conf.d/99-bitrix.cnf` и поднимает приоритет `mysql.cnf` до 700. Проверка:
```bash
readlink -f /etc/mysql/my.cnf        # /etc/mysql/mysql.cnf
mysql -e "select @@transaction_isolation, @@authentication_policy"
```

**Пользователь MySQL не может подключиться после обновления до 8.4 (ошибка аутентификации).**
В MySQL/Percona 8.4 плагин `mysql_native_password` выключен по умолчанию, а `CREATE USER IF NOT EXISTS` не меняет плагин у существующей учётки. Установщик задаёт `authentication_policy=mysql_native_password`, включает плагин и создаёт/переводит пользователей через `IDENTIFIED WITH mysql_native_password`. Проверка:
```bash
mysql -e "select user, host, plugin from mysql.user"
```

**Установка «зависла» на шаге `Restart getty@tty1.service`, SSH отвалился, `systemctl` пишет `Transport endpoint is not connected`.**
Этот шаг — наследие CentOS (показ IP на консоли). На Debian перезапуск `getty@tty1` не завершается и подвешивает PID 1; лечится только принудительной перезагрузкой:
```bash
sync; echo s > /proc/sysrq-trigger; echo u > /proc/sysrq-trigger; echo b > /proc/sysrq-trigger
```
В актуальной версии плейбука этот блок удалён — обновите меню командой `update_menu`.

---

# **Поддержка, вопросы по локализации решений и шаблонов Битрикс на языки, предложения**
Если у вас есть вопросы или предложения, присоединяйтесь:
[**Telegram-чат поддержки**](https://t.me/bitrix_ferma)

