# **Main Menu**

**Language:** [RU](README.md) · **EN** · [UK](README_uk.md) · [KZ](README_kz.md) · [AZ](README_az.md) · [UZ](README_uz.md) · [TM](README_tm.md) · [TJ](README_tj.md) · [KA](README_ka.md)

![Main Menu](images/main_menu_en.png)

# **Information**
A menu for managing the Bitrix environment, adapted for **Debian 12 / Debian 13**. Debian 13 (trixie) is the primary target: the project replaces the CentOS 9 environment on modern Debian machines.  
Based on the project [(YogSottot) bitrix-gt](https://github.com/YogSottot/bitrix-gt), improved and optimized for **modern versions of Debian 12–13 and Bitrix**.

---

# **Environment Features**
- Fully automatic installation of all necessary components:  
  **Ansible, PHP 8.3 (default), MySQL 8.4 LTS, Nginx, Apache, Redis, Push & Pull server.**
- **Database engine choice: Oracle MySQL 8.4 LTS or Percona Server 8.4 LTS** (`DB_ENGINE` variable).
- **Composite support**.
- Serving static files **via Brotli**.
- Ability to **use custom Nginx configurations** without modifying the standard ones.
- Support for **full-text search with Sphinx**.
- Option to **install and configure a document conversion server (`LibreOffice`, `ImageMagick`)**.
- Ability to **install and monitor Netdata**.

---

# **Menu Features**
- View site list.
- Create and delete sites in **core and symbolic link modes**.
- Automatic transfer of agents to **CRON** when creating a site in core mode.
- Issue **Let’s Encrypt SSL certificates**.
- Manage **HTTP → HTTPS redirects**.
- **Change PHP versions**.
- **Configure SMTP** (globally and per site).
- **Update, restart, and shut down the server** through the menu.
- Notification of new menu versions.
- Update the menu **with a single command**:
  ```bash
  update_menu
  ```
- **Two interface languages — Russian and English** — selected automatically from the system locale (`ru_*` → Russian, any other → English); can be forced with the `BS_MENU_LANG` variable.
- **PostgreSQL for Bitrix** — installed and removed from the add-ons menu, with `postgresql.conf` presets selected by the amount of RAM.

---

# **Installation**
### ⚠ **Important:** Install and use the menu **only as the root user**.

#### **Full environment installation on Debian 12 / Debian 13**
##### Installation via `CURL`
```bash
apt install -y curl wget && bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```
##### Installation via `WGET`
```bash
apt install -y curl wget && bash <(wget -qO- https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```

---

## Choosing the database engine: MySQL or Percona Server
The installer can use **Oracle MySQL 8.4 LTS** or **Percona Server for MySQL 8.4 LTS**. Both use the same service (`mysql.service`), the same configuration directory (`/etc/mysql/conf.d/99-bitrix.cnf`) and the same authentication mode (`mysql_native_password`), so Bitrix works identically.

```bash
# Interactive choice (MySQL by default)
bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)

# Percona Server 8.4 LTS, without questions
DB_ENGINE=percona bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)

# Oracle MySQL 8.4 LTS, without questions
DB_ENGINE=mysql bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```

**Verified on a clean Debian 13 (trixie), amd64:** PHP 8.3.36 (the only PHP branch in the system), MySQL/Percona 8.4.11, Nginx 1.26.3, Apache 2.4.69, Node.js 20.19.2, push-server 0.4.0; all services are active; site creation in `full` and `link` modes works.

## MySQL/Percona presets by the amount of RAM

During installation, database parameters are selected automatically by the amount of RAM (`MemTotal` from `/proc/meminfo`).

| RAM, GB | Buffer pool | Temp tables | Redo log | Log buffer |
|-----|-----|-----|-----|-----|
| <3 | 768M | 64M | 512M | 32M |
| 3&#8209;6 | 1536M | 96M | 768M | 64M |
| 6&#8209;12 | 3072M | 128M | 1G | 96M |
| 12&#8209;24 | 6144M | 128M | 2G | 128M |
| 24&#8209;48 | 12288M | 256M | 4G | 256M |
| ≥48 | 24576M | 256M | 8G | 256M |

| RAM, GB | Connections | Table cache | Thread cache | IO |
|-----|-----|-----|-----|-----|
| <3 | 40 | 2000 | 64 | 400&nbsp;/&nbsp;800 |
| 3&#8209;6 | 60 | 4000 | 96 | 600&nbsp;/&nbsp;1200 |
| 6&#8209;12 | 80 | 8000 | 128 | 1000&nbsp;/&nbsp;2000 |
| 12&#8209;24 | 85 | 14336 | 128 | 2000&nbsp;/&nbsp;4000 |
| 24&#8209;48 | 200 | 20000 | 256 | 3000&nbsp;/&nbsp;6000 |
| ≥48 | 300 | 32768 | 256 | 4000&nbsp;/&nbsp;8000 |

The preset is chosen by the first matching threshold; it can be forced with a variable:

```bash
MYSQL_PRESET=8g DB_ENGINE=percona bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```

Allowed values: `2g`, `4g`, `8g`, `16g`, `32g`, `64g` (default — `auto`). The parameters are written to `/etc/mysql/conf.d/10-bitrix-memory.cnf`.

## PostgreSQL for a Bitrix portal

PostgreSQL is installed from the menu: item `8` → «Additional components» → `4`. MySQL keeps working — the portal chooses the DBMS during installation.

| RAM, GB | Buffer pool | Planner cache | work_mem | Maintenance |
|---|---|---|---|---|
| <3 | 512MB | 1536MB | 4MB | 128MB |
| 3&#8209;6 | 1GB | 3GB | 6MB | 256MB |
| 6&#8209;12 | 2GB | 6GB | 8MB | 512MB |
| 12&#8209;24 | 4GB | 12GB | 12MB | 1GB |
| 24&#8209;48 | 8GB | 24GB | 16MB | 1GB |
| ≥48 | 16GB | 48GB | 24MB | 2GB |

| RAM, GB | Connections | WAL buffer | Temp buffer |
|---|---|---|---|
| <3 | 40 | 16MB | 8MB |
| 3&#8209;6 | 60 | 16MB | 8MB |
| 6&#8209;12 | 80 | 16MB | 16MB |
| 12&#8209;24 | 85 | 16MB | 24MB |
| 24&#8209;48 | 200 | 16MB | 32MB |
| ≥48 | 300 | 16MB | 48MB |

Full parameter names: buffer pool — `shared_buffers`, planner cache — `effective_cache_size`, maintenance — `maintenance_work_mem`, connections — `max_connections`, WAL buffer — `wal_buffers`, temp buffer — `temp_buffers`.

Created automatically: database `bitrix` (`LC_CTYPE='C.UTF-8' TEMPLATE template0`), user `bitrix`, `GRANT CREATE` on schema `public`, extension `pgcrypto`, password authentication in `pg_hba.conf`.

The preset is chosen by the first matching threshold; it can be forced with `BS_POSTGRES_PRESET` in `config.sh`.

---

# **Menu Update**
If a new menu version is released, update it **with a single command**:
```bash
update_menu
```
The menu can also be updated manually via `CURL` or `WGET`.  
When updating, the current version **is automatically backed up** in `/root/backup_vm_menu/DD.MM.YYYY HH:MM:SS`.

#### **Update via `CURL`**
```bash
bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/update_menu.sh)
```
#### **Update via `WGET`**
```bash
bash <(wget -qO- https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/update_menu.sh)
```

---

# **Usage**
The menu is installed in **`/root/vm_menu`**, and for convenience, a **symbolic link** is created:
- `/root/menu.sh` → `/root/vm_menu/menu.sh`

The menu can be launched with the commands:
```bash
./menu.sh   # If in /root
/root/menu.sh   # If in any other directory
```
Additionally, the menu path **is automatically added to `.profile`**, so it launches immediately upon **SSH** connection.

---

# **Settings**
The menu is highly configurable.  
All parameters can be modified in the file:
```bash
/root/vm_menu/bash_scripts/config.sh
```
By default, everything is pre-configured, but you can adjust the environment as needed.

### Interface language

The menu is bilingual: Russian and English. The language is selected automatically from the system locale:
`ru_RU.UTF-8` (or any `ru_*`) — Russian; any other locale, including `C.UTF-8` and `en_US.UTF-8` — English.

To force it, use the environment variable or the `BS_MENU_LANG` parameter in `config.sh`:

```bash
BS_MENU_LANG=en /root/menu.sh   # English on a server with a Russian locale
BS_MENU_LANG=ru /root/menu.sh   # Russian on a server with an English locale
```

All interface strings live in one file — `/root/vm_menu/bash_scripts/i18n.sh` (dictionaries `MSG_RU` and `MSG_EN`).

---

# **Updates and New Features**
The menu automatically **notifies about new versions**.  
Update it with the command:
```bash
update_menu
```
If the menu breaks due to experiments or modifications — just **run the update**, and it **will revert to a working version**.

---

# **Support, Localization, and Suggestions**
If you have questions or suggestions, join:
[**Telegram Support Chat**](https://t.me/bitrix_ferma)

