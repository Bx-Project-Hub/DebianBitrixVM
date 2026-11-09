# **Main Menu**
![Main Menu](images/main_menu.png)

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

