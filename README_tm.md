# **Baş menyu**

**Dil:** [RU](README.md) · [EN](README_en.md) · [UK](README_uk.md) · [KZ](README_kz.md) · [AZ](README_az.md) · [UZ](README_uz.md) · **TM** · [TJ](README_tj.md) · [KA](README_ka.md)

![Baş menyu](images/main_menu_en.png)

# **Maglumat**
Bitrix gurşawyny dolandyrmak üçin menyu, **Debian 12 / Debian 13** üçin uýgunlaşdyrylan. Esasy maksat — Debian 13 (trixie): taslama häzirki zaman Debian maşynlarynda CentOS 9 gurşawyny çalyşýar.  
Gurşaw **1C-Bitrix resmi resminamalary** esasynda ýygnaldy — [«Debian 13 üçin gurşawy sazlamak»](https://dev.1c-bitrix.ru/learning/course/index.php?COURSE_ID=32) kursy (paketler, Nginx, PHP, Apache, MySQL/MariaDB, PostgreSQL, Redis, push-server) — we Bitrix önümleriniň resmi ulgam talaplaryna laýyk. Awtomatlaşdyrma **standart Ansible shemasy** boýunça guruldy (`playbooks/` + `roles/`: `defaults`, `vars`, `tasks`, `meta`), diňe `ansible.builtin` modullary ulanylýar, daşarky kolleksiýalarysyz.

---

# **Gurşawyň mümkinçilikleri**
- Ähli zerur komponentleriň doly awtomatiki gurnalmagy:  
  **Ansible, PHP 8.3 (öňden kesgitlenen), MySQL 8.4 LTS, Nginx, Apache, Redis, Push & Pull serveri.**
- **Maglumatlar bazasynyň hereketlendirijisini saýlamak: Oracle MySQL 8.4 LTS ýa-da Percona Server 8.4 LTS** (`DB_ENGINE` üýtgeýjisi).
- **Kompozit goldawy**.
- Statik faýllaryň **Brotli arkaly berilmegi**.
- Standart konfigurasiýalary üýtgetmän **özboluşly Nginx konfigurasiýalaryny ulanmak** mümkinçiligi.
- **Sphinx bilen doly tekst gözlegini** goldamak.
- **Resminamalary öwürmek hyzmatyny (`LibreOffice`, `ImageMagick`) gurnamak we sazlamak** mümkinçiligi.
- **Netdata-y gurnamak we gözegçilik etmek** mümkinçiligi.

---

# **Menyu mümkinçilikleri**
- Saýt sanawyny görkezmek.
- Saýtlary **ýadrosy we simboliki baglanyşyk görnüşinde** döretmek we ýok etmek.
- Ýadro tertibinde saýt döredilende agentleri **CRON-a** awtomatiki geçirmek.
- **Let’s Encrypt SSL şahadatnamalaryny** bermek.
- **HTTP → HTTPS ugrukdyryşyny dolandyrmak**.
- **PHP wersiýalaryny üýtgetmek**.
- **SMTP sazlamak** (jemi ýa-da her bir saýt üçin aýratyn).
- **Serweri täzeden işletmek, täzeläp we öçürmek**.
- Täze menýu wersiýasynyň çykmagy barada habarnama bermek.
- **Birinji buýruk bilen menýuny täzeläň**:
  ```bash
  update_menu
  ```
- **Iki interfeýs dili — rus we iňlis** — ulgam lokalyna görä awtomatik saýlanýar (`ru_*` → rus dili, beýlekiler → iňlis dili); `BS_MENU_LANG` üýtgeýjisi bilen mejbury bellemek bolýar.
- **Bitrix üçin PostgreSQL** — goşmaçalar menýusyndan gurmak we aýyrmak, `postgresql.conf` presetleri RAM göwrümine görä saýlanýar.

---

# **Gurnama**
### ⚠ **Möhüm:** Menýuny **diňe root ulanyjy hökmünde** gurnamagy we ulanmagy maslahat berýäris.

#### **Debian 12 / Debian 13 üçin doly gurşaw gurnamak**
##### `CURL` arkaly gurnama
```bash
apt install -y curl wget && bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```
##### `WGET` arkaly gurnama
```bash
apt install -y curl wget && bash <(wget -qO- https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```

---

## Maglumatlar bazasynyň hereketlendirijisini saýlamak: MySQL ýa-da Percona Server
Gurnaýjy **Oracle MySQL 8.4 LTS** ýa-da **Percona Server for MySQL 8.4 LTS** saýlamaga mümkinçilik berýär. Ikisi hem birmeňzeş hyzmaty (`mysql.service`), konfigurasiýa papkasyny (`/etc/mysql/conf.d/99-bitrix.cnf`) we autentifikasiýa tertibini (`mysql_native_password`) ulanýar, şonuň üçin Bitrix iki ýagdaýda-da deň işleýär.

```bash
# Interaktiw saýlaw (deslapky — MySQL)
bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)

# Percona Server 8.4 LTS, soragsyz
DB_ENGINE=percona bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)

# Oracle MySQL 8.4 LTS, soragsyz
DB_ENGINE=mysql bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```

**Arassa Debian 13 (trixie), amd64-de barlanyldy:** PHP 8.3.36 (ulgamda ýeke-täk PHP şahasy), MySQL/Percona 8.4.11, Nginx 1.26.3, Apache 2.4.69, Node.js 20.19.2, push-server 0.4.0; ähli hyzmatlar işjeň; saýt döretmek `full` we `link` tertiplerinde işleýär.

## RAM göwrümine görä MySQL/Percona konfigurasiýa presetleri

Gurnama wagtynda maglumatlar bazasynyň parametrleri operatiw ýadyň göwrümine görä awtomatik saýlanýar (`MemTotal`, `/proc/meminfo`).

| RAM, GB | Bufer howzy | Temp tablisalar | Redo žurnaly | Log buferi |
|-----|-----|-----|-----|-----|
| <3 | 768M | 64M | 512M | 32M |
| 3&#8209;6 | 1536M | 96M | 768M | 64M |
| 6&#8209;12 | 3072M | 128M | 1G | 96M |
| 12&#8209;24 | 6144M | 128M | 2G | 128M |
| 24&#8209;48 | 12288M | 256M | 4G | 256M |
| ≥48 | 24576M | 256M | 8G | 256M |

| RAM, GB | Baglanyşyklar | Tablisa keşi | Akym keşi | IO |
|-----|-----|-----|-----|-----|
| <3 | 40 | 2000 | 64 | 400&nbsp;/&nbsp;800 |
| 3&#8209;6 | 60 | 4000 | 96 | 600&nbsp;/&nbsp;1200 |
| 6&#8209;12 | 80 | 8000 | 128 | 1000&nbsp;/&nbsp;2000 |
| 12&#8209;24 | 85 | 14336 | 128 | 2000&nbsp;/&nbsp;4000 |
| 24&#8209;48 | 200 | 20000 | 256 | 3000&nbsp;/&nbsp;6000 |
| ≥48 | 300 | 32768 | 256 | 4000&nbsp;/&nbsp;8000 |

Preset ilkinji laýyk çäge görä saýlanýar; üýtgeýji bilen mejbury bellemek bolýar:

```bash
MYSQL_PRESET=8g DB_ENGINE=percona bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/install_full_environment.sh)
```

Rugsat berilýän bahalar: `2g`, `4g`, `8g`, `16g`, `32g`, `64g` (deslapky — `auto`). Parametrler `/etc/mysql/conf.d/10-bitrix-memory.cnf` faýlyna ýazylýar.

## Bitrix portaly üçin PostgreSQL

Menýudan gurnalýar: `8` → «Goşmaça komponentler» → `4`. MySQL işlemegini dowam edýär — MBD saýlawy portal gurnalanda amala aşyrylýar.

| RAM, GB | Bufer howzy | Meýilleşdiriji keşi | work_mem | Hyzmat |
|---|---|---|---|---|
| <3 | 512MB | 1536MB | 4MB | 128MB |
| 3&#8209;6 | 1GB | 3GB | 6MB | 256MB |
| 6&#8209;12 | 2GB | 6GB | 8MB | 512MB |
| 12&#8209;24 | 4GB | 12GB | 12MB | 1GB |
| 24&#8209;48 | 8GB | 24GB | 16MB | 1GB |
| ≥48 | 16GB | 48GB | 24MB | 2GB |

| RAM, GB | Baglanyşyklar | WAL buferi | Temp buferi |
|---|---|---|---|
| <3 | 40 | 16MB | 8MB |
| 3&#8209;6 | 60 | 16MB | 8MB |
| 6&#8209;12 | 80 | 16MB | 16MB |
| 12&#8209;24 | 85 | 16MB | 24MB |
| 24&#8209;48 | 200 | 16MB | 32MB |
| ≥48 | 300 | 16MB | 48MB |

Parametrleriň doly atlary: bufer howzy — `shared_buffers`, meýilleşdiriji keşi — `effective_cache_size`, hyzmat — `maintenance_work_mem`, baglanyşyklar — `max_connections`, WAL buferi — `wal_buffers`, temp buferi — `temp_buffers`.

Awtomatik döredilýär: `bitrix` bazasy (`LC_CTYPE='C.UTF-8' TEMPLATE template0`), `bitrix` ulanyjysy, `public` shemasyna `GRANT CREATE`, `pgcrypto` giňeltmesi, `pg_hba.conf`-da parol autentifikasiýasy.

Preset ilkinji laýyk çäge görä saýlanýar; mejbury — `config.sh`-daky `BS_POSTGRES_PRESET`.

## Içine alnan baglylyklar (`vendor/`)

Öňler daşarky saýtlardan ýüklenýän zatlaryň ählisi repozitoriýada — `vendor/`: nginx gzip/zstd
modullary (Debian-da ýok), push&pull serweri, Bitrix-iň PHP/Nginx/Apache konfigurasiýalary,
Bitrix gurnama skriptleri, Netdata gurnama skripti we repozitoriýa açarlary. Gurnaýjy `vendor`
katalogy `/root/vm_menu/vendor`-a göçürýär, `vendor/CHECKSUMS.sha256` barlaýar we faýllary şol ýerden
alýar; tor diňe ýerli nusga ýok bolanda ulanylýar. Täzelemek — `tools/vendor-fetch.sh`,
barlamak — `tools/vendor-fetch.sh --check`. Debian, deb.sury.org, MySQL/Percona we Netdata
repozitoriýalary bilgeşleýin daşarky galýar: olar paket we howpsuzlyk täzelenmeleriniň çeşmesi,
içine alnan nusgalar derrew könelerdi.

### Bütewiligi barlamak (SHA256)

Her skriptiň, konfigurasiýanyň we paketiň barlag jemi bar. Manifestler repozitoriýada:
`CHECKSUMS.sha256` (kök: gurnaýjy, täzeleýji, `tools/`, `repositories/`),
`vm_menu/CHECKSUMS.sha256` (ählı menýu: `menu.sh`, `bash_scripts/`, `ansible/` pleýbuklary we
rollary, şablonlar we konfigurasiýalar) we `vendor/CHECKSUMS.sha256` (içine alnan paketler we
faýllar).

Barlaglar awtomatik ýerine ýetirilýär: gurnama wagtynda (ähli manifestler boýunça `sha256sum -c`,
nädogrylyk gurnamany togtadýar), menýuny täzelände (ýüklenen menýu işleýän nusgany çalyşmazdan
öň barlanýar), içine alnan nginx `.deb` paketlerini gurmazdan öň we `vendor_get` içinde islendik
içine alnan faýl ulanylmazdan öň. Manifestleri täzeden hasaplamak —
`tools/checksums.sh --update`, barlamak — `tools/checksums.sh --check`.

---

# **Menýuny täzeläň**
Täze wersiýa çykan bolsa, ony **bir buýruk bilen täzeläň**:
```bash
update_menu
```
Menýuny `CURL` ýa-da `WGET` arkaly el bilen hem täzeläp bolýar.  
Täzelenende häzirki wersiýa **awtomatiki ätiýaçlyk nusgasynda saklanýar** `/root/backup_vm_menu/DD.MM.YYYY HH:MM:SS`.

#### **`CURL` arkaly täzelenme**
```bash
bash <(curl -sL https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/update_menu.sh)
```
#### **`WGET` arkaly täzelenme**
```bash
bash <(wget -qO- https://raw.githubusercontent.com/Bx-Project-Hub/DebianBitrixVM/master/update_menu.sh)
```

---

# **Ulanyş**
Menýu **`/root/vm_menu`** atly katalogda ýerleşýär we **simboliki baglanyşyk** döredilýär:
- `/root/menu.sh` → `/root/vm_menu/menu.sh`

Menýuny şu buýruklar bilen işletmek bolýar:
```bash
./menu.sh   # /root katalogynda bolsaňyz
/root/menu.sh   # Islendik beýleki katalogdan işletmek üçin
```
Şeýle hem, menýunyň ýoly **awtomatiki `.profile`-e girizilýär**, şonuň üçin ol **SSH** birikdirilende derrew başlaýar.

---

# **Sazlamalar**
Menýu köp ugurdan sazlanmaga mümkinçilik berýär.  
Ähli parametrleri şu faýlda üýtgedip bolýar:
```bash
/root/vm_menu/bash_scripts/config.sh
```
Asyl ýagdaýda ähli zat öňünden gurlan, ýöne gerek bolsa, gurşawy özüňize laýyklykda düzedip bilersiňiz.

### Interfeýs dili

Menyu iki dilli: rus we iňlis. Dil ulgam lokalyna görä awtomatik saýlanýar:
`ru_RU.UTF-8` (ýa-da islendik `ru_*`) — rus dili; beýleki islendik, şol sanda `tk_TM.UTF-8`
we `C.UTF-8` — iňlis dili.

Mejbury saýlaw — gurşaw üýtgeýjisi ýa-da `config.sh` faýlyndaky `BS_MENU_LANG` parametri:

```bash
BS_MENU_LANG=en /root/menu.sh   # rus lokalynyň serwerinde iňlis dili
BS_MENU_LANG=ru /root/menu.sh   # iňlis lokalynyň serwerinde rus dili
```

Interfeýsiň ähli setirleri bir faýlda saklanýar — `/root/vm_menu/bash_scripts/i18n.sh`
(`MSG_RU` we `MSG_EN` sözlükleri).

---

# **Täzelenmeler we täze aýratynlyklar**
Menýu awtomatiki **täze wersiýalar barada habar berýär**.  
Ony şu buýruk bilen täzeläp bolýar:
```bash
update_menu
```
Eger menýu synaglaryňyz ýa-da üýtgetmeler sebäpli işlemese — **täzelenmegi işletseňiz**, ol **işleýän wersiýa gaýdyp geler**.

---

# **Goldaw, lokalizasiýa we teklipler**
Soraglaryňyz ýa-da teklipleriňiz bar bolsa, şu ýere goşulyň:
[**Telegram goldaw çaty**](https://t.me/bitrix_ferma)

