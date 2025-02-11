# bitrix-gt
bitrix-gt from firstvds

В данном пакете собраны скрипты для установки окружения Bitrix на **Debian 11** и **Debian 12**.  
Расширенный скрипт **`custom_bitrix_setup.sh`** добавляет **меню, аналогичное Окружению для CentOS** и включает автоматическую установку MySQL 8 из официального репозитория Oracle.

## Доступные скрипты

### **Основные скрипты**
- **`bitrix_gt.sh`** — установка **nginx + apache + php-fpm + mariadb** для **БУС**.
- **`bitrix24_gt.sh`** — установка **nginx + apache + php-fpm + mariadb + redis + push-server** для **Bitrix24**.
- **`bitrix_setup_vanilla.sh`** — установка **nginx + apache + mariadb + redis + push-server**.  
  Воспроизводит официальное руководство:  
  [Настройка окружения для Debian 11](https://dev.1c-bitrix.ru/learning/course/index.php?COURSE_ID=32&CHAPTER_ID=05360&LESSON_PATH=3903.4862.20866.5360).

### **Расширенный скрипт**
- **`custom_bitrix_setup.sh`** — кастомизированный скрипт установки Bitrix, основанный на имеющихся решениях.  
  Отличается следующими особенностями:
  - **Меню, аналогичное Окружению для CentOS**, что упрощает настройку сервера.
  - **Автоматическая установка MySQL 8**, загружаемого из официального репозитория Oracle.
  - Оптимизирован для работы на **Debian 11** и **Debian 12**.
  - Воспроизводит официальное руководство [Настройка окружения для Debian 11](https://dev.1c-bitrix.ru/learning/course/index.php?COURSE_ID=32&CHAPTER_ID=05360&LESSON_PATH=3903.4862.20866.5360), но с дополнительными улучшениями.

## Альтернативные решения для развёртывания Bitrix
Если вам требуется другое окружение, посмотрите также:
- [ISPConfig сервер](https://github.com/Wladimir-N/ispconfig)
- [Bitrix Docker сервер](https://gitlab.com/bitrix-docker/server)
