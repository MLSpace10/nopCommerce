# Phase 4 — итоговый отчёт

Дата актуализации: 20 августа 2026 года.

## 1. Статус фазы

Phase 4 завершена и подтверждена успешными локальными проверками и чистым интеграционным запуском на Linux GitHub runner.

Основной функциональный checkpoint Phase 4:

- commit: `59ef005fc3bc09af504293a3dff02e2b1228dfff`;
- сообщение: `Phase 4 — pilot task baselines`;
- состав: 42 файла — 12 изменённых и 30 новых;
- объём: 1093 добавленные строки и 18 удалённых строк.

После функционального checkpoint в `develop` были добавлены совместимые исправления тестов и инфраструктуры CI. Текущее подтверждённое состояние ветки:

- ветка: `develop`;
- HEAD: `a6839e10ae236e7d50026c672b0fb63045e2f247`;
- `develop` синхронизирована с `origin/develop`;
- рабочее дерево чистое;
- force push и pull request не использовались;
- Phase 5 не начата.

## 2. Что реализовано

Phase 4 добавляет три ученические pilot baseline-задачи.

### TRN-001 — контролируемые ошибки чтения базы данных

Подготовлены:

- профили временной и постоянной ошибки чтения базы данных;
- детерминированный SQL-сценарий с операциями `apply`, `verify` и `reset`;
- ученический ticket;
- сценарий воспроизведения;
- видимая приёмочная проверка;
- требования к доказательствам выполнения.

Baseline стабильно воспроизводит HTTP 500 при управляемой временной ошибке чтения.

### TRN-003 — отсутствующий endpoint сведений о товаре

Подготовлены:

- детерминированные данные товара из нескольких источников;
- contract-first ticket на новую возможность;
- воспроизведение отсутствующего маршрута;
- HTTP-, nullable- и contract-проверки;
- SQL-проверки исходного состояния;
- требования к доказательствам выполнения.

Baseline подтверждает, что существующий список товаров отвечает HTTP 200, а отсутствующий details-маршрут — HTTP 404. SQL-проверка подтверждает товар `1`, пустой GTIN и одну связь с категорией.

### TRN-012 — идемпотентность создания заказа

Подготовлены:

- управляемый профиль потерянного ответа;
- сохраняемый SQL-сценарий;
- детерминированная очистка и восстановление остатков;
- последовательное, параллельное и timeout-воспроизведение;
- HTTP- и SQL-проверки конкуренции и конфликта payload;
- ученический ticket, visible tests и требования к доказательствам.

Baseline подтверждает исходный дефект: повторные запросы в последовательном, параллельном и lost-response сценариях приводят к двум сохранённым заказам.

## 3. Основные добавленные компоненты

В ученический Git tree вошли:

- fault hooks и focused tests Training API для pilot-задач;
- `TrainingDatabaseExceptions.cs`;
- SQL-сценарии `training/db/scenarios/TRN-001`, `TRN-003` и `TRN-012`;
- три student task package в `training/tasks`;
- общий helper `_task-common.ps1`;
- общий runner `verify-pilot-baselines.ps1`;
- Phase 4 step в workflow `training.yml`;
- расширения OpenAPI и обновлённый generated bundle;
- обновления `verify-api.ps1`, README и каталога задач;
- отчёт Phase 4.

Mentor-only материалы не добавлялись в ученический Git tree.

## 4. Checkpoint-ветки

Созданы и опубликованы в ученическом fork следующие ветки:

| Ветка | SHA |
|---|---|
| `task/TRN-001-baseline` | `59ef005fc3bc09af504293a3dff02e2b1228dfff` |
| `task/TRN-003-baseline` | `59ef005fc3bc09af504293a3dff02e2b1228dfff` |
| `task/TRN-012-baseline` | `59ef005fc3bc09af504293a3dff02e2b1228dfff` |

Локальные ветки и соответствующие ветки в `origin` указывают на один и тот же функциональный checkpoint. Они намеренно не перемещались после исправлений общей CI-инфраструктуры.

## 5. Последующее усиление CI и bootstrap

После фиксации pilot baselines были обнаружены и устранены проблемы, которые мешали надёжной проверке чистого окружения.

| Commit | Назначение |
|---|---|
| `ca3fac9ace46482836c45c022282a6da559075f1` | Устранена зависимость теста manifest validator от CRLF/LF. Production-логика валидатора не изменялась. |
| `0ed3f03a2434ba9d061ed9e5c098233a15dc0052` | Добавлено ограниченное ожидание готовности plugin registry во время bootstrap. |
| `1a9496ce573135046aef196d6b09e70fcf670846` | Добавлена безопасная диагностика контейнеров при падении bootstrap. |
| `41c30c6f67588c3487e8cb988a1ff12401ee0a0b` | Исправлено ложное определение успешной установки nopCommerce. `restart-form` больше не считается признаком успеха; проверяется успешный restart-блок, а ошибки установки извлекаются и редактируются безопасно. |
| `a6839e10ae236e7d50026c672b0fb63045e2f247` | Весь `/app/App_Data`, включая `appsettings.json`, переведён на Docker named volume `app-data`; удалён несовместимый с Linux bind mount отдельного файла. |

Последнее исправление сохраняет две требуемые модели работы:

- обычный `start` сохраняет установленное состояние в named volume;
- `reset` удаляет volumes и создаёт полностью чистое окружение.

## 6. Проверки

### Локальные и статические проверки

Успешно выполнены:

- PowerShell parser для изменённых скриптов;
- `docker compose config --quiet`;
- статические проверки хранения `App_Data`;
- сценарии успешного и ошибочного HTML-ответа initializer;
- проверка task framework и разделения student/mentor материалов;
- focused .NET tests: 21 passed, 0 failed;
- полный build `NopCommerce.sln`: PASS, 0 errors;
- `git diff --check`: PASS.

Локальный Docker reset/bootstrap не выполнялся, потому что Docker Desktop Linux engine был недоступен. Вместо него выполнена полная интеграционная проверка на чистом Linux GitHub runner.

### GitHub Actions

Финальные обязательные запуски:

- `.NET #6`: **Success**;
- `Commerce Engineering Lab #5`: **Success**.

В успешном `Commerce Engineering Lab #5` подтверждены:

- сборка и запуск Docker-окружения;
- здоровое состояние приложения, SQL Server и Redis;
- HTTP-, SQL-, Redis-, API- и OpenAPI-проверки;
- установка и доступность Training API;
- три последовательных воспроизведения каждой pilot baseline-задачи;
- ожидаемое падение каждого visible test на заявленной границе baseline-дефекта;
- очистка данных после pilot-сценариев;
- clean reset из пустой training database;
- корректное повторное создание `App_Data` в named volume.

Диагностический failure-step в успешном запуске не выполнялся, что соответствует его условию `failure()`.

## 7. Разделение материалов и безопасность

Проверка student Git tree не обнаружила:

- `mentor-notes.md`;
- каталогов `hints`, `hidden-tests` и `reference-source`;
- `solution.patch`;
- `review-checklist.md`.

Mentor notes, hint levels, hidden tests, reference sources, review checklists и solution patches находятся вне ученического репозитория.

Проверка Git-visible текстовых файлов не обнаружила поддерживаемых сигнатур приватных ключей, AWS access keys и GitHub tokens. Игнорируемый локальный `training/.env` в Git tree не входит. Диагностический workflow маскирует известные пароли и API key до вывода журналов и не печатает содержимое конфигурационных файлов.

## 8. Обнаруженные ограничения

- Полный набор upstream-тестов содержит нестабильные проверки, не относящиеся к Phase 4: наблюдались падения `CanExportOrdersXlsx`, внешнего VAT lookup и `TestGetNopLatestVersion`. Повторный GitHub run завершился успешно без изменений соответствующей production-логики.
- NuGet vulnerability audit мог выдавать `NU1900`, когда индекс уязвимостей nuget.org был недоступен. Restore, build и focused tests при этом проходили.
- GitHub Actions выводит предупреждения о переходе используемых actions с Node.js 20 на Node.js 24. Они не заблокировали финальные workflow.
- Mentor-репозиторий защищён локальными правами файловой системы. Для командного или организационного использования всё ещё нужен отдельный access-controlled mentor remote и изолированная CI secret boundary.
- Checkpoint-ветки зафиксированы на функциональном commit `59ef005f...` и не содержат последующие общие исправления CI/bootstrap из `develop`. Это сохранённое намеренное состояние, а не рассинхронизация.

## 9. Итог

Готово:

- три pilot baseline-задачи и их student packages;
- детерминированные SQL-сценарии;
- fault profiles и Training API contracts;
- visible acceptance tests;
- общий pilot runner;
- OpenAPI и CI-интеграция;
- checkpoint-ветки в ученическом fork;
- переносимое хранение `App_Data` и надёжная диагностика bootstrap.

Проверено:

- сборка, focused tests и Git hygiene;
- разделение student/mentor материалов и отсутствие поддерживаемых сигнатур секретов;
- Docker, HTTP, SQL Server, Redis, API и OpenAPI;
- воспроизводимость всех трёх baseline-дефектов;
- clean reset на чистом Linux GitHub runner.

Оставшиеся ограничения перечислены в разделе 8 и не блокируют завершение Phase 4.

**Phase 4 завершена. Phase 5 не начата.**
