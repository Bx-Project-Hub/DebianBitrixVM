Role Name
=========

Установка и удаление PostgreSQL для портала Bitrix на Debian 12 / Debian 13.

Requirements
------------

* Debian 12 (bookworm) или Debian 13 (trixie);
* PHP из репозитория deb.sury.org (пакет `php<версия>-pgsql`);
* запуск от root (плейбук использует `become`).

Role Variables
--------------

| Переменная | По умолчанию | Назначение |
|------------|--------------|------------|
| `postgres_action` | — | `INSTALL` или `DELETE` (обязательна) |
| `postgres_preset` | `auto` | пресет конфигурации: `auto` (по RAM), `2g`, `4g`, `8g`, `16g`, `32g`, `64g` |
| `postgres_database` | `bitrix` | имя базы для портала |
| `postgres_user` | `bitrix` | пользователь базы |
| `postgres_packages` | `postgresql`, `postgresql-contrib` | пакеты |
| `php_version` | определяется | версия PHP для расширения `pgsql` |
| `menu_lang` | `ru` | язык итоговых сообщений (`ru` / `en`) |

Пресеты (`vars/main.yml`) подобраны под нагрузку портала: `shared_buffers` ≈ 25% RAM,
`effective_cache_size` ≈ 75% RAM, `work_mem` ограничен так, чтобы `max_connections`
соединений не могли занять всю память. Выбор по `MemTotal`: `<3`, `3–6`, `6–12`,
`12–24`, `24–48`, `≥48` ГБ.

Dependencies
------------

Нет внешних коллекций: используются только модули `ansible.builtin`.

Что делает роль
---------------

Установка (`INSTALL`):

1. Ставит пакеты PostgreSQL и `php<версия>-pgsql`, включает расширение `pgsql`;
2. записывает `/etc/postgresql/<версия>/main/conf.d/99-bitrix.conf` (пресет + общие параметры);
3. переключает `pg_hba.conf` на парольную аутентификацию (`peer`/`scram-sha-256` → `password`);
4. задаёт пароль суперпользователя `postgres` (сохраняется в `/root/.pgpass`, 0600);
5. создаёт базу `bitrix` с `LC_CTYPE='C.UTF-8' TEMPLATE template0`, пользователя `bitrix`,
   выдаёт права и `CREATE` в схеме `public`, ставит расширение `pgcrypto`;
6. проверяет вход по паролю и наличие `pgcrypto`, печатает параметры подключения.

Удаление (`DELETE`) — обратный порядок: остановка сервиса, удаление пакетов
`postgresql*`, данных `/var/lib/postgresql`, конфигурации `/etc/postgresql`, логов,
`/root/.pgpass` и пакетов `php*-pgsql`.

Пример запуска
--------------

```bash
ansible-playbook -i localhost, -c local install_or_delete_postgresql.yaml \
  -e postgres_action=INSTALL -e postgres_preset=8g
```

Справка по настройке: «Конфигурация PostgreSQL» в курсе «Настройка окружения для
Debian 13» на dev.1c-bitrix.ru.
