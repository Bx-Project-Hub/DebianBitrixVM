# **Main Menu**
![Main Menu](images/main_menu.png)

# **Information**
A menu for managing the Bitrix environment, adapted for **Debian 11 / Debian 12**.  
Based on the project [(YogSottot) bitrix-gt](https://github.com/YogSottot/bitrix-gt), improved and optimized for **modern versions of Debian 11-12 and Bitrix**.

---

# **Environment Features**
- Fully automatic installation of all necessary components:  
  **Ansible, PHP 8.2 (default), MySQL 8.0, Nginx, Apache, Redis, Push & Pull server.**
- **Composite support**.
- Serving static files **via Brotli**.
- Ability to **use custom Nginx configurations** without modifying the standard ones.
- Support for **full-text search with Sphinx**.
- Option to **install and configure a document conversion server (`unoconv`, `ImageMagick`)**.
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

#### **Full environment installation on Debian 11 / Debian 12**
##### Installation via `CURL`
```bash
apt install -y curl wget && bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```
##### Installation via `WGET`
```bash
apt install -y curl wget && bash <(wget -qO- https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```

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
![Update](images/new_version.png)

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

