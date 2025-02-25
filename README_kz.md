# **Негізгі мәзір**
![Негізгі мәзір](images/main_menu.png)

# **Ақпарат**
Bitrix ортасын басқаруға арналған мәзір, **Debian 11 / Debian 12** үшін бейімделген.  
(YogSottot) bitrix-gt](https://github.com/YogSottot/bitrix-gt) жобасы негізінде әзірленген және **заманауи Debian 11-12 және Bitrix** үшін оңтайландырылған.

---

# **Ортаның мүмкіндіктері**
- Барлық қажетті компоненттердің толық автоматты түрде орнатылуы:  
  **Ansible, PHP 8.2 (әдепкі), MySQL 8.0, Nginx, Apache, Redis, Push & Pull сервері.**
- **Композитті қолдау**.
- Статикалық файлдарды **Brotli арқылы беру**.
- Стандартты конфигурацияларды өзгертпей **жеке Nginx конфигурацияларын пайдалану** мүмкіндігі.
- **Sphinx арқылы толық мәтіндік іздеуді** қолдау.
- **Құжаттарды түрлендіру серверін (`unoconv`, `ImageMagick`) орнату және баптау** мүмкіндігі.
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

#### **Debian 11 / Debian 12 үшін толық ортаны орнату**
##### `CURL` арқылы орнату
```bash
apt install -y curl wget && bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```
##### `WGET` арқылы орнату
```bash
apt install -y curl wget && bash <(wget -qO- https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```

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
![Жаңарту](images/new_version.png)

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

