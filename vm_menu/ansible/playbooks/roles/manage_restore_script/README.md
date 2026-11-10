Role Name
=========

Размещение и удаление `restore.php` для портала Bitrix — **только по запросу**.

Зачем отдельная роль
--------------------

`restore.php` принимает архив резервной копии и разворачивает его на сервере.
Постоянно держать такой файл в каталоге сайта (и тем более в проекте) нельзя:
пока он доступен, любой, кто до него дотянется, может попытаться залить свой
архив. Поэтому файл:

* не хранится в `vendor/` проекта;
* не копируется при создании сайта (`create_site` кладёт только `bitrixsetup.php`);
* размещается администратором из меню на время восстановления;
* удаляется сразу после восстановления.

Requirements
------------

Debian 12 / 13, запуск от root (используется `become`), доступ к
`https://www.1c-bitrix.ru` на момент размещения.

Role Variables
--------------

| Переменная | По умолчанию | Назначение |
|------------|--------------|------------|
| `restore_script_action` | — | `PLACE` или `REMOVE` (обязательна) |
| `site` | `""` | домен (имя каталога сайта) |
| `path_sites` | `/var/www/html` | каталог сайтов |
| `restore_path` | `{{ path_sites }}/{{ site }}` | каталог сайта |
| `restore_script_url` | официальный URL `restore.php` | источник файла |
| `user_server_sites` / `group_user_server_sites` | `www-data` | владелец файла (права `0640`) |
| `menu_lang` | `ru` | язык сообщений (`ru` / `en`) |

Пример
------

```bash
ansible-playbook -i localhost, -c local manage_restore_script.yaml \
  -e restore_script_action=PLACE -e site=example.ru
```

После восстановления:

```bash
ansible-playbook -i localhost, -c local manage_restore_script.yaml \
  -e restore_script_action=REMOVE -e site=example.ru
```

В меню это пункт `8` → `5` («Скрипт восстановления restore.php»).
