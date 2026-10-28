# Live-ops: как вести живую игру (cadence, релизы, события, эксперименты, аналитика, спад)

**Зачем этот файл.** Рабочий справочник Builder-роли и Advisor-роли по жизни игры после запуска: как часто выпускать обновления (официальные диапазоны и то, что делают хиты), как устроить еженедельный дроп по дням, какой тулчейн релиза использовать (config-флаги, перезапуск только устаревших серверов, staging в live, откат, алерты по версии), как проводить события и разбирать их постфактум, как работать с Configs и Experiments, что мерить и когда убивать или масштабировать игру, как сообщать об изменениях (включая нерфы платного), как не превращать уведомления в dark pattern, как вести себя на стадиях спада и когда делать сиквел вместо обновления.

**Актуально на: октябрь 2026.** Перепроверять (самое волатильное):
- API Configs (BETA), Experiments (EXPERIMENTAL), server-management restarts (BETA), Analytics Query API (BETA): лимиты и эндпоинты могут меняться;
- лимит числа конфигов (1 000 в доках Configs против 100 ключей на repository в Open Cloud, раздел 11);
- порог Kids/Select (250 highly engaged plays за 60 дней; было 500 до 20 авг 2026) и цена expedited review (50 000 R$, менялась в 2026);
- вес сигналов Recommended For You (RFY, окно 28 дней с июня 2026) и age-aware ranking;
- правило о reward-driven media feeds (с 25 авг 2026);
- Today's Picks / Standout Games (формы номинации);
- числа спада и пики хитов (трекеры, окт 2026), расписания обновлений конкретных игр.

Пометки: **(док)** = официальная документация Roblox (creator-docs, октябрь 2026); **(сообщество)** = DevForum, блоги, вики, трекеры; **(синтез)** = мой вывод/шаблон из фактов, не опубликованная практика студии. Числа без пометки взяты из официальных доков или первичных источников.

## Оглавление

1. [Главные правила (кратко)](#1-главные-правила-кратко)
2. [Cadence обновлений: официальные диапазоны и практика хитов](#2-cadence-обновлений-официальные-диапазоны-и-практика-хитов)
3. [Шаблон еженедельного дропа по дням](#3-шаблон-еженедельного-дропа-по-дням)
4. [Тулчейн релиза](#4-тулчейн-релиза)
5. [События: почему пики 10M+ были событиями](#5-события-почему-пики-10m-были-событиями)
6. [Постмортем события](#6-постмортем-события)
7. [Конфиги и эксперименты](#7-конфиги-и-эксперименты)
8. [Аналитика: что мерить и как принимать решения (kill/scale gate)](#8-аналитика-что-мерить-и-как-принимать-решения)
9. [Коммуникация: патчноуты, нерфы, group wall, уведомления](#9-коммуникация-патчноуты-нерфы-group-wall-уведомления)
10. [Today's Picks, Standout Games, event featuring](#10-todays-picks-standout-games-event-featuring)
11. [Стадии спада и действия](#11-стадии-спада-и-действия)
12. [Сиквел или обновление](#12-сиквел-или-обновление)
13. [Команда и процесс](#13-команда-и-процесс)
14. [Чек-листы](#14-чек-листы)
15. [Конфликты источников и открытые вопросы](#15-конфликты-источников-и-открытые-вопросы)

---

## 1. Главные правила (кратко)

1. **Cadence под вашу команду.** Соло и команда до 5 человек: контент раз в 2 недели + сезон/ивент на месяц + крупное обновление раз в 2-3 месяца. Хиты с 10+ людьми: недельный дроп в фиксированный день и час, с 2+ ротируемыми "event pods". Один дроп: меньше 3 недель усилий.
2. **Релиз без перезапуска всех игроков.** Выкладывайте код заранее, контент прячьте за config-флагом, в нужный час переключайте флаг. Перезапускайте только серверы со старой версией, с bleed-off 5-10 минут и обратным отсчётом в игре.
3. **Перед пушем ставьте алерты** (crash rate > 5% за 5 минут, фильтр по place version). После релиза 1-3 дня следите за place-version метриками; при регрессии сначала откат config-флага, потом (если сломан код) restore, publish, restart.
4. **События = главный рычаг пика.** Все пики 10M+ с Q2 2025 пришлись на запланированные server-wide события. Но пик события в 5-15 раз выше дневного уровня: серверы и монетизацию планируйте под дневной уровень.
5. **Решения по D1/сессии/конверсии принимайте по своему dashboard-band (P50-P90 похожих игр),** а не по вендорским таблицам по жанрам. Не сравнивайте дневную конверсию с цифрой "5%" (раздел 8.4).
6. **Эксперименты:** 14-60 дней, не меньше ~1 000 DAU, не больше 1 baseline + 2 treatment, не решайте по ранним данным; early-harm флаги: playtime -10%, ARPU -20%, payer conversion -20%.
7. **Нерф или удаление проданной функциональности без предупреждения = fraud** по Community Standards. Объявляйте заранее, компенсируйте или grandfather покупателей.
8. **Каждое крупное обновление: подайте номинацию в Today's Picks и Standout Games,** для 7-30-дневных событий включите featuring за 7+ дней. Это бесплатные редакторские каналы.
9. **Хиты спадают быстро.** Медиана: -50% за 4-8 недель от пика, -90% за 8-14 недель. Из 14 вирусных игр только 3 держат top-10 базу после 6 месяцев (~1-10% от пика). Держите 4-6 недель контента про запас к запуску.
10. **Сиквел работает, только если исходная экономика мертва или раздута И сиквел добавляет систему.** Иначе делайте обновление.

---

## 2. Cadence обновлений: официальные диапазоны и практика хитов

### 2.1 Официальные заявления Roblox (док)

| Страница | Что сказано |
|---|---|
| Strategies | "If it's sustainable for your team, aim for minor content updates every **1-2 weeks** and major system updates every **2-3 months**." Roadmap на 6-12 месяцев |
| Retention (D30) | "A common frequency is to release smaller updates on the existing mechanics every **2-4 weeks**, and bigger updates of new features every **2-3 months**." |
| Content updates | "many games release content cadence updates every **two weeks to one month**"; рекомендовано "**fewer than three weeks' effort**" на дроп |
| LiveOps essentials | Content cadence "varies... ranging from **weekly to monthly**"; крупные обновления "may necessitate many months of development"; QoL "as needed" |
| Season pass design | Сезон: "**one month** is a good starting point"; между сезонами "at least a **one-week rest period**"; в последнюю неделю double XP как catch-up; еженедельные миссии |

**Разрешение кажущегося противоречия (1-2 недели против 2-4):** страницы описывают диапазон по мощности команды. Strategies даёт идеал (1-2 недели), Content updates и Retention описывают типичное (2 недели - 1 месяц), все согласны по крупным (2-3 месяца). Хиты идут еженедельно, но только с выделенными event-командами.

### 2.2 Четыре типа обновлений (LiveOps essentials)

1. **Content cadence:** только арт на готовых системах (питомцы, транспорт, оружие, карты, квесты, ограниченные события, сезонный контент, UGC-конкурсы). Контент "should not be immediately consumed by the majority of players": закрывайте прогрессом, ограничением по времени или season pass.
2. **Major updates:** арт + дизайн + программирование, новые системы: social (гильдии, trading, parties), competitive (PvP, лидерборды, турниры), collections и achievements (питомцы, season pass), live events (переделка карты, новые роли). Это меню для слота "раз в 2-3 месяца".
3. **QoL.**
4. **Bug fixes.**

### 2.3 Что делают хиты (с датами)

| Игра/студия | Cadence | Источник |
|---|---|---|
| Grow a Garden (Splitting Point) | Еженедельно; в июле 2025 создали **две команды, посвящённые событиям**; релизы по субботам 7:00 PT (нояб 2025); события ~2 недели | Wikipedia; PCGamesN |
| 99 Nights in the Forest | Еженедельно; перед релизом 45-минутная "Update Party" на выходных (sandbox-плейтест) | DevForum Spotlight, 31 окт 2025 |
| Adopt Me! (Uplift) | Еженедельно; слоты Пн 11:05 ET и Пт 11:05/11:15 ET (фан-трекер, окт 2026). Ранее недельный график "led to crunch": наняли producers, развели треки, построили инструменты | AllThings.How; VICE 2021 |
| Steal a Brainrot | Обычно по пятницам; Admin Abuse/Admin War привязаны к обновлениям | Sportskeeda |
| Plants vs Brainrots | Admin abuse по субботам ~11:00 UTC за ~1 час до обновления (раздел 5) | Destructoid, нояб 2025 |
| Rivals | Крупные обновления ~каждые 5 недель (19 за 21 месяц), косметика | RoWatcher (не подтверждено) |
| Twin Atlas | Контрактные community-разработчики добавляют контент "every month"; ежемесячные guild-сезоны | Naavik, май 2025 |
| Sailor Piece | Примерно еженедельно по средам, рост до 745K за ~5 месяцев | сводка топ-игр |

### 2.4 Правило для скилла по составу и ритму

| Команда | Ритм |
|---|---|
| Соло / до 5 человек | Ежедневные квесты или login rewards; контент раз в 2 недели (до 3 недель усилий); сезон/пасс на 1 месяц + 1 неделя паузы; крупная система раз в 2-3 месяца |
| 10+ человек, хит | То же + **фиксированный день и час** (пт или сб) еженедельного дропа + слот события; 2+ ротируемых event pod, чтобы ни одна команда не выпускала каждую неделю |
| Любая | После каждого обновления сверка D1/D7, времени сессии, конверсии, ARPPU и новых игроков с benchmark-band |

**Вывод:** расписание "каждую неделю" выживает только при разделении команды на pods или при общем контент-инструментарии (Uplift). Выгорание официально называется риском: LiveOps best practices содержат "prioritize mental health" и "be realistic about... the frequency with which they can release updates".

### 2.5 Календарь горизонтов (синтез)

| Горизонт | Малая команда (1-5) | Хит-команда (10+) |
|---|---|---|
| Ежедневно | daily quests / login rewards | то же + дневной ограниченный сток |
| Еженедельно | QoL, баг-фиксы по мере нужды, недельные миссии в пассе | **дроп в фиксированный день** + слот admin/live event |
| 2-4 недели | content cadence drop (<= 3 недель усилий) | - |
| Ежемесячно | сезон/пасс (1 месяц + 1 неделя паузы), guild/leaderboard сезон | то же |
| 2-3 месяца | major system update | то же; ~5 недель для соревновательных игр (Rivals) |
| 6-12 месяцев | roadmap (Strategies) | roadmap + brand integrations |

Источники: create.roblox.com/docs/get-started/strategies; /docs/production/analytics/retention; /docs/production/game-design/content-updates, /liveops-essentials, /season-pass-design; en.wikipedia.org/wiki/Grow_a_Garden; vice.com (Uplift, 13 мая 2021); pcgamesn.com/grow-a-garden/update-schedule; naavik.co/podcast/launching-original-ip-on-roblox/.

---

## 3. Шаблон еженедельного дропа по дням

**Это синтез** из официальных механик (раздел 4) и ритма хитов; Roblox не публикует длину спринта, а ни одна студия не раскрыла внутренний график (content lock / QA / release day: STILL OPEN).

### 3.1 Субботний дроп (хит-команда или еженедельный режим)

| День | Шаг | Инструмент |
|---|---|---|
| Сб-7 и раньше | Создать страницу события; для 7-30-дневного события подать на Off-Platform Featuring (минимум за 7 дней); подготовить номинации Today's Picks и Standout Games | Events & Updates |
| Пн-Ср | Сборка в отдельном dev-experience или защищённом subplace; скриптеры работают в Drafts и делают Commit | Drafts; "Secure within universe only" |
| **Ср** | **Content lock.** Публикация билда с новым контентом **за config-флагом**, обязательные version notes. Перезапуск только устаревших серверов с bleed-off 5-10 минут | Version History; Restart; Configs |
| Чт | QA на live-серверах через `SetTestingValue` (влияет на один сервер); Team Test; early testers/Playtesters | ConfigService testing |
| Пт | Настроить алерты: crash rate > 5% за 5 минут (critical), падение CCU неделя к неделе; фильтр на новую place version | Alerts |
| **Сб, фиксированный час** | Переключить config ("Publish over 15 min" для постепенной раскатки). Отправить update announcement (60 символов). Запустить внутриигровое событие / admin-момент (за ~1 час до патча, см. раздел 5) | Configs; Update announcements |
| Сб+1 ... +3 | Смотреть ошибки и производительность по place version. Регрессия: откатить config сразу; код сломан: restore, publish, restart | Performance; Version History |
| Сб+7 | Постмортем события: сравнение с неделей до и неделей после (раздел 6) | LiveOps planning |

**Время суток (сообщество, не официально):** сторонняя кривая RoWatcher (июнь 2026) рекомендует субботу 14:00-16:00 UTC перед ~19:00 UTC пиком; Grow a Garden выходит в субботу 7:00 PT (это ~14:00 UTC летом); Plants vs Brainrots имеет admin abuse в 11:00 UTC. Для своей игры выберите час по hourly-графику своей аудитории.

### 3.2 Режим "каждые 2 недели" (малая команда, синтез)

Два pods, каждый на 2-недельном цикле, выпускают в чередующиеся недели. Верхняя граница scope pod'а задана официальным "under 3 weeks of effort". Чередование pods это рекомендация скилла, а не подтверждённая практика студии.

| Неделя | Pod A | Pod B |
|---|---|---|
| 1 | Сборка дропа N, content lock в среду | Сборка дропа N+1 |
| 2 | Релиз N (флаг), мониторинг | Content lock N+1 |
| 3 | Сборка N+2 | Релиз N+1 |

Для одного человека: цикл 2 недели (неделя 1 сборка контента, неделя 2 QA + релиз + постмортем), QoL и баги между дропами.

### 3.3 Опыт 99 Nights

Еженедельные обновления, перед каждым 45-минутная "Update Party" (sandbox-сессия в выходные для плейтеста). Команда из 5 человек, ~3 месяца до запуска. Уроки команды: "Don't scope super high and follow the fun", плейтестить рано и часто, наблюдать за игроками, не знающими, что за ними наблюдают.

Источники: create.roblox.com/docs/projects/update-games; /docs/production/promotion/experience-events; devforum.roblox.com/t/creator-spotlight-the-story-behind-99-nights-in-the-forest/4036940; rowatcher.com (сообщество).

---

## 4. Тулчейн релиза

### 4.1 Публикация и перезапуск (док, Release game updates)

- **Публикация не переносит игроков на новую версию.** Старые серверы живут, пока не опустеют, если их не перезапустить.
- Перезапуск: Creator Hub, Configurations, Server management:
  - **Restart only servers with outdated versions** (рекомендация дока, если у вас нет update workflow, независимого от place version);
  - **задержка перезапуска 1-60 минут** ("server bleed-off").
- При перезапуске Roblox: (1) прекращает matchmaking в старые серверы, (2) ждёт задержку, (3) телепортирует игроков каждого старого сервера **вместе** на один новый сервер.
- `DataModel.ServerRestartScheduled(restartTime, source, attributes)` срабатывает на затронутых серверах. `source` = `CloseReason.DeveloperUpdate` для ваших обновлений и `RobloxMaintenance` для платформенных. Используйте для обратного отсчёта, "сохраните прогресс", телепорта.
- Если меняется формат данных игрока, перезапускайте обязательно; иначе версии могут сосуществовать "for a prolonged period".
- **Официальный паттерн timed drop:** "deploy early, hide content behind a config, and then change the config value to release your new content". Это разделяет code lock и release moment.
- Часы события: `workspace:GetServerTimeNow()` (клиент, монотонное сглаженное серверное время); на сервере `os.time()` или `DateTime.now()`. Док рекомендует для старта события в реальное время.

```lua
-- Обратный отсчёт перед перезапуском (на сервере; показать UI игрокам через remote)
game.ServerRestartScheduled:Connect(function(restartTime, source, attributes)
	-- source == Enum.CloseReason.DeveloperUpdate | RobloxMaintenance
	-- attributes: словарь из Open Cloud advanced restart (до 500 байт)
end)
```

### 4.2 Open Cloud: перезапуск и сообщения

**Простой перезапуск** (STABLE, scope `universe:write`, 30/мин):
```bash
curl -sS -X POST "https://apis.roblox.com/cloud/v2/universes/$U:restartServers" \
  -H "x-api-key: $KEY" -H 'Content-Type: application/json' \
  --data '{"bleedOffServers":true,"bleedOffDurationMinutes":10}'
```
`placeIds[]` необязателен (все places); `closeAllVersions:false` (по умолчанию) = перезапуск только при наличии более новой версии; bleed-off 1-60 минут.

**Расширенный перезапуск** (BETA, 100/мин): `POST /server-management/v1/universes/{u}/restarts` с `{"bleedOffDurationMinutes":1-240, "places":{"<placeId>":{"excludeCurrentVersion":true} | {"versions":[12,13]}}, "attributes":{...<=500 байт...}}`. Возвращает `{id, playersImpacted, instancesImpacted}`. `GET .../restarts:forecast` показывает влияние заранее, `GET .../restarts` статус. `attributes` доходят до `ServerRestartScheduled`.

**Server-wide сообщение** (STABLE, 5 000/мин): `POST /cloud/v2/universes/$U:publishMessage` с `{"topic":"announce","message":"..."}` (подписка через MessagingService).

**Уведомления игрокам** (STABLE, 4 000/сек): `POST /cloud/v2/users/$USER_ID/notifications`; строка сообщения сначала создаётся в Dashboard (API для создания строк нет, ручной шаг).

### 4.3 Configs как переключатель релиза (док)

- До 1 000 активных конфигов (док Configs; см. конфликт с лимитом Open Cloud в разделе 15).
- Изменения сначала **staged**: команда видит их в play-сессиях Studio, игроки нет.
- Публикация: "Publish now" (~15 с - 1 мин) или "Publish over 15 min" (постепенная раскатка).
- История позволяет восстановить прежние значения.
- **"Publish As"** копирует конфиги из **staging/development experience** в live.
- Conditional configs: до 100 условий на игру и 20 на ключ; атрибуты таргета: new vs returning, источник, tenure, payer status, engagement.
- Пример сегментации (Adopt Me!, Roblox Newsroom, авг 2026): не показывать rewarded-ad prompts плательщикам.

### 4.4 Версии, откат, drafts (док)

- **Version notes обязательны при каждой публикации.** Studio может **сгенерировать publish notes** из save notes с прошлой публикации, это готовый черновик патчноутов.
- **Restore не публикует.** Откат live-игры: restore, publish, restart servers.
- Drafts mode (выкл. по умолчанию): скриптеры правят приватно, затем Commit, с Compare и Merge with Server.
- Откат конфига: `POST .../revisions/{id}/restore` даёт новый draftHash и **не публикует**; нужен `/publish`.

### 4.5 Аудитории до релиза и утечки (док)

- **Early testers:** до 10 друзей схожего возраста.
- **Playtesters** ограничивает игру пользователями с Edit/Playtest доступом; **Friends** ограничивает публичную игру друзьями владельца; **Exclude from recommendations** не пускает тестовую игру в RFY.
- **Риск staging-subplace:** клиенты могут телепортироваться в любой place вселенной, поэтому неанонсированный контент в dev/staging subplace может утечь, "Direct Access" off не помогает. Решение: Access Control for Places = **"Secure within universe only"** или держать staging в **отдельном experience**.
- **Для Kids/Select:** новая игра сначала доступна только age-checked 16+ и открывается для Kids/Select после **250 уникальных plays highly engaged age-checked игроков за 60 дней** (было 500 до 20 авг 2026) либо через expedited review (50 000 R$, возвращаемые; сумма менялась в 2026). Ранний D1 читайте с поправкой: аудитория 16+ нерепрезентативна для детской игры.
- Лимит публикации: не более 5 никогда не выпускавшихся игр в день.

### 4.6 Алерты и мониторинг (док)

- **Alerts:** нужно 100+ DAU; до 20 на игру; webhook в Discord/Slack/PagerDuty. Официальный пример: "Client crash rate above 5%" за 5 минут, critical, настраивается **до** пуша обновления. Для minute-granularity нужно не меньше 5 подряд точек. Можно фильтровать по **place version**.
- **Performance dashboard:** разбивка по Place Version для сравнения нового билда со старыми; аннотации "Roblox update" отделяют платформенные регрессии от своих.
- **Error report:** опция "Show version" добавляет place-version аннотации.
- Через Analytics Query API: `ClientCrashRate15m`, `ClientFpsAvg`, `ClientMemoryUsageAvg` (история performance-метрик 28 дней).

### 4.7 Консолидированный release gate (синтез; Roblox не публикует единый чек-лист)

Каждый релиз: (1) CI зелёный; (2) все ассеты `Approved` (asset в `Reviewing` невидим игрокам); (3) контент-аудит: если ответ анкеты maturity изменился, **пересдать questionnaire до публикации**; (4) PolicyService-гейты (paid random items, paid trading); (5) идемпотентный `ProcessReceipt` для каждого developer product; (6) нет хардкода цен; (7) performance smoke на TEST; (8) publish, затем restart устаревших серверов с 5-10 мин bleed-off, затем публикация config; (9) иконку и thumbnails перезаливать только при изменении.

Источники: create.roblox.com/docs/projects/update-games, /projects/version-history, /projects/collaboration, /production/configs, /production/publishing/publish-games-and-places, /production/publishing/kids-and-select, /scripting/security/access-control, /production/analytics/alerts, /production/analytics/performance, /reference/engine/classes/DataModel, /reference/engine/classes/Workspace. → см. builder/project-setup (CI/CD, Open Cloud), builder/studio-config.

---

## 5. События: почему пики 10M+ были событиями

### 5.1 Факты

- До Q2 2025 ни одна игра не превышала ~2M CCU. Пики 10M+ существуют только с Q2 2025 и (по сводке) все были запланированными server-wide событиями.
- Платформенный рекорд 47,4M CCU связан с "Admin Abuse War" (Naavik: август 2025; Beebom связывает с "October surge": дата не решена).

| Игра | Пик | Триггер |
|---|---|---|
| Steal a Brainrot | 25,4M (развитие: до 25,8M у трекеров) | Начало окт 2025, admin events; 12,8M concert spike в янв 2026 |
| Grow a Garden | 22,3M (Naavik приводит 21,3M в июне; последняя сводка: 22,3M 23 авг 2025) | "Admin war" с SaB |
| Steal An Egg | 14,27M, 19 сен 2026 | Кроссовер "Sammy Is Coming" с SaB (одно портфолио) |
| 99 Nights in the Forest | 14,2M, H2 2025 | Точная дата и триггер не подтверждены |
| Murder Mystery 2 | ~2,2M, 25 окт 2026 | Halloween-событие (трекеры) |
| Bee Swarm Simulator | 259K, дек 2025 | Beesmas примерно утраивает CCU при базе 30-64K |

### 5.2 Урок

- **Пик события в 5-15 раз выше дневного уровня** (Steal An Egg 14,27M против ~1,3M; MM2 ~2,2M против ~0,2M). Спайки событий падают на 50% за часы. Планируйте серверы и монетизацию под дневной уровень; маркетинг под пик.
- Admin abuse и кроссоверы работают, потому что дают общее ожидание, причину зайти в фиксированное время и пики CCU, питающие алгоритм (синтез).
- Шаблон Plants vs Brainrots (Destructoid, нояб 2025): admin abuse **каждую субботу ~11:00 UTC, примерно за 1 час до обновления**, длится ~1 час, на всех серверах, включая приватные; редкие лимитированные существа с 1M+ HP, ротация редкой погоды, рестоки редких семян, **server-wide luck boost**. К концу 2025 три admin-abuse события на обновление.
- Fish It!: "Atlantis Boost" позволяет игрокам запускать server-wide баффы.
- Параметры для копирования (синтез): фиксированные день и час; событие ~1 час **перед** патчем, чтобы игроки остались на патч; общий server-wide бафф; редкая лимитированная награда.
- **Портфолио-кроссоверы** (GaG x SaB, SaB x SaE) дали рекордные дневные спайки; для соло-разработчика эквивалент это коллаборации с другими разработчиками.

### 5.3 Риски события

- **Не награждайте пассивное потребление ленты.** С 25 авг 2026 игра не допускается в Kids/Select, если сочетает все три элемента: (1) медиа-лента (короткие видео, изображения, stories); (2) autoplay, continuous replay loop, infinite scroll или autoscroll; (3) награда (в том числе подразумеваемая) за продолжение просмотра. Steal An Egg в этот день был снят на 3 ч 20 мин и вернулся с удалённой AI-видеолентой; за ~4 дня это стало правилом платформы. Rewarded video ads вне правила.
- **Проверяйте экономику событий:** пример из LiveOps planning (турнир по рыбалке выявил неожиданный источник основной валюты).
- **Не ломайте экономику ивентом:** дюпы и необкатанные обновления убили Garden Horizons (200K-1M до ~23K за 2 недели).
- **Бот-накрутка:** не гонитесь за цифрами накрученных конкурентов.

Источники: gamedevreports.substack.com (Newzoo); destructoid.com/plants-vs-brainrots-admin-abuse-schedule; devforum.roblox.com/t/roblox-kids-and-select-new-restrictions-on-reward-driven-media-feeds/4829188; naavik.co/deep-dives/the-state-of-ugc-games-2026/; en.wikipedia.org/wiki/Steal_a_Brainrot. → см. advisor/case-studies, advisor/top-games.

---

## 6. Постмортем события

Официальный метод (LiveOps planning): три шага **Plan, Communicate, Monitor and analyze**.

**Plan.** Выберите целевой KPI; предскажите, какие действия игроков его сдвинут; проверьте влияние наград на экономику.

**Communicate.** Каналы вне игры (соцсети, сообщество) и внутри (login pop-up, UI alert, лобби). Компромисс: ранний анонс позволяет планировать возвращение; поздний ощущается спонтанно, но его можно не заметить. Продумайте "memorable start".

**Monitor and analyze.**
- Данные должны быть **своевременными:** смотрите почасовые данные в тот же день, чтобы событие не раздавало лишние призы.
- Данные должны быть **сопоставимыми:** сравнивайте событие с **неделей до и неделей после**.
- Успех = выше краткосрочное и долгосрочное удержание и выше продажи предметов и валюты **во время и после** события.

**Шаблон постмортема (синтез):**

| Блок | Вопросы |
|---|---|
| Цель | Какой KPI и ожидаемый сдвиг? |
| Факты | CCU/DAU по часам, новые против вернувшихся, D1/D7 когорты события, время сессии, конверсия, ARPPU |
| Сравнение | Неделя до, неделя во время, неделя после (метки: `Visits`, `DailyActiveUsers` по `IsNewUser`, `ForwardD1Retention`, `PayingUsersCVR`) |
| Экономика | Не раздали ли валюту сверх плана? Не обесценили ли платные предметы? |
| Техника | Crash rate и FPS по place version; ошибки |
| Каналы | Откуда трафик (Acquisition): RFY, Today's Picks, ссылки, поиск, события; сколько RSVP |
| Вывод | Повторять? Что изменить? Что перенести в постоянный контент? |

Источник: create.roblox.com/docs/production/game-design/liveops-planning.

---

## 7. Конфиги и эксперименты

### 7.1 Что где

- **Configs:** значения без перезапуска (баланс, флаги релиза, сезонные темы, сегментация).
- **Experiments (A/B):** сравнение вариантов конфига на доле игроков с целевой метрикой.
- Взаимосвязь: релиз-флаг (раздел 4) это тоже конфиг; сезонная UI-тема (Configs), расположение кнопок (Experiments).

### 7.2 Configs: лимиты и вызовы (Open Cloud, BETA)

Путь: `/creator-configs-public-api/v1/configs/universes/{u}/repositories/InExperienceConfig`.
- `PUT /draft:overwrite` или `PATCH /draft` с `{"entries":{...}}` (необязательный `previousDraftHash` для оптимистичной блокировки) возвращает `draftHash`.
- `POST /publish` с `{"draftHash","message","deploymentStrategy":"Immediate"|"GradualRollout"}` (gradual = 15 минут) возвращает `{"configVersion":N}`. **Publish лимит 10/мин.**
- `GET` возвращает значения, `GET /full` метаданные; `GET /revisions?MaxPageSize=10`; `POST /revisions/{id}/restore` не публикует.
- Лимиты: **100 ключей на repository**, ключи до 256 символов, string/JSON значения до 100 000 символов.

### 7.3 Experiments (Open Cloud, EXPERIMENTAL, 10/мин)

```bash
curl -sS -X POST "https://apis.roblox.com/creator-configs-public-api/v1/experimentation/universes/$U/experiments" \
  -H "x-api-key: $KEY" -H 'Content-Type: application/json' --data '{
  "name":"LowerBossHealth","description":"D1 test",
  "experimentConfiguration":{"productType":"EXPERIMENT_PRODUCT_TYPE_IN_GAME_CONFIGS",
    "inGameConfigExperimentConfiguration":{"variants":[
      {"variantMeta":{"label":"Control","isBaseline":true,"weight":50},"configEntry":{"key":"bossHealth"}},
      {"variantMeta":{"label":"Treatment A","isBaseline":false,"weight":50},"configEntry":{"key":"bossHealth","entryValue":300}}]}},
  "exposurePercent":40,"durationSeconds":1209600,
  "universeGoalMetric":"UNIVERSE_EXPERIMENT_METRIC_DAY_1_RETENTION"}'
```
- **Жизненный цикл:** DRAFT (PATCH/DELETE допустимы), затем `:start` или `:schedule` (после этого конфигурация неизменяема), `/stats` через 24+ часа (следите за `isSrmDetected`), `:complete` с `{"variantId":...}` раскатывает победителя (без него откат). Каждый мутирующий вызов возвращает `operation` для polling.
- **Целевые метрики:** `..._AVERAGE_SESSION_TIME`, `..._PLAYTIME_PER_USER`, `..._DAY_1_RETENTION`, `..._DAY_7_RETENTION`, `..._PAYER_CONVERSION_RATE`, `..._AVERAGE_REVENUE_PER_USER`, `..._AVERAGE_REVENUE_PER_PAYING_USER`.

### 7.4 Правила и пороги экспериментов (док)

| Параметр | Значение |
|---|---|
| Длительность | **14-60 дней** |
| Варианты | 1 baseline + не больше 2 treatment (in-experience) |
| Одновременно | один matchmaking-эксперимент на universe; один активный эксперимент на ключ конфига |
| Минимальный DAU | игры с **< 1 000 DAU** "might struggle to get useful data"; если минимально обнаружимый эффект (MDE) выше ~100%, не запускайте |
| Early-harm флаги первые 24 ч | playtime **-10%**, ARPU **-20%**, payer conversion **-20%**; вред оценивается только при **>= 10 000** игроков в эксперименте (варианты + контроль) |
| Решения | не решайте по ранним данным; ждите дневные результаты со статистической значимостью |
| Конверсия в экспериментах | "Payer conversion rate" = **кумулятивная за срок** эксперимента (не дневная) |
| Price optimization | нужно **>= 60 000 транзакций** за последние 30 дней |

### 7.5 Что тестировать (синтез)

Хорошие кандидаты: FTUE-шаги, цены и бандлы, расположение кнопок, сложность босса/экономика, matchmaking-сигналы (Adopt Me! тестировал размер сервера и сигналы). Плохие: что трогает платные предметы без предупреждения (раздел 9.2).

Источники: create.roblox.com/docs/production/experiments, /cloud/guides/configs, /cloud/guides/experiments, /production/monetization/price-optimization; about.roblox.com/newsroom/2026/08/optimize-testing-live-updates-roblox-analytics-experimentation-platform.

---

## 8. Аналитика: что мерить и как принимать решения

### 8.1 Что отслеживать

| Группа | Метрики (идентификаторы Analytics Query API, регистр важен) |
|---|---|
| Удержание | `ForwardD1Retention`, `ForwardD7Retention`, `ForwardD30Retention`, `DailyCohortRetention`, `DauMauStickiness` |
| Вовлечение | `DailyActiveUsers`, `AveragePlayTimeMinutesPerDAU`, `AverageSessionLengthMinutes`, `Visits` |
| Монетизация | `DailyRevenue`, `AverageRevenuePerUser` (ARPDAU), `AverageRevenuePerPayingUser`, `PayingUsers`, `PayingUsersCVR` |
| Сигналы RFY | `RFYPlayThroughRate`, `RFYDuration0To60`, `RFYDuration61To180`, `RFYD1Playtime`, `RFYD2To7PlayDays`, `RFYD8To28PlayDays`, `RFYD1CoplayDays`, `RFYD1QualifiedPlaySessions`, `RFYD1SpendDay`, `RFYD1RobuxSpend` (+ D2To7/D8To28 варианты) |
| Производительность | `ClientCrashRate15m`, `ClientFpsAvg`, `ClientMemoryUsageAvg`, `ServerFrameRateAvg`, `OomUnexpectedExits` |
| Воронки | `FunnelStepCompletionRate`, `FunnelStepChurnRate`, `FunnelUserChurnRate` |
| Экономика | `EconomyTransactionAmount`, `EconomyTransactionCount`, `EconomyAverageWalletBalance` |
| Кастомные события | `CustomEventAvgPerUserValue` |
| Thumbnails | `ThumbnailImpressions`, `ThumbnailQualifiedPTR` |
| Безопасность | `TotalAbuseReports` |
| Хранилища | `DataStoreRequestsByStatus` (мониторинг throttling) |

### 8.2 Кастомные события и воронки (в коде)

`AnalyticsService`: `LogEconomyEvent` (flowType Source/Sink, currency, amount, endingBalance, transactionType, itemSku), `LogFunnelStepEvent` (funnelSessionId), `LogOnboardingFunnelStepEvent(player, step, name)` (только сервер, шаг 1 логируйте в `PlayerAdded`), `LogProgressionEvent`/Start/Complete/Fail, `LogCustomEvent`, `GetPlayerSegmentsAsync`. Устаревшие `Fire*` не используйте. Логируйте событие после успеха операции.

Пример из официального проекта Plant: воронка показала **70% отвала между шагом 1 ("In Farm") и шагом 2 ("Plant Seed")**; исправлено контекстными подсказками.

### 8.3 Analytics Query API (BETA, scope `universe.analytics:read`)

```bash
curl -sS 'https://apis.roblox.com/analytics-query-api/v1/universes/'"$U"'/metrics' \
  -H "x-api-key: $KEY" -H 'Content-Type: application/json' \
  --data '{"metric":"ForwardD1Retention","granularity":"OneDay",
           "startTime":"2026-10-12T00:00:00Z","endTime":"2026-10-26T00:00:00Z",
           "breakdown":["Platform"]}'
```
- Обязательны `metric`, `granularity`, `startTime` (включительно); `endTime` **исключительно**. `breakdown[]`, `filter[]`, `limit` необязательны.
- Granularity: `OneMinute`/`HalfHour` только performance; `OneHour` performance + часть монетизации; `OneDay` все метрики; `OneWeek` считает уникальных за неделю, а не сумму дней.
- Ответ `200` с `values[]`; `202 {done:false, path}` значит poll `GET .../{path}`. Статус точки: `Valid`, `Projected`, `NotStatisticallySignificant`.
- История: стандартные метрики **4 года**, performance **28 дней**.
- Ошибки: `429` код 3000 = превышен бюджет точек (сужайте диапазон, `limit`); `503` retry.
- Бенчмарки: `POST https://apis.roblox.com/analytics-benchmark/v1/universes/{u}/benchmarks` с `{metric, startTime, endTime (включительно), benchmarkType?: GENRE|SIMILARITY|TOP_EXPERIENCES, percentiles?}`. По умолчанию percentiles **50 и 90** (10 и 50 там, где ниже лучше).

**Недельный отчёт (синтез):** каждый понедельник запрашивать `DailyActiveUsers` (breakdown `IsNewUser`), `ForwardD1Retention`, `ForwardD7Retention`, `AveragePlayTimeMinutesPerDAU`, `PayingUsersCVR`, `AverageRevenuePerPayingUser`, `RFYPlayThroughRate`, `ClientCrashRate15m`, `FunnelStepChurnRate`; к каждой метрике приложить P50/P90 бенчмарк. Помечать любую метрику ниже P50 и любое изменение неделя к неделе хуже -10% (порог мой). Отчёт становится входом для выбора следующего config/experiment. Также ежедневно смотреть **новые показы (new-user impressions)**: в июле 2026 у нескольких игр показы упали ~в 10 раз (CCU -80-90%), и ответа персонала не было.

### 8.4 Бенчмарки Roblox и P50/P90 kill/scale gate

**Официальные факты (док):**
- Benchmarks открываются при **100+ DAU**; сравнение с "похожими играми" (затем Genre, затем All). Показывается **полоса 50-й - 90-й перцентиль**. Пример из доков: D1 band 12,11%-18,73% означает, что 50% похожих игр <= 12,11% и 10% >= 18,73%. Охват: все KPI удержания, среднее время сессии, ARPPU, ARPDAU, CVR, play-through rate.
- Верхнеуровневые success-KPI сравниваются с топ-1000 игр по 30-дневному playtime и исключают игры моложе 30 дней. Benchmarks **не** являются сигналом дискавери.
- Официальная последовательность: до привлечения большого числа игроков подтяните D1, затем время сессии, затем D7/D30, затем конверсию и ARPPU **до уровня похожих игр или выше**; потом закупайте трафик и перепроверяйте после каждого обновления.
- FTUE: до веселья **за 5 минут или меньше**.
- Soft-launch форматы: playtest в малых группах; ограниченный публичный тест "weekend, week"; закрытая групповая бета; открытый тег Beta.

**Таблица решений (синтез из официальных ворот; не стандарт студий):**

| Стадия | Длительность | Критерий прохода | При провале |
|---|---|---|---|
| 0. Концепт | часы - 2 дня | Страница игры и thumbnail протестированы (Dubit: CTR рекламы или opt-in уведомлений относительно ваших прошлых концептов) | Бросить концепт |
| 1. Прототип ядра | 4 ч - 2 недели | Тестеры без подсказок понимают и просят продолжить | Переделать ядро один раз, потом убить |
| 2. Ограниченный публичный тест | выходные - 1 неделя, 300-500+ новых игроков | Медианная первая сессия не ниже нормы жанра (Twin Atlas: 20+ мин для RPG); веселье за <= 5 мин; D1 измерен | Убить или отложить (Wacky Wizards пересобрали через 2 года) |
| 3. Live при 100+ DAU | 2-4 недели | D1 и время сессии **>= P50** полосы похожих игр; D7 растёт к P50 | Чинить FTUE по воронкам; если ниже P50 после 2 циклов обновлений: убить или держать как дешёвый тайтл |
| 4. Масштаб | постоянно | Показы и новые игроки растут неделя к неделе 2+ недели подряд; D1 идёт к P90; конверсия и ARPPU >= P50 | Тогда добавлять рекламу, инфлюенсеров, недельный cadence и людей |
| 5. Sunset или поддержка | - | Устойчивый спад без идей реанимации: sunset. Небольшой, но прибыльный (~$10K/мес): один мейнтейнер | - |

Практические сигналы Twin Atlas (Naavik, май 2025): масштаб = устойчивый рост неделя к неделе ("not a single spike"); успех soft-launch = первые сессии 20+ минут примерно у 500 засеянных игроков; sunset = "consistent downtrend" и нет идей; примерно 3 новых игрока в час ≈ 1 CCU.

**Предпроверка без своего band (до 100 DAU):** медианы D1 GameAnalytics 2025 по длине сессии: 0-3 мин 4,31%; 4-6 мин 6,20%; 7-12 мин 7,91%; 13-18 мин 10,24%; 19-24 мин 11,46%; 25+ мин 10,76% (top 10%: 9,25% - 18,86%). Дневной ARPPU P50 $0,72, P90 $9,91. Правило скилла: пре-запусковой prior = бакеты GameAnalytics; после 100 DAU только свой dashboard-band; **вендорские таблицы по жанрам не использовать** (RoWatcher даёт противоречащие таблицы: D1 для roleplay 15-22% против "<40% опасно").

**Реальность малых разработчиков (сообщество):** запуск с D1 3-8% обычен и проваливается; ~16% после правки прогрессии хватило на ~20K CCU у sim; улучшение bounce с 21% до 15% дало +50% CCU.

### 8.5 Конверсия: определения (чтобы не путать)

| Цифра | Что значит |
|---|---|
| Dashboard "Conversion rate" | % DAU, которые платят; **дневной** |
| Experiments "Payer conversion rate" | **Кумулятивно за срок** эксперимента |
| Платформа DAU-to-purchase | ~1,25% (Q2 2025, Newzoo) |
| Naavik ">0,5% = high" | дневной, уровень игры (Blade Ball, 2023) |
| RoWatcher "ниже 5% убыток" | знаменатель не указан, по сути когортная; только ориентир |

**Вывод:** дневная конверсия 0,5-1,5% нормальна или сильна; когортная выше в разы, надёжного бенчмарка нет. Никогда не сравнивайте дневную цифру с "5%".

### 8.6 Диагностика падения CCU (кратко)

Порядок: (1) платформенное, сезонное, субботний цикл? (2) баннер reduced exposure, клон, смена Kids/Select, **региональное ограничение** (страна пропадает целиком)? (3) какой источник трафика упал (Acquisition)? (4) какой сигнал RFY упал? (5) какой сегмент (читать RFY с разбивкой по возрасту)? Подробности → см. advisor/discovery-growth.

Источники: create.roblox.com/docs/production/analytics, /analytics/analytics-dashboard#benchmarking, /cloud/guides/analytics, /cloud/guides/analytics/metrics, /cloud/guides/analytics/benchmarks, /production/analytics/funnel-events, /reference/engine/classes/AnalyticsService; gameanalytics.com/reports/2025-roblox-report; naavik.co/podcast/launching-original-ip-on-roblox/; rowatcher.com (сообщество). → см. advisor/idea-evaluation (kill/scale gates), builder/code-architecture (аналитика в коде).

**Каркас событий воронки (пакет пользователя: 09 §17.4, 03 §7; названия — предложение, свериться с актуальными лимитами AnalyticsService/Custom Events):** `SESSION_START` → `FTUE_READY` → `FIRST_ACTION` → `FIRST_PAYOFF` → `SECOND_VOLUNTARY_ACTION` → `UNLOCK_SEEN`/`UNLOCK_EARNED` → `COLLECTION_OPENED` → `ITEM_DISPLAYED` → `SOCIAL_SHOWCASE_VIEWED` → `CHALLENGE_*` → `SHOP_VIEWED` → `PURCHASE_COMPLETE`. Главное: `SECOND_VOLUNTARY_ACTION` (игрок сам повторил действие) отделяет «любопытство» от «интереса»; с официальными шагами онбординга — `LogOnboardingFunnelStepEvent` (`advisor/psychology-retention.md §10.1`).

---

## 9. Коммуникация: патчноуты, нерфы, group wall, уведомления

### 9.1 Патчноуты и анонсы

- **Version notes** обязательны при публикации; Studio генерирует черновик из save notes (раздел 4.4). Используйте как основу публичных патчноутов.
- **Update announcements** (страница игры): **максимум 60 символов, не чаще раза в 3 дня**. Статистика: Views, Visit rate, Unfollow rate (следите за unfollow).
- **События:** не более 10 текущих или будущих событий на игру; страница события с "Notify Me"; Trending Events in Experiences требует событие, начавшееся за последние 7 дней, **>= 1 000 RSVP** и публичность.
- **Канал обратной связи:** Jandel (Splitting Point) называет главным сигналом после обновлений **Roblox group wall** (Mogura VR, 2025). Сообщество: Discord игры (Bee Swarm ~750K, Blade Ball 500K+). Ссылки на Discord внутри игры теперь блокируются, поэтому общайтесь через Roblox Communities и experience notifications.
- Тон для детской аудитории (синтез): короткие, иконические сообщения; для 13+ можно подробнее.

### 9.2 Нерфы и изменения платного (Community Standards)

**Fraud: "removing functionality for buyers without proper notice".** Нерф или удаление проданного game pass или developer product без предупреждения нарушает Community Standards. Правило скилла: **объявлять изменения платных предметов заранее; компенсировать или grandfather покупателей;** никогда не обесценивать купленное. Это же снижает риск негатива в group wall.

Связанные запреты для live-ops: Gambling (симулированный и реальный): никаких wager-механик на валюту или предметы; "Win Robux" конкурсы запрещены; тип "tip jar" допустим, только если игрок ничего не получает взамен. Награды за лайки не запрещены явно (RIVALS даёт 3 ключа за лайк), но метаданные с денежной наградой "not prioritized for recommendations".

### 9.3 Уведомления (официальные правила)

- **Experience notifications** уходят только opt-in пользователям **13+**.
- Opt-in prompt `PromptOptIn()` стандартизован, текст менять нельзя; не покажется, если пользователь младше 13, уже подписан или видел prompt за последние 30 дней. Защищайте `CanPromptOptInAsync()` в `pcall`. Лучше вызывать в подходящий момент (например, сразу после запуска 2-часового таймера вылупления).
- Уведомления должны быть **персонализированными** на основе активности ("You're 2 races away from completing the weekly challenge!"; плохо: общая реклама "new cars dropped") и побуждать к **немедленному действию**; строка уведомления до 99 символов.
- **Запрещённые dark patterns:** disguised ads; time-pressured actions ("Make a purchase in the next 10 minutes"); bait-and-switch free items; tricking users into purchasing (ссылка, открывающая предзагруженную покупку).
- **Не привязывайте геймплей к включению уведомлений** ("Do not gate gameplay").
- Streaks и daily rewards (синтез из FTC-жалобы Fairplay, 2026; не правило Roblox): нестрогий streak (пропуск ставит на паузу или даёт grace day), награды дня N косметические или convenience, не гасящая пропуском мощность; не слать уведомления, давящие чувством вины. Roblox Engagement Rewards это 7-дневная лестница.

Источники: create.roblox.com/docs/production/promotion/experience-notifications, /experience-events; about.roblox.com/community-standards; quartz.com (FTC complaint, 20 мая 2026). → см. builder/compliance, advisor/psychology-retention.

---

## 10. Today's Picks, Standout Games, event featuring

Три документированные **редакторские поверхности**, все по номинации, без опубликованных пороговых метрик:

| Поверхность | Что это | Действие |
|---|---|---|
| **Today's Picks on Home** | Ежедневная кураторская подборка лучших игр: "exciting updates, new and notable games, events, seasonal and/or cultural moments". Статус: Open, любой может номинировать через survey; редакция рассматривает постоянно, **уведомляются только выбранные** | **Заполняйте форму при каждом заметном обновлении** (официальная рекомендация). Есть сестринская программа для Marketplace |
| **Standout Games** | "Novel games hand curated by Roblox" (необычные механики, выделяющийся визуал, недопредставленный жанр); с 30 апр 2026 вместе с retention-weighted discovery | Подавать survey; без числовых порогов |
| **Event featuring (Off-Platform)** | Roblox, App Store, Google Play маркетинг; отбор по росту DAU, playtime, удержанию, монетизации | Подать **не позднее чем за 7 дней** до начала; "best events run 7-30 days" |

**Факты:** трафик Today's Picks **исключён из сигналов Home Recommendation** (персонал, DevForum, 3 нояб 2025). То есть это чистый top-of-funnel бонус: не вредит RFY и не обучает его. Today's Picks единственная поверхность, явно ориентированная на **обновления существующих игр**.

**Правило скилла:** после каждого крупного обновления или события (особенно сезонного/культурного) подавайте Today's Picks и Standout Games; для событий 7-30 дней включайте featuring за 7+ дней.

Источники: create.roblox.com/docs/creator-programs/todays-picks-home, /creator-programs/standout-games, /production/promotion/experience-events; devforum.roblox.com/t/todays-picks-and-site-events-negatively-effecting-a-games-home-recommendation-signals/4042042.

---

## 11. Стадии спада и действия

### 11.1 Данные по спаду вирусных хитов (октябрь 2026, трекеры; пики по событиям)

| Игра | Пик (дата) | Недель до -50% (дневной уровень) | Недель до -90% | Сейчас относительно пика |
|---|---|---|---|---|
| Grow a Garden | 22,3M (23 авг 2025) | <= 12-16 | <= ~30 | 17-27K (-99,9%) |
| Steal a Brainrot | 25,4M (нач. окт 2025) | ~12-20 | по дневному среднему не достигнуто | топ-5 после 12 месяцев, 108-325K (~1%) |
| Escape Tsunami for Brainrots | ~5M (янв 2026) | <= 6 | <= 10 | -97% |
| Garden Horizons | >1M (фев 2026) | <= 2 | <= 2 | -98% |
| Kick a Lucky Block | 1,7M (весна 2026) | <= 8 | <= 10 | >= -99% |
| Animal Hospital | 737K (5 июл 2026) | ~6,5 | ~12 | -97% |
| +1 Speed Keyboard Escape | 7,28M (лето 2026) | ~6 | ~10 | -99,6% |
| Grow a Garden 2 | ~508K (июнь 2026) | ~8-9 | <= 15 | >= -96% |
| Steal An Egg | 14,27M (19 сен 2026) | пока не достигнуто по дневному уровню | -90% относительно спайка за дни | 5-10% спайка |
| Ride A Pet | 1,4-1,55M (сен 2026) | <= 3-4 | <= 5-6 | -98,5% |
| Slayers 2 | 237-268K (нед. запуска) | ~1,5 | ~5 | -91-94% |
| 99 Nights (evergreen) | 14,2M (H2 2025) | n/a | ниже 10% спайка, но база 150-300K | ~1-3% спайка, top-10 19 месяцев |

**Правила (n = 14 хитов, вывод):**
- Медиана: **-50% через ~4-8 недель** после пика месяца, **-90% через ~8-14 недель**; 11 из 14 потеряли >= 90% за ~4 месяца.
- Самые быстрые: Garden Horizons, Ride A Pet, Slayers 2 (спайк запуска / сломанная экономика).
- **Только 3 из 14 сохранили top-10 базу после 6 месяцев:** Steal a Brainrot, 99 Nights, (пока) Steal An Egg; все с недельным live-ops и кросс-IP событиями; держат лишь ~1-10% пика.
- Сиквелы и копии спадают не медленнее оригиналов.
- Оценка времени от запуска до пика в 2026: 4-8 недель.

### 11.2 Стадии и действия (синтез)

| Стадия | Признак | Что делать |
|---|---|---|
| 0. Запуск/спайк (недели 0-2) | Рост, ажиотаж | Иметь 4-6 недель контента в запасе (Slayers 2 без runway упал на 91% за 5 недель); следить за экономикой (дюпы), crash rate, паритетом платформ (консоль не позже) |
| 1. Пик/плато | Показы растут, D1 держится | Фиксированный cadence; события; Today's Picks; не добавлять P2W; ранний второй системный слой |
| 2. Спад -50% (недели 4-8) | CCU неделя 2 ниже 50% от пика недели запуска; нет запланированного обновления | **Добавить вторую систему** (social, trading, rebirth, ranked) к дням 30-60; сезон/пасс; событие; чинить FTUE по воронкам |
| 3. Падение к -90% (недели 8-14) | Время сессии падает при держащемся D1 (loop exhaustion), Index/completion насыщается | Major update (раздел 2.2): social/competitive/collections/live events; ребрендинг карты; рассмотреть сиквел только при мёртвой экономике (раздел 12) |
| 4. Хвост (1-10% пика) | Устойчивая база | Минимальная команда; ~$10K/мес и один мейнтейнер считается "keep" (Twin Atlas); недельные/месячные cadence-дропы низкой стоимости; сезонные события (Beesmas утраивает CCU) |
| 5. Sunset | Устойчивый спад, идей реанимации нет | Закрыть доступ (revoke public access), перенести команду; сохранить данные и экономику; спин-офф в новый прототип |

**Ранние предупреждающие сигналы (по причинам провалов):**
- Нет контентного runway после спайка (10 из ~30 провалов): CCU недели 2 < 50% пика и нет расписания обновлений.
- Loop exhaustion (7): время сессии падает при держащемся D1.
- Платформа/политика (7): баннер reduced exposure, показы новых игроков -50% день ко дню; держите анкету maturity честной.
- Экономика (6): резкий обвал цен топ-предметов, всплеск числа редких; **никогда не обесценивайте платное**.
- P2W/монетизация, добавленная после запуска, или раздутые бандлы (5): падение рейтинга лайков после обновления магазина; запускайте магазин сразу, косметика прежде всего, используйте early-harm флаги экспериментов.
- Команда/выгорание (4): срыв сроков. Пример: Garden Horizons, командный исход из-за оплаты.
- Производительность (3): crash rate > 5%, FPS на слабых телефонах.
- Операционные ошибки: Jailbreak -70K CCU в день после случайного удаления. Группа-владелец, бэкапы, права.
- Выживание при засухе контента: Blox Fruits и DOORS пережили 15 и 24 месяца без больших обновлений (сильное ядро + большие события); лёгкое ядро не переживёт.

Источники: studiokrew.com/blog/top-roblox-games-august-2026, /september-2026; rowatcher.com/news/is-the-brainrot-trend-dying...; allthings.how (Garden Horizons, Steal An Egg); statroblox.com/leaderboards/playing. → см. advisor/case-studies, advisor/genres-trends (жизненные циклы).

---

## 12. Сиквел или обновление

**Правило (вывод из кейсов):** сиквел работает, когда **экономика оригинала мертва или раздута И сиквел добавляет хотя бы одну крупную систему.** Проваливается, когда делит живую аудиторию и просит игроков бросить прогресс.

| Кейс | Результат | Причина |
|---|---|---|
| PSX, затем Pet Simulator 99 (BIG Games, дек 2023) | Успех | Оригинал упал до 10-20K, экономика инфлировала; PS99 добавил большие системы |
| Bubble Gum Simulator, затем BGS INFINITY (Rumble, 2024) | Успех (~381K) | Сброс мёртвой экономики (оригинал ~7K), большие новые системы |
| Grow a Garden 2 (12 июня 2026) | 976K пик, затем ~2K за ~4 месяца (~4,5% пика оригинала) | Слитый цикл, потраченная новизна (ферма + кража), **нет переноса прогресса** (sunk-cost оригинала сработал против сиквела), новый режим платформы (retention-weighted RFY, Kids/Select), оригинал ещё жил (48-161K). Повторяющиеся обновления и P2W: низкая уверенность (источник с конфликтом интересов) |
| Piggy: Intercity 2026 | 27-67K пик, затем ~60 CCU | Сиквел/релонч без новой системы |
| Slayers 2 | 268K, затем 24K за 5 недель | Big-bang запуск без контентного runway |

**Чек-лист решения:**
1. Оригинал всё ещё держит >~48K CCU или здоровый DAU? Тогда **обновление**, не сиквел.
2. Есть ли новая система (не ретема): новый глагол, новая коллекция, новая социальная структура?
3. Можно ли перенести прогресс или награду за него? Если нет, ожидайте раскола аудитории.
4. Есть ли 4-6 недель контента про запас на запуск?
5. Подходит ли сиквел под текущий режим платформы (глубокие игры для 13+, 28-дневное удержание)?

**Альтернативы сиквелу:** крупная переработка внутри игры (Wacky Wizards был отложен и пересобран через 2 года в хит); ребрендинг + major update; новый прототип из портфолио (Twin Atlas ~10 месячных прототипов в год; Jandel "80-100" прототипов).

Источники: allthings.how (Grow a Garden 2, 13 июня 2026); studiokrew.com; naavik.co/podcast (The Gang, Twin Atlas).

---

## 13. Команда и процесс

| Студия | Размер и структура (с датами) |
|---|---|
| 99 Nights | 5 человек (3 соавтора, художник, аниматор); ~3 месяца до запуска |
| Roblox на GDC 2026 | "teams of fewer than 10" достигают 25M+ CCU |
| Gamefam | 40 FTE (2021), 100+ (дек 2024); нанимает нативных Roblox-разработчиков |
| The Gang | ~220 человек (июль 2025); producers на тайтл; бренд-работа и оригинальные игры в отдельных юнитах |
| Twin Atlas | 100+ (60+ full-time, нояб 2025); дивизия быстрых прототипов; платит community-разработчикам за поддержку малых игр |
| Voldex | 60 FTE (фев 2025); купил Brookhaven; модель: купить проверенные игры + live-ops платформа |
| Uplift (Adopt Me!) | ~40 (2021, устарело); producers разводят контент-треки; "zero burnout studio" |
| Splitting Point (GaG) | Две event-команды для еженедельного cadence (июль 2025) |

**Уроки Gamefam ("5 mistakes", TechCrunch, 2021):** (1) не переносить мобильный F2P-онбординг (Speed Run Simulator убрал туториал, D1 вырос); (2) не оптимизировать под китов (редизайн VIP, revenue per visit +25%); (3) не делать "чуть лучшую копию", а добавить твист; (4) графика не побеждает, побеждают скорость доступа и real-time мультиплеер; (5) потратить "1000 hours on Roblox" до дизайна.

**Hit rate (для планирования):** ~5-10% на прототип, ~10-20% на выпущенную игру у опытных; планируйте **10-20 прототипов на заметный хит**; первый хит ожидаем после ~5 выпущенных игр или ~6 месяцев полного времени (The Gang). Это не измеренная отраслевая ставка.

**Не публикуется:** длина спринта, внутренний недельный pipeline (content lock / QA / release) именованных студий; официального guidance Roblox по спринтам нет (проверено по доков-репо). Официальные формы прототипирования: бумажные прототипы (минуты) и Studio-прототипы (дни-недели), прототипируйте ядро, UI/UX, правила, edge cases; затем командные и внешние плейтесты.

**Выгорание:** официальный пункт LiveOps best practices (mental health). Подход Uplift: producers + контент-инструменты вместо кранча.

Источники: techcrunch.com/2021/03/26/5-mistakes-creators-make-building-new-games-on-roblox/; naavik.co/podcast/launching-a-roblox-game-studio-with-the-gang/; businesswire.com (Voldex, 4 фев 2025); netinfluencer.com (Twin Atlas, нояб 2025); create.roblox.com/docs/production/game-design/prototyping.

---

## 14. Чек-листы

### 14.1 Перед еженедельным дропом

1. Контент залочен в среду, на live за config-флагом; version notes написаны.
2. Анкета maturity: ответы не изменились (иначе пересдать до публикации).
3. Ассеты `Approved`; PolicyService-гейты, `ProcessReceipt` идемпотентны.
4. Алерты: crash rate > 5% за 5 мин на новую place version; CCU неделя к неделе.
5. Restart: только устаревшие серверы, bleed-off 5-10 мин, отсчёт `ServerRestartScheduled`.
6. Анонс (<= 60 символов), event page, номинации Today's Picks и Standout (если крупное).
7. План отката: сначала config, затем restore, publish, restart.
8. Нет платных функций, которые нерфятся без объявления.

### 14.2 После дропа (1-3 дня)

1. Place-version метрики: crash, FPS, память; ошибки.
2. D1/D7 когорты, время сессии, конверсия, ARPPU против P50/P90 band.
3. Экономика: не раздали ли валюту, цены топ-предметов.
4. Group wall, Discord, unfollow rate.
5. Новые показы (new-user impressions) ежедневно.
6. Через 7 дней: постмортем события (неделя до, во время, после).

### 14.3 Раз в месяц

1. Сезон/пасс закрыт, неделя паузы; следующий планируется (double XP в последнюю неделю).
2. Решение по стадии (раздел 11): нужна ли вторая система? major update?
3. Эксперименты: что запущено (14-60 дней), результаты, раскатка победителя.
4. Нагрузка на команду: pods ротируются? нет ли признаков выгорания?

---

## 15. Конфликты источников и открытые вопросы

**Неразрешённые или частично разрешённые конфликты:**

| Вопрос | Расхождение | Что принять |
|---|---|---|
| Лимит Configs | Док Configs (в нотах): до **1 000 активных конфигов**; Open Cloud-руководство: **100 ключей на repository**, значения до 100 000 символов | Различие может быть между UI-лимитом и repository API; **проверить в Creator Hub**. Для планирования исходите из 100 ключей на repository |
| Cadence 1-2 недели против 2-4 | Strategies против Retention/Content updates | Разрешено как диапазон по мощности команды (раздел 2.1) |
| Конверсия "5%" против "0,5% высоко" | Разные знаменатели | Разрешено определениями (раздел 8.5) |
| Пик Grow a Garden | 21,3M (Naavik, июнь 2025) против 22,3M (23 авг 2025, Wikipedia/Splitting Point) | Использовать 22,3M (более поздняя и подтверждённая сводка); оговаривать разброс |
| Платформенный рекорд 47,4M | Август 2025 (Naavik/сводка) против "октябрьский всплеск" (Beebom) | Не решено; цитировать как "2025" |
| Вход Splitting Point в GaG | ~500 CCU (GamesBeat) против ~1 000 CCU (Wikipedia) | Использовать "около 500-1 000 CCU" |
| Peak SaB | 25,4M (подтверждён разработчиком) против 25,2M и 25,8M (трекеры) | Цитировать 25,4M; 25,8M как неподтверждённый |
| Время субботнего дропа | GaG 7:00 PT (~14:00 UTC); PvB admin abuse ~11:00 UTC; сторонняя кривая 14:00-16:00 UTC; Adopt Me! пн/пт 11:05 ET; SaB пятница | Не единое правило: выбирайте час по часовому графику своей аудитории |
| Порог Kids/Select | 500 до 20 авг 2026, затем 250; expedited fee 100 000 R$ (авг), затем 50 000 R$ | Использовать 250 и 50 000, перепроверять (менялось 4 раза в 2026) |
| Hit rate | ~15% на выпущенную игру (Jandel) против ~5-7% на прототип | Диапазон 5-10% прототип, 10-20% выпущенная игра |

**Открыто / не подтверждено:**
- Длина спринта и внутренний график дропа именованных студий (недоступно публично).
- Подтверждённые вес сигналов RFY, механика age-aware ranking и сигнала "direct growth" (не опубликованы).
- Определения Up-and-Coming, Fun with Friends, Top Earning, Top Rated, Top Revisited не опубликованы.
- Публичные жанровые бенчмарки удержания (показываются только внутри dashboard).
- Тезис "Roblox goes private" из подкаста Deconstructor of Fun: подтверждения нет; не утверждать как факт.
- Выполнение сквозного CI-пайплайна на живой вселенной не проверялось ([NOT EXECUTED]).
- Данные по Slayers 2 (причина падения) выведены из дат, не из источника.
