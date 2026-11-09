# **Менюи асосӣ**
![Менюи асосӣ](images/main_menu.png)

# **Маълумот**
Меню барои идоракунии муҳити Bitrix, ки барои **Debian 12 / Debian 13** мутобиқ карда шудааст. Ҳадафи асосӣ — Debian 13 (trixie): лоиҳа муҳити CentOS 9-ро дар мошинҳои муосири Debian иваз мекунад.  
Дар асоси лоиҳаи [(YogSottot) bitrix-gt](https://github.com/YogSottot/bitrix-gt) таҳия шуда, барои **Debian 12–13 ва Bitrix** оптимизатсия шудааст.

---

# **Имкониятҳои муҳит**
- Насби пурраи автоматии ҳамаи ҷузъҳои зарурӣ:  
  **Ansible, PHP 8.3 (пешфарз), MySQL 8.4 LTS, Nginx, Apache, Redis, Push & Pull сервер.**
- **Интихоби муҳаррики пойгоҳи додаҳо: Oracle MySQL 8.4 LTS ё Percona Server 8.4 LTS** (тағйирёбандаи `DB_ENGINE`).
- **Дастгирии композит**.
- Тақсими статикӣ **бо Brotli**.
- Имконияти **истифодаи конфигуратсияҳои шахсии Nginx** бе тағйири стандартӣ.
- Дастгирии **ҷустуҷӯи пурраи матнӣ бо Sphinx**.
- Имконияти **насб ва танзими сервери табдили ҳуҷҷатҳо (`LibreOffice`, `ImageMagick`)**.
- Имконияти **насб ва мониторинги Netdata**.

---

# **Имкониятҳои меню**
- Дидани рӯйхати сайтҳо.
- Эҷод ва нест кардани сайтҳо дар **ҳолати аслӣ ва пайванди рамзӣ**.
- Ҳангоми эҷоди сайт дар ҳолати аслӣ **агентҳоро ба CRON** автоматӣ интиқол медиҳад.
- Барориши **шаҳодатномаҳои SSL Let’s Encrypt**.
- Идоракунии **интиқоли HTTP → HTTPS**.
- **Иваз кардани версияҳои PHP**.
- **Танзими SMTP** (умумӣ ва барои ҳар як сайт алоҳида).
- **Навсозӣ, бозоғозӣ ва хомӯш кардани сервер** тавассути меню.
- Огоҳӣ дар бораи баромадани версияи нави меню.
- **Навсозии меню бо як фармон**:
  ```bash
  update_menu
  ```

---

# **Насб**
### ⚠ **Муҳим:** Менюро **танҳо ҳамчун root-корбар** насб ва истифода баред.

#### **Насби пурраи муҳит дар Debian 12 / Debian 13**
##### Насб бо `CURL`
```bash
apt install -y curl wget && bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```
##### Насб бо `WGET`
```bash
apt install -y curl wget && bash <(wget -qO- https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```

---

## Интихоби муҳаррики пойгоҳи додаҳо: MySQL ё Percona Server
Насбкунанда имкон медиҳад **Oracle MySQL 8.4 LTS** ё **Percona Server for MySQL 8.4 LTS**-ро интихоб кунед. Ҳарду ҳамон хидмат (`mysql.service`), ҳамон ҷузвдони конфигуратсия (`/etc/mysql/conf.d/99-bitrix.cnf`) ва ҳамон режими аутентификатсия (`mysql_native_password`)-ро истифода мебаранд, бинобар ин Bitrix дар ҳар ду ҳолат якхела кор мекунад.

```bash
# Интихоби интерактивӣ (пешфарз — MySQL)
bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)

# Percona Server 8.4 LTS, бе савол
DB_ENGINE=percona bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)

# Oracle MySQL 8.4 LTS, бе савол
DB_ENGINE=mysql bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```

**Дар Debian 13 (trixie)-и тоза, amd64 санҷида шуд:** PHP 8.3.36 (танҳо шохаи PHP дар система), MySQL/Percona 8.4.11, Nginx 1.26.3, Apache 2.4.69, Node.js 20.19.2, push-server 0.4.0; ҳамаи хидматҳо фаъоланд; сохтани сайт дар режимҳои `full` ва `link` кор мекунад.

---

# **Навсозии меню**
Агар версияи нави меню баромада бошад, онро **бо як фармон навсозӣ кардан мумкин аст**:
```bash
update_menu
```
Менюро инчунин бо `CURL` ё `WGET` дастӣ навсозӣ кардан мумкин аст.  
Ҳангоми навсозӣ, версияи ҷорӣ **ба таври худкор захира карда мешавад** `/root/backup_vm_menu/DD.MM.YYYY HH:MM:SS`.

#### **Навсозӣ бо `CURL`**
```bash
bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/update_menu.sh)
```
#### **Навсозӣ бо `WGET`**
```bash
bash <(wget -qO- https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/update_menu.sh)
```

---

# **Истифода**
Меню дар **`/root/vm_menu`** насб карда мешавад ва барои осонӣ **пайванди рамзӣ** эҷод мегардад:
- `/root/menu.sh` → `/root/vm_menu/menu.sh`

Менюро бо фармонҳои зерин оғоз кардан мумкин аст:
```bash
./menu.sh   # Агар дар /root бошед
/root/menu.sh   # Аз дигар директорияҳо оғоз кардан
```
Инчунин, роҳ ба меню **ба таври худкор ба `.profile` ворид карда мешавад**, бинобар ин **он ҳангоми пайвастшавӣ бо SSH фавран оғоз мешавад**.

---

# **Танзимот**
Меню фасеҳ аст ва танзимшаванда мебошад.  
Ҳамаи параметрҳоро дар файли зерин тағйир додан мумкин аст:
```bash
/root/vm_menu/bash_scripts/config.sh
```
Бо нобаёнӣ ҳама чиз танзим шудааст, аммо дар ҳолати зарурӣ муҳитро мувофиқи эҳтиёҷоти худ танзим кардан мумкин аст.

---

# **Навсозӣ ва имкониятҳои нав**
Меню **баромадани версияҳои навро ба таври худкор хабар медиҳад**.  
Онро бо фармони зерин навсозӣ кардан мумкин аст:
```bash
update_menu
```
Агар меню бинобар таҷрибаҳо ё тағйирот кор накунад — **навсозиро оғоз кунед**, ва он **ба версияи коршоям бармегардад**.

---

# **Дастгирӣ, локализатсия ва пешниҳодҳо**
Агар савол ё пешниҳод дошта бошед, ба гурӯҳи зерин ҳамроҳ шавед:
[**Чати дастгирии Telegram**](https://t.me/bitrix_ferma)

