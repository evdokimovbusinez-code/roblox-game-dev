# Настройка игры в Studio и Creator Dashboard (Creator Hub)

**Зачем этот файл.** Это рабочий справочник Builder-роли для настройки готовой игры: что ставить в каждой вкладке Studio **Experience Settings** и на каждой странице **Creator Dashboard**, когда отступать от значений по умолчанию, как пройти релиз (private → questionnaire → 16+ → Kids/Select), как пошагово создать Game Pass / Developer Product / подписку / private server / бейдж, как собрать каталог магазина и донаты, что можно автоматизировать через Open Cloud, а что делается только руками. В конце два чек-листа, pre-publish и первые 24 часа, и список значений, которые нужно прочитать в Studio или Creator Hub своими глазами.

**Актуально на: октябрь 2026.** Перепроверять:
- пороги Kids/Select (250 plays за 60 дней, expedited 50 000 R$, менялись 4 раза за 2026 год);
- лимиты Robux transfers (500/1 000, с 2SV 5 000/10 000) и родительские ограничения;
- срок бесплатного Plus для креаторов (истекает примерно в ноябре 2026);
- цену Roblox Plus ($4.99);
- правила 18+ DevEx rate (R15 only);
- стабильность Open Cloud эндпоинтов (BETA/EXPERIMENTAL);
- дату обязательного platform-integrated chat (май 2027).

Названия: окно **File → Game Settings** теперь называется **File → Experience Settings**, а в документации «experience» всё чаще заменяется на «game».

---

## Содержание
0. Главные правила (TL;DR)
1. Карта: где живёт каждая настройка
2. Experience Settings вкладка за вкладкой (+ Avatar Settings, Workspace/Lighting)
3. Places: max players, server fill, доступ, версии, рестарты
4. Метаданные и жанр
5. Владение: группа, роли, коллабораторы, передача
6. Релиз: private → questionnaire → 16+ → Kids/Select
7. Монетизационные объекты пошагово (passes, products, подписки, private servers, paid access, Shop, Managed Pricing, ads)
8. Бейджи: создание, лимиты, план
9. Шаблон каталога магазина
10. Донаты в 2026: tip jar, Robux transfers, payouts
11. Локализация, уведомления, API keys
12. Автоматизация: Open Cloud vs только Dashboard vs только Studio
13. Pre-publish чек-лист
14. Первые 24 часа после релиза
15. Ручная проверка: что прочитать в Studio/Creator Hub
16. Нерешённые конфликты и открытые вопросы

---

## 0. Главные правила (TL;DR)

1. **Сначала группа, потом первый publish.** Группа стоит 100 R$. Если перенести игру в группу позже, закроются сервера, пропадёт публичный доступ и discovery просядет на срок до 24 ч.
2. **Жанр выбирается один раз.** Сменить его можно только раз в 3 месяца. Название тоже не трогать: частые переименования снижают находимость.
3. **Avatar type = R15 (только R15).** Вариант «R15 & R6» (PlayerChoice) лишает игру 18+ DevEx rate (0.0054) и SLIM-рендера.
4. **Security: всё OFF, кроме реально нужного.** Studio Access to API Services на production **никогда** не включать: Studio пишет в живые DataStore. Для тестов нужна отдельная приватная DEV-вселенная.
5. **Цены никогда не хардкодить.** Managed Pricing включён по умолчанию, у Plus-подписчиков скидка 10–20%. Цену для UI берите из `GetProductInfoAsync`.
6. **Developer Products: только `ProcessReceipt`, идемпотентно.** Roblox постоянно аудирует обработчики, и продукты с ошибками снимаются с внешних поверхностей.
7. **Глобальная кнопка Shop по умолчанию OFF.** Включите её (Monetization → Shop).
8. **Cross-game продажа passes/products отключена с 29–30 мая 2026.** Донаты между игроками делаются только через `PromptRobuxTransferAsync` (игра получает 10%).
9. **Questionnaire нужно заполнить полностью и честно** и переотправлять после каждого апдейта, который меняет ответы. Без него playability ограничивается.
10. **Max players ≤100, если нужен голос.** Server fill: «Roblox optimized» для социальных игр, «Maximum» для раундовых. В тайкуне max players = числу плотов.
11. **5 бесплатных бейджей в сутки (GMT/UTC)**, дальше по 100 R$ за штуку. Выдавать только с сервера.
12. **Открытая разработка = утечка.** Опция «Direct Access» не защищает subplace от клиентских телепортов. Тестовые места держите в отдельной приватной вселенной.

---

## 1. Карта: где живёт каждая настройка

**Studio → File → Experience Settings**, вкладки: Basic Info, Communication, Permissions, Monetization, Security, Places, Localization, World, Other.
**Avatar Settings** открываются отдельным окном (меню File или вкладка Avatar).
Часть вкладок Studio — тонкие ярлыки на Creator Hub: например, Monetization → «Configure on Creator Hub».

**Creator Dashboard, левая навигация (2026):**

| Группа | Страницы |
|---|---|
| Publish settings | Game details, Content rating (questionnaire), Manage Audience |
| Audience | Access Settings, Reach, Communication Settings, Localization, Advanced Settings |
| Configurations | Places, Server management |
| Monetization | Passes, Developer Products, Subscriptions, Shop, Managed Pricing, Ads, Roblox Plus |
| Engagement | Badges, Notifications, Social Links (+ Events & Updates) |
| Safety | Collaborators |

**Кто источник истины.** Метаданные, аудиторию, монетизацию, бейджи, уведомления, соцссылки, локализацию и server management задаёт **Dashboard**. Движковые параметры (World, Avatar, Workspace, Lighting, `LoadStringEnabled`), а также Security-тумблеры, Drafts Mode и HttpEnabled задаёт **Studio**.

Сводная таблица «что автоматизируется» → §12.

Важный факт для автоматизации. Тумблеры Security, жанр, avatar type, friends-only и server fill есть **только** во внутреннем `develop.roblox.com` API (`PATCH /v2/universes/{id}/configuration`, `PATCH /v2/places/{id}`). Он помечен EXPERIMENTAL и работает **только с cookie-авторизацией** (`roblox-legacy-cookie`), API-ключи там не принимаются. Не используйте его: автоматизация через `.ROBLOSECURITY` хрупкая и опасна для аккаунта. Эти шаги делаются руками.

Источники: [Experience settings (live, страница удалена из репо 31.07.2026)](https://create.roblox.com/docs/en-us/studio/experience-settings); [Open Cloud scopes/openapi](https://create.roblox.com/docs/cloud/reference/scopes); [Paid access](https://create.roblox.com/docs/production/monetization/paid-access-robux)

---

## 2. Experience Settings вкладка за вкладкой

Сама страница настроек предупреждает, что эти настройки «can lead to unexpected or difficult-to-debug behavior». Поэтому держите **один источник истины** для значений геймплея: config-модуль в коде.

### 2.1 Basic Info

| Поле | Рекомендация | Когда отклоняться |
|---|---|---|
| Name | Стабильное, keyword-first, не больше 1–2 эмодзи, без повторов слов (повторы могут привести к демоушену) | Никогда не гоняться за трендом переименованием |
| Description | Первые ~160 символов — хук с ключевыми словами. Всё описание подходит для всех возрастов | — |
| Content Maturity Label | Только отображает результат questionnaire. Для широкой аудитории цель Minimal/Mild | Хоррор с реалистичной кровью → Moderate (без Roblox Kids) |
| Game Icon | 512×512, читается при ~150 px | → см. builder/packaging.md |
| Screenshots & Videos | 3–5 активных изображений 1920×1080 + 1 видео | — |
| Playable Devices | Computer, Phone, Tablet, Console = ON | VR только если протестировано. TV (`playableDevices` = 6) только если игра проходится пультом с D-pad. Paid access в Robux недоступен на Xbox |

Поле `promotionalText` существует в API, но где оно в UI, не задокументировано (→ §15).

### 2.2 Communication

| Поле | Рекомендация | Когда отклоняться |
|---|---|---|
| Enable Microphone (в voice-доке: «Enable Voice Chat») | ON для social, RP, co-op и хоррора (max ≤100) | OFF для соревновательных игр с молодой аудиторией |
| Enable Camera (анимация аватара камерой игрока) | ON для social/RP, иначе OFF | Значение по умолчанию не задокументировано |

Отдельно на Dashboard: Audience → Communication Settings → **Allow Strong Language** ослабляет фильтр чата для старшей аудитории и добавляет лейбл. Метаданные и ассеты никогда не могут содержать мат.

Факты:
- Голос включён по умолчанию для новых игр с max ≤100 игроков. Доступен age-verified пользователям 13+ в части стран, остальным через ID.
- Голос нужен для speech-to-text API.
- Выключать голос для отдельного места через `VoiceChatService.EnableDefaultVoice = false` (затем рестарт серверов), а **не** через max players >100.
- Поле Open Cloud `voiceChatEnabled` не влияет на уже запущенные сервера.

Чат:
- Только `TextChatService`. Legacy chat удалён 30.04.2025.
- **С мая 2027 обязателен platform-integrated chat.** Если не нужны префиксы команд и чтение текста сообщений, ставьте `TextChatService.PlatformIntegratedChat = Enabled` уже сейчас. Если нужны, планируйте переписывание: при PIC текст сообщений в коде недоступен, а команды делаются через `TextChatCommand`.

Подробнее о чате и правилах → builder/compliance.md.

### 2.3 Permissions

| Поле | Рекомендация |
|---|---|
| Playability (API `audiences`: Editors / PlayTesters / Friends / Public) | Private → Playtesters → Public (§6). Финальный релиз через Dashboard → Manage Audience |

### 2.4 Monetization (ярлыки на Creator Hub)

Badges, Paid Access, Private Servers, Developer Products.
- Private servers: **ON**.
- Paid access: **OFF**, кроме закрытой беты или премиум-игры.

Подробно → §7.

### 2.5 Security

| Поле | Production | Когда включать |
|---|---|---|
| Allow HTTP Requests | **OFF** | Вебхуки, Secrets (`HttpService:GetSecret`), внешние API или Open Cloud из игры. Лимиты: 500 HTTP/мин на сервер, вызовы Open Cloud из игры имеют отдельный бюджет 2 500/мин |
| Secrets (локальные) | Только для тестов | Production-секреты хранятся в Creator Hub |
| Enable Studio Access to API Services | **OFF** | Только в отдельной DEV-вселенной: Studio работает с теми же DataStore, что и живая игра |
| Allow Third Party Sales | OFF | UGC-магазин или merch booth с чужими предметами. Свои ассеты продаются и при OFF |
| Allow Third Party Teleports | OFF | Телепорт в **чужие** игры. Между своими играми работает и при OFF |
| Allow Mesh / Image APIs (EditableImage/EditableMesh в живой игре) | OFF | Если используете. Нужна верификация 13+ и ID |
| API-only: `IsThirdPartyAssetAllowed`, `IsClientTeleportAllowed` | OFF | Клиентские телепорты не нужны: используйте серверный `TeleportAsync` |
| `ServerScriptService.LoadStringEnabled` (через Properties, не в этом окне) | **false** (это значение по умолчанию) | Никогда |

Для непубликованного места `HttpEnabled` включается из Command Bar: `game:GetService("HttpService").HttpEnabled = true`. Rojo не синхронизирует `HttpEnabled`.

### 2.6 Places

Create; ⋯ → Configure Place / Edit (max players, Server Fill); Version History. Подробно → §3.

### 2.7 Localization

| Поле | Рекомендация |
|---|---|
| Source Language | Язык, на котором пишется игра |
| Automatic Text Capture (ATC) | ON |
| Use Translated Content | ON |
| Automatic Translation | ON для топ-5–8 языков вашей аудитории (квота считается как символы × языки) |

Подробно → §11.

### 2.8 World

Пресеты Classic / Realistic / Action и поля Gravity (studs/s² + m/s²), Jump (высота в studs или сила в studs/s), Walk (studs/s), Slope (максимальный угол подъёма).

Известные якоря:
- Значения движка по умолчанию (= Classic, вывод): Gravity **196.2**, WalkSpeed **16**, JumpHeight **7.2** / JumpPower **50**, MaxSlopeAngle **89**.
- Реальная гравитация **35 studs/s²** (9.8 m/s², 1 stud = 28 см). Это почти наверняка гравитация пресета Realistic, но это вывод.
- Числа пресетов **нигде не опубликованы**. Прочитайте их в Studio (§15) или, лучше, задайте явные значения в config-модуле и не полагайтесь на имена пресетов.

Тюнинг по жанрам (**оценка**, относительно дефолтов движка):

| Жанр | Gravity | Walk | Jump | Slope | Примечание |
|---|---|---|---|---|---|
| Obby / platformer | 196.2 | 16 | 7.2 h / 50 p | 89 | Зафиксировать **до** постройки уровней: от них зависят все дистанции прыжков |
| Simulator / tycoon | 196.2 | 16–20 | default | 89 | Базу держать скромной: скорость продаётся как pass или апгрейд |
| Horror (chase) | 196.2 | 10–14 (спринт 18–22 скриптом) | 5–7.2 | 89 | Медленная база даёт темпу монстра создавать напряжение |
| Shooter / action | 196.2 | 16–20 | default | 89 | Для соревновательных игр рассмотреть AuthorityMode Server |
| Low-gravity режим | 50–100 | 16 | default | 89 | Как тематический режим, не как база |

Realistic-гравитация (35) при масштабе персонажей Roblox ощущается «ватной» и используется редко. Скрипты всё равно могут переопределять значения per character (`Humanoid.WalkSpeed`). StarterPlayer-значения применяются только при респауне.

### 2.9 Avatar Settings (отдельное окно)

API-энам `universeAvatarType`: MorphToR6 = 1, PlayerChoice = 2, MorphToR15 = 3. Значит, «R15» в Studio = MorphToR15 = «R15 Only» из требований 18+ DevEx, а «R15 & R6» = PlayerChoice и **дисквалифицирует 18+ rate**.

| Вкладка / поле | Варианты (по умолчанию **жирным**) | Рекомендация |
|---|---|---|
| Top bar: avatar type | R6 / R15 / R15 & R6 | **R15** |
| Top bar: preset | **Player Choice** / Consistent Gameplay (одинаковый рост + box collider) | Player Choice для social/sim. Consistent Gameplay для PvP, обби и хоррор-погонь |
| Body → Scale | **Player Choice** / Custom Scale (min/max рост в studs) | Custom, только если этого требуют двери, вентиляции или лазы (частый случай в хорроре) |
| Body → Appearance / Build | **Player Choice** / Custom | Player Choice: самовыражение стимулирует покупки аватарных предметов |
| Clothing → Scale / Custom Clothing | **Player Choice** / bounds / per-slot override | Override только для командной формы |
| Accessories → Accessory Scale | **Player Choice** / Custom Limit (Scale или Remove) | Custom Limit → Scale в соревновательных играх, чтобы огромные аксессуары не мешали обзору и хитбоксам |
| Accessories → Behaviors | Тумблеры VFX / Sound / Emissives | Sound OFF в хорроре и стелсе |
| Movement → Collision | **Default (OuterBox)** / Single Collider / Legacy (InnerBox) | Single Collider для PvP, обби и хоррора |
| Movement → Animation Packs | **Player Choice** / Standard R15 / Standard R6 | Player Choice. Standard R6 никогда, если нужен 18+ rate |
| Movement → Animation Clips | **Player Choice** / Custom | Custom для стилизованного жанра (например, хоррор-присед) |
| Movement → Abilities | **Legacy Humanoid** / Character Controller Library | Legacy, если не нужны переключаемые в рантайме способности |

18+ DevEx rate (0.0054, с 08.06.2026): персонаж игрока должен быть R15 (или квалифицирующий кастомный риг) **100% активного времени**. Возможность заспавниться или переключиться в R6 в любой момент лишает игру этого курса. NPC не учитываются, проверки идут в фоне.

R6 выбирайте только для combat-игр с «легаси-ощущением», осознанно жертвуя 18+ rate. В этом случае включите `Workspace.AvatarUnificationMode = Enabled`.

### 2.10 Other

| Поле | Рекомендация |
|---|---|
| Enable Drafts Mode | По умолчанию OFF. ON для команд от 3 скриптеров. Изменение вступает в силу, когда все коллабораторы выйдут |
| Shutdown All Servers | Аварийная кнопка. В обычной работе используйте Server management → Restart (§3.4) |

### 2.11 Workspace / StarterPlayer / Lighting (Properties в Studio)

| Свойство | Значение | Почему |
|---|---|---|
| StreamingEnabled | ON (по умолчанию для новых мест, не скриптуется) | Память, мобильные устройства, SLIM |
| ModelStreamingBehavior | Improved | Рекомендация доков |
| StreamingIntegrityMode | PauseOutsideLoadedArea | — |
| StreamingMinRadius / TargetRadius | 64 / 1024 | TargetRadius должен быть больше MinRadius |
| StreamOutBehavior | Opportunistic | «help prevent out-of-memory crashes» |
| SignalBehavior | Deferred | Default пока равен Immediate, но станет Deferred |
| EnableSLIMAvatars | Enabled (при R15 + streaming) | Пример из доков: сцена с ~2.6M треугольников падает до ~170k |
| RejectCharacterDeletions | Default/Enabled | Защита от удаления персонажа клиентом |
| AuthorityMode | Automatic. **Server** только для соревновательных FPS, гонок, спорта и боёвок с нуля | Server требует писать геймплей в `RunService:BindToSimulation` |
| Lighting.LightingStyle | Realistic + PrioritizeLightingQuality для хоррора и атмосферных игр. Soft для стилизованных и мобильных | `Lighting.Technology` устарел |

Подробно об архитектуре и производительности → builder/code-architecture.md, о свете и арте → builder/art-ui-audio.md.

Источники: [Experience settings (live)](https://create.roblox.com/docs/en-us/studio/experience-settings); [Avatar Settings](https://create.roblox.com/docs/studio/avatar-settings); [18+ DevEx rate](https://create.roblox.com/docs/production/monetization/18-plus-devex-rate); [Units](https://create.roblox.com/docs/physics/units); [StarterPlayer](https://create.roblox.com/docs/reference/engine/classes/StarterPlayer); [Streaming](https://create.roblox.com/docs/workspace/streaming); [Voice chat](https://create.roblox.com/docs/chat/voice-chat); [Platform-integrated chat](https://create.roblox.com/docs/chat/platform-integrated-chat); [DevForum: legacy chat removal](https://devforum.roblox.com/t/migrate-to-textchatservice-removing-support-for-legacy-chat-and-custom-chat-systems/3237100); [Data stores](https://create.roblox.com/docs/cloud-services/data-stores); [HTTP service](https://create.roblox.com/docs/cloud-services/http-service)

---

## 3. Places: max players, server fill, доступ, версии, рестарты

### 3.1 Max players и Server Fill

- **Max players задаётся только на Dashboard:** Configurations → Places → место → Access → **Maximum Visitor Count**. Через Open Cloud это поле `serverSize`.
- **Server Fill:** Experience Settings → Places → ⋯ → Edit (или в Access-настройках места).

| API `socialSlotType` | Метка в UI (зависит от версии UI) | Поведение |
|---|---|---|
| Automatic | «Roblox optimized» (по умолчанию) | Заполняет до `Players.PreferredPlayers` (< Max), держит слоты для друзей |
| Empty | «Maximum» (по BR-киту), возможно «None» | Заполняет сервер до MaxPlayers, прежде чем открыть новый |
| Custom | «Custom» / «Customize how many slots to reserve» + число | Резервирует N слотов для социальных заходов |

Связка «метка ↔ API-значение» — вывод: подтверждены метка «Maximum» и API-значения, точные текущие подписи нужно проверить (§15).

**Рекомендации (эвристика, не из официальных доков):**

| Тип игры | Max players | Fill |
|---|---|---|
| Social / hangout / RP | 20–40 | Automatic |
| Simulator / tycoon | 8–20, **= число плотов** в тайкуне | Automatic или Custom с 2–4 слотами |
| Horror co-op | 4–8 | Custom с 1–2 слотами или Automatic |
| Раундовый PvP / BR-лобби | Размер режима | **Maximum** (быстрый старт раундов) |
| Нужен голос | **≤100** | — |

- Больше 100 выставить можно (это видно из voice-дока). Фраза «Servers support up to 100 players» — мягкий потолок. Жёсткий максимум не подтверждён (§15).
- Известный баг (DevForum, окт. 2025): при server size 50 и 8 custom social slots Roblox всё равно создавал сервера на 1 игрока. Если видите это в аналитике, переключитесь на Maximum или Automatic и напишите репорт.
- Matchmaking распределяет игроков по взвешенным сигналам (друзья/тот же IP, пинг, возраст, язык). Веса можно настраивать.

### 3.2 Доступ к местам (телепорты)

Audience → Access Settings → **Access Control for Places**:

| Режим | Что разрешает | Когда |
|---|---|---|
| Fully open | Любое место доступно любым путём | Почти никогда |
| Limited to same universe | Клиентские и серверные телепорты внутри вселенной | По умолчанию для мультиплейсовых игр без гейтинга |
| Secure within universe only | Только серверный телепорт | Платные или прогрессионные зоны, тестовые места |

- **Миф:** выключение «Direct Access» у места только убирает кнопку Join на сайте и **не** блокирует клиентские телепорты. Кик внутри subplace не мешает репликации контента.
- **Конфиденциальность:** dev- и test-места держите в **отдельной приватной вселенной**. Это единственный надёжный способ.
- Миграция на Secure:
  1. Найдите клиентские `Teleport()`.
  2. Замените их на RemoteEvent / ProximityPrompt / Touched.
  3. Сделайте серверный `TeleportAsync`.
  4. Включите Secure.

### 3.3 Стартовое место, новые места, версии

- **Новое место:** File → Publish As → игра → «Add as a new place».
- **Смена стартового места:**
  1. Сделайте бэкап.
  2. Dashboard → Places → Edit in Studio на новом месте.
  3. File → **Publish As** → та же игра → выберите текущее стартовое → Overwrite. Обычный Publish здесь **не** использовать.
  4. Рестарт серверов.
- **Version notes обязательны** при публикации. Перед большим апдейтом сохраните контрольную точку «pre-update».
- **Откат:** Window → Version History → ⋯ → Open Local Copy → Save to Roblox As. Восстановление **не публикует** автоматически: нужен publish и рестарт.
- В Team Create сначала отключите коллаборацию: активные коллабораторы могут перезаписать откат. Автосейв в Team Create каждые 4 мин (live scripts — 5 мин).

### 3.4 Рестарт серверов

- Configurations → **Server management** → выбрать места → Restart Servers.
- Всегда ставьте галочку «Restart only servers with outdated versions» и задержку **1–60 мин** (рекомендация 5–10 мин).
- Срабатывает `DataModel.ServerRestartScheduled` (`Enum.CloseReason.DeveloperUpdate`), игроки переносятся на сервера с новой версией.
- Open Cloud: `POST /cloud/v2/universes/{id}:restartServers`.
- Тёмный деплой: выпускайте контент выключенным и включайте через Configs → см. builder/liveops.md.

Источники: [Players API](https://create.roblox.com/docs/reference/engine/classes/Players); [Battle royale setup](https://create.roblox.com/docs/resources/battle-royale/installation-and-setup); [Matchmaking](https://create.roblox.com/docs/matchmaking); [Teleport](https://create.roblox.com/docs/projects/teleport); [Access control](https://create.roblox.com/docs/scripting/security/access-control); [Version History](https://create.roblox.com/docs/projects/version-history); [Release game updates](https://create.roblox.com/docs/projects/update-games); [DevForum: 1-player servers](https://devforum.roblox.com/t/roblox-is-creating-1-player-servers-over-filling-existing-ones-harming-interaction/3981365)

---

## 4. Метаданные и жанр

### 4.1 Первый publish
File → Publish → окно «Game details»: иконка, thumbnail, Name, **Genre + Subgenre**, Description → Save. При этом создаётся `UniverseID`. Новая игра **приватна** по умолчанию. Лимит: не больше 5 никогда не релизнутых игр в день.

### 4.2 Жанр
- Задаётся в Dashboard → Publish settings → Game details. **Менять можно раз в 3 месяца.**
- Roblox может переназначить неточный жанр (придёт письмо). Апелляция одна: roblox.com/support → «Experience Genre».
- Жанр питает жанровые Charts. Обновление занимает несколько дней.

| Жанр | Субжанры |
|---|---|
| Action | Battlegrounds & Fighting; Music & Rhythm; Open World Action |
| Adventure | Exploration; Scavenger Hunt; Story |
| Education | — |
| Entertainment | Music & Audio; Showcase & Hub; Video |
| Obby & platformer | Classic Obby; Runner; Tower Obby |
| Party & casual | Childhood Game; Coloring & Drawing; Minigame; Quiz |
| Puzzle | Escape Room; Match & Merge; Word |
| RPG | Action RPG; Open World & Survival RPG; Turn-based RPG |
| Roleplay & avatar sim | Animal Sim; Dress Up; Life; Morph Roleplay; Pet Care |
| Shooter | Battle Royale; Deathmatch Shooter; PvE Shooter |
| Shopping | Avatar Shopping |
| Simulation | Idle; Incremental Simulator; Physics Sim; Sandbox; Tycoon; Vehicle Sim |
| Social | — |
| Sports & racing | Racing; Sports |
| Strategy | Board & Card Games; Tower Defense |
| Survival | 1 vs All; Escape |
| Utility & other | — |

Хоррор отдельным жанром не выделен. Типичные варианты: Survival → 1 vs All / Escape (погоня в духе Granny или Piggy) или Adventure → Story (сюжетный хоррор). Выбирайте по ядру геймплея (вывод).

Legacy-энам `genre` в develop API (All, Scary, FPS, RPG…) — **старая таксономия**. Для discovery он бесполезен.

### 4.3 Name / Description
- Точные лимиты длины для игр **не опубликованы**. Безопасное правило: название ≤50 символов (на практике ≤30 из-за обрезки на плитке), описание ≤1 000 символов, хук в первых ~160.
- Структура описания: Hook (≤160) / Recent updates / Main content / Additional info (устройства, коды, FAQ). Теги и хэштеги в ранжировании не используются. Управление в описании не перечисляйте.
- **Если сохранение молча падает («Unknown»), почти всегда причина в текст-фильтре, а не в длине.** Убирайте слова по одному и повторяйте.

### 4.4 Иконка, thumbnails, видео
- Иконка: квадрат ≥512×512, модерируется. Configurations → Places → стартовое место → Icon. Одна иконка на локаль.
- Thumbnails: до 10 штук, 16:9, 1920×1080. Важное не размещайте внизу: там его перекроет счётчик игроков. **Thumbnail personalization:** держите активными 2–5 (по тестам Roblox в среднем +8.5% qualified play-through) и «не выбирайте одного победителя».
- Видео: 3 загрузки в месяц (отклонённые тоже считаются), только настоящий геймплей, без озвучки, песен со словами и рекламных обещаний. Не показываются на Xbox, PlayStation и VR.
- Подробно о дизайне → builder/packaging.md.

### 4.5 Social links
- Engagement → Social Links: до 3 ссылок, по одной на тип (Facebook, Twitter, YouTube, Twitch, Discord, Guilded, Roblox community).
- Добавлять может только age-checked 16+ креатор. Для групповой игры нужен хотя бы один такой коллаборатор, иначе через 90 дней после его ухода ссылки удаляются автоматически.
- Видны только age-checked 16+ пользователям.
- **В игре ссылки запрещены.** Можно: «Check out our social media links on our game's page». Нельзя: «Join our Discord discord.gg/…».

Источники: [Publish games and places](https://create.roblox.com/docs/production/publishing/publish-games-and-places); [Genres](https://create.roblox.com/docs/production/publishing/experience-genres); [Descriptions](https://create.roblox.com/docs/production/publishing/descriptions); [Icons](https://create.roblox.com/docs/production/publishing/experience-icons); [Thumbnails](https://create.roblox.com/docs/production/publishing/thumbnails); [Social links](https://create.roblox.com/docs/production/promotion/social-media-links); [DevForum: name won't save](https://devforum.roblox.com/t/roblox-wont-save-my-experience-name-suddenly-and-im-not-sure-why-update/2663909)

---

## 5. Владение: группа, роли, коллабораторы, передача

**Почему группа:**
- ролевые и пер-игровые права;
- регулярные % сплиты и разовые выплаты (Finances → Payouts, CSV `userId,payoutInRobux`, 2FA);
- audit log;
- общие ассеты;
- API-ключи на отдельном бот-аккаунте с минимальной ролью (Roblox это «strongly recommends»).

Кроме того, допуск в Kids/Select зависит от **владельца группы**: у него должны быть ID-верификация и 2FA. Учтите, что в конфликтах внутри группы Roblox не арбитр.

**Роли (рекомендация):**

| Роль | Права |
|---|---|
| Owner | Всё. Аккаунт максимально защищён |
| Admin | Publish + Monetization manager |
| Developer | Edit all games |
| Tester | Play |
| Analyst | Analytics |
| Moderator | Bans manager (читает игровой чат, только 18+) |
| Bot | Минимум под API-ключи |

**Коллабораторы:**
- Уровни Owner / Edit / Play / No Access.
- В личной игре Edit можно выдать только друзьям.
- Team Create требует age check и совместимых возрастных диапазонов (13–15 с 9–17; 16–17 с 13+; 18+ с 16+). Диагностика: Safety → Collaborators.

**Передача в группу** (Game details → Initiate ownership transfer):
- Запрос живёт 7 дней, повторная передача возможна через 30 дней.
- ID и URL сохраняются.
- Приватные ModuleScript, InsertService-ассеты и личные пакеты нужно перезалить в группу.
- Доход от текущих подписок на private servers уходит группе без сплитов.
- **Публичный доступ снимается, сервера закрываются, нужен повторный релиз, discovery проседает до 24 ч.**
- Вывод: создавайте группу до первого publish.

Источники: [Groups](https://create.roblox.com/docs/projects/groups); [Collaboration](https://create.roblox.com/docs/projects/collaboration); [Ownership transfer](https://create.roblox.com/docs/projects/game-ownership-transfer); [API keys](https://create.roblox.com/docs/cloud/auth/api-keys)

---

## 6. Релиз: private → questionnaire → 16+ → Kids/Select

### 6.1 Поток релиза
1. **Private** (по умолчанию): играют только создатель, коллабораторы с Edit и разрешённые роли группы.
2. **Early testers:** File → Invite early testers, до 10 друзей схожего возраста или trusted friends. Они видят preview-watermark. Manage Audience → вкладка Playtest.
3. **Первый вопрос questionnaire** (есть ли age-restricted контент?):
   - **No** → лейбл «Content May Vary», доступ только для age-checked 16+.
   - Полностью заполненный questionnaire с результатом Minimal / Mild / Moderate открывает таргетинг на все возрасты.
4. **Public:** Publish settings → Manage Audience → вкладка Public. Тумблер «Friends» = только для друзей. Advanced Settings → «Exclude from recommendations» опционален.
5. **Evaluation для Kids/Select** идёт автоматически (§6.3), прогресс виден на Audience → Reach.

**Требования применяются ко ВСЕМ release-действиям, включая апдейты и смену аудитории.** Если владелец потерял статус (например, кончился Plus и нет сбора), всеаудиторный апдейт не пройдёт. Сама игра при истечении подписки остаётся live.

### 6.2 Требования

| Аудитория | Требования к аккаунту владельца | Требования к игре |
|---|---|---|
| 16+ и Trusted Friends | Хорошая репутация, аккаунт ≥2 дней, age check | Ответ на первый вопрос |
| Все возрасты (Kids 5–8, Select 9–15) | Всё выше + верификация (face, если <18; гос. ID, если 18+) + **2FA** + **Plus/Premium 2 месяца подряд ИЛИ возвратный сбор 1 000 R$** | Полный questionnaire с Minimal/Mild/Moderate + evaluation |

| Тир аккаунта | Видит контент |
|---|---|
| Roblox Kids (5–8) | Minimal, Mild. Чат выключен по умолчанию |
| Roblox Select (9–15) | Minimal, Mild, Moderate. Чат вводится постепенно после age check |
| Roblox (16+ age-checked) | Всё, кроме Restricted |
| Restricted | Только 18+ ID-verified. Недоступно в Корее, Саудовской Аравии, Турции и др. |

### 6.3 Evaluation, сборы и их история

**Текущие правила (HEAD доков, окт. 2026):**
- **250 уникальных plays от «highly engaged» age-checked 16+ игроков за 60 дней.** Проверка ежечасно. «Highly engaged» = стаж аккаунта + время в вашей игре + любая покупка Robux на платформе за последние 60 дней. Плюс safety review.
- **Порог поддержания** для уже допущенных игр: 25 игроков.
- **Сбор 1 000 R$** платится в Audience → Reach. Его заменяет Plus/Premium 2 месяца подряд.
- **Expedited review: 50 000 R$**, ревью за 48 ч (при повторной подаче отсчёт начинается заново). Возврат **по запросу** через 90 дней, если игра держит 25 highly engaged игроков. Можно оставить, чтобы сохранять допуск.

| Дата | Изменение |
|---|---|
| 19.05.2026 | Введено требование сбора или подписки (пилот NZ, NL, AU, ID) |
| Июнь 2026 | Глобальный запуск: 500 plays за 60 дней; expedited 100 000 R$ |
| 16.07.2026 | Порог поддержания 100 → 25 |
| 20.08.2026 | **Порог допуска 500 → 250**; условие возврата сбора 100 → 25 игроков |
| 12.09.2026 | **Expedited 100 000 → 50 000 R$** |

**Возврат 1 000 R$.** Две страницы доков описывают его по-разному:
- «25 highly engaged игроков 60 дней без модерации» (Publishing);
- «автоматически через 90 дней после допуска, а если допуск так и не получен — через 90 дней после оплаты; исключение — перманентное удаление игры» (FAQ Kids and Select).

**Правило агента:** считайте сбор депозитом на 60–90 дней, а не расходом. Риск потерять его есть только при перманентном удалении игры.

**Бесплатный Plus для креаторов.** Около 100 000 креаторов получили 6 месяцев Plus (май 2026), что засчитывается вместо сбора. Проверка: зелёный баннер в publishing permissions. Критерии отбора не публичны. Истекает **примерно в ноябре 2026**, после этого нужен платный Plus ($4.99/мес) 2 месяца подряд или сбор. **Перед оплатой сбора всегда проверяйте баннер.**

### 6.4 Questionnaire (Publish settings → Content rating)
- Категории: violence, blood, fear, crude humor, unplayable gambling, strong language, romantic themes, alcohol, social hangout, free-form user creation, sensitive issues, paid random items, paid item trading, media, AI interaction.
- Отвечайте по **самому экстремальному** контенту в игре. **Переотправляйте** после апдейтов, меняющих ответы. Искажение ведёт к модерации.
- Social hangout → 16+ (с приватными пространствами 18+). Свободное рисование → 16+. Strong language, романтика, алкоголь → 18+.
- Paid random items и trading: раскрыть в questionnaire и гейтить через `PolicyService` (`ArePaidRandomItemsRestricted`, `IsPaidItemTradingAllowed`).
- Хоррор (вывод): jump-scares обычно дают **Mild**, реалистичная кровь — **Moderate**, что исключает Roblox Kids. Если цель — самая широкая аудитория, дозируйте кровь.
- Детали рейтингов и правил → builder/compliance.md.

**Типовой путь all-ages игры (вывод):**
1. Полный честный questionnaire с целью Minimal/Mild.
2. ID и 2FA у владельца (группы).
3. Проверка бесплатного Plus, иначе Plus или сбор.
4. Релиз на 16+.
5. Набор 250 engaged plays за 60 дней (документированный рычаг — реклама, → см. advisor/discovery-growth.md).
6. Expedited 50k платить только под жёсткую дату запуска.

Источники: [Publish games and places](https://create.roblox.com/docs/production/publishing/publish-games-and-places); [Kids and Select](https://create.roblox.com/docs/production/publishing/kids-and-select); [Content maturity](https://create.roblox.com/docs/production/promotion/content-maturity); [DevForum: Alternate Publishing Requirements](https://devforum.roblox.com/t/alternate-publishing-requirements-for-roblox-kids-and-select/4630944); [DevForum: Kids/Select global launch](https://devforum.roblox.com/t/roblox-kids-and-select-global-launch-upcoming-updates-to-eligibility-ads-manager-and-expedited-review/4685717); [Introducing Roblox Plus](https://about.roblox.com/en-au/newsroom/2026/04/introducing-roblox-plus-subscription)

---

## 7. Монетизационные объекты пошагово

Зачем и по какой цене продавать → advisor/monetization.md. Код покупок (`ProcessReceipt`, идемпотентность) → builder/code-architecture.md. Здесь только конфигурация.

### 7.0 Сводка лимитов

| Объект | Где | Лимиты цены и прочее |
|---|---|---|
| Game Pass | Monetization → Passes | Исторически 1–1 000 000 000 R$ (из дока убрано 06.10.2026, в API `price` int64 без границ). Цена по умолчанию на странице **Sales** паса. Для Buy-Robux-промо: >49 и <801 R$ |
| Developer Product | Monetization → Developer Products | 1 R$ – 1 млрд R$. Цена на **Basic Settings**. Удалить нельзя, только снять с продажи |
| Subscription | Monetization → Subscriptions | Robux: ≥49 R$. Local currency: $2.99 / 4.99 / 7.99 / 9.99 / 14.99. Максимум 50 на игру |
| Private server | Audience → Access Settings | Смена цены **отменяет все активные подписки** |
| Paid access (Robux) | Audience → Access Settings → Payment | 25–1 000 R$ |
| Paid access (local) | там же | $9.99 / $29.99 / $49.99 |
| Regional/managed price | Managed Pricing | 30–100% от цены по умолчанию (не выше её) |
| Plus-скидка | автоматически | Не применяется к предметам дороже 1 000 000 R$ |

### 7.1 Game Pass (одноразовая покупка)
1. Игра должна быть опубликована.
2. Monetization → **Passes** → Create pass.
3. Иконка: ≤512×512, **круглая обрезка**, .jpg/.png/.bmp. Своя иконка на каждый пасс, иначе Roblox покажет дефолтную.
4. Name + Description → **категория** (организует внутриигровой Shop) → Create.
5. Откройте пасс → **Sales** → цена по умолчанию. Пассы теперь всегда Listed: тумблер «Item for Sale» убран 06.10.2026.
6. ⋯ → Copy Asset ID → в config.
7. Код: `UserOwnsGamePassAsync` на PlayerAdded + серверная обработка `PromptGamePassPurchaseFinished`. Историю покупок по пользователю Roblox не хранит.
8. **Buy Robux bonus pool:** отдельный уникальный пасс, 50–800 R$, с thumbnail, не рандомный.

### 7.2 Developer Product (повторяемая покупка)
1. Monetization → **Developer Products** → Create developer product.
2. Иконка ≤512×512 → Name / Description → категория → цена (1 R$ – 1 млрд) → Save.
3. **Только `ProcessReceipt`**: вернуть `PurchaseGranted` после фактической выдачи. `PromptProductPurchaseFinished` для выдачи не использовать.
4. **Listed** продукты продаются вне игры (главная, поиск, страница после покупки Robux). Включайте Listed **только после проверки ProcessReceipt**. Roblox аудирует обработчики, и продукты с флагом снимаются с внешних поверхностей до «Mark as fixed» (баннер в Monetization → Shop).
5. Старые инструкции про «test mode / External Purchase Settings» **устарели** (убраны в окт. 2026).

### 7.3 Subscription
1. Monetization → **Subscriptions** → Create Subscription.
2. Cover image, **уникальное имя (нельзя изменить)**, description (≤1 000 символов, эмодзи можно), payment type, **product type: Durable / Consumable / Currency (нельзя изменить)**.
3. Активация требует **постоянного «shortened game name»**. Выбирайте его один раз и навсегда.

| | Robux | Local currency |
|---|---|---|
| Цена | ≥49 R$, regional pricing принудительно ON | $2.99 / 4.99 / 7.99 / 9.99 / 14.99 |
| Выплата | 70% ежемесячно | 70% в 1-й месяц, далее 100%, hold 30 дней |
| Смена цены | Раз в 60 дней; о повышении предупреждение за 30 дней | Нельзя |
| Ограничения | — | Нужна ID или телефонная верификация. Недоступно в AR, CN, CO, IN, ID, JP, RU, TW, TR, UAE, UA, VN |

- **Россия в списке недоступных для local-currency подписок.** Для русскоязычной аудитории используйте Robux-подписки.
- Взаимоисключающих тиров нет, кросс-селла и affiliate тоже. Есть вебхуки на события подписки.
- Названия короткие и самоописательные, цена и срок видны. Держите 1–3 подписки (VIP-формат).

### 7.4 Private servers
1. Игра должна быть публичной.
2. Audience → **Access Settings** → Allow private servers → Requires Robux (цена) или бесплатно → Save.
3. Несовместимо с paid access.
4. **Цену выставляйте один раз**: любое изменение отменяет все активные подписки.
5. Plus-подписчики получают платные private servers бесплатно. Игра получает до **100 R$ на подписчика** за квалифицирующий сервер: ≥60 мин суммарно за 30 дней, сервер в топ-5 подписчика, 70% цены с потолком 100. Отсюда цена **100–150 R$**: потолок достигается при ≥143 R$ (вывод).
6. Через Open Cloud это поле `privateServerPriceRobux`. Если оно не задано, private servers выключены.

### 7.5 Paid access
- **Robux:** 25–1 000 R$. Нужны verified email и аккаунт ≥30 дней. Не работает на Xbox, escrow до 7 дней, возвратов нет. Автоматически выключает копирование и требует публичной игры без private servers.
- **Local currency:** $9.99 / 29.99 / 49.99, нужны ID, 13+ и Tipalti. Покупка только на desktop/web. Есть **Demo Mode**: не купившие могут зайти, контент гейтится через `PlayerOwnsAssetAsync(player, game.PlaceId)`, у переключения есть кулдаун.
- По умолчанию **OFF**. Отклоняться только для закрытой беты или премиум-продукта.

### 7.6 Shop, Managed Pricing, Plus, Ads
- **Shop** (Monetization → Shop): вкладки Overview и Item catalog, изменения требуют Save. Категории предлагаются автоматически и редактируются. Пассы всегда Listed, продукты Listed или Unlisted (Unlisted продаются только через ваши промпты). **Global Shop button OFF по умолчанию → включить.**
- **Managed Pricing** (regional pricing + price optimization): новые игры и предметы включены по умолчанию. При opt-in сначала подсвечиваются захардкоженные цены. Подписки и private servers регионализируются автоматически.
  - В UI цены брать из `GetProductInfoAsync` / `GetDeveloperProductsAsync`.
  - Подарки и трейды защищать от арбитража через `GetUsersPriceLevelsAsync`.
  - Проверка: Dynamic Price Check, до 5 тест-аккаунтов.
- **Roblox Plus** (Monetization → Roblox Plus):
  - скидка подписчикам 10%, с 3-го месяца 20%; субсидирует Roblox, креатор получает свои 70%;
  - `PromptRobloxSubscriptionPurchase` даёт **250 R$/мес × 3** за нового подписчика из игры (hold 60 дней);
  - захардкоженные цены покажут Plus-игрокам неверную сумму.
- **Rewarded video ads** (Monetization → Ads → Settings → Rewarded Video → Serving enabled → выбрать dev product как награду):
  - Допуск: 13+, ID, публичная игра, **≥2 000 уникальных посетителей в месяц**.
  - Награда эквивалентна 3–10 R$, без рандома. «Exclude likely spenders» включать только если награду можно и купить.
  - Код: `GetAdAvailabilityNowAsync` → `CreateAdRewardFromDevProductId` + `ShowRewardedVideoAdAsync`, выдача в `ProcessReceipt`.
- **Paid random items:** шансы в процентах с суммой ровно 100% + гейт `PolicyService` → builder/compliance.md.

Источники: [Passes](https://create.roblox.com/docs/production/monetization/passes); [Developer products](https://create.roblox.com/docs/production/monetization/developer-products); [Subscriptions](https://create.roblox.com/docs/production/monetization/subscriptions); [Private servers](https://create.roblox.com/docs/production/monetization/private-servers); [Paid access Robux](https://create.roblox.com/docs/production/monetization/paid-access-robux); [Paid access local currency](https://create.roblox.com/docs/production/monetization/paid-access-local-currency); [Shop](https://create.roblox.com/docs/production/monetization/shop); [Managed pricing](https://create.roblox.com/docs/production/monetization/managed-pricing); [Regional pricing](https://create.roblox.com/docs/production/monetization/regional-pricing); [Roblox Plus](https://create.roblox.com/docs/production/monetization/roblox-plus); [Rewarded video ads](https://create.roblox.com/docs/production/promotion/rewarded-video-ads)

---

## 8. Бейджи

### 8.1 Создание и лимиты
1. Dashboard: наведите на игру → ⋯ → **Create Badge** (управление: Engagement → Badges).
2. Иконка по шаблону 512×512 с **круглой обрезкой**, Name, Description (**как именно получить**), «Badge is Enabled». Выключенный бейдж скрыт и не выдаётся.
3. **5 бесплатных в сутки на игру** (24 ч по GMT), каждый следующий стоит **100 R$**. Остаток квоты: `GET /v1/universes/{universeId}/free-badges-quota` (UTC-день).
4. Порядок меняется пачками до 50 штук.
5. Названия и описания бейджей ATC не захватывает. Их локализуют на вкладке Products в Translator Portal.

**Код:**
- `AwardBadgeAsync` срабатывает, только если: игрок в игре, бейджа у него нет, вызов с сервера, из места этой игры, бейдж включён. Лимит **50 + 35 × игроков в минуту**.
- `UserHasBadgeAsync` / `CheckUserBadgesAsync`: **10 + 5 × игроков в минуту на сервер**. `CheckUserBadgesAsync` проверяет до 10 ID за вызов, его и используйте на входе.
- **Игрок может удалить бейдж и получить его снова.** Владение бейджем — не ключ против повторной выдачи наград. Для этого нужен флаг в DataStore.
- Оборачивайте вызовы в pcall и никогда не выдавайте бейдж по клиентскому remote без серверной валидации.
- `GetBadgeInfoAsync` возвращает IsEnabled, AwardCount, PastDayAwardCount и **Rarity** (0–1). Rarity видна на странице игры, и игроки читают её как сложность («Impossible», «Insane»).

### 8.2 План бейджей (шаблон, вывод)

| День | Бейджи (5 бесплатных) |
|---|---|
| 1 | 1) «Welcome!» за вход (~100%); 2) первая веха core loop (~5 мин); 3) средняя веха (~1 ч); 4) социальный («Played with a friend» / «Invited a friend»); 5) сложный скилловый («Impossible») |
| 2–7 | По 5 в день: завершение зон, коллекция 100%, ивентовые, «Met the developer» (ограничен по времени) |

- **Порядок:** по прогрессии, затем ивентовые, затем секретные и сложные в конце.
- **Имена** из 2–3 слов. **Иконки** в единой рамке, цвет по тиру (bronze/silver/gold), чтобы сетка на странице читалась как набор.
- **Не делать:** бейджи за покупки (выглядит как pay-to-badge), десятки тривиальных бейджей (обесценивают редкость).
- Бейджи используются и в официальных механиках: награды ивентов, реферальные награды, payload в `ExperienceInviteOptions` → см. builder/liveops.md.

Источники: [Badges](https://create.roblox.com/docs/production/publishing/badges); [BadgeService API](https://create.roblox.com/docs/reference/engine/classes/BadgeService); [Quest design](https://create.roblox.com/docs/production/game-design/introduction-to-quest-design)

---

## 9. Шаблон каталога магазина

### 9.1 Официальные правила
- Каждому пассу или продукту нужны своя иконка (пасс — круглая обрезка) и **категория Shop**.
- У каждого предмета очевидная польза. Пример из доков — фонарик в Doors: сразу понятно, чем он помогает. Предметы бывают durable или consumable, enhancement или expression.
- Магазин интегрированный, контекстный, приглашающий. Дефицитную функциональность объясняйте прямо в магазине (пример — Revives в Doors).
- **Starter pack не показывайте на первом экране загрузки.** Уместен со 2-й сессии.
- **Формулировки для детей:** не «GET IT NOW» / «LAST CHANCE» / «BUY BEFORE IT'S GONE!», а «View Item», «See Price», «Open Shop». Никакого ложного дефицита и перезапускающихся таймеров.
- Порядок в своём UI: `RankProductsAsync` (один раз на входе, жёсткий rate limit) или `RecommendTopProductsAsync` (до 50 предметов, пустой список, если за 28 дней не было продаж). В Roblox Shop порядок определяет сам Roblox.

### 9.2 Шаблон для типичного симулятора (вывод; обоснование цен → advisor/monetization.md)

| Категория (в этом порядке) | Тип | Примеры (имя = польза, ≤3 слов) | Цена R$ |
|---|---|---|---|
| ⭐ Featured / Starter | Product (одноразовость через флаг в DataStore) | «Starter Pack» (со 2-й сессии) | 49–99 |
| Boosts | Pass (durable enhancement) | «2x Coins», «2x Speed», «Auto Collect», «+1 Pet Slot», «Lucky» | 99–499 |
| VIP | Pass и/или подписка | «VIP» (чат-тег, VIP-зона, +10% монет); подписка «VIP Monthly» | 199–499 pass; ≥49 R$ или $4.99 подписка |
| Currency | Products (consumable) | Small / Medium / Large / Huge Coin Pack, каждый следующий +15–25% бонуса за R$ | 25 / 99 / 399 / 999 |
| Consumables | Products | «Revive», «Skip Stage», «1h Luck Boost» | 15–75 |
| Cosmetics (expression) | Passes / products | «Golden Trail», «Neon Pet Skin» | 49–299 |
| Support the dev | Products | «Tip 10 / 50 / 250» + supporter-тег | 10–250 |
| Private server | Access setting | — | 100–150 |
| Buy-Robux промо | Отдельный уникальный pass | Лучший «оффер» игры | 50–800 |

**Иконки (вывод, совместимо с круглой обрезкой):**
- единая визуальная система: та же рамка, тот же свет, объект по центру в круге ~400 px;
- польза кодируется крупной цифрой или символом («2x», часы), а не мелким текстом: при 150 px он нечитаем;
- цвет по категории: золото = VIP, зелёный = валюта, синий = бусты;
- иконки с текстом локализуются (`legacy-game-internationalization …/icons` для passes и products).

### 9.3 Вариант для хоррора (пример)
- **Passes:** «Flashlight+», «Extra Battery Slot» (enhancement в стиле Doors), «Spectator Cam», «VIP Lobby».
- **Products:** «Revive» (контекстный промпт при смерти, **не раньше первой смерти**), «Skip Level» (только после 3 неудачных попыток).
- **Cosmetics:** «Lantern Skin».
- **Не продавать** урон или скорость в co-op хорроре: это ломает кривую напряжения.

Источники: [Passes](https://create.roblox.com/docs/production/monetization/passes); [Shop](https://create.roblox.com/docs/production/monetization/shop); [Monetization foundations](https://create.roblox.com/docs/production/game-design/monetization-foundations); [Contextual purchases](https://create.roblox.com/docs/production/game-design/contextual-purchases); [Monetization](https://create.roblox.com/docs/production/monetization)

---

## 10. Донаты в 2026

**Что изменилось.** Transfers API запущен 04.05.2026. **29.05.2026** (в баннере доков указано «May 30») отключены cross-game продажи passes и products, то есть продажи вне родной игры и её страницы. На этом держались будки PLS DONATE. Причина по словам Roblox: «To protect players on our platform from fraud and exploitation». Продажи аватарных предметов изменение не затронуло.

| Цель | Механизм | Сколько получаете | Кто может платить | Правила |
|---|---|---|---|---|
| Игроки дают чаевые **разработчику** (tip jar) | Developer products «Support the dev»: 10 / 25 / 50 / 100 / 250 / 1 000 R$ | 70% (Plus-скидку субсидирует Roblox) | Любой с Robux | Должен давать что-то реальное (тег, титул, место в лидерборде, бейдж), иначе вводит в заблуждение. Выдача в `ProcessReceipt`. Можно Listed |
| Игроки дарят **друг другу** (PLS DONATE-стиль) | `MarketplaceService:PromptRobuxTransferAsync(sender, receiverUserId, amount)`, только с сервера | **10%** каждого перевода (DevEx-eligible) | **Только подписчики Roblox Plus** | 10–500 R$ за транзакцию. Получатель получает 90%, **они НЕ DevEx-eligible**: не обещайте «вывод» |
| Платить **коллабораторам** | Group Payouts | — | Средства группы | 0% комиссии, 100% получателю, DevEx-eligible. Transfers не для зарплат |

**Лимиты отправителя (официальные, DevForum):**
- Базовые: **500 R$/день, 1 000 R$/месяц** (Roblox говорит, что их хватает примерно 95% бывших пользователей cross-game продаж).
- С **2-Step Verification** и хорошей репутацией (с 20.05.2026): **5 000 R$/день, 10 000 R$/месяц**. Требования к верхнему тиру сообщество называет неясными, так что «2SV + good standing» — необходимое, но, возможно, недостаточное условие.
- 18+ отправители и получатели проходят age check. С **02.06.2026 перевод без родительского одобрения доступен с 16 лет** в большинстве регионов (в части регионов с 18). Младшим нужны привязанный родитель и одобрение каждого перевода.
- Запланированы (статус на окт. 2026 не подтверждён): кастомные лимиты от родителей (осень 2026) и Trusted Friends с разовым одобрением.

**Код и UX:**
- Чеки через `BindReceiptHandler` с `Enum.ReceiptType.RobuxTransferSender` / `RobuxTransferReceiver`, ответ `Enum.ReceiptDecision.Processed` или `NotProcessedYet`.
- Чек приходит на тот сервер, где игрок находится, когда перевод завершится. Офлайн-получатель получит его при следующем заходе. При родительском одобрении **оба чека задерживаются**.
- Значит, награда «спасибо» должна быть **идемпотентной по `TransferRequestId`** и терпеть долгие задержки.
- Сумма фиксируется, как только открылось окно перевода. До этого UI может предлагать кнопки, слайдер или ввод.
- Перед промптом показывайте «для отправки нужен Roblox Plus».
- **Никогда** не стройте донаты на cross-game passes или products: они больше не продаются.

Источники: [Robux transfers](https://create.roblox.com/docs/production/monetization/robux-transfers); [DevForum: Disabling Cross-Game Sales… Transfers API](https://devforum.roblox.com/t/disabling-cross-game-sales-of-passes-and-dev-products-and-introducing-the-transfers-api/4618396); [DevForum: Update on Roblox Plus, Transfers, and Community Gifting](https://devforum.roblox.com/t/update-on-roblox-plus-transfers-and-community-gifting/4637912); [DevForum: higher limit requirements unclear](https://devforum.roblox.com/t/higher-robux-transfer-limit-requirements-are-still-unclear/4848664); [Groups/Payouts](https://create.roblox.com/docs/projects/groups)

---

## 11. Локализация, уведомления, API keys

**Локализация** (Audience → Localization):
- Settings: source language, «Capture text from experience UI while users play» ON, «Use Translated Content» ON. Languages: автоперевод «Experience Information» и «Experience Strings & Products» по языкам.
- ATC захватывает UI с `AutoLocalize`, из Studio строки приходят за 1–2 мин. Автоочистка устаревших строк включена по умолчанию.
- Автоперевод заполняет только пустые записи. Квота: начальная + ежемесячная, считается как символы × языки («hello» на 10 языков = 50). Конкретные числа видны только в UI.
- ATC **не захватывает**: стандартные лидерборды и чат, собственные tools, текст на картинках, имена бейджей и пассов. Их переводят вручную на вкладке Products.
- Локализованные name, description, иконку и до 10 thumbnails задают в Translator Portal → язык → Information.
- Правило: строки короткие и параметризованные (`{count} coins`), динамический и пользовательский текст исключён из ATC. Подробно → builder/packaging.md.

**Experience notifications:**
- Нужны ≥100 визитов, отсутствие модерации и права manage.
- Строки создаются **только в Dashboard** (Engagement → Notifications, ≤99 символов, параметры, `{experienceName}`), а отправка автоматизируется (`POST /cloud/v2/users/{id}/notifications` или пакет OpenCloud в ServerScriptService).
- Лимит: 1 уведомление на пользователя в день на игру, launchData ≤200 байт.
- Opt-in: `ExperienceNotificationService:CanPromptOptInAsync` → `PromptOptIn`. Показывается только 13+ и не чаще раза в 30 дней.
- Без dark patterns и без гейтинга геймплея за opt-in.

**Updates / Events** (Engagement): анонс апдейта ≤60 символов, раз в 3 дня; не больше 10 событий; «Submit for Featuring» за ≥7 дней; Trending Events от 1 000 RSVP → builder/liveops.md.

**Analytics:** включена по умолчанию. Добавьте custom, economy и funnel события → builder/liveops.md.

**API keys** (Creator Dashboard → API Keys / Credentials):
- Создаёт человек: name, API system, **Restrict by Experience**, операции (scopes), опционально IP CIDR и срок.
- Права ключа = права владельца. Ключ **истекает после 60 дней без использования**.
- Ключи, которые используются с серверов Roblox, не ограничивайте по IP. Храните ключи в Secrets Store.
- Выдавайте ключ бот-аккаунту в группе.

Источники: [Automatic translation](https://create.roblox.com/docs/production/localization/automatic-translations); [Add translations](https://create.roblox.com/docs/production/localization/add-translations); [Experience notifications](https://create.roblox.com/docs/production/promotion/experience-notifications); [Experience events](https://create.roblox.com/docs/production/promotion/experience-events); [API keys](https://create.roblox.com/docs/cloud/auth/api-keys)

---

## 12. Автоматизация: Open Cloud vs только Dashboard vs только Studio

Схема работы (вывод): **человек один раз создаёт оболочку.** Первый publish делается в Studio (создаёт universe), рядом создаётся приватная DEV-вселенная, ID копируются в `.env`. Дальше агент публикует, настраивает, создаёт пассы и продукты, загружает иконки и гоняет тесты через API. Для ручных шагов агент готовит «click sheet» (`release/HUMAN_STEPS.md`) с заранее заполненными ответами. Настройка CI → builder/project-setup.md.

### 12.1 Можно через Open Cloud (API key)

| Действие | Эндпоинт | Scope | Лимит / стабильность |
|---|---|---|---|
| Публикация .rbxl/.rbxlx в **существующее** место | `POST /universes/v1/{u}/places/{p}/versions?versionType=Published` (или `Saved`) | `universe-places:write` | 30/мин, BETA. Не обновляет EditableImage/Mesh, PartOperation, SurfaceAppearance, BaseWrap: после их правки публикуйте из Studio |
| Name / description / **serverSize** места | `PATCH /cloud/v2/universes/{u}/places/{p}` | `universe.place:write` | 100/мин, STABLE. 409, если место открыто в Team Create. Name/description игры меняются через root place |
| Устройства, голос, цена private server, соцссылки | `PATCH /cloud/v2/universes/{u}` | `universe:write` | 100/мин, STABLE. `visibility` и `ageRating` **только для чтения** |
| Activate / deactivate universe | `POST /legacy-develop/v1/universes/{id}/activate\|deactivate` | `legacy-universe:manage` | EXPERIMENTAL |
| Рестарт серверов | `POST /cloud/v2/universes/{id}:restartServers` | `universe:write` | 30/мин |
| Game passes create/update | `POST /game-passes/v1/universes/{u}/game-passes` (name, description, imageFile, isForSale, price, isManagedPricingEnabled) | `game-pass:write` | 5/сек, BETA |
| Developer products create/update | `POST /developer-products/v2/universes/{u}/developer-products` | `developer-product:write` | 3/сек, BETA |
| Бейджи | `POST /legacy-badges/v1/universes/{u}/badges`; `PATCH /legacy-badges/v1/badges/{id}` | `legacy-universe.badge:manage-and-spend-robux` | 100/мин, EXPERIMENTAL. **Тратит Robux** после 5 бесплатных |
| Иконка, thumbnails (+alt-text, порядок, удаление) по языкам | `legacy-game-internationalization/v1/game-icon…`, `…/game-thumbnails…` | `legacy-universe:manage` | 100/мин, EXPERIMENTAL |
| Локализованные имена, описания и иконки passes/products/badges | legacy-game-internationalization | `legacy-universe:manage` | EXPERIMENTAL |
| Таблицы локализации, перевод | `legacy-localization-tables`; `:translateText` | `legacy-universe:manage` | translateText 10 000/мин, BETA |
| Отправка уведомлений | `POST /cloud/v2/users/{id}/notifications` | `user.user-notification:write` | 4 000/сек |
| Configs и experiments | creator-configs-public-api | `universe:read/write` | Publish конфига 10/мин |
| Баны | user-restrictions | `universe.user-restriction:read/write` | — |
| Luau Execution (облачные тесты) | `…/luau-execution-session-tasks` | `universe.place.luau-execution-session:write` | 5/мин на создание, ≤10 незавершённых на место |
| DataStores, MemoryStore, Messaging, Secrets | `cloud/v2/universes/{u}/…` | `universe-datastores.*`, `universe.secret:*` и др. | — |

Лимиты суммируются по **владельцу** ключа. На 429 повторяйте с `retry-after` или экспоненциальным backoff.

### 12.2 Только Dashboard или браузер (человек)
- Создание universe и place (публичного эндпоинта нет) и первый publish.
- **Maturity & Compliance questionnaire**.
- **Релиз / аудитория** (Manage Audience, Friends-only), Access Control for Places, server fill (`socialSlotType`), copy-доступ.
- **Жанр / субжанр**.
- Оплата сбора 1 000 R$ и expedited 50 000 R$, Plus.
- **Подписки** (эндпоинта создания нет), листинг в **Shop** и тумблер Shop button, Managed Pricing opt-in, rewarded ads.
- Private servers ON/OFF (цену можно задать через API), paid access.
- Строки уведомлений, видео-thumbnails, Events/Updates.
- Роли группы, коллабораторы, Payouts, DevEx и налоги, создание API-ключей.
- Age check, ID, 2FA.

### 12.3 Только Studio
- Security-тумблеры (HTTP, API Services, Third Party Sales/Teleports, Mesh/Image APIs) и `LoadStringEnabled`.
- **Avatar Settings**, **World tab**, Drafts Mode.
- Свойства Workspace / Lighting / StarterPlayer (через Rojo-файлы они тоже задаются, кроме `HttpEnabled`; террейн и CSG — бинарные данные).
- Publish мест с EditableImage/Mesh, SurfaceAppearance, BaseWrap, PartOperation.
- Работа в Studio через MCP → builder/mcp-studio.md.

### 12.4 Минимальный набор scopes для агентского ключа
`universe-places:write`, `universe.place:write`, `universe:read/write`, `universe.place.luau-execution-session:write`, `game-pass:read/write`, `developer-product:read/write`, `legacy-universe:manage`, `legacy-universe.badge:manage-and-spend-robux` (только если разрешено тратить Robux), `universe-messaging-service:publish`, `user.user-notification:write`, `asset:read/write`, `universe-datastores.*` (для поддержки только на чтение).

Ключ ограничен одной вселенной (Restrict by Experience) и выдан бот-аккаунту группы.

Источники: [Open Cloud reference](https://create.roblox.com/docs/cloud); [Scopes](https://create.roblox.com/docs/cloud/reference/scopes); [Place publishing guide](https://create.roblox.com/docs/cloud/guides/usage-place-publishing); [Rate limits](https://create.roblox.com/docs/cloud/reference/rate-limits); [Experience notifications (Open Cloud)](https://create.roblox.com/docs/cloud/guides/experience-notifications)

---

## 13. Pre-publish чек-лист

[A] выполняет агент (код или API), [H] человек (UI).

**Аккаунт и владение**
1. [H] Группа создана (100 R$). У владельца: ID (face, если <18), 2FA, аккаунт ≥2 дней. Проверен зелёный баннер бесплатного Plus, иначе решение: Plus 2 месяца или депозит 1 000 R$ (дата записана).
2. [H] Роли Owner / Admin / Dev / Tester / Analyst / Moderator, бот-аккаунт, API-ключ с минимальными scopes, ограниченный вселенной.
3. [H] Отдельная **приватная DEV-вселенная**. Studio Access to API Services ON только в ней.

**Studio до первого publish**
4. [A/H] Avatar Settings: **R15** (не «R15 & R6»), preset по жанру (§2.9), Collision по жанру.
5. [A] Workspace: StreamingEnabled ON, Improved / PauseOutsideLoadedArea / Opportunistic, 64/1024, SignalBehavior Deferred, EnableSLIMAvatars Enabled, RejectCharacterDeletions Default.
6. [A] Lighting: LightingStyle и PrioritizeLightingQuality выбраны.
7. [A/H] World: значения движения зафиксированы в config-модуле (обби: **до** постройки уровней).
8. [A] **Аудит чата:** нет `ChatScript` / `ChatServiceRunner` из старых free models, используется TextChatService. Если префиксы не нужны, `PlatformIntegratedChat = Enabled`. Текст вне чата фильтруется через `GetNonChatStringFor…Async`.
9. [A] `LoadStringEnabled = false`. Security: всё OFF, кроме нужного.

**Первый publish и метаданные**
10. [H] File → Publish **в группу**: name (стабильное, ≤50, лучше ≤30), **жанр/субжанр (блок на 3 месяца)**, описание с хуком ≤160, иконка 512×512, thumbnails 1920×1080.
11. [H] Communication: голос ON для social / co-op / хоррора при max ≤100.
12. [H] Places: max players (тайкун = число плотов), Server Fill (§3.1), Access Control for Places (Secure при гейтинге subplaces), копирование запрещено.
13. [A/H] 3–5 thumbnails активны, personalization включена, есть 1 видео (квота 3 в месяц).

**Монетизация**
14. [A] Passes и products созданы (API или UI): кастомные иконки (круглая safe-зона), имена «польза-first», категории Shop, ID в config.
15. [A] Цены не захардкожены, используется `GetProductInfoAsync`. [H] Пройден Dynamic Price Check.
16. [A] `ProcessReceipt` идемпотентен и протестирован. [H] Products переведены в Listed только после этого. **Global Shop button ON.**
17. [H] Private servers: цена выставлена один раз (100–150 R$). Paid access OFF.
18. [H] Подписки только после выбора постоянного shortened game name.
19. [A] Донаты: tip-jar products. Для transfers показывается текст «нужен Plus» до промпта, награда идемпотентна по `TransferRequestId`.
20. [H] Отдельный Buy-Robux pass за 50–800 R$ (опционально).

**Прочее**
21. [A/H] 5 бейджей дня 1 по плану §8.2, проверка через `CheckUserBadgesAsync` на входе.
22. [H] Локализация: source language, ATC ON, Translated Content ON, автоперевод топ-языков.
23. [A] PolicyService-гейты (random items, trading, ads), UI с шансами при наличии.
24. [H] **Questionnaire заполнен полностью** по самому жёсткому контенту.
25. [H] Social links (нужен 16+ verified), в игре ссылок нет.
26. [H] 1–3 строки уведомлений созданы (отправка начнётся после 100 визитов).
27. [A] Analytics: custom, economy и funnel события.
28. [A/H] Publish с version notes → early testers (до 10) → Manage Audience → Public.

## 14. Первые 24 часа после релиза

1. Игра публичная (Friends OFF), лейбл зрелости виден на странице. Audience → Reach показывает прогресс к 250 engaged plays.
2. Error reports, crash reports, серверные логи. Фикс → publish с notes → **рестарт только устаревших серверов** с задержкой 5–10 мин.
3. Monetization → Shop: нет баннера о флагнутом ProcessReceipt. Тест-покупка pass, product и private server с альт-аккаунта.
4. Через несколько часов таблица thumbnail personalization начинает заполняться. **Не снимайте thumbnails раньше времени.**
5. Первая аналитика: длина сессии D0, отказ на первой игре, конверсия. Строки ATC приходят в Localization.
6. **Не переименовывать и не менять жанр.** Завтрашняя бесплатная квота уходит на 5 новых бейджей.
7. Реклама для набора 250 engaged plays от 16+ (→ advisor/discovery-growth.md).
8. После 100 визитов включите отправку уведомлений и место для `PromptOptIn`.
9. Если апдейт меняет контент, переотправьте questionnaire до публикации.

Источники для §13–14: синтез разделов выше. Официального единого «launch checklist» у Roblox нет.

---

## 15. Ручная проверка: что прочитать в Studio / Creator Hub

Эти значения **не опубликованы ни в одном текстовом источнике** (проверены доки, вся git-история и openapi.json) или волатильны. Сессия Studio + Creator Hub примерно на 15 минут закрывает большую часть. Результаты стоит записать в память проекта.

| # | Что проверить | Где | Зачем |
|---|---|---|---|
| 1 | Числа пресетов World: Classic / Realistic / Action (gravity, jump, walk, slope) | Studio → Experience Settings → World → выбрать пресет | Сверить с config-модулем. Предположение: Classic = дефолты движка, Realistic gravity = 35 |
| 2 | Максимальная длина name и description игры | Creator Hub → Game details: печатать до упора | Сейчас безопасное правило ≤50 / ≤1 000 |
| 3 | Текущие подписи Server Fill и как они соответствуют Automatic / Empty / Custom | Places → место → Access / Edit | Связка выведена, не подтверждена |
| 4 | Жёсткий максимум server size (>100) | Places → Access → Maximum Visitor Count (валидация ввода) | В сообществе называют 200 или 700, не подтверждено |
| 5 | Default «Enable Camera»; где в UI `promotionalText` | Studio Communication; Game details | Не задокументировано |
| 6 | Квоты автоперевода | Audience → Localization | Числа есть только в UI |
| 7 | Где сейчас редактируется цена пасса и какие у неё min/max | Pass → Sales | Док изменился 06.10.2026 |
| 8 | Зелёный баннер бесплатного Plus и срок его окончания | Publishing permissions | Решение «платить сбор или нет» |
| 9 | Текущий порог Kids/Select и цена expedited | Audience → Reach; страница Kids and Select | Менялись 4 раза за 2026 |
| 10 | Список стран для голоса | Help Center: Voice Chat FAQ | Сайт был заблокирован при исследовании |
| 11 | Лимиты transfers, вышли ли родительские капы и Trusted Friends | DevForum / Help Center | Анонсировано на осень 2026 |
| 12 | Разблокирован ли Payouts в группе | Group → Finances → Payouts | Критерии не публикуются |

---

## 16. Нерешённые конфликты и открытые вопросы

- **Возврат сбора 1 000 R$:** «25 engaged игроков 60 дней» (Publishing) против «авто через 90 дней после допуска или оплаты» (FAQ, более конкретно и новее, от 27.05.2026). Практическое правило: депозит на 60–90 дней.
- **Дата отключения cross-game продаж:** 29 мая (DevForum, пресса) против «May 30» (баннер доков). Скорее всего, это разница часовых поясов или формулировки. На решения не влияет.
- **Сутки квоты бейджей:** «24 ч GMT» (док) и «UTC-день» (эндпоинт квоты). Фактически одно и то же.
- **`ageRating` / `visibility` в Open Cloud:** в одной заметке они в списке полей Universe, в другой — read-only. Верно второе: менять их можно только через UI (questionnaire / Manage Audience). Значения энама (`AGE_RATING_ALL`, `9_PLUS`, `13_PLUS`, `17_PLUS`) — legacy-ярлыки, не совпадающие с Minimal/Mild/Moderate/Restricted.
- **Метки avatar type:** «R15» в Studio = «R15 Only» в 18+ доке (разрешено через API-энам MorphToR15).
- **Неизвестно:** числа World-пресетов, лимиты name/description, жёсткий потолок server size, квоты перевода, критерии бесплатного Plus и разблокировки Payouts (последние два Roblox не публикует).
