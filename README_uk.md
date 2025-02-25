# **Головне меню**
![Головне меню](images/main_menu.png)

# **Інформація**
Меню для керування середовищем Bitrix, адаптоване для **Debian 11 / Debian 12**.  
Засноване на проєкті [(YogSottot) bitrix-gt](https://github.com/YogSottot/bitrix-gt), доопрацьоване та оптимізоване для **сучасних версій Debian 11-12 і Bitrix**.

---

# **Можливості середовища**
- Повна автоматична установка всіх необхідних компонентів:  
  **Ansible, PHP 8.2 (за замовчуванням), MySQL 8.0, Nginx, Apache, Redis, Push & Pull сервер.**
- **Підтримка композиту**.
- Віддача статичних файлів **через Brotli**.
- Можливість **використовувати власні конфігурації Nginx**, не змінюючи стандартні.
- Підтримка **повнотекстового пошуку Sphinx**.
- Можливість **встановлення сервера конвертації документів (`unoconv`, `ImageMagick`)**.
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

#### **Повне встановлення середовища на Debian 11 / Debian 12**
##### Встановлення через `CURL`
```bash
apt install -y curl wget && bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```
##### Встановлення через `WGET`
```bash
apt install -y curl wget && bash <(wget -qO- https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```

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

