# **Baş menyu**
![Baş menyu](images/main_menu.png)

# **Maglumat**
Bitrix gurşawyny dolandyrmak üçin menyu, **Debian 12 / Debian 13** üçin uýgunlaşdyrylan. Esasy maksat — Debian 13 (trixie): taslama häzirki zaman Debian maşynlarynda CentOS 9 gurşawyny çalyşýar.  
(YogSottot) bitrix-gt](https://github.com/YogSottot/bitrix-gt) taslamasynyň esasynda döredildi we **häzirki zaman Debian 12–13 we Bitrix** üçin optimizasiýa edildi.

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

---

# **Täzelenmeler we täze aýratynlyklar**
![Täzelenme](images/new_version.png)

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

