# **Əsas menyu**
![Əsas menyu](images/main_menu.png)

# **Məlumat**
Bitrix mühitinin idarə edilməsi üçün menyu, **Debian 11 / Debian 12** üçün uyğunlaşdırılıb.  
(YogSottot) bitrix-gt](https://github.com/YogSottot/bitrix-gt) layihəsi əsasında hazırlanıb və **müasir Debian 11-12 və Bitrix** üçün optimallaşdırılıb.

---

# **Mühitin imkanları**
- Bütün vacib komponentlərin tam avtomatik quraşdırılması:  
  **Ansible, PHP 8.2 (standart), MySQL 8.0, Nginx, Apache, Redis, Push & Pull serveri.**
- **Kompozit dəstəyi**.
- Statik faylların **Brotli vasitəsilə ötürülməsi**.
- Standart konfiqurasiyaları dəyişdirmədən **fərdi Nginx konfiqurasiyalarını istifadə etmək** imkanı.
- **Sphinx ilə tam mətn axtarışı** dəstəyi.
- **Sənəd konvertasiya serverinin (`unoconv`, `ImageMagick`) quraşdırılması və konfiqurasiyası** imkanı.
- **Netdata quraşdırmaq və monitorinq aparmaq** imkanı.

---

# **Menyunun imkanları**
- Saytların siyahısına baxmaq.
- Saytları **əsas və simvolik link rejimində** yaratmaq və silmək.
- Əsas rejimdə sayt yaradıldıqda agentləri **CRON-a** avtomatik köçürmək.
- **Let’s Encrypt SSL sertifikatlarını** çıxarmaq.
- **HTTP → HTTPS yönləndirməsini idarə etmək**.
- **PHP versiyalarını dəyişdirmək**.
- **SMTP konfiqurasiyası** (ümumi və hər sayt üçün ayrıca).
- **Serveri yeniləmək, yenidən başladmaq və söndürmək**.
- Yeni menyu versiyasının çıxışı barədə bildiriş vermək.
- **Tək əmr ilə menyunu yeniləmək**:
  ```bash
  update_menu
  ```

---

# **Quraşdırma**
### ⚠ **Vacib:** Menyunu **yalnız root istifadəçi olaraq** quraşdırmaq və istifadə etmək tövsiyə olunur.

#### **Debian 11 / Debian 12 üçün tam mühitin quraşdırılması**
##### `CURL` vasitəsilə quraşdırma
```bash
apt install -y curl wget && bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```
##### `WGET` vasitəsilə quraşdırma
```bash
apt install -y curl wget && bash <(wget -qO- https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```

---

# **Menyunu yeniləmək**
Əgər yeni versiya çıxıbsa, onu **tək əmr ilə yeniləyə bilərsiniz**:
```bash
update_menu
```
Menyunu `CURL` və ya `WGET` vasitəsilə əl ilə də yeniləmək mümkündür.  
Yeniləmə zamanı cari versiya **avtomatik olaraq ehtiyat nüsxə kimi saxlanır** `/root/backup_vm_menu/DD.MM.YYYY HH:MM:SS`.

#### **`CURL` vasitəsilə yeniləmə**
```bash
bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/update_menu.sh)
```
#### **`WGET` vasitəsilə yeniləmə**
```bash
bash <(wget -qO- https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/update_menu.sh)
```

---

# **İstifadə qaydası**
Menyu **`/root/vm_menu`** qovluğuna quraşdırılır və **simvolik link** yaradılır:
- `/root/menu.sh` → `/root/vm_menu/menu.sh`

Menyunu aşağıdakı əmrlərlə işə salmaq mümkündür:
```bash
./menu.sh   # Əgər /root qovluğundasınızsa
/root/menu.sh   # Digər qovluqdan işə salmaq üçün
```
Bundan əlavə, menyunun yolu **avtomatik olaraq `.profile`-ə əlavə edilir**, buna görə **SSH bağlantısı zamanı avtomatik başlayır**.

---

# **Konfiqurasiya**
Menyu çox çevik və konfiqurasiya oluna biləndir.  
Bütün parametrləri aşağıdakı faylda dəyişmək mümkündür:
```bash
/root/vm_menu/bash_scripts/config.sh
```
Varsayılan olaraq hər şey optimal şəkildə tənzimlənib, lakin ehtiyac yaranarsa, mühiti fərdi ehtiyaclarınıza uyğun tənzimləyə bilərsiniz.

---

# **Yeniləmələr və yeni imkanlar**
![Yeniləmə](images/new_version.png)

Menyu **yeni versiyalar barədə avtomatik məlumat verir**.  
Aşağıdakı əmr ilə onu yeniləyə bilərsiniz:
```bash
update_menu
```
Əgər menyu təcrübələr və ya dəyişikliklər nəticəsində işləmirsə — **yeniləməni işə salın**, və o **işlək versiyaya qaytarılacaq**.

---

# **Dəstək, lokalizasiya və təkliflər**
Əgər sualınız və ya təklifiniz varsa, aşağıdakı qrupa qoşulun:
[**Telegram dəstək qrup**](https://t.me/bitrix_ferma)

