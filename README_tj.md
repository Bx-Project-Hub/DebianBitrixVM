# **Менюи асосӣ**

**Забон:** [RU](README.md) · [EN](README_en.md) · [UK](README_uk.md) · [KZ](README_kz.md) · [AZ](README_az.md) · [UZ](README_uz.md) · [TM](README_tm.md) · **TJ** · [KA](README_ka.md)

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

## Пресетҳои конфигуратсияи MySQL/Percona аз рӯи ҳаҷми RAM

Ҳангоми насб параметрҳои сервери пойгоҳи додаҳо аз рӯи ҳаҷми хотираи амалиётӣ ба таври худкор интихоб мешаванд (`MemTotal`, `/proc/meminfo`).

| RAM, ГБ | Ҳавзи буфер | Ҷадвалҳои temp | Журнали redo | Буфери лог |
|-----|-----|-----|-----|-----|
| <3 | 768M | 64M | 512M | 32M |
| 3&#8209;6 | 1536M | 96M | 768M | 64M |
| 6&#8209;12 | 3072M | 128M | 1G | 96M |
| 12&#8209;24 | 6144M | 128M | 2G | 128M |
| 24&#8209;48 | 12288M | 256M | 4G | 256M |
| ≥48 | 24576M | 256M | 8G | 256M |

| RAM, ГБ | Пайвастҳо | Кеши ҷадвалҳо | Кеши ҷараёнҳо | IO |
|-----|-----|-----|-----|-----|
| <3 | 40 | 2000 | 64 | 400&nbsp;/&nbsp;800 |
| 3&#8209;6 | 60 | 4000 | 96 | 600&nbsp;/&nbsp;1200 |
| 6&#8209;12 | 80 | 8000 | 128 | 1000&nbsp;/&nbsp;2000 |
| 12&#8209;24 | 85 | 14336 | 128 | 2000&nbsp;/&nbsp;4000 |
| 24&#8209;48 | 200 | 20000 | 256 | 3000&nbsp;/&nbsp;6000 |
| ≥48 | 300 | 32768 | 256 | 4000&nbsp;/&nbsp;8000 |

Пресет аз рӯи аввалин ҳадди мувофиқ интихоб мешавад; бо тағйирёбанда маҷбурӣ таъин кардан мумкин аст:

```bash
MYSQL_PRESET=8g DB_ENGINE=percona bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```

Қиматҳои иҷозатдодашуда: `2g`, `4g`, `8g`, `16g`, `32g`, `64g` (пешфарз — `auto`). Параметрҳо ба `/etc/mysql/conf.d/10-bitrix-memory.cnf` навишта мешаванд.

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

