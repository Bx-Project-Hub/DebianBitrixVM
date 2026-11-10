# **Головне меню**

**Мова:** [RU](README.md) · [EN](README_en.md) · **UK** · [KZ](README_kz.md) · [AZ](README_az.md) · [UZ](README_uz.md) · [TM](README_tm.md) · [TJ](README_tj.md) · [KA](README_ka.md)

![Головне меню](images/main_menu_en.png)

# **Інформація**
Меню для керування середовищем Bitrix, адаптоване для **Debian 12 / Debian 13**. Основна мета — Debian 13 (trixie): проєкт замінює середовище CentOS 9 на сучасних Debian-машинах.  
Оточення зібрано за **офіційною документацією 1С-Бітрікс** — курс [«Налаштування оточення для Debian 13»](https://dev.1c-bitrix.ru/learning/course/index.php?COURSE_ID=32) (пакети, Nginx, PHP, Apache, MySQL/MariaDB, PostgreSQL, Redis, push-server) — та за офіційними системними вимогами до продуктів Bitrix. Автоматизація побудована за **стандартною схемою Ansible** (`playbooks/` + `roles/` з `defaults`, `vars`, `tasks`, `meta`), використовуються лише модулі `ansible.builtin`, без зовнішніх колекцій.

---

# **Можливості середовища**
- Повна автоматична установка всіх необхідних компонентів:  
  **Ansible, PHP 8.3 (за замовчуванням), MySQL 8.4 LTS, Nginx, Apache, Redis, Push & Pull сервер.**
- **Вибір СУБД: Oracle MySQL 8.4 LTS або Percona Server 8.4 LTS** (змінна `DB_ENGINE`).
- **Підтримка композиту**.
- Віддача статичних файлів **через Brotli**.
- Можливість **використовувати власні конфігурації Nginx**, не змінюючи стандартні.
- Підтримка **повнотекстового пошуку Sphinx**.
- Можливість **встановлення сервера конвертації документів (`LibreOffice`, `ImageMagick`)**.
- Можливість **встановлення та моніторингу Netdata**.

---

# **Можливості меню**
- Перегляд списку сайтів.
- Створення та видалення сайтів у режимах **ядра та символічного посилання**.
- Автоматичне переведення агентів на **CRON** при створенні сайту в режимі ядра.
- Випуск **SSL-сертифікатів Let’s Encrypt**.
- Керування редиректом **HTTP → HTTPS**.
- **Зміна версій PHP**.
- **Налаштування SMTP** (глобально та індивідуально для кожного сайту).
- **Оновлення, перезавантаження та вимкнення сервера** через меню.
- Повідомлення про вихід нової версії меню.
- Оновлення меню **однією командою**:
  ```bash
  update_menu
  ```
- **Дві мови інтерфейсу — російська та англійська** — визначаються автоматично за локаллю системи (`ru_*` → російська, будь-яка інша → англійська); можна задати примусово змінною `BS_MENU_LANG`.
- **PostgreSQL для Bitrix** — встановлення й видалення з меню доповнень, з пресетами `postgresql.conf` під обсяг RAM.

---

# **Встановлення**
### ⚠ **Важливо:** Встановлювати та використовувати меню **тільки від root-користувача**.

#### **Повне встановлення середовища на Debian 12 / Debian 13**
##### Встановлення через `CURL`
```bash
apt install -y curl wget && bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```
##### Встановлення через `WGET`
```bash
apt install -y curl wget && bash <(wget -qO- https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```

---

## Вибір СУБД: MySQL або Percona Server
Інсталятор дозволяє вибрати **Oracle MySQL 8.4 LTS** або **Percona Server for MySQL 8.4 LTS**. Обидва варіанти використовують той самий сервіс (`mysql.service`), каталог конфігурації (`/etc/mysql/conf.d/99-bitrix.cnf`) і режим автентифікації (`mysql_native_password`), тому Bitrix працює однаково.

```bash
# Інтерактивний вибір (за замовчуванням MySQL)
bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)

# Percona Server 8.4 LTS, без питань
DB_ENGINE=percona bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)

# Oracle MySQL 8.4 LTS, без питань
DB_ENGINE=mysql bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```

**Перевірено на чистій Debian 13 (trixie), amd64:** PHP 8.3.36 (єдина гілка PHP у системі), MySQL/Percona 8.4.11, Nginx 1.26.3, Apache 2.4.69, Node.js 20.19.2, push-server 0.4.0; усі сервіси активні; створення сайту в режимах `full` і `link` працює.

## Пресети конфігурації MySQL/Percona під обсяг RAM

Під час встановлення параметри сервера БД добираються автоматично за обсягом оперативної пам’яті (`MemTotal` з `/proc/meminfo`).

| RAM, ГБ | Буферний пул | Temp-таблиці | Redo-журнал | Лог-буфер |
|-----|-----|-----|-----|-----|
| <3 | 768M | 64M | 512M | 32M |
| 3&#8209;6 | 1536M | 96M | 768M | 64M |
| 6&#8209;12 | 3072M | 128M | 1G | 96M |
| 12&#8209;24 | 6144M | 128M | 2G | 128M |
| 24&#8209;48 | 12288M | 256M | 4G | 256M |
| ≥48 | 24576M | 256M | 8G | 256M |

| RAM, ГБ | З’єднань | Кеш таблиць | Кеш потоків | IO |
|-----|-----|-----|-----|-----|
| <3 | 40 | 2000 | 64 | 400&nbsp;/&nbsp;800 |
| 3&#8209;6 | 60 | 4000 | 96 | 600&nbsp;/&nbsp;1200 |
| 6&#8209;12 | 80 | 8000 | 128 | 1000&nbsp;/&nbsp;2000 |
| 12&#8209;24 | 85 | 14336 | 128 | 2000&nbsp;/&nbsp;4000 |
| 24&#8209;48 | 200 | 20000 | 256 | 3000&nbsp;/&nbsp;6000 |
| ≥48 | 300 | 32768 | 256 | 4000&nbsp;/&nbsp;8000 |

Пресет вибирається за першим відповідним порогом; примусово задається змінною:

```bash
MYSQL_PRESET=8g DB_ENGINE=percona bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```

Допустимі значення: `2g`, `4g`, `8g`, `16g`, `32g`, `64g` (за замовчуванням — `auto`). Параметри записуються в `/etc/mysql/conf.d/10-bitrix-memory.cnf`.

## PostgreSQL для порталу Bitrix

Встановлюється з меню: пункт `8` → «Додаткові компоненти» → `4`. MySQL продовжує працювати — СУБД вибирається під час встановлення порталу.

| RAM, ГБ | Буферний пул | Кеш планувальника | work_mem | Обслуговування |
|---|---|---|---|---|
| <3 | 512MB | 1536MB | 4MB | 128MB |
| 3&#8209;6 | 1GB | 3GB | 6MB | 256MB |
| 6&#8209;12 | 2GB | 6GB | 8MB | 512MB |
| 12&#8209;24 | 4GB | 12GB | 12MB | 1GB |
| 24&#8209;48 | 8GB | 24GB | 16MB | 1GB |
| ≥48 | 16GB | 48GB | 24MB | 2GB |

| RAM, ГБ | З’єднань | WAL-буфер | Temp-буфер |
|---|---|---|---|
| <3 | 40 | 16MB | 8MB |
| 3&#8209;6 | 60 | 16MB | 8MB |
| 6&#8209;12 | 80 | 16MB | 16MB |
| 12&#8209;24 | 85 | 16MB | 24MB |
| 24&#8209;48 | 200 | 16MB | 32MB |
| ≥48 | 300 | 16MB | 48MB |

Повні назви параметрів: буферний пул — `shared_buffers`, кеш планувальника — `effective_cache_size`, обслуговування — `maintenance_work_mem`, з’єднання — `max_connections`, WAL-буфер — `wal_buffers`, temp-буфер — `temp_buffers`.

Створюється автоматично: база `bitrix` (`LC_CTYPE='C.UTF-8' TEMPLATE template0`), користувач `bitrix`, `GRANT CREATE` на схему `public`, розширення `pgcrypto`, парольна аутентифікація в `pg_hba.conf`.

Пресет вибирається за першим відповідним порогом; примусово — `BS_POSTGRES_PRESET` у `config.sh`.

## Вкладені залежності (`vendor/`)

Усе, що раніше завантажувалося з чужих сайтів, лежить у репозиторії — `vendor/`: модулі
nginx gzip/zstd (яких немає в Debian), push&pull-сервер, конфіги Bitrix для PHP/Nginx/Apache,
скрипти встановлення Bitrix, скрипт встановлення Netdata та ключі репозиторіїв. Інсталятор
копіює `vendor` у `/root/vm_menu/vendor`, перевіряє `vendor/CHECKSUMS.sha256` і бере файли звідти;
мережа використовується лише за відсутності локальної копії. Оновлення —
`tools/vendor-fetch.sh`, перевірка — `tools/vendor-fetch.sh --check`. Репозиторії Debian,
deb.sury.org, MySQL/Percona та Netdata навмисно залишаються зовнішніми: це джерела пакетів
і оновлень безпеки, вкладені копії застаріли б одразу.

### Скрипт restore.php — лише за запитом

`restore.php` розгортає на сервері архів резервної копії, тому постійно тримати його в каталозі
сайту небезпечно. На відміну від `bitrixsetup.php` він **не зберігається** у `vendor/`, **не
копіюється** під час створення сайту і розміщується **лише за запитом** з меню
(`8` → `5` → `1`) безпосередньо з офіційної адреси
`https://www.1c-bitrix.ru/download/files/scripts/restore.php` (власник — користувач сайту,
права `0640`). Після відновлення порталу скрипт треба видалити (`8` → `5` → `2`).
Реалізовано роллю `manage_restore_script` (`PLACE` / `REMOVE`) і плейбуком
`manage_restore_script.yaml`.

Сторінка нового сайту (`index.html`) генерується шаблоном `site_full_tpl/index.j2`:
картка з кроками встановлення та кнопкою майстра; посилання на `restore.php` немає —
лише нагадування, як розмістити скрипт із меню та видалити після відновлення.

Офіційні джерела: сервер push&pull — `https://repo.bitrix24.tech/vm/push-server-0.4.0.tgz`,
конфігурації PHP/Nginx/Apache — `https://dev.1c-bitrix.ru/docs/chm_files/debian.zip`,
інсталятор — `https://www.1c-bitrix.ru/download/scripts/bitrixsetup.php`.

### Контроль цілісності (SHA256)

Кожен скрипт, конфіг і пакет має контрольну суму. Маніфести лежать у репозиторії:
`CHECKSUMS.sha256` (корінь: інсталятор, оновлювач, `tools/`, `repositories/`),
`vm_menu/CHECKSUMS.sha256` (усе меню: `menu.sh`, `bash_scripts/`, плейбуки й ролі `ansible/`,
шаблони та конфіги) і `vendor/CHECKSUMS.sha256` (вкладені пакети й файли).

Перевірки виконуються автоматично: під час встановлення (`sha256sum -c` за всіма маніфестами,
розбіжність перериває встановлення), під час оновлення меню (завантажене меню перевіряється
до заміни робочої копії), перед встановленням вкладених `.deb` nginx і у `vendor_get` перед
використанням будь-якого вкладеного файлу. Перерахувати маніфести —
`tools/checksums.sh --update`, перевірити — `tools/checksums.sh --check`.

---

# **Оновлення меню**
Якщо вийшла нова версія меню, оновити його можна **однією командою**:
```bash
update_menu
```
Меню також можна оновити вручну через `CURL` або `WGET`.  
При оновленні поточна версія **автоматично зберігається у резервній копії** `/root/backup_vm_menu/ДД.ММ.ГГГГ ЧЧ:ММ:СС`.

#### **Оновлення через `CURL`**
```bash
bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/update_menu.sh)
```
#### **Оновлення через `WGET`**
```bash
bash <(wget -qO- https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/update_menu.sh)
```

---

# **Використання**
Меню встановлюється в **`/root/vm_menu`**, а для зручності створюється **символічне посилання**:
- `/root/menu.sh` → `/root/vm_menu/menu.sh`

Можна запускати меню командами:
```bash
./menu.sh   # Якщо знаходишся в /root
/root/menu.sh   # Якщо знаходишся в іншій директорії
```
Також шлях до меню **автоматично прописується в `.profile`**, тож воно запускається одразу при підключенні через **SSH**.

---

# **Налаштування**
Меню гнучко налаштовується.  
Усі параметри можна змінити у файлі:
```bash
/root/vm_menu/bash_scripts/config.sh
```
За замовчуванням там уже все налаштовано, але за потреби можна підлаштувати середовище під свої завдання.

### Мова інтерфейсу

Меню двомовне: російська та англійська. Мова визначається автоматично за локаллю системи:
`ru_RU.UTF-8` (або будь-яка `ru_*`) — російська; будь-яка інша, зокрема `uk_UA.UTF-8` і `C.UTF-8` — англійська.

Примусовий вибір — змінна оточення або параметр `BS_MENU_LANG` у `config.sh`:

```bash
BS_MENU_LANG=en /root/menu.sh   # англійська на сервері з російською локаллю
BS_MENU_LANG=ru /root/menu.sh   # російська на сервері з англійською локаллю
```

Усі рядки інтерфейсу зберігаються в одному файлі — `/root/vm_menu/bash_scripts/i18n.sh`
(словники `MSG_RU` і `MSG_EN`).

---

# **Оновлення та нові можливості**
Меню автоматично **інформує про вихід нових версій**.  
Оновлення можна виконати командою:
```bash
update_menu
```
Якщо меню перестало працювати через експерименти чи зміни — просто **запусти оновлення**, і воно **повернеться до робочої версії**.

---

# **Підтримка, локалізація та пропозиції**
Якщо у вас є запитання або пропозиції, приєднуйтесь:
[**Telegram-чат підтримки**](https://t.me/bitrix_ferma)

