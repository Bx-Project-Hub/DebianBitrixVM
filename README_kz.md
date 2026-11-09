# **Негізгі мәзір**
![Негізгі мәзір](images/main_menu.png)

# **Ақпарат**
Bitrix ортасын басқаруға арналған мәзір, **Debian 12 / Debian 13** үшін бейімделген. Негізгі мақсат — Debian 13 (trixie): жоба заманауи Debian машиналарында CentOS 9 ортасын алмастырады.  
(YogSottot) bitrix-gt](https://github.com/YogSottot/bitrix-gt) жобасы негізінде әзірленген және **заманауи Debian 12–13 және Bitrix** үшін оңтайландырылған.

---

# **Ортаның мүмкіндіктері**
- Барлық қажетті компоненттердің толық автоматты түрде орнатылуы:  
  **Ansible, PHP 8.3 (әдепкі), MySQL 8.4 LTS, Nginx, Apache, Redis, Push & Pull сервері.**
- **ДҚ қозғалтқышын таңдау: Oracle MySQL 8.4 LTS немесе Percona Server 8.4 LTS** (`DB_ENGINE` айнымалысы).
- **Композитті қолдау**.
- Статикалық файлдарды **Brotli арқылы беру**.
- Стандартты конфигурацияларды өзгертпей **жеке Nginx конфигурацияларын пайдалану** мүмкіндігі.
- **Sphinx арқылы толық мәтіндік іздеуді** қолдау.
- **Құжаттарды түрлендіру серверін (`LibreOffice`, `ImageMagick`) орнату және баптау** мүмкіндігі.
- **Netdata орнату және мониторинг жасау** мүмкіндігі.

---

# **Мәзір мүмкіндіктері**
- Веб-сайттар тізімін қарау.
- Веб-сайттарды **ядро және символдық сілтеме режимінде** жасау және жою.
- Ядро режимінде сайт жасағанда агенттерді **CRON-ға** автоматты түрде көшіру.
- **Let’s Encrypt SSL сертификаттарын** шығару.
- **HTTP → HTTPS бағыттауларын басқару**.
- **PHP нұсқаларын өзгерту**.
- **SMTP параметрлерін өзгерту** (жалпы немесе әр сайт үшін жеке).
- **Серверді жаңарту, қайта қосу және өшіру**.
- Жаңа мәзір нұсқасы шыққаны туралы хабарлау.
- **Бір пәрменмен мәзірді жаңарту**:
  ```bash
  update_menu
  ```

---

# **Орнату**
### ⚠ **Маңызды:** Мәзірді **тек root пайдаланушысы ретінде** орнату және пайдалану ұсынылады.

#### **Debian 12 / Debian 13 үшін толық ортаны орнату**
##### `CURL` арқылы орнату
```bash
apt install -y curl wget && bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```
##### `WGET` арқылы орнату
```bash
apt install -y curl wget && bash <(wget -qO- https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```

---

## Дерекқор қозғалтқышын таңдау: MySQL немесе Percona Server
Орнатушы **Oracle MySQL 8.4 LTS** немесе **Percona Server for MySQL 8.4 LTS** таңдауға мүмкіндік береді. Екеуі де бір қызметті (`mysql.service`), бір конфигурация каталогын (`/etc/mysql/conf.d/99-bitrix.cnf`) және бір аутентификация режимін (`mysql_native_password`) пайдаланады, сондықтан Bitrix екі жағдайда да бірдей жұмыс істейді.

```bash
# Интерактивті таңдау (әдепкі — MySQL)
bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)

# Percona Server 8.4 LTS, сұрақсыз
DB_ENGINE=percona bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)

# Oracle MySQL 8.4 LTS, сұрақсыз
DB_ENGINE=mysql bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```

**Таза Debian 13 (trixie), amd64 жүйесінде тексерілді:** PHP 8.3.36 (жүйедегі жалғыз PHP тармағы), MySQL/Percona 8.4.11, Nginx 1.26.3, Apache 2.4.69, Node.js 20.19.2, push-server 0.4.0; барлық қызметтер белсенді; сайтты `full` және `link` режимдерінде құру жұмыс істейді.

## RAM көлемі бойынша MySQL/Percona конфигурациясының пресеттері

Орнату кезінде дерекқор серверінің параметрлері жедел жад көлемі бойынша автоматты түрде таңдалады (`MemTotal`, `/proc/meminfo`).

| RAM, ГБ | Буферлік пул | Temp кестелер | Redo журналы | Лог буфері |
|-----|-----|-----|-----|-----|
| <3 | 768M | 64M | 512M | 32M |
| 3&#8209;6 | 1536M | 96M | 768M | 64M |
| 6&#8209;12 | 3072M | 128M | 1G | 96M |
| 12&#8209;24 | 6144M | 128M | 2G | 128M |
| 24&#8209;48 | 12288M | 256M | 4G | 256M |
| ≥48 | 24576M | 256M | 8G | 256M |

| RAM, ГБ | Қосылымдар | Кесте кэші | Ағын кэші | IO |
|-----|-----|-----|-----|-----|
| <3 | 40 | 2000 | 64 | 400&nbsp;/&nbsp;800 |
| 3&#8209;6 | 60 | 4000 | 96 | 600&nbsp;/&nbsp;1200 |
| 6&#8209;12 | 80 | 8000 | 128 | 1000&nbsp;/&nbsp;2000 |
| 12&#8209;24 | 85 | 14336 | 128 | 2000&nbsp;/&nbsp;4000 |
| 24&#8209;48 | 200 | 20000 | 256 | 3000&nbsp;/&nbsp;6000 |
| ≥48 | 300 | 32768 | 256 | 4000&nbsp;/&nbsp;8000 |

Пресет бірінші сәйкес шек бойынша таңдалады; айнымалымен мәжбүрлеп орнатуға болады:

```bash
MYSQL_PRESET=8g DB_ENGINE=percona bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```

Рұқсат етілген мәндер: `2g`, `4g`, `8g`, `16g`, `32g`, `64g` (әдепкі — `auto`). Параметрлер `/etc/mysql/conf.d/10-bitrix-memory.cnf` файлына жазылады.

---

# **Мәзірді жаңарту**
Егер жаңа нұсқа шықса, оны **бір пәрменмен жаңартуға болады**:
```bash
update_menu
```
Мәзірді `CURL` немесе `WGET` арқылы қолмен жаңартуға да болады.  
Жаңарту кезінде ағымдағы нұсқа **автоматты түрде сақтық көшірмеге** жазылады `/root/backup_vm_menu/DD.MM.YYYY HH:MM:SS`.

#### **`CURL` арқылы жаңарту**
```bash
bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/update_menu.sh)
```
#### **`WGET` арқылы жаңарту**
```bash
bash <(wget -qO- https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/update_menu.sh)
```

---

# **Қолдану**
Мәзір **`/root/vm_menu`** каталогына орнатылады және **символдық сілтеме** жасалады:
- `/root/menu.sh` → `/root/vm_menu/menu.sh`

Мәзірді келесі пәрмендер арқылы іске қосуға болады:
```bash
./menu.sh   # Егер /root ішінде болсаңыз
/root/menu.sh   # Басқа каталогтан іске қосу үшін
```
Сондай-ақ, мәзір жолы **автоматты түрде `.profile`-ге қосылады**, сондықтан **SSH байланысы кезінде бірден іске қосылады**.

---

# **Баптаулар**
Мәзір икемді және оңай баптауға болады.  
Барлық параметрлерді келесі файлда өзгертуге болады:
```bash
/root/vm_menu/bash_scripts/config.sh
```
Бастапқы күйінде барлық параметрлер оңтайлы орнатылған, бірақ қажет болса, ортаны қажеттіліктеріңізге қарай бейімдей аласыз.

---

# **Жаңартулар және жаңа мүмкіндіктер**
Мәзір **жаңа нұсқалар туралы автоматты түрде хабарлайды**.  
Оны келесі пәрменмен жаңартуға болады:
```bash
update_menu
```
Егер мәзір тәжірибелер немесе өзгертулер салдарынан жұмыс істемесе — **жаңартуды іске қосыңыз**, және ол **жұмыс істейтін нұсқаға қайтады**.

---

# **Қолдау, локализация және ұсыныстар**
Егер сұрақтарыңыз немесе ұсыныстарыңыз болса, келесі топқа қосылыңыз:
[**Telegram қолдау чаты**](https://t.me/bitrix_ferma)

