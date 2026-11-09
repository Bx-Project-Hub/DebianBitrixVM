# **Əsas menyu**

**Dil:** [RU](README.md) · [EN](README_en.md) · [UK](README_uk.md) · [KZ](README_kz.md) · **AZ** · [UZ](README_uz.md) · [TM](README_tm.md) · [TJ](README_tj.md) · [KA](README_ka.md)

![Əsas menyu](images/main_menu_en.png)

# **Məlumat**
Bitrix mühitinin idarə edilməsi üçün menyu, **Debian 12 / Debian 13** üçün uyğunlaşdırılıb. Əsas hədəf — Debian 13 (trixie): layihə müasir Debian maşınlarında CentOS 9 mühitini əvəz edir.  
(YogSottot) bitrix-gt](https://github.com/YogSottot/bitrix-gt) layihəsi əsasında hazırlanıb və **müasir Debian 12–13 və Bitrix** üçün optimallaşdırılıb.

---

# **Mühitin imkanları**
- Bütün vacib komponentlərin tam avtomatik quraşdırılması:  
  **Ansible, PHP 8.3 (standart), MySQL 8.4 LTS, Nginx, Apache, Redis, Push & Pull serveri.**
- **VB mühərrikinin seçimi: Oracle MySQL 8.4 LTS və ya Percona Server 8.4 LTS** (`DB_ENGINE` dəyişəni).
- **Kompozit dəstəyi**.
- Statik faylların **Brotli vasitəsilə ötürülməsi**.
- Standart konfiqurasiyaları dəyişdirmədən **fərdi Nginx konfiqurasiyalarını istifadə etmək** imkanı.
- **Sphinx ilə tam mətn axtarışı** dəstəyi.
- **Sənəd konvertasiya serverinin (`LibreOffice`, `ImageMagick`) quraşdırılması və konfiqurasiyası** imkanı.
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
- **İki interfeys dili — rus və ingilis** — sistem lokalına görə avtomatik seçilir (`ru_*` → rus dili, digərləri → ingilis dili); `BS_MENU_LANG` dəyişəni ilə məcburi təyin etmək olar.
- **Bitrix üçün PostgreSQL** — əlavələr menyusundan quraşdırma və silmə, `postgresql.conf` presetləri RAM həcminə görə seçilir.

---

# **Quraşdırma**
### ⚠ **Vacib:** Menyunu **yalnız root istifadəçi olaraq** quraşdırmaq və istifadə etmək tövsiyə olunur.

#### **Debian 12 / Debian 13 üçün tam mühitin quraşdırılması**
##### `CURL` vasitəsilə quraşdırma
```bash
apt install -y curl wget && bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```
##### `WGET` vasitəsilə quraşdırma
```bash
apt install -y curl wget && bash <(wget -qO- https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```

---

## Verilənlər bazası mühərrikinin seçimi: MySQL və ya Percona Server
Quraşdırıcı **Oracle MySQL 8.4 LTS** və ya **Percona Server for MySQL 8.4 LTS** seçməyə imkan verir. Hər ikisi eyni xidmətdən (`mysql.service`), eyni konfiqurasiya qovluğundan (`/etc/mysql/conf.d/99-bitrix.cnf`) və eyni autentifikasiya rejimindən (`mysql_native_password`) istifadə edir, ona görə Bitrix hər iki halda eyni işləyir.

```bash
# İnteraktiv seçim (susmaya görə MySQL)
bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)

# Percona Server 8.4 LTS, sualsız
DB_ENGINE=percona bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)

# Oracle MySQL 8.4 LTS, sualsız
DB_ENGINE=mysql bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```

**Təmiz Debian 13 (trixie), amd64 üzərində yoxlanılıb:** PHP 8.3.36 (sistemdə yeganə PHP budağı), MySQL/Percona 8.4.11, Nginx 1.26.3, Apache 2.4.69, Node.js 20.19.2, push-server 0.4.0; bütün xidmətlər aktivdir; `full` və `link` rejimlərində sayt yaradılması işləyir.

## RAM həcminə görə MySQL/Percona konfiqurasiya presetləri

Quraşdırma zamanı verilənlər bazası parametrləri operativ yaddaşın həcminə görə avtomatik seçilir (`MemTotal`, `/proc/meminfo`).

| RAM, GB | Bufer hovuzu | Temp cədvəllər | Redo jurnalı | Log buferi |
|-----|-----|-----|-----|-----|
| <3 | 768M | 64M | 512M | 32M |
| 3&#8209;6 | 1536M | 96M | 768M | 64M |
| 6&#8209;12 | 3072M | 128M | 1G | 96M |
| 12&#8209;24 | 6144M | 128M | 2G | 128M |
| 24&#8209;48 | 12288M | 256M | 4G | 256M |
| ≥48 | 24576M | 256M | 8G | 256M |

| RAM, GB | Bağlantılar | Cədvəl keşi | Thread keşi | IO |
|-----|-----|-----|-----|-----|
| <3 | 40 | 2000 | 64 | 400&nbsp;/&nbsp;800 |
| 3&#8209;6 | 60 | 4000 | 96 | 600&nbsp;/&nbsp;1200 |
| 6&#8209;12 | 80 | 8000 | 128 | 1000&nbsp;/&nbsp;2000 |
| 12&#8209;24 | 85 | 14336 | 128 | 2000&nbsp;/&nbsp;4000 |
| 24&#8209;48 | 200 | 20000 | 256 | 3000&nbsp;/&nbsp;6000 |
| ≥48 | 300 | 32768 | 256 | 4000&nbsp;/&nbsp;8000 |

Preset ilk uyğun həddə görə seçilir; dəyişənlə məcburi təyin etmək olar:

```bash
MYSQL_PRESET=8g DB_ENGINE=percona bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```

İcazə verilən dəyərlər: `2g`, `4g`, `8g`, `16g`, `32g`, `64g` (susmaya görə — `auto`). Parametrlər `/etc/mysql/conf.d/10-bitrix-memory.cnf` faylına yazılır.

## Bitrix portalı üçün PostgreSQL

Menyudan quraşdırılır: `8` → «Əlavə komponentlər» → `4`. MySQL işləməyə davam edir — VBİS portalın quraşdırılması zamanı seçilir.

| RAM, GB | Bufer hovuzu | Planlaşdırıcı keşi | work_mem | Xidmət |
|---|---|---|---|---|
| <3 | 512MB | 1536MB | 4MB | 128MB |
| 3&#8209;6 | 1GB | 3GB | 6MB | 256MB |
| 6&#8209;12 | 2GB | 6GB | 8MB | 512MB |
| 12&#8209;24 | 4GB | 12GB | 12MB | 1GB |
| 24&#8209;48 | 8GB | 24GB | 16MB | 1GB |
| ≥48 | 16GB | 48GB | 24MB | 2GB |

| RAM, GB | Bağlantılar | WAL buferi | Temp buferi |
|---|---|---|---|
| <3 | 40 | 16MB | 8MB |
| 3&#8209;6 | 60 | 16MB | 8MB |
| 6&#8209;12 | 80 | 16MB | 16MB |
| 12&#8209;24 | 85 | 16MB | 24MB |
| 24&#8209;48 | 200 | 16MB | 32MB |
| ≥48 | 300 | 16MB | 48MB |

Parametrlərin tam adları: bufer hovuzu — `shared_buffers`, planlaşdırıcı keşi — `effective_cache_size`, xidmət — `maintenance_work_mem`, bağlantılar — `max_connections`, WAL buferi — `wal_buffers`, temp buferi — `temp_buffers`.

Avtomatik yaradılır: `bitrix` bazası (`LC_CTYPE='C.UTF-8' TEMPLATE template0`), `bitrix` istifadəçisi, `public` sxeminə `GRANT CREATE`, `pgcrypto` genişlənməsi, `pg_hba.conf`-da parol autentifikasiyası.

Preset ilk uyğun həddə görə seçilir; məcburi — `config.sh` faylındakı `BS_POSTGRES_PRESET`.

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

### İnterfeys dili

Menyu ikidilli: rus və ingilis. Dil sistem lokalına görə avtomatik seçilir:
`ru_RU.UTF-8` (və ya hər hansı `ru_*`) — rus dili; hər hansı digəri, o cümlədən `az_AZ.UTF-8`
və `C.UTF-8` — ingilis dili.

Məcburi seçim — mühit dəyişəni və ya `config.sh` faylındakı `BS_MENU_LANG` parametri:

```bash
BS_MENU_LANG=en /root/menu.sh   # rus lokalı olan serverdə ingilis dili
BS_MENU_LANG=ru /root/menu.sh   # ingilis lokalı olan serverdə rus dili
```

Bütün interfeys sətirləri bir faylda saxlanılır — `/root/vm_menu/bash_scripts/i18n.sh`
(`MSG_RU` və `MSG_EN` lüğətləri).

---

# **Yeniləmələr və yeni imkanlar**
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

