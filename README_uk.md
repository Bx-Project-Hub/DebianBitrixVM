# **Головне меню**
![Головне меню](images/main_menu.png)

# **Інформація**
Меню для керування середовищем Bitrix, адаптоване для **Debian 12 / Debian 13**. Основна мета — Debian 13 (trixie): проєкт замінює середовище CentOS 9 на сучасних Debian-машинах.  
Засноване на проєкті [(YogSottot) bitrix-gt](https://github.com/YogSottot/bitrix-gt), доопрацьоване та оптимізоване для **сучасних версій Debian 12–13 і Bitrix**.

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

---

# **Оновлення та нові можливості**
![Оновлення](images/new_version.png)

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

