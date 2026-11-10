#!/bin/bash
# Локализация меню Debian BitrixVM.
#
# Язык интерфейса выбирается автоматически по локали системы:
#   * локаль начинается с ru (ru_RU.UTF-8 и т. п.) → русский интерфейс;
#   * любая другая локаль (en_US, uk_UA, C, C.UTF-8, пустая) → английский.
# Принудительный выбор: BS_MENU_LANG="ru" | "en" | "auto" в config.sh
# или переменной окружения: BS_MENU_LANG=en /root/menu.sh
#
# Все строки интерфейса — через функцию t:
#   echo "   $(t menu.sites)"                 — строка без параметров
#   printf '   %s\n' "$(t php.done "8.3.36")" — строка с параметром %s
#
# ВАЖНО: в строках с параметрами не должно быть «лишних» символов %,
# иначе printf истолкует их как спецификаторы.

# Определение языка интерфейса по локали.
function detect_menu_lang() {
    case "${BS_MENU_LANG:-auto}" in
        ru|en) printf '%s' "${BS_MENU_LANG}"; return 0 ;;
    esac

    # BS_LOCALE_ORIGINAL выставляется в menu.sh ДО принудительного C.UTF-8,
    # иначе выбор языка зависел бы от подмены локали ради Ansible.
    local loc="${BS_LOCALE_ORIGINAL:-${LC_ALL:-${LC_MESSAGES:-${LANG:-}}}}"
    local lang_pref="${LANGUAGE:-}"

    # LANGUAGE=ru:en_US — glibc отдаёт приоритет этому списку
    if [ -n "$lang_pref" ]; then
        case "$lang_pref" in
            ru|ru:*|ru_*) printf 'ru'; return 0 ;;
        esac
        case "$lang_pref" in
            en|en:*|en_*) printf 'en'; return 0 ;;
        esac
    fi

    case "$loc" in
        ru|ru_*|ru.*|russian*) printf 'ru' ;;
        *)                     printf 'en' ;;
    esac
}

# Активный словарь (заполняется в i18n_init) и словари языков.
declare -A MSG

# ---------------------------------------------------------------- русский ---
declare -A MSG_RU=(

    # Общее
    [common.yes]="да"
    [common.no]="нет"
    [common.na]="н/д"
    [common.unknown]="неизвестен"
    [common.undefined]="не определена"
    [common.cancelled]="Отменено."
    [common.enter_command]="Введите команду:"
    [common.press_enter]="Нажмите Enter, чтобы вернуться в меню. "
    [common.back_main]="Вернуться в главное меню"
    [common.back]="Назад"
    [common.check_params]="Проверьте параметры:"
    [common.invalid_email]="Ошибка: некорректный e-mail."
    [common.unknown_command]="Ошибка: неизвестная команда \"%s\". Введите H для справки."
    [common.unknown_command_short]="Ошибка: неизвестная команда."
    [common.confirm_default]="Выполнить действие?"
    [common.need_root]="Ошибка: меню нужно запускать от пользователя root."
    [common.need_root_hint]="Используйте: sudo /root/menu.sh"
    [common.cancel_hint]="0 — отмена"
    [common.gb]="ГБ"
    [common.dhms]="%d д %d ч %d мин"
    [common.hm]="%d ч %d мин"
    [common.m]="%d мин"

    # Запуск
    [boot.unsupported]="Внимание: меню рассчитано на Debian 12 и Debian 13."
    [boot.current_os]="Текущая ОС: %s %s."
    [boot.continue]="Продолжение через 5 секунд..."

    # Главное меню
    [menu.tagline]="— управление окружением Bitrix"
    [menu.label_os]="ОС:"
    [menu.services]="Сервисы:"
    [menu.section_sites]="Сайты"
    [menu.section_access]="Доступ и безопасность"
    [menu.section_env]="Окружение"
    [menu.section_server]="Сервер"
    [menu.item_sites]="Список сайтов"
    [menu.item_sites_hint]="(каталоги, тип, HTTPS, document root)"
    [menu.item_add]="Создать сайт"
    [menu.item_add_hint]="(собственное ядро или ссылки на общее ядро)"
    [menu.item_delete]="Удалить сайт"
    [menu.item_delete_hint]="(каталог, конфигурация, база данных)"
    [menu.item_ssl]="Выпустить сертификат Let's Encrypt для сайта"
    [menu.item_redirect]="Включить или выключить редирект HTTP → HTTPS"
    [menu.item_php]="Сменить версию PHP"
    [menu.item_php_hint]="(текущая: %s)"
    [menu.item_smtp]="Настроить SMTP для отправки писем"
    [menu.item_addons]="Установить или удалить дополнения"
    [menu.item_addons_hint]="(Sphinx, конвертер, Netdata, PostgreSQL, restore.php)"
    [menu.item_emulate_on]="Включить эмуляцию BitrixVM (переменная %s)"
    [menu.item_emulate_off]="Выключить эмуляцию BitrixVM (текущая версия: %s)"
    [menu.item_update_pkgs]="Обновить пакеты системы"
    [menu.item_update_pkgs_hint]="(apt update && apt upgrade)"
    [menu.item_reboot]="Перезагрузить сервер"
    [menu.item_poweroff]="Выключить сервер"
    [menu.item_menu_new]="Обновить меню до новой версии"
    [menu.item_menu_current]="Обновить меню"
    [menu.item_menu_current_hint]="(переустановить текущую версию)"
    [menu.item_help]="Подробная справка по пунктам меню"
    [menu.item_exit]="Выход"
    [menu.new_version]="\e[33m
          Доступна новая версия меню Debian BitrixVM.
          Текущая версия: %s → новая: %s
          Ссылка: \e]8;;%s\a%s\e]8;;\a
          Обновить: команда \"update_menu\" или пункт \"U\" в меню.\n\e[0m"
    [menu.update_action]="Доступно обновление меню: введите \"update_menu\" или выберите пункт \"U\"."

    # Сайты
    [sites.in_path]="Сайты в %s:"
    [sites.col_dir]="Каталог сайта"
    [sites.col_type]="Тип"
    [sites.col_default]="По умолч."
    [sites.col_https]="HTTPS"
    [sites.col_docroot]="Document root"
    [sites.none]="Сайты не найдены."
    [sites.none_in]="Сайты не найдены в %s."
    [sites.type_note]="Тип: full — собственное ядро сайта, link — символические ссылки на общее ядро."
    [sites.choose_default]="Выберите сайт"
    [sites.choose_suffix]="%s (номер, %s): "
    [sites.invalid_number]="Ошибка: неверный номер."

    # Создание сайта
    [add.title]="Меню → Создание сайта"
    [add.domain_prompt]="Домен сайта (например, example.ru; %s): "
    [add.invalid_domain]="Ошибка: некорректный домен. Пример: example.ru"
    [add.dir_exists]="Ошибка: каталог %s уже существует."
    [add.mode_title]="Режим создания:"
    [add.mode_full]="full — собственное ядро Bitrix в каталоге сайта (для нового сайта)"
    [add.mode_link]="link — символические ссылки на ядро существующего сайта (мультисайтовость)"
    [add.mode_prompt]="Выберите режим [1]: "
    [add.source_prompt]="Путь к сайту-источнику ядра [%s]: "
    [add.no_bitrix]="Ошибка: в %s нет каталога bitrix."
    [add.db_name_prompt]="Имя базы данных [%s]: "
    [add.db_user_prompt]="Пользователь базы данных [%s]: "
    [add.db_exists]="Ошибка: база данных %s уже существует."
    [add.user_exists]="Ошибка: пользователь MySQL %s уже существует."
    [add.confirm_ssl]="Выпустить сертификат Let's Encrypt после создания сайта?"
    [add.confirm_www]="Выпустить сертификат также для www.%s?"
    [add.confirm_redirect]="Включить редирект HTTP → HTTPS?"
    [add.param_domain]="Домен:"
    [add.param_mode]="Режим:"
    [add.param_core]="Ядро сайта:"
    [add.param_db]="База данных:"
    [add.param_db_value]="%s (пользователь %s)"
    [add.param_ssl]="Let's Encrypt:"
    [add.param_ssl_value]="%s"
    [add.param_ssl_value_full]="%s (%s, www: %s)"
    [add.param_redirect]="HTTPS-редирект:"
    [add.confirm_create]="Создать сайт %s?"

    # Удаление сайта
    [del.title]="Меню → Удаление сайта"
    [del.warning]="Будут удалены каталог сайта, конфигурации Nginx/Apache и (для режима full) база данных."
    [del.choose]="Какой сайт удалить"
    [del.param_site]="Сайт:"
    [del.param_dir]="Каталог:"
    [del.param_type]="Тип:"
    [del.param_db]="База:"
    [del.param_db_value]="%s (пользователь %s)"
    [del.confirm_prompt]="Для подтверждения введите имя сайта (%s): "

    # Let's Encrypt
    [le.title]="Меню → Сертификат Let's Encrypt"
    [le.http01]="Сертификат выпускается по протоколу HTTP-01: домен должен уже указывать на этот сервер, а порт 80 — быть доступен извне."
    [le.choose]="Для какого сайта выпустить сертификат"
    [le.email_prompt]="E-mail для Let's Encrypt: "
    [le.confirm]="Выпустить сертификат для %s?"

    # Редирект
    [redir.title]="Меню → Редирект HTTP → HTTPS"
    [redir.choose]="Для какого сайта изменить редирект"
    [redir.enabled]="Сейчас редирект ВКЛЮЧЁН."
    [redir.disabled]="Сейчас редирект ВЫКЛЮЧЕН."
    [redir.confirm_disable]="Выключить редирект HTTP → HTTPS для %s?"
    [redir.confirm_enable]="Включить редирект HTTP → HTTPS для %s?"

    # PHP
    [php.title]="Меню → Смена версии PHP"
    [php.current]="Текущая версия PHP: %s"
    [php.available]="Доступные для установки версии PHP:"
    [php.cant_list]="Не удалось получить список версий PHP (apt-cache search)."
    [php.check_repo]="Проверьте, что подключён репозиторий deb.sury.org."
    [php.version_prompt]="Введите версию PHP для установки (например, 8.3; %s): "
    [php.unsupported]="Ошибка: версия %s не поддерживается меню (доступно: %s)."
    [php.unavailable]="Ошибка: версия PHP %s недоступна в подключённых репозиториях."
    [php.confirm]="Установить PHP %s и переключить Apache на неё?"
    [php.no_version]="Ошибка: не указана версия PHP."
    [php.no_repo]="Ошибка: не подключён репозиторий deb.sury.org (/etc/apt/sources.list.d/sury-php.list)."
    [php.install_env]="Установите окружение через install_full_environment.sh."
    [php.installing]="Установка PHP %s..."
    [php.install_failed]="Ошибка: не удалось установить PHP %s."
    [php.cant_download_configs]="Предупреждение: не удалось скачать конфигурацию Bitrix (debian.zip)."
    [php.cant_enable_mod]="Ошибка: не удалось включить mod_php %s для Apache."
    [php.done]="Готово. Активная версия PHP: %s."

    # SMTP
    [smtp.title]="Меню → SMTP"
    [smtp.item_site]="Настроить или обновить SMTP-аккаунт для сайта"
    [smtp.item_default]="Настроить общий аккаунт default (используется, если для сайта аккаунт не задан)"
    [smtp.item_show]="Показать сохранённые аккаунты"
    [smtp.saved]="Сохранённые SMTP-аккаунты (%s):"
    [smtp.no_file]="Файл не найден. Аккаунты ещё не настраивались."
    [smtp.no_accounts]="Аккаунты не найдены."
    [smtp.configure_title]="Меню → SMTP → Настройка аккаунта"
    [smtp.choose_site]="Для какого сайта настроить SMTP"
    [smtp.account]="Аккаунт: %s"
    [smtp.account_note]="(это имя должно совпадать с доменом сайта: Apache передаёт его в msmtp-wrapper)"
    [smtp.host_prompt]="SMTP-сервер (например, smtp.yandex.ru): "
    [smtp.port_prompt]="Порт SMTP [587]: "
    [smtp.from_prompt]="Адрес отправителя [%s]: "
    [smtp.confirm_auth]="Требуется авторизация на SMTP-сервере?"
    [smtp.auth_method_prompt]="Метод авторизации (auto/plain/login/cram-md5) [auto]: "
    [smtp.login_prompt]="Логин: "
    [smtp.password_prompt]="Пароль: "
    [smtp.confirm_tls]="Использовать TLS?"
    [smtp.param_account]="Аккаунт:"
    [smtp.param_server]="Сервер:"
    [smtp.param_from]="От:"
    [smtp.param_auth]="Авторизация:"
    [smtp.param_auth_on]="включена (логин %s, метод %s)"
    [smtp.param_auth_off]="выключена"
    [smtp.param_tls]="TLS:"
    [smtp.confirm_save]="Сохранить настройки SMTP?"

    # Дополнения
    [ext.title]="Дополнительные компоненты"
    [ext.sphinx]="Sphinx — полнотекстовый поиск (пакет %s)"
    [ext.converter]="Сервер конвертации файлов (LibreOffice + RabbitMQ + transformer)"
    [ext.netdata]="Netdata — мониторинг ресурсов сервера"
    [sphinx.title]="Меню → Sphinx (полнотекстовый поиск)"
    [sphinx.install]="Установить Sphinx"
    [sphinx.delete]="Удалить Sphinx"
    [sphinx.confirm_install]="Установить Sphinx (%s)?"
    [sphinx.confirm_delete]="Удалить Sphinx?"
    [netdata.title]="Меню → Netdata (мониторинг)"
    [netdata.install]="Установить Netdata"
    [netdata.delete]="Удалить Netdata"
    [netdata.confirm_install]="Установить Netdata?"
    [netdata.confirm_delete]="Удалить Netdata?"
    [conv.title]="Меню → Сервер конвертации файлов"
    [conv.note]="Компоненты: LibreOffice, RabbitMQ, transformer (служба обработки файлов)."
    [conv.need_site]="Требуется установленный сайт с ядром Bitrix."
    [conv.install]="Установить"
    [conv.delete]="Удалить"
    [conv.choose]="Для какого сайта выполнить действие"
    [conv.action_install]="установку"
    [conv.action_delete]="удаление"
    [conv.confirm]="Выполнить «%s» сервера конвертации для %s?"
    [ext.postgres]="PostgreSQL — база данных для портала Bitrix (пресеты под объём RAM)"
    [postgres.title]="Меню → PostgreSQL"
    [postgres.note]="Ставится PostgreSQL из репозитория Debian и расширение pgsql для PHP. База создаётся с LC_CTYPE=C.UTF-8 (TEMPLATE template0), включается pgcrypto, вход — по паролю."
    [postgres.preset_note]="Параметры postgresql.conf подбираются по объёму RAM: shared_buffers ≈ 25%, effective_cache_size ≈ 75%, work_mem — с учётом max_connections."
    [postgres.install]="Установить PostgreSQL"
    [postgres.delete]="Удалить PostgreSQL"
    [postgres.delete_warning]="Внимание: при удалении пропадут ВСЕ базы данных PostgreSQL, включая созданные вручную."
    [postgres.confirm_install]="Установить PostgreSQL и создать базу %s для портала?"
    [postgres.confirm_delete]="Удалить PostgreSQL вместе со всеми базами данных?"
    [ext.restore]="Скрипт восстановления restore.php (разместить по запросу / удалить)"
    [restore.title]="Меню → Скрипт восстановления портала (restore.php)"
    [restore.note]="restore.php разворачивает архив резервной копии на сервере и поэтому опасен."
    [restore.note2]="В проекте он не хранится и при создании сайта не копируется: размещайте его только на время восстановления и сразу удаляйте после."
    [restore.place]="Разместить restore.php в каталоге сайта"
    [restore.remove]="Удалить restore.php из каталога сайта"
    [restore.choose]="Для какого сайта выполнить действие"
    [restore.confirm_place]="Разместить restore.php в каталоге сайта %s? После восстановления его нужно удалить!"
    [restore.confirm_remove]="Удалить restore.php из каталога сайта %s?"
    [restore.action_place]="размещение"
    [restore.action_remove]="удаление"
    [ext.apps_cms]="Приложения для CMS Bitrix — pandoc, PDF (wkhtmltopdf/weasyprint)"
    [ext.apps_b24]="Приложения для CRM / Битрикс24 — документы + OCR (tesseract)"
    [ext.memcached]="memcached — кэш в памяти + PHP-расширение (установить/удалить)"
    [apps.title_cms]="Меню → Приложения для CMS Bitrix"
    [apps.title_b24]="Меню → Приложения для CRM / Битрикс24"
    [apps.note]="Пакеты берутся из стандартного репозитория Debian: ставятся только те, что в нём есть, отсутствующие пропускаются."
    [apps.cms_list]="Состав: pandoc (конвертация документов), wkhtmltopdf или weasyprint (HTML → PDF)."
    [apps.b24_list]="Состав: pandoc, wkhtmltopdf или weasyprint (PDF счетов и документов), tesseract-ocr + tesseract-ocr-rus (распознавание сканов)."
    [apps.install]="Установить"
    [apps.delete]="Удалить"
    [apps.confirm_install]="Установить приложения группы «%s»?"
    [apps.confirm_delete]="Удалить приложения группы «%s» (вместе с зависимостями)?"
    [apps.nothing_found]="В подключённых репозиториях не найдено ни одного пакета из этого набора."
    [apps.unknown_group]="Ошибка: неизвестная группа приложений: %s"
    [apps.group_cms]="CMS Bitrix"
    [apps.group_b24]="CRM / Битрикс24"
    [memcached.title]="Меню → memcached"
    [memcached.note]="Ставится сервер memcached и PHP-расширение memcached для активной версии PHP; модуль включается для CLI и Apache."
    [memcached.listening]="Проверка после установки: printf 'version\r\n' | nc 127.0.0.1 11211"
    [memcached.install]="Установить memcached и расширение PHP"
    [memcached.delete]="Удалить memcached и расширение PHP"
    [memcached.confirm_install]="Установить memcached и включить расширение PHP memcached?"
    [memcached.confirm_delete]="Удалить memcached и расширение PHP memcached?"

    # Сервер, обновления
    [menu.item_autoupd_on]="Включить автообновление меню (по crontab раз в сутки)"
    [menu.item_autoupd_off]="Выключить автообновление меню (включено: %s)"
    [autoupd.enabled]="Автообновление меню включено: crontab «%s», лог %s"
    [autoupd.disabled]="Автообновление меню выключено (запись удалена из crontab)."
    [autoupd.failed_on]="Не удалось включить автообновление: crontab вернул ошибку."
    [autoupd.failed_off]="Не удалось выключить автообновление: crontab вернул ошибку."
    [autoupd.no_launcher]="Внимание: /usr/local/bin/update_menu не найден — автообновление не сработает (переустановите меню)."
    [upd.confirm_pkgs]="Обновить пакеты системы (apt update && apt upgrade)?"
    [upd.confirm_menu]="Обновить меню (текущая версия сохранится в /root/backup_vm_menu)?"
    [upd.failed]="Обновление не выполнено (код %s). Текущее меню продолжает работать."
    [upd.no_file]="Обновление выполнено, но файл меню не найден: %s"
    [upd.run_manual]="Запустите меню вручную: /root/menu.sh"
    [upd.restarting]="Перезапуск меню..."
    [emul.on]="Эмуляция BitrixVM включена (%s=%s)."
    [emul.off]="Эмуляция BitrixVM отключена (удалена переменная %s)."
    [action.unknown_sphinx]="Ошибка: неизвестное действие для Sphinx: %s"
    [action.unknown_netdata]="Ошибка: неизвестное действие для Netdata: %s"
    [action.unknown_conv]="Ошибка: неизвестное действие для сервера конвертации: %s"
    [action.unknown_postgres]="Ошибка: неизвестное действие для PostgreSQL: %s"
    [action.unknown_restore]="Ошибка: неизвестное действие со скриптом восстановления: %s"
    [action.unknown_memcached]="Ошибка: неизвестное действие для memcached: %s"
    [server.confirm_reboot]="Вы действительно хотите ПЕРЕЗАГРУЗИТЬ сервер? (Y/N): "
    [server.confirm_poweroff]="Вы действительно хотите ВЫКЛЮЧИТЬ сервер? (Y/N): "
    [server.enter_yn]="Введите Y или N."

    # Панель состояния
    [status.title]=" Состояние сервера "
    [status.load]="Загрузка"
    [status.mem]="Память"
    [status.disk]="Диск /"
    [status.uptime]="Аптайм"
    [status.interfaces]="Сетевые интерфейсы и IP:\n"

    # Панель «Установлено»
    [env.title]=" Установлено "
    [env.sites]="Сайты (%s)"
    [env.ssl_days]="SSL %s дн."
    [env.no_ssl]="без SSL"
    [env.and_more]="… и ещё %s"
    [env.no_sites]="сайтов нет"
    [env.addons]="Дополнения %s"
    [env.addons_none]="Дополнения не установлены"
    [env.netdata_stats]="Статистика Netdata: %s — нагрузка CPU, память, диск, сеть в реальном времени"
    [env.default]="default"
)

# -------------------------------------------------------------- английский ---
declare -A MSG_EN=(

    [common.yes]="yes"
    [common.no]="no"
    [common.na]="n/a"
    [common.unknown]="unknown"
    [common.undefined]="not detected"
    [common.cancelled]="Cancelled."
    [common.enter_command]="Enter command:"
    [common.press_enter]="Press Enter to return to the menu. "
    [common.back_main]="Back to the main menu"
    [common.back]="Back"
    [common.check_params]="Check the parameters:"
    [common.invalid_email]="Error: invalid e-mail address."
    [common.unknown_command]="Error: unknown command \"%s\". Type H for help."
    [common.unknown_command_short]="Error: unknown command."
    [common.confirm_default]="Perform the action?"
    [common.need_root]="Error: the menu must be run as root."
    [common.need_root_hint]="Use: sudo /root/menu.sh"
    [common.cancel_hint]="0 — cancel"
    [common.gb]="GB"
    [common.dhms]="%dd %dh %dm"
    [common.hm]="%dh %dm"
    [common.m]="%dm"

    [boot.unsupported]="Warning: this menu is designed for Debian 12 and Debian 13."
    [boot.current_os]="Current OS: %s %s."
    [boot.continue]="Continuing in 5 seconds..."

    [menu.tagline]="— Bitrix environment management"
    [menu.label_os]="OS:"
    [menu.services]="Services:"
    [menu.section_sites]="Sites"
    [menu.section_access]="Access and security"
    [menu.section_env]="Environment"
    [menu.section_server]="Server"
    [menu.item_sites]="List sites"
    [menu.item_sites_hint]="(directories, type, HTTPS, document root)"
    [menu.item_add]="Create a site"
    [menu.item_add_hint]="(own core or links to a shared core)"
    [menu.item_delete]="Delete a site"
    [menu.item_delete_hint]="(directory, configuration, database)"
    [menu.item_ssl]="Issue a Let's Encrypt certificate for a site"
    [menu.item_redirect]="Enable or disable HTTP → HTTPS redirect"
    [menu.item_php]="Change the PHP version"
    [menu.item_php_hint]="(current: %s)"
    [menu.item_smtp]="Configure SMTP for outgoing mail"
    [menu.item_addons]="Install or remove add-ons"
    [menu.item_addons_hint]="(Sphinx, converter, Netdata, PostgreSQL, restore.php)"
    [menu.item_emulate_on]="Enable BitrixVM emulation (variable %s)"
    [menu.item_emulate_off]="Disable BitrixVM emulation (current version: %s)"
    [menu.item_update_pkgs]="Update system packages"
    [menu.item_update_pkgs_hint]="(apt update && apt upgrade)"
    [menu.item_reboot]="Reboot the server"
    [menu.item_poweroff]="Shut down the server"
    [menu.item_menu_new]="Update the menu to the new version"
    [menu.item_menu_current]="Update the menu"
    [menu.item_menu_current_hint]="(reinstall the current version)"
    [menu.item_help]="Detailed help on the menu items"
    [menu.item_exit]="Exit"
    [menu.new_version]="\e[33m
          A new Debian BitrixVM menu version is available.
          Current version: %s → new: %s
          Link: \e]8;;%s\a%s\e]8;;\a
          Update: run \"update_menu\" or choose item \"U\" in the menu.\n\e[0m"
    [menu.update_action]="Menu update available: run \"update_menu\" or choose item \"U\"."

    [sites.in_path]="Sites in %s:"
    [sites.col_dir]="Site directory"
    [sites.col_type]="Type"
    [sites.col_default]="Default"
    [sites.col_https]="HTTPS"
    [sites.col_docroot]="Document root"
    [sites.none]="No sites found."
    [sites.none_in]="No sites found in %s."
    [sites.type_note]="Type: full — the site has its own core, link — symbolic links to a shared core."
    [sites.choose_default]="Choose a site"
    [sites.choose_suffix]="%s (number, %s): "
    [sites.invalid_number]="Error: invalid number."

    [add.title]="Menu → Create site"
    [add.domain_prompt]="Site domain (for example, example.com; %s): "
    [add.invalid_domain]="Error: invalid domain. Example: example.com"
    [add.dir_exists]="Error: directory %s already exists."
    [add.mode_title]="Creation mode:"
    [add.mode_full]="full — a separate Bitrix core inside the site directory (for a new site)"
    [add.mode_link]="link — symbolic links to the core of an existing site (multi-site)"
    [add.mode_prompt]="Choose the mode [1]: "
    [add.source_prompt]="Path to the source site with the core [%s]: "
    [add.no_bitrix]="Error: %s has no bitrix directory."
    [add.db_name_prompt]="Database name [%s]: "
    [add.db_user_prompt]="Database user [%s]: "
    [add.db_exists]="Error: database %s already exists."
    [add.user_exists]="Error: MySQL user %s already exists."
    [add.confirm_ssl]="Issue a Let's Encrypt certificate after creating the site?"
    [add.confirm_www]="Issue the certificate for www.%s as well?"
    [add.confirm_redirect]="Enable HTTP → HTTPS redirect?"
    [add.param_domain]="Domain:"
    [add.param_mode]="Mode:"
    [add.param_core]="Site core:"
    [add.param_db]="Database:"
    [add.param_db_value]="%s (user %s)"
    [add.param_ssl]="Let's Encrypt:"
    [add.param_ssl_value]="%s"
    [add.param_ssl_value_full]="%s (%s, www: %s)"
    [add.param_redirect]="HTTPS redirect:"
    [add.confirm_create]="Create the site %s?"

    [del.title]="Menu → Delete site"
    [del.warning]="The site directory, Nginx/Apache configurations and (in full mode) the database will be deleted."
    [del.choose]="Which site to delete"
    [del.param_site]="Site:"
    [del.param_dir]="Directory:"
    [del.param_type]="Type:"
    [del.param_db]="Database:"
    [del.param_db_value]="%s (user %s)"
    [del.confirm_prompt]="To confirm, type the site name (%s): "

    [le.title]="Menu → Let's Encrypt certificate"
    [le.http01]="The certificate is issued over HTTP-01: the domain must already point to this server and port 80 must be reachable from outside."
    [le.choose]="For which site to issue the certificate"
    [le.email_prompt]="E-mail for Let's Encrypt: "
    [le.confirm]="Issue a certificate for %s?"

    [redir.title]="Menu → HTTP → HTTPS redirect"
    [redir.choose]="For which site to change the redirect"
    [redir.enabled]="The redirect is currently ENABLED."
    [redir.disabled]="The redirect is currently DISABLED."
    [redir.confirm_disable]="Disable the HTTP → HTTPS redirect for %s?"
    [redir.confirm_enable]="Enable the HTTP → HTTPS redirect for %s?"

    [php.title]="Menu → Change PHP version"
    [php.current]="Current PHP version: %s"
    [php.available]="PHP versions available for installation:"
    [php.cant_list]="Could not get the list of PHP versions (apt-cache search)."
    [php.check_repo]="Make sure the deb.sury.org repository is configured."
    [php.version_prompt]="Enter the PHP version to install (for example, 8.3; %s): "
    [php.unsupported]="Error: version %s is not supported by the menu (available: %s)."
    [php.unavailable]="Error: PHP %s is not available in the configured repositories."
    [php.confirm]="Install PHP %s and switch Apache to it?"
    [php.no_version]="Error: PHP version is not specified."
    [php.no_repo]="Error: the deb.sury.org repository is not configured (/etc/apt/sources.list.d/sury-php.list)."
    [php.install_env]="Install the environment with install_full_environment.sh."
    [php.installing]="Installing PHP %s..."
    [php.install_failed]="Error: failed to install PHP %s."
    [php.cant_download_configs]="Warning: could not download the Bitrix configuration (debian.zip)."
    [php.cant_enable_mod]="Error: failed to enable mod_php %s for Apache."
    [php.done]="Done. Active PHP version: %s."

    [smtp.title]="Menu → SMTP"
    [smtp.item_site]="Configure or update an SMTP account for a site"
    [smtp.item_default]="Configure the shared default account (used when a site has no account)"
    [smtp.item_show]="Show saved accounts"
    [smtp.saved]="Saved SMTP accounts (%s):"
    [smtp.no_file]="File not found. No accounts have been configured yet."
    [smtp.no_accounts]="No accounts found."
    [smtp.configure_title]="Menu → SMTP → Configure account"
    [smtp.choose_site]="For which site to configure SMTP"
    [smtp.account]="Account: %s"
    [smtp.account_note]="(this name must match the site domain: Apache passes it to msmtp-wrapper)"
    [smtp.host_prompt]="SMTP server (for example, smtp.example.com): "
    [smtp.port_prompt]="SMTP port [587]: "
    [smtp.from_prompt]="Sender address [%s]: "
    [smtp.confirm_auth]="Does the SMTP server require authentication?"
    [smtp.auth_method_prompt]="Authentication method (auto/plain/login/cram-md5) [auto]: "
    [smtp.login_prompt]="Login: "
    [smtp.password_prompt]="Password: "
    [smtp.confirm_tls]="Use TLS?"
    [smtp.param_account]="Account:"
    [smtp.param_server]="Server:"
    [smtp.param_from]="From:"
    [smtp.param_auth]="Authentication:"
    [smtp.param_auth_on]="enabled (login %s, method %s)"
    [smtp.param_auth_off]="disabled"
    [smtp.param_tls]="TLS:"
    [smtp.confirm_save]="Save the SMTP settings?"

    [ext.title]="Additional components"
    [ext.sphinx]="Sphinx — full-text search (package %s)"
    [ext.converter]="File conversion server (LibreOffice + RabbitMQ + transformer)"
    [ext.netdata]="Netdata — server resource monitoring"
    [sphinx.title]="Menu → Sphinx (full-text search)"
    [sphinx.install]="Install Sphinx"
    [sphinx.delete]="Remove Sphinx"
    [sphinx.confirm_install]="Install Sphinx (%s)?"
    [sphinx.confirm_delete]="Remove Sphinx?"
    [netdata.title]="Menu → Netdata (monitoring)"
    [netdata.install]="Install Netdata"
    [netdata.delete]="Remove Netdata"
    [netdata.confirm_install]="Install Netdata?"
    [netdata.confirm_delete]="Remove Netdata?"
    [conv.title]="Menu → File conversion server"
    [conv.note]="Components: LibreOffice, RabbitMQ, transformer (file processing service)."
    [conv.need_site]="A site with the Bitrix core is required."
    [conv.install]="Install"
    [conv.delete]="Remove"
    [conv.choose]="For which site to perform the action"
    [conv.action_install]="install"
    [conv.action_delete]="removal"
    [conv.confirm]="Perform the «%s» of the conversion server for %s?"
    [ext.postgres]="PostgreSQL — database for a Bitrix portal (RAM-based presets)"
    [postgres.title]="Menu → PostgreSQL"
    [postgres.note]="Installs PostgreSQL from the Debian repository and the PHP pgsql extension. The database is created with LC_CTYPE=C.UTF-8 (TEMPLATE template0), pgcrypto is enabled, authentication is password-based."
    [postgres.preset_note]="postgresql.conf settings are selected by the amount of RAM: shared_buffers ≈ 25%, effective_cache_size ≈ 75%, work_mem is balanced against max_connections."
    [postgres.install]="Install PostgreSQL"
    [postgres.delete]="Remove PostgreSQL"
    [postgres.delete_warning]="Warning: removing PostgreSQL deletes ALL PostgreSQL databases, including manually created ones."
    [postgres.confirm_install]="Install PostgreSQL and create the %s database for the portal?"
    [postgres.confirm_delete]="Remove PostgreSQL together with all its databases?"
    [ext.restore]="Restore script restore.php (place on demand / remove)"
    [restore.title]="Menu → Portal restore script (restore.php)"
    [restore.note]="restore.php deploys a backup archive on the server, which makes it dangerous."
    [restore.note2]="It is not stored in the project and is not copied when a site is created: place it only for the duration of a restore and delete it right after."
    [restore.place]="Place restore.php into the site directory"
    [restore.remove]="Remove restore.php from the site directory"
    [restore.choose]="For which site to perform the action"
    [restore.confirm_place]="Place restore.php into the site directory %s? It must be deleted after the restore!"
    [restore.confirm_remove]="Remove restore.php from the site directory %s?"
    [restore.action_place]="placement"
    [restore.action_remove]="removal"
    [ext.apps_cms]="Applications for Bitrix CMS — pandoc, PDF (wkhtmltopdf/weasyprint)"
    [ext.apps_b24]="Applications for CRM / Bitrix24 — documents + OCR (tesseract)"
    [ext.memcached]="memcached — in-memory cache + PHP extension (install/remove)"
    [apps.title_cms]="Menu → Applications for Bitrix CMS"
    [apps.title_b24]="Menu → Applications for CRM / Bitrix24"
    [apps.note]="Packages come from the standard Debian repository: only available ones are installed, missing ones are skipped."
    [apps.cms_list]="Includes: pandoc (document conversion), wkhtmltopdf or weasyprint (HTML → PDF)."
    [apps.b24_list]="Includes: pandoc, wkhtmltopdf or weasyprint (invoice and document PDF), tesseract-ocr + tesseract-ocr-rus (scan recognition)."
    [apps.install]="Install"
    [apps.delete]="Remove"
    [apps.confirm_install]="Install the «%s» application set?"
    [apps.confirm_delete]="Remove the «%s» applications (with dependencies)?"
    [apps.nothing_found]="None of these packages were found in the configured repositories."
    [apps.unknown_group]="Error: unknown application group: %s"
    [apps.group_cms]="Bitrix CMS"
    [apps.group_b24]="CRM / Bitrix24"
    [memcached.title]="Menu → memcached"
    [memcached.note]="Installs the memcached server and the PHP memcached extension for the active PHP version; the module is enabled for CLI and Apache."
    [memcached.listening]="Check after installation: printf 'version\r\n' | nc 127.0.0.1 11211"
    [memcached.install]="Install memcached and the PHP extension"
    [memcached.delete]="Remove memcached and the PHP extension"
    [memcached.confirm_install]="Install memcached and enable the PHP memcached extension?"
    [memcached.confirm_delete]="Remove memcached and the PHP memcached extension?"

    [menu.item_autoupd_on]="Enable menu auto-update (daily via crontab)"
    [menu.item_autoupd_off]="Disable menu auto-update (enabled: %s)"
    [autoupd.enabled]="Menu auto-update enabled: crontab «%s», log %s"
    [autoupd.disabled]="Menu auto-update disabled (crontab entry removed)."
    [autoupd.failed_on]="Failed to enable auto-update: crontab returned an error."
    [autoupd.failed_off]="Failed to disable auto-update: crontab returned an error."
    [autoupd.no_launcher]="Warning: /usr/local/bin/update_menu not found — auto-update will not run (reinstall the menu)."
    [upd.confirm_pkgs]="Update system packages (apt update && apt upgrade)?"
    [upd.confirm_menu]="Update the menu (the current version will be backed up to /root/backup_vm_menu)?"
    [upd.failed]="Update failed (code %s). The current menu keeps working."
    [upd.no_file]="Update finished, but the menu file was not found: %s"
    [upd.run_manual]="Start the menu manually: /root/menu.sh"
    [upd.restarting]="Restarting the menu..."
    [emul.on]="BitrixVM emulation enabled (%s=%s)."
    [emul.off]="BitrixVM emulation disabled (variable %s removed)."
    [action.unknown_sphinx]="Error: unknown action for Sphinx: %s"
    [action.unknown_netdata]="Error: unknown action for Netdata: %s"
    [action.unknown_conv]="Error: unknown action for the conversion server: %s"
    [action.unknown_postgres]="Error: unknown action for PostgreSQL: %s"
    [action.unknown_restore]="Error: unknown action for the restore script: %s"
    [action.unknown_memcached]="Error: unknown action for memcached: %s"
    [server.confirm_reboot]="Do you really want to RESTART the server? (Y/N): "
    [server.confirm_poweroff]="Do you really want to SHUT DOWN the server? (Y/N): "
    [server.enter_yn]="Please enter Y or N."

    [status.title]=" Server status "
    [status.load]="Load"
    [status.mem]="Memory"
    [status.disk]="Disk /"
    [status.uptime]="Uptime"
    [status.interfaces]="Network interfaces and IPs:\n"

    [env.title]=" Installed "
    [env.sites]="Sites (%s)"
    [env.ssl_days]="SSL %s d"
    [env.no_ssl]="no SSL"
    [env.and_more]="… and %s more"
    [env.no_sites]="no sites"
    [env.addons]="Add-ons %s"
    [env.addons_none]="No add-ons installed"
    [env.netdata_stats]="Netdata dashboard: %s — live CPU, memory, disk and network metrics"
    [env.default]="default"
)

# Текст справки (пункт H).
function i18n_help_text() {
    if [ "${BS_MENU_LANG_CURRENT:-en}" = "ru" ]; then
        cat <<'HELP'

   Справка по меню Debian BitrixVM
   ==============================

   САЙТЫ
   1) Список сайтов — каталоги в /var/www/html, тип (full/link), признак
      «сайт по умолчанию», наличие HTTPS-редиректа и полный путь к document root.
      full — у сайта собственное ядро Bitrix; link — символические ссылки на
      общее ядро (каталоги local, bitrix, upload, images).

   2) Создать сайт — создаёт каталог, конфигурации Nginx и Apache, при режиме full
      базу данных и пользователя MySQL, генерирует .settings.php и dbconn.php,
      при необходимости переводит агенты Bitrix на CRON и выпускает сертификат.

   3) Удалить сайт — удаляет каталог сайта, конфигурации Nginx/Apache, а для
      режима full — базу данных и пользователя MySQL. Требуется ввести имя сайта.

   ДОСТУП И БЕЗОПАСНОСТЬ
   4) Сертификат Let's Encrypt — выпуск по HTTP-01. Домен должен указывать на
      сервер, порт 80 должен быть открыт.
   5) Редирект HTTP → HTTPS — включает или выключает перенаправление на HTTPS
      (файл-маркер .htsecure в каталоге сайта).

   ОКРУЖЕНИЕ
   6) Смена версии PHP — доустанавливает выбранную версию из репозитория
      deb.sury.org и переключает Apache и CLI (update-alternatives).
   7) SMTP — аккаунты в /var/www/html/.msmtprc. Apache передаёт имя аккаунта
      в msmtp-wrapper (обычно это домен сайта). Аккаунт default используется,
      если аккаунт сайта не найден.
   8) Дополнения — Sphinx, сервер конвертации файлов, Netdata, PostgreSQL,
      restore.php (разместить по запросу / удалить).

   СКРИПТ ВОССТАНОВЛЕНИЯ restore.php
   Хранить restore.php в каталоге сайта постоянно нельзя: он разворачивает
   архив резервной копии. В проекте файла нет, при создании сайта он не
   копируется. Порядок: 8 → 5 → 1 (разместить) → восстановление портала →
   8 → 5 → 2 (удалить).
   9) Эмуляция BitrixVM — переменная BITRIX_VA_VER в /etc/apache2/envvars
      (нужна некоторым решениям маркетплейса).

   СЕРВЕР
   A) Обновление пакетов — apt update && apt upgrade.
   R) Перезагрузка. P) Выключение. U) Обновление меню.
   C) Автообновление меню по crontab (раз в сутки): включить или выключить.

   ЯЗЫК ИНТЕРФЕЙСА
   Язык выбирается по локали системы: русская локаль (ru_RU.UTF-8) — русский
   интерфейс, любая другая — английский. Принудительно:
     BS_MENU_LANG=ru /root/menu.sh
     BS_MENU_LANG=en /root/menu.sh
   либо параметр BS_MENU_LANG в config.sh (auto | ru | en).

   ШАПКА МЕНЮ
   Панель «Состояние сервера» показывает load average, загрузку CPU, память,
   диск и аптайм. Значения окрашены по порогам: до 70% — зелёный,
   70–89% — жёлтый, от 90% — красный.

   Панель «Установлено» подсказывает, что уже развёрнуто на сервере:
   сайты (тип full/link, пометка default), срок действия сертификата
   Let's Encrypt, версию и состояние push&pull и установленные дополнения
   (Sphinx, Netdata, RabbitMQ). Сертификаты подсвечиваются по остатку дней:
   меньше 14 — красный, меньше 30 — жёлтый.

   Настройки в /root/vm_menu/bash_scripts/config.sh:
     BS_MENU_LANG           — язык интерфейса: auto (по локали), ru, en;
     BS_STATUS_PANEL        — вкл/выкл панель состояния (true/false);
     BS_STATUS_PANEL_SITES  — вкл/выкл панель «Установлено»;
     BS_STATUS_MAX_SITES    — сколько сайтов перечислять (остальные «и ещё N»);
     BS_STATUS_PANEL_WIDTH  — ширина панелей в символах;
     BS_CPU_SAMPLE_MS       — окно замера CPU в миллисекундах (0 — без замера);
     BS_USE_COLOR           — вкл/выкл цвета (можно отключить через NO_COLOR=1);
     BS_SHOW_IP_CURRENT_SERVER_IN_MENU — показывать интерфейсы и IP.

HELP
        return 0
    fi

    cat <<'HELP'

   Debian BitrixVM menu help
   =========================

   SITES
   1) List sites — directories in /var/www/html with their type (full/link),
      the "default site" flag, HTTPS redirect status and the full document root.
      full — the site has its own Bitrix core; link — symbolic links to a shared
      core (local, bitrix, upload, images directories).

   2) Create a site — creates the directory, Nginx and Apache configurations, and
      in full mode the MySQL database and user; generates .settings.php and
      dbconn.php; optionally switches Bitrix agents to CRON and issues a
      certificate.

   3) Delete a site — removes the site directory, Nginx/Apache configurations and,
      in full mode, the MySQL database and user. Typing the site name is required.

   ACCESS AND SECURITY
   4) Let's Encrypt certificate — issued over HTTP-01. The domain must point to
      the server and port 80 must be open.
   5) HTTP → HTTPS redirect — enables or disables redirection to HTTPS
      (the .htsecure marker file in the site directory).

   ENVIRONMENT
   6) Change PHP version — installs the selected version from the deb.sury.org
      repository and switches Apache and CLI (update-alternatives).
   7) SMTP — accounts in /var/www/html/.msmtprc. Apache passes the account name to
      msmtp-wrapper (usually the site domain). The default account is used when no
      account is found for the site.
   8) Add-ons — Sphinx, file conversion server, Netdata, PostgreSQL,
      restore.php (place on demand / remove).

   RESTORE SCRIPT restore.php
   restore.php must not stay in a site directory permanently: it deploys a
   backup archive. The project does not ship the file and does not copy it
   on site creation. Workflow: 8 → 5 → 1 (place) → restore the portal →
   8 → 5 → 2 (remove).
   9) BitrixVM emulation — the BITRIX_VA_VER variable in /etc/apache2/envvars
      (required by some Marketplace solutions).

   SERVER
   A) Package update — apt update && apt upgrade.
   R) Reboot. P) Shut down. U) Menu update.

   INTERFACE LANGUAGE
   The language follows the system locale: a Russian locale (ru_RU.UTF-8) gives the
   Russian interface, any other locale gives English. To force it:
     BS_MENU_LANG=ru /root/menu.sh
     BS_MENU_LANG=en /root/menu.sh
   or the BS_MENU_LANG parameter in config.sh (auto | ru | en).

   MENU HEADER
   The "Server status" panel shows load average, CPU usage, memory, disk and
   uptime. Values are coloured by threshold: below 70% — green, 70–89% — yellow,
   from 90% — red.

   The "Installed" panel shows what is already deployed on the server: sites
   (full/link type, default mark), Let's Encrypt certificate expiry, push&pull
   version and state, and installed add-ons (Sphinx, Netdata, RabbitMQ).
   Certificates are highlighted by days left: less than 14 — red, less than 30 —
   yellow.

   Settings in /root/vm_menu/bash_scripts/config.sh:
     BS_MENU_LANG           — interface language: auto (by locale), ru, en;
     BS_STATUS_PANEL        — enable/disable the status panel (true/false);
     BS_STATUS_PANEL_SITES  — enable/disable the "Installed" panel;
     BS_STATUS_MAX_SITES    — how many sites to list ("and N more" for the rest);
     BS_STATUS_PANEL_WIDTH  — panel width in characters;
     BS_CPU_SAMPLE_MS       — CPU sampling window in milliseconds (0 — no sampling);
     BS_USE_COLOR           — enable/disable colours (also NO_COLOR=1);
     BS_SHOW_IP_CURRENT_SERVER_IN_MENU — show interfaces and IPs.

HELP
}

# Инициализация словаря. Вызывается один раз при старте меню.
function i18n_init() {
    BS_MENU_LANG_CURRENT="$(detect_menu_lang)"
    case "$BS_MENU_LANG_CURRENT" in
        ru) MSG=()
            for _k in "${!MSG_RU[@]}"; do MSG["$_k"]="${MSG_RU[$_k]}"; done ;;
        *)  BS_MENU_LANG_CURRENT="en"
            MSG=()
            for _k in "${!MSG_EN[@]}"; do MSG["$_k"]="${MSG_EN[$_k]}"; done ;;
    esac
    unset _k
}

# Перевод по ключу: t ключ [параметры для printf]
function t() {
    local key="$1"; shift
    local msg="${MSG[$key]:-$key}"
    if (( $# > 0 )); then
        # shellcheck disable=SC2059
        printf "$msg" "$@"
    else
        printf '%s' "$msg"
    fi
}
