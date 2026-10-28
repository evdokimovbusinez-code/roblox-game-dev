# Архитектура кода: данные, покупки, remotes, безопасность, производительность, библиотеки, тесты

**Назначение.** Файл говорит Builder-роли, как писать серверный и клиентский код Roblox-игры так, чтобы он не терял данные, не дюпал предметы, не ломался на покупках, выдерживал эксплойтеров и укладывался в лимиты платформы; Advisor-роли — почему именно так и где риски. Рабочая реализация всех паттернов — `assets/template/` (один серверный и один клиентский вход, сервисы с `init()/start()`); здесь правила, числа, причины и расширения, которых в шаблоне нет (возвраты, трейды, Server Authority, производительность). Тулчейн и CI — `builder/project-setup.md`; работа внутри Studio — `builder/mcp-studio.md`; правила монетизации и политика — `advisor/monetization.md`, `builder/compliance.md`.

**Актуально на:** октябрь 2026.
**Перепроверять:**
- лимиты DataStore (унифицированы 29.07.2026, per-server ×40 с 04.2026), MessagingService, MemoryStore;
- `BindReceiptHandler` (добавлен 04.05.2026) и его отсутствие в старых `globalTypes`;
- точный JSON и `EventType` вебхука Transaction Refunded (публично не опубликованы — залогировать первое реальное событие);
- Server Authority (полный релиз 09.07.2026) — API и ограничения;
- статус `coroutine.finally`, `const`, классов в Luau; серверный `--!native`;
- состояние Hyperion/Android Remote Attestation (как включать — не найдено в документации);
- статус библиотек (Jecs, Zap, Blink, Vide, Fusion, React Luau, Jest Roblox);
- условия rewarded video ads (порог ≈2 000 уникальных посетителей/мес. по документации на 11.2025).

Код не проходил живой плейтест в Studio: логика частично исполнена на моках (см. §3, §5), статический анализ шаблона чист на обоих решателях типов.

## Содержание
0. [Главные правила (TL;DR)](#0)
1. [Архитектура: два входа, сервисы, поток данных](#1)
2. [Данные: ProfileStore, лимиты, ключи, миграции, RTBF](#2)
3. [Покупки: чеки, идемпотентность, возвраты](#3)
4. [Remotes: валидация, лимиты, сеть](#4)
5. [Безопасность: Server Authority, античит, трейды](#5)
6. [Фильтрация текста, PolicyService, возрастные гейты](#6)
7. [Производительность](#7)
8. [Библиотеки и их статус в 2026](#8)
9. [Тестирование](#9)
10. [Типизация и возможности Luau](#10)
11. [Ввод (Input Action System)](#11)
12. [Лимиты MessagingService/MemoryStore и платные Extended Services](#12)
13. [Конфликты источников и открытые вопросы](#13)

<a id="0"></a>
## 0. Главные правила (TL;DR)

1. **Сервер — единственный источник правды.** Клиент присылает намерение («купить Flashlight»), а не результат («дай 100 монет»). Всё, что приходит с клиента, считается подделанным.
2. **Данные игрока — только через ProfileStore (session locking).** Ключ `Player_{UserId}`; миграции выполняются **до** `Reconcile()`; при неудачной загрузке игрока кикают, а не пускают с дефолтными данными; никаких сохранений на каждое действие; каждый растущий список в профиле ограничен по размеру (лимит значения ключа 4 194 304 символов).
3. **Чек Developer Product закрывается только после надёжного сохранения.** Один обработчик на игру (`BindReceiptHandler` — предпочтительно, либо один `ProcessReceipt`), идемпотентность по `PurchaseId`, `Processed` — когда `PurchaseId` уже в `LastSavedData`. Не реализовать обработчик = чеки автоматически подтверждаются и не восстанавливаются.
4. **Developer-product выдачи сами отзывайте при возврате** (passes и аватарные вещи Roblox отзывает сам): вебхук Transaction Refunded → ваш endpoint → очередь → идемпотентный откат на сервере.
5. **Валидируйте каждый аргумент remote:** `typeof`, `math.isfinite` (NaN и ±inf — это number), диапазоны, `utf8.len` для строк, whitelist-ключи; перед этим — rate limit на игрока. Лимит движка: около 500 запросов/с на клиента на тип remote; unreliable ≤1 000 байт, лишнее отбрасывается.
6. **Никогда не банить по клиентскому детекту.** Только серверные эвристики + лестница последствий (лог → тихая коррекция → временное ограничение → кик/бан); для постоянных нарушителей `Players:BanAsync`.
7. **Любой игрокский текст, видимый другим, обязан пройти `TextService:FilterStringAsync`**; игры без фильтрации снимают с публикации до исправления.
8. **PolicyService — обязательная интеграция:** платные случайные предметы, платный трейдинг, реклама и подписки гейтятся на сервере по флагам игрока; при сбое загрузки политики — самый строгий вариант.
9. **Производительность:** симуляцию держать на сервере, визуал — на клиенте; пул вместо Instance.new/Destroy; сервер держать ниже 50% памяти (6,25 GiB + 100 MiB × пик игроков); тестировать на слабом Android, а не в Studio.
10. **Для новых проектов:** без Knit (архив с 31.07.2024); простые ModuleScript-сервисы; Jest Roblox 3.20.x; Zap/Blink для горячих remotes; `--!strict` + luau-lsp в CI.

<a id="1"></a>
## 1. Архитектура: два входа, сервисы, поток данных

**Почему так.** Автор Knit архивировал его: дело не в поддержке, а в том, что фреймворк не использует типизацию Luau; рекомендация автора — обычные ModuleScript как сервисы и тонкая типизированная обёртка над RemoteEvent с runtime-проверками. Официальная структура документации и стартовый репозиторий Roblox («один Script на сторону, остальное в ModuleScript») ведут туда же.

```
repo/
  default.project.json  rokit.toml  wally.toml  selene.toml  stylua.toml  .luaurc
  src/
    server/   -> ServerScriptService.Server
      Main.server.luau            единственный Script: require все сервисы, init() всех, потом start() всех
      services/  PlayerData  Purchases  Remotes  Shop  Analytics  Policy   (+ Trade, Refund, Quests, ... по игре)
    client/   -> StarterPlayerScripts.Client
      Main.client.luau            единственный LocalScript: controllers
      controllers/  StateController  HudController  InputController ...
    shared/   -> ReplicatedStorage.Shared
      Config  Types  Remotes  NumberFormat
```

**Правила модулей**
- Сервис — таблица с необязательными `init()` (создание объектов, чтение конфига; не ждёт других сервисов, не yield'ит) и `start()` (подписка на события, циклы). Порядок задаётся строками в `Main.server.luau`: сначала создать remotes, затем подписки; обработчик чеков регистрируется на старте, до первых PlayerAdded.
- Циклические `require` запрещены (Roblox их не поддерживает; RFC на циклические требования только предложен). Развязка — передача зависимостей в `start()` или события.
- Состояние игрока живёт в `profile.Data`, а не в таблицах модуля, которые переживают сессию. Модульные кэши по `Player` чистить в `PlayerRemoving`.
- Клиент рисует то, что прислал сервер (`StateController`), и шлёт намерения. Клиент дожидается начального состояния (в шаблоне — хендшейк `ClientReady`, чтобы не потерять ключи при медленной загрузке).
- Код пишите «deferred-safe»: `SignalBehavior.Default` сейчас равен Immediate, но «в будущем переключится» на Deferred; шаблоны Studio уже стоят на Deferred, Server Authority принудительно включает его. Не читайте состояние синхронно сразу после `Fire`.
- `require` по строке (`./`, `../`, `@self`, `@game`) не блокирует: если модуля ещё нет — ошибка; для реплицируемых модулей клиента используйте `WaitForChild`. В шаблоне — Instance-пути.
- Теги (CollectionService) — для поведения конкретных объектов мира (двери, подбираемые предметы): один сервис подписывается на `GetInstanceAddedSignal(tag)` и навешивает логику на каждый помеченный объект. Script Sync атрибуты и теги не синхронизирует, поэтому теги ставьте кодом при старте или держите в `.rbxm` из Studio (практика, не из исследования).

**Поток данных (один направленный).**
1. Клиентский ввод (InputAction или GUI) → remote с **намерением**.
2. Сервер: rate limit → тип/конечность/границы/enum → владение и состояние.
3. Сервис меняет `profile.Data` (без yield между проверкой и мутацией).
4. Репликация дельты клиенту (`StateChanged`, Replica или атрибуты) — только ключи из белого списка.
5. Клиент перерисовывает UI.
6. ProfileStore сохраняет по автосейву (300 с по умолчанию) и при выходе; покупки и трейды форсят `Save()`.
7. Аналитика пишется **после** успеха.

**Конфигурация и фича-флаги.** Живые значения (флаги событий, баланс) — в Roblox Configs (`ConfigService`, запуск 06.11.2025; условия по стране/языку/источнику/новый-возвращающийся/платящий — с 24.08.2026), а не в константах. Ключи конфигов держите типизированными константами; снимок (`ConfigSnapshot`) — точка во времени: обновляйте на безопасных границах (между раундами), `GetConfigAsync` оборачивайте в `pcall`. Это заменяет самописные фича-флаги на DataStore/MemoryStore. API-вызовы — `project-setup.md`, §10.

Источники: github.com/Sleitnick/Knit/blob/main/ARCHIVAL.md; create.roblox.com/docs/ai/coding-harness; create.roblox.com/docs/scripting/events/deferred; create.roblox.com/docs/production/configs.

<a id="2"></a>
## 2. Данные: ProfileStore, лимиты, ключи, миграции, RTBF

### Выбор
| Вариант | Вердикт |
|---|---|
| **ProfileStore** (`lm-loleris/profilestore@1.0.3`, репозиторий MadStudioRoblox) | **По умолчанию.** Session lock, кража сессии после 40 с конфликта, «мёртвый» сервер через 630 с, `LastSavedData`, автосейв 300 с, собственный `BindToClose`. 50 зависимых пакетов в Wally, 41 переупаковка — де-факто стандарт. Последний коммит 31.07.2025, «стабильный, поддерживается редко» |
| Официальный образец Roblox «player data and purchasing» | Для понимания и команд, которым нужен свой код. Блокировка — GUID в метаданных ключа внутри того же `UpdateAsync`; автосейв 180 с с рандомным сдвигом; `BindToClose` сохраняет параллельно (есть всего 30 с); при ошибке загрузки профиль помечается `hasErrored` и **не пишется**. Документация сама называет образец «не доказанным в популярной игре» |
| DataStore2 | **Legacy**, официально «не использовать в новых проектах» (есть официальный мигратор) |
| Голые Get/SetAsync | Нет: нет блокировки сессий → дюпы и откаты |

Константы ProfileStore (меняются `ProfileStore.SetConstant`): `AUTO_SAVE_PERIOD` 300 с, `LOAD_REPEAT_PERIOD` 10 с, `FIRST_LOAD_REPEAT` 5 с, `SESSION_STEAL` 40 с, `ASSUME_DEAD` 630 с, `START_SESSION_TIMEOUT` 120 с, `MAX_MESSAGE_QUEUE` 1000. API: `StartSessionAsync(key, {Cancel, Steal})`, `Profile.Data/LastSavedData`, `OnSave/OnLastSave/OnAfterSave/OnSessionEnd`, `IsActive()`, `Reconcile()`, `EndSession()`, `AddUserId()`, `Save()`, `MessageAsync`. **`IsActive()` гарантирован только до ближайшего yield** — после любого ожидания проверяйте заново. Не предназначен для лидербордов и глобального состояния. Для репликации серверного состояния клиенту есть компаньон Replica.

### Ключи, RTBF (право на забвение)
- Мало DataStore, один–несколько ключей на игрока, **статический шаблон** `Player_{UserId}` (требуется для автоматического RTBF). До 100 шаблонов удаления с токеном `{UserId}`; UserId должен входить в **имя или scope** хранилища/ключа. Настройка — Creator Hub → Configurations → Data stores manager → RTBF Deletion либо Open Cloud Configs API (`user_data_templates`); если схема не подходит — вебхук right-to-erasure. **Регистрировать шаблон в день 1.**
- `profile:AddUserId(userId)` — связь профиля с пользователем.
- Очереди возвратов и любые побочные ключи с UserId тоже подпадают под RTBF: включите их в шаблоны либо удаляйте в обработчике erasure.

### Лимиты DataStore (окт. 2026)
Два слоя, **оба верны, но измеряют разное**.

| Тип | На сервер (по умолчанию, в минуту; настраивается `SetRateLimitForRequestType`) | На весь experience (серверы + Open Cloud, в минуту) |
|---|---|---|
| Read | 60 + игроки×40 | 300 + CCU×40 |
| Write | 60 + игроки×40 | 300 + CCU×20 |
| List | 5 + игроки×2 | 300 + CCU×2 |
| Remove | 60 + игроки×40 | 300 + CCU×40 |
| Ordered write/remove | 30 + игроки×5 | — |

История: до 07.04.2026 per-server был ×10, с 09.04.2026 ×40 и стал настраиваемым (вызывать один раз на тип при старте; не для `UpdateAsync`/`OnUpdate`; для новых типов base 0–10 000, per-player 0–200); 14.07.2026 (live 29.07.2026) experience-лимиты унифицированы между Open Cloud и игровым API. `UpdateAsync` расходует и read, и write. Серверный лимит — потолок, а не гарантия: если все серверы будут писать на максимум, первым упрётся experience-бюджет. Ошибки различают слои: `StandardWriteExperienceThrottled` и `StandardWriteGameServerThrottled`.

Прочее: значение ≤4 194 304 символов после сериализации; имя/ключ/scope ≤50; метаданные ≤300; на ключ 25 MB/мин чтения и 4 MB/мин записи; очередь на ключ — 30 запросов (дальше ошибки 301–306); хранилище 500 MB + 1 MB × lifetime-пользователи (удалённые данные считаются ещё 30 дней). Расчёт: игра с автосейвом 180–300 с использует ≈0,2–0,33 записи/игрок/мин — меньше 2% бюджета. Риски — сохранение на каждое действие, глобальные счётчики и лидерборды на каждое событие, Open Cloud-джобы, конкурирующие с боевым трафиком.

Официальные практики: буферизируйте в памяти; разносите циклы случайным сдвигом и джиттером; повторы по ключу с экспоненциальной паузой; предпочитайте `UpdateAsync`; горячие чтения шардируйте (`Weather_1..N`, шард по хэшу `JobId`); для превышения квот — Extended Services (§12). Версии: первая запись в ключ каждый UTC-час создаёт бэкап, живёт 30 дней после замены; `GetAsync` кэшируется 4 с; после неудачной записи проверяйте `DataStoreGetOptions.UseCache = false` («failed call не всегда означает, что запись не прошла»). Откат испорченных данных — `ListVersionsAsync(key, Descending, nil, maxDateMillis)` → `GetVersionAsync` → запись обратно.

### Миграции схемы
Поле `SchemaVersion` и упорядоченные идемпотентные шаги `MIGRATIONS[n]` (n → n+1). **Миграции — до `Reconcile()`**: иначе Reconcile проставит в старый сейв текущий `SchemaVersion` из шаблона, и миграции молча пропустятся (воспроизведено исполнением). Для нового пустого профиля (`next(data) == nil`) просто ставим текущую версию. Миграция не удаляет данные, нужные старой версии кода: при выкатке старые и новые серверы работают одновременно. После смены формата данных — рестарт серверов «только устаревших версий» (`ServerRestartScheduled` для отсчёта и принудительного сохранения).

```luau
local MIGRATIONS: { [number]: (data: any) -> () } = {
	[1] = function(data) -- v1 -> v2: инвентарь перешёл с массива видов на записи по GUID
		local old = data.Inventory or {}
		data.Inventory = {}
		for _, kind in old do
			local id = HttpService:GenerateGUID(false)
			data.Inventory[id] = { id = id, kind = kind, createdAt = os.time() }
		end
	end,
}
-- migrate(profile.Data); profile:Reconcile()   <- именно в таком порядке
```

### Чек-лист защиты данных
1. Session lock (ProfileStore). 2. `UpdateAsync` вместо `SetAsync` для read-modify-write вне ProfileStore. 3. `SchemaVersion` + цепочка миграций. 4. `Reconcile` после миграций. 5. Сохранение при выходе и в `BindToClose` (30 с). 6. Не писать, пока сессия не загружена или принадлежит другому серверу. 7. Список любого типа (PurchaseIds, Grants, TradeLog, RefundsApplied) — с потолком длины. 8. Мониторинг бюджетов (Observability Dashboard, оповещения о запросах, `DataStoreRequestsByStatus`). 9. Санитизация клиентских данных перед сохранением (§4). 10. Ключи `Player_{UserId}` + RTBF-шаблон.

Источники: create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits, .../best-practices, .../versioning-listing-and-caching, .../right-to-be-forgotten, .../player-data-purchasing; devforum.roblox.com/t/profilestore/3190543; DevForum 4739240.

<a id="3"></a>
## 3. Покупки: чеки, идемпотентность, возвраты

### Контракт (исправлено относительно ранних заметок)
- Обработчик вызывается при покупке, при показе успешного промпта и **при входе игрока**. Таймерных повторов нет: после `NotProcessedYet` чек приходит снова только после следующей покупки на этом сервере или когда пользователь перезайдёт на любой сервер.
- **Обработчик может yield'ить сколько угодно** («can yield for as long as the server is running»). Запрет на yield относится только к функции выдачи внутри трансформации `UpdateAsync`. Ранняя заметка «обработчик не должен yield'ить» — неверна.
- **Один и тот же чек может обрабатываться на двух серверах одновременно** (игрок перезашёл, пока первый сервер не вернул результат) — поэтому идемпотентность проверяется по данным под session lock.
- Даже `PurchaseGranted` может не записаться на бэкенде — тогда чек придёт снова. Несколько ожидающих чеков приходят в недетерминированном порядке. **Если не реализовать обработчик, чеки подтверждаются автоматически и пропадают.**
- `receiptInfo`: `PurchaseId`, `PlayerId`, `ProductId`, `PlaceIdWherePurchased`, `CurrencySpent` (точная сумма Robux даже при ценовых тестах), `CurrencyType`, `ProductPurchaseChannel` (`InExperience`, `ExperienceDetailsPage`, `AdReward`, `CommerceProduct`).
- **`BindReceiptHandler(Enum.ReceiptType.DeveloperProduct, handler, filter?)`** (с 04.05.2026): типы `DeveloperProduct`, `RobuxTransferSender`, `RobuxTransferReceiver`; результат `Enum.ReceiptDecision.Processed|NotProcessedYet`; фильтр по массиву ID имеет приоритет над catch-all, неподошедшие чеки падают в `ProcessReceipt` (можно внедрять постепенно); повторная регистрация — ошибка. Чек Robux-перевода приходит на сервер, где находится пользователь в момент расчёта; отправитель может ждать одобрения получателя (родителя). В `globalTypes` старых сборок метода нет — вызывайте через `:: any`.
- Внешние продажи: продукты со статусом Listed можно купить с главной, из поиска, со страницы игры (вкладка Store) и со страницы после покупки Robux — игрок входит с чеком в ожидании. **Roblox непрерывно проверяет ваш обработчик**; флагнутый продукт снимается с внешних поверхностей, пока не исправите и не нажмёте «Mark as fixed» (внутри игры продаётся). Game passes достаточно Listed.

### Правила реализации (воспроизведены в `assets/template/src/server/services/Purchases.luau`)
1. Единственный обработчик на игру, регистрируется на старте (`Main.server.luau`).
2. Найти игрока и профиль; нет игрока — `NotProcessedYet`.
3. Если `PurchaseId` уже в `profile.Data.PurchaseIds` — выдачу пропустить (идемпотентность), но подтверждение всё равно ждать.
4. Выдача — несколько непрерывных строк над `profile.Data` без yield, внутри `pcall`; неизвестный продукт → `NotProcessedYet` + warn.
5. Записать `PurchaseId` (кольцевой буфер ≈100) и запись в `Grants[PurchaseId] = {productId, at, robux}` (нужна для отката).
6. Подтверждать **только когда `PurchaseId` присутствует в `profile.LastSavedData`**: опрос с `profile:Save()` каждые ~10 с и таймаутом ≈60 с (не `OnAfterSave:Wait()` — сломанный DataStore повесил бы поток навсегда). Это предпочитаемый паттерн самого ProfileStore; официальный вариант «выдать, затем Save()» теряет покупку лишь если все DataStore-вызовы упали до краха сервера.
7. Награда за rewarded-видео идёт через тот же путь (`AdReward`), а не из результата показа рекламы.
8. Аналитика экономики — после успеха.

### Подписки и реклама
- Подписки: `GetUserSubscriptionStatusAsync(user, id)` → `IsSubscribed`, `IsRenewing` при входе (в `pcall`); `PromptSubscriptionPurchaseFinished` покупку не подтверждает — перепроверять статус; событие `Players.UserSubscriptionStatusChanged(player, subscriptionId)`; подписки в Robux (от 49 R$, 70% выплата) и в валюте региона ($2,99–$14,99, 70% первый месяц, затем 100%, нужна ID/телефон-верификация, недоступно в ряде стран); до 50 подписок на игру. Гейт — `PolicyService`: `IsEligibleToPurchaseSubscription`.
- Rewarded video ads: клиент `AdService:GetAdAvailabilityNowAsync` (только клиент) → кнопка только если реклама готова; сервер `CreateAdRewardFromDevProductId` + `ShowRewardedVideoAdAsync(player, reward)`; награда через чек. Правила: явная кнопка, раскрытие награды, награда — developer product (не Robux, не случайный предмет, не гейт прогресса), 3–10 Robux в эквиваленте, не повреждать персонажа во время показа. Порог по документации 11.2025 — ≥2 000 уникальных посетителей в месяц (запуск был 100K DAU), издатель 13+, ID, 2FA; игра public, без свободного творчества, с пройденной анкетой.
- Game passes: `UserOwnsGamePassAsync` кэшируется; при первом входе после покупки всегда true; покупки вне игры доходят за «несколько минут»; выдавайте при входе и по `PromptGamePassPurchaseFinished(wasPurchased)`.
- Региональные цены: managed pricing включён по умолчанию для passes (не ниже 30% от базы). Для игр с трейдингом/подарками: `MarketplaceService:GetUsersPriceLevelsAsync({userIds})` при входе (1–1000, 1000 = полная цена; не кэшировать дольше сессии); разрешать обмен только между равными уровнями, подарки — только с высокого уровня на низкий. **Обязательно для любой торговой игры** (арбитраж региональных цен).

### Возвраты (refund/chargeback) — вебхук Transaction Refunded
Проблема: passes и аватарные вещи Roblox отзывает сам, а выдачу за Developer Product **вы отзываете сами** (в payload — исходная цена, не фактически уплаченная). Источник событий — только вебхук (по OpenAPI других каналов нет: эндпоинты истории транзакций требуют cookie, в движке сигнала возврата нет; для подписок есть `GetUserSubscriptionPaymentHistoryAsync` со статусом `Refunded`).

Что известно (документация webhook-notifications, правки 03.09–13.10.2026): событие покрывает developer products, passes, private servers, paid access; подписки — отдельным триггером (`Subscription Refunded`; для commerce-заказов — `Commerce Product Order Refunded`, дедуп по ID заказа). В payload: ID покупателя, тип и ID продукта, Robux (**исходная цена**), universe и place покупки, «transaction or receipt ID», время возврата. Конверт: `{NotificationId, EventType, EventTime, EventPayload}`; дубль определяется по `NotificationId`. Endpoint: публичный HTTPS, POST, 2xx за 5 с; 5 повторов в фиксированное окно, затем доставка прекращается; не более 5 вебхуков на аккаунт; для групповых игр настраивает только владелец группы. Roblox полностью поддерживает Discord и Slack, для прочих получателей надёжность «не гарантируется» — комбинируйте с ручной сверкой. «Test Response» шлёт только `SampleNotification`, возврат на заказ не сэмплируется.

**Не опубликовано (залогировать при первом событии):** точные имена JSON-полей, строка `EventType`, равен ли «transaction/receipt ID» значению `receiptInfo.PurchaseId`. Поэтому: сохраняйте в `Grants` по `PurchaseId` и при несовпадении id отправляйте в ручной разбор.

**Подпись:** заголовок `roblox-signature: t=<unix>,v1=<base64 HMAC-SHA256(secret, "<t>.<сырое тело JSON>")>`; отвергайте запросы старше ≈300 секунд.
```python
import base64, hashlib, hmac, time

def verify(secret: bytes, header: str, raw_body: bytes, tolerance: int = 300) -> bool:
    parts = dict(p.split("=", 1) for p in header.split(","))
    t, v1 = parts.get("t"), parts.get("v1")
    if not t or not v1 or abs(time.time() - int(t)) > tolerance:
        return False
    expected = base64.b64encode(hmac.new(secret, t.encode() + b"." + raw_body, hashlib.sha256).digest()).decode()
    return hmac.compare_digest(expected, v1)
```
(Проверено на синтетической подписи; реальные заголовки Roblox не проверялись.)

**Конвейер отката (исполнен на моках, не на живом Roblox):**
1. При выдаче: `Grants[PurchaseId] = {productId, at, robux}`; чистить записи старше выбранного горизонта (Roblox окно возвратов не публикует — горизонт выбираете сами, напр. 180 дней).
2. Endpoint вне Roblox: проверить подпись, дедуп по `NotificationId`, записать **один ключ на возврат** через Open Cloud: `POST /cloud/v2/universes/{u}/data-stores/RefundQueue/entries?id=Refund_{buyerUserId}_{transactionId}` с телом `{"value":{"id":"<transaction id>","productId":n,"at":unix}}` (scope `universe-datastores.objects:create`). Один ключ на возврат — endpoint не делает read-modify-write, дубли попадают в тот же ключ. Опционально `POST /cloud/v2/universes:{u}:publishMessage` в тему `Refunds` с `{"userId":n}`, чтобы живой сервер применил сразу.
3. В игре `RefundService` при загрузке профиля (и по сообщению `Refunds`) читает `ListKeysAsync("Refund_{userId}_")` (одна страница из 50 — больше 50 ожидающих возвратов у одного пользователя это сигнал мошенничества для эскалации), откатывает выдачу **идемпотентно** (`RefundsApplied`, кольцо 200), сохраняет, и только потом `RemoveAsync` ключей очереди. Нет записи в `Grants` → warn и ручной разбор.
4. Политика, закодированная в примере: баланс может уйти в минус («долг»); альтернатива — обнуление (Roblox не предписывает). Для предмета, который уже ушёл через трейд: пометить `locked = true` у получателя и разбирать вручную, а не отбирать у третьего игрока.

Ядро отката:
```luau
local function applyOne(data, id: string)
	if table.find(data.RefundsApplied, id) ~= nil then return end -- идемпотентно
	local grant = data.Grants[id]
	local reverse = if grant then REVERSALS[grant.productId] else nil -- зеркало GRANTS
	if reverse then reverse(data); data.Grants[id] = nil else warn("Refund with no matching grant", id) end
	table.insert(data.RefundsApplied, id)
	while #data.RefundsApplied > 200 do table.remove(data.RefundsApplied, 1) end
end
```

**Раскладка монетизации (пакет пользователя: 10 §13, гипотеза-ориентир, не требование).** `ProductCatalog` (данные: тип, ID, действие выдачи, права, конфликтующие бонусы; цена в UI не хардкодится), `PurchaseLedger` (идемпотентность по `PurchaseId`, журнал выдач и откатов), `CurrencyWallet`, `BuffService` (единый расчёт множителей с капами, временных/постоянных эффектов, `expiration` сохраняется в профиле; ни один модуль не умножает награду сам), `PolicyGate` (флаги PolicyService), `FraudProtections` (лимиты, аномалии). Идемпотентность, возвраты и `UpdateAsync` выше описаны полнее пакета.

Источники: create.roblox.com/docs/reference/engine/classes/MarketplaceService; .../production/monetization/developer-products, .../regional-pricing, .../subscriptions; .../production/promotion/rewarded-video-ads; create.roblox.com/docs/cloud/webhooks/webhook-notifications.

<a id="4"></a>
## 4. Remotes: валидация, лимиты, сеть

**Контракт каждого client→server remote** (реализован в `services/Remotes.luau`): (1) намерение, не результат; (2) rate limit по `UserId` (token bucket: ёмкость + скорость пополнения) раньше любой работы; (3) валидация типов, границ, enum/whitelist; (4) проверка владения и состояния; (5) мутация без yield между проверкой и изменением; (6) некорректный ввод отбрасывается молча, валидный, но отклонённый — исправляется отправкой актуального состояния клиенту.

**Валидаторы.**
- `typeof(v) == "number"` недостаточно: NaN проходит проверку типа, но ломает все сравнения; всегда `math.isfinite(v)`, затем границы, для целых — `v == math.floor(v)`.
- Строки: `utf8.len(v)` не `nil` (валидный UTF-8) и длина в символах ≤ предела; то же для ключей таблиц.
- Таблицы: проверять структуру, а не только `typeof` (таблица может имитировать данные); ограничивать число ключей и вложенность.
- Instance: проверять класс и `IsDescendantOf` известной папки; клиент не должен присылать Instance, ценность которого определяет сервер.
- Клиентские строки как ключи — только через whitelist (`allowed[key] ~= nil`), иначе возможны сюрпризы вроде `"__index"`.
- Игровое поведение (ProximityPrompt, Touched) эксплойтер может вызывать с любой частотой — лимитируйте на сервере и перепроверяйте расстояние/состояние.

**Санитизация данных перед сохранением** (раздел «Data store manipulation» документации): без Instance; ограничение длины строк и числа ключей, которые клиент может добавить; без NaN и nil-индексов; валидный UTF-8 (в том числе в ключах); отсечение ±inf. Официальный пример эксплойта: отправитель трейда отдаёт предмет и выходит, его сохранение падает из-за невалидных данных, он перезаходит с предметом — дюп.

**Intent-only для ответов и результатов (жанровые главы `advisor/genres/01–08`).** Клиент шлёт выбор или намерение (`SubmitAnswer(optionId)`, `StartDig(targetId)`), но не результат: `correct=true`, «выпал legendary», `damage=9999`, итоговый счёт. Сервер сам считает исход и награду. Сопутствующие правила:
- Idle/числа выше 1e15: big-number схема (мантисса+экспонента или суффиксная таблица), сохранение в профиле строкой/парой чисел, формат через `NumberFormat`; лимиты математики проверять тестом (§9).
- Коллекции хранить по версионированным ID с миграцией старых; переименование/удаление предмета не должно стирать собранное.
- Карточные/скрытые игры: чужие руки и порядок колоды клиенту не отдаются вообще (иначе виден в сетевом трафике).
- Правила, шансы и таблицы наград держать в `ServerStorage`, а не в `ReplicatedStorage` (клиент видит содержимое реплицируемых папок). Награду выдавать ровно один раз по `resultId`; кнопка COLLECT — только UX.

**Лимиты и транспорт.**
- Около **500 запросов/с на клиента на тип remote** (общий пул remote одного типа). Избыточные reliable события **задерживаются** (порядок сохраняется), избыточные unreliable — **отбрасываются**. Очередь для событий без обработчика ограничена, переполнение пишет ошибку.
- `UnreliableRemoteEvent`: без гарантии доставки и порядка, payload **>1 000 байт отбрасывается** (сжатие буферов делает размер непредсказуемым); для эфемерного (эффекты, позиции). Событие без слушателя отбрасывается.
- Для высокой нагрузки — буферные IDL-генераторы Zap или Blink (оба активны, §8); валидацию на сервере сохраняйте в любом случае. Заявленные автором Blink ускорения (1,6–3,7×) — собственный бенчмарк, независимых нет.
- Не твините на сервере (свойство реплицируется каждый кадр), VFX создавайте на клиенте, отправляйте дельты, а не целиком инвентарь, большие карты спавните порциями; в тестовом примере передвижение 2000 MeshPart с сервера занимало ≈2500 Kb/s против почти нуля при одном сигнале и локальном движении.
- Сервер не должен быть ретранслятором «клиент→клиент» без проверки: он решает, что и кому передать.
- Направленность: трафик в «неправильную» сторону (server→client remote, на который что-то пришло от клиента) — признак подделки; honeypot-remote (приманка, которую легальный клиент не вызывает) — лог и кик.
- Network ownership: эксплойтер может заявить владение незаякоренными частями. Для критичных взаимодействий — заякоренные части или принудительно серверное владение.

Источники: create.roblox.com/docs/scripting/security/client-server-boundary, .../security-tactics; create.roblox.com/docs/scripting/events/remote; create.roblox.com/docs/reference/engine/classes/UnreliableRemoteEvent.

<a id="5"></a>
## 5. Безопасность: Server Authority, античит, трейды

### Модель угроз
Эксплойтер может вызывать remote с любыми аргументами, срабатывать Touched/ProximityPrompt с любой частотой, менять локальный DataModel, декомпилировать любой реплицируемый на клиент скрипт. Следствия: логика — в `ServerScriptService` (не в ReplicatedStorage/Workspace); для каждой фичи считайте «максимально осмысленную частоту вызова».

### Server Authority (2026) и когда его применять
`Workspace.AuthorityMode = Server` автоматически включает пять настроек: `NextGenerationReplication`, `PlayerScriptsUseInputActionSystem`, `SignalBehavior = Deferred`, `UseFixedSimulation`, `StreamingEnabled`. Игровая логика — в `RunService:BindToSimulation(fn)` внутри ModuleScript, инициализируемого **и на клиенте, и на сервере**; допустимы только API с пометкой Simulation Access; время — `time()` (фиксированный шаг, перематывается при пересимуляции), **не** `tick()/os.time()/os.clock()`; `task.spawn` сохраняет ограничения симуляции, `task.defer` их снимает. Кастомное состояние — атрибуты предсказываемых инстансов (первые 64 атрибута, имя ≤50 символов, строка ≤50), записываются только в связанных функциях; расхождение вызывает полный откат и пересимуляцию. Ввод — только InputAction (клонируются под `Player`), не `UserInputService.InputBegan`. Remotes работают для дискретных событий, но порядок относительно обновлений свойств/атрибутов не гарантирован. Эффекты и звуки — в `RenderStepped` по результатам симуляции. Предсказание по инстансу: `RunService:SetPredictionMode(instance, Automatic|On|Off)`. Тестировать под задержкой через Network Simulator. Официальный совет: замедленное ускорение и «fuse»-задержки скрывают рассинхрон.

**Когда брать (вывод):** быстрые экшены с передвижением и физикой, где fly/speed-хаки убивают игру (PvP, гонки, шутеры). Для симуляторов, тайкунов, обби, хорроров с одиночной механикой хватает серверной валидации remote — Server Authority добавляет сложность (две стороны симуляции, ограничения API) и, при постоянно проседающем серверном heartbeat, может потребовать платный Compute (§12: «более чем удваивает CPU на игрока»; подавляющему большинству игр не нужен).

Если Server Authority не используется: валидация движения по эвристикам (leaky-bucket аккумуляторы, проекция на плоскость XZ, явные исключения для телепортов); эксплойтеры с network ownership могут ставить любой WalkSpeed, реплицировать NaN/Inf CFrame и подавлять Touched.

### Серверное обнаружение и реакция
- Эвристики: самое быстрое время прохождения, скорость прироста, ритм действий; **скоринг подозрительности** по нескольким разным детекторам.
- Лестница последствий: тихий лог → тихая митигация (clamp, drop, ресинк) → временное ограничение → кик/бан с отложенными видимыми последствиями (чтобы не давать подсказок).
- `Players:BanAsync`: до 50 UserId за вызов, `Duration` в секундах (−1 = навсегда), `DisplayReason` ≤400 символов (фильтруется), `PrivateReason` ≤1000 (клиенту не отправляется); бан по умолчанию распространяется на подозреваемые альт-аккаунты (`ExcludeAltAccounts` отключает), `ApplyDeviceBlock` блокирует устройство на 24 ч; серверный, в Studio не работает.
- **Никогда не банить по клиентскому детекту** (его можно подделать — получите ложные баны). Hyperion ложно банил разработчиков, тестирующих античит в edit-enabled experience (баг-репорт 2026) — тестируйте античит в изолированных вселенных.
- `Player:IsVerified(Enum.VerifiedLevel.Low|High)` — серверный, в Studio всегда false; Roblox предлагает его для защиты рейтингов и торговли. Использовать как **дополнительный** гейт.

### Целостность клиента
Официальные документы не упоминают Hyperion/Byfron; guidance — серверная авторизация. Известно: Hyperion (anti-tamper) на Windows с 05.2023; на Android с 07.2026 есть **опциональная Remote Attestation** (проверка реального физического устройства и неизменённого приложения; не проходят root, разблокированный загрузчик, эмуляторы, виртуальные окружения, Amazon Fire; игра сама решает, использовать ли и насколько строго — например, для рейтинговых режимов); как разработчик включает проверку, в документации не найдено. Платформенные статусы Hyperion на macOS/iOS/Xbox неизвестны, статистика эффективности не публикуется. **Правило:** любой клиент считается модифицируемым; для соревновательных режимов включить attestation, когда найдётся настройка, и гейтить рейтинг и торговлю по `IsVerified()`.

### Прочие официальные требования безопасности
- **Телепорты:** клиент может телепортироваться в **любой** place вселенной; отключение Direct Access лишь прячет кнопку Join, а кик происходит после репликации контента. Включите Access Control for Places → «Secure within universe only»; dev/test-места держите в **отдельных приватных вселенных**.
- **Сторонние ассеты:** бэкдоры из Toolbox — изолируйте вставленные модели (`Workspace.SandboxedInstanceMode = Experimental`, `Model.Sandboxed = true`, минимальные `Capabilities`; бета); осторожно с Network, DataStore, AssetRequire, CapabilityControl, LoadString. Roblox планирует авто-песочницу для ассетов Creator Store.
- **Секреты:** ключи Open Cloud — в Secrets store, не в скриптах и не в DataStore.

### Трейды: защита от дюпа
Принцип из официальной документации: «проверить все данные до любой операции обмена; транзакционный паттерн, где данные всех игроков проверяются до коммита; откат всего при сбое любой части».

Реализация (исполнена на моках; в раунде 3 исправлены **две реальные ошибки** исходной версии — дублирующийся ID в оффере уничтожал предмет, а самообмен стирал предметы):
```luau
local function validateOffer(inventory, itemIds): { [string]: true }?
	if #itemIds > MAX_ITEMS_PER_SIDE then return nil end
	local seen = {}
	for _, id in itemIds do
		if typeof(id) ~= "string" or seen[id] or inventory[id] == nil then return nil end -- дубли и чужие предметы
		if inventory[id].locked then return nil end -- удержание по возврату / в другом трейде
		seen[id] = true
	end
	return seen
end

function TradeService.commit(a, b, tradingEnabled: boolean): boolean
	if not tradingEnabled then return false end -- kill-switch через Configs
	if a.player == b.player then return false end -- самообмен стирал бы предметы
	local pa, pb = PlayerData.get(a.player), PlayerData.get(b.player)
	if not (pa and pb) then return false end
	if #a.itemIds == 0 and #b.itemIds == 0 then return false end
	if not validateOffer(pa.Data.Inventory, a.itemIds) or not validateOffer(pb.Data.Inventory, b.itemIds) then return false end
	-- снимок записей ДО мутации, затем удаление, затем выдача; без yield от проверки до конца
	local fromA, fromB = {}, {}
	for _, id in a.itemIds do fromA[id] = pa.Data.Inventory[id] end
	for _, id in b.itemIds do fromB[id] = pb.Data.Inventory[id] end
	for id in fromA do pa.Data.Inventory[id] = nil end
	for id in fromB do pb.Data.Inventory[id] = nil end
	for id, rec in fromA do pb.Data.Inventory[id] = rec end
	for id, rec in fromB do pa.Data.Inventory[id] = rec end
	-- аудит с id предметов на обеих сторонах (с потолком длины лога), затем форс-сохранение обоих
	pa:Save(); pb:Save()
	return true
end
```
Обвязка вокруг коммита: машина состояний «оффер → блокировка → принятие → серверный отсчёт ≈5 с», кулдаун на игрока, гейты `Policy.canTradePaidItems` (`IsPaidItemTradingAllowed`), равенство `GetUsersPriceLevelsAsync` и по желанию `IsVerified()`. Трейды — только внутри одного сервера, оба профиля под активной session lock этого сервера. Каждый предмет — запись с GUID. Серверное время и таймауты решают сервер.

Источники: create.roblox.com/docs/projects/server-authority, .../server-authority/techniques; .../scripting/security/security-tactics, .../server-side-detection, .../access-control, .../network-ownership, .../third-party-vulnerabilities; devforum.roblox.com/t/security-tactics-and-cheat-mitigation-docs-update/3959613; Roblox Help: Android Remote Attestation.

<a id="6"></a>
## 6. Фильтрация текста, PolicyService, возрастные гейты

### Фильтрация текста — обязательна
Любой текст, введённый игроком и показываемый другим (таблички, имена питомцев, био, сохранённый текст при последующем показе, сгенерированные слова), обязан пройти фильтр. «Если Roblox получает жалобы или автоматически определяет, что игра не применяет фильтрацию, система снимает игру с публикации, пока вы её не добавите».
Паттерн: клиент отправляет по `FocusLost` (не на каждый символ) → сервер `TextService:FilterStringAsync(text, fromUserId)` в `pcall` → `:GetNonChatStringForBroadcastAsync()` для всех либо `:GetNonChatStringForUserAsync(toUserId)` для конкретного зрителя. Хранить можно исходный текст, но при показе фильтровать заново. В шаблоне — `Policy.filterForBroadcast`. Для самописных чатов: `TextChatService:CanUserChatAsync(userId)`, `CanUsersChatAsync(from, to)`, `CanUsersDirectChatAsync`.

### PolicyService
`PolicyService:GetPolicyInfoForPlayerAsync(player)` (по геолокации, возрастной группе и платформе; вызывать при входе, кэшировать; ошибка, если вызвать более 100 раз до ответа) возвращает поля: `AreAdsAllowed`; `ArePaidRandomItemsRestricted` (если true — нельзя взаимодействовать с платными генераторами случайных предметов, ни за Robux, ни за внутриигровую валюту, купленную за Robux); `IsContentSharingAllowed`; `IsEligibleToPurchaseCommerceProduct`; `IsEligibleToPurchaseSubscription`; `IsPaidItemTradingAllowed`; `IsPhotoToAvatarAllowed`; `IsSubjectToChinaPolicies`; `IsEndlessContentLoadAllowed`; `IsEndlessContentAutoplayAllowed`; `AllowedExternalLinkReferences` — legacy, всегда пустой массив. Интеграция **обязательна** («You must integrate this API») для подписок, commerce-продуктов, платных случайных предметов, платного трейдинга и рекламы.
- **Fail closed:** пока политика не загружена или загрузка упала, возвращать самый строгий вариант (шаблон так и делает).
- Платные случайные предметы: скрыть UI **и** отклонять на сервере; показывать шансы процентами, в сумме ровно 100% (при одноразовых исходах пересчитывать остаток).
- Нельзя ложную срочность: нет фальшивой дефицитности, сбрасываемых таймеров, давления «GET IT NOW» в сторону несовершеннолетних.
- Developer products обязаны использовать `ProcessReceipt`/bound handler, не `PromptProductPurchaseFinished`.

### Возраст и верификация
- `Player.AgeChecked` — `Enum.AgeCheckStatus` (`Checked`/`Unchecked`; присутствует в API-дампе), `Player:PromptAgeCheck()`, `Player:IsVerified(level)`. Ранняя заметка «публичного API статуса возрастной проверки нет» опровергнута API-дампом: статус есть, а вот **возраст игрока не отдаётся**.
- Возрастные уровни платформы: Roblox Kids (5–8: Minimal/Mild), Roblox Select (9–15: до Moderate, чат отключён пока нет проверки возраста), Roblox (16+ с проверкой: всё, кроме Restricted 18+). Новая игра стартует только для age-checked 16+ (метка «Content May Vary»), чтобы раскрыться для младших — нужны рейтинг Minimal–Moderate, 250 уникальных игр высоко вовлечённых age-checked пользователей за 60 дней либо ускоренная проверка за 50 000 Robux. Подробности — `builder/compliance.md`. Для хоррора это решает стратегию запуска.
- Team Create требует возрастной проверки для добавления соавторов (с ограничениями по возрастным группам).
- Автоперевод: Automatic Text Capture подхватывает строки UI и заполняет только **пустые** записи — ручные переводы побеждают.

Источники: create.roblox.com/docs/ui/text-filtering; .../reference/engine/classes/PolicyService, .../TextChatService; .../production/monetization/paid-random-items; .../production/publishing/kids-and-select.

<a id="7"></a>
## 7. Производительность

**Официальные числа** (Identify performance issues):
- Память сервера: **6,25 GiB + 100 MiB × пиковые игроки** (30 игроков ≈ 9,18 GiB; память не уменьшается, когда игроки уходят); держать **ниже 50%**.
- Серверный heartbeat ограничен 60 FPS (бюджет кадра 16,67 мс); смотреть Developer Console → Server Jobs → Heartbeat.
- Клиент: 60 FPS по умолчанию (до 240 на Windows по настройке); профилировать на слабых устройствах, «Studio skews stats». Тревога: **crash rate выше 2–3%**, особенно скачок после обновления.
- Горячие точки памяти клиента: Developer Console → Memory → PlaceMemory: `GraphicsMeshParts`, `GraphicsTexture`, `Sounds`. Пример целевого бюджета из документации: <1 000 draw calls и <1 000 000 треугольников на базовом устройстве. MB-бюджетов по категориям нет.
- Аудитория: ≈65% игроков типичной игры на Android, из них ≈60% с 2–4 GB RAM, >50% всех игроков на устройствах с Passmark 10 000–20 000; эмулятор устройств Studio неточен по памяти. Закладывать клиентский footprint значительно ниже ≈1 GB (оценка).
- Загрузка: ReplicatedFirst → остальной DataModel (только область вокруг спавна) → аватар; Studio-настройка «Print Join Size Breakdown» печатает топ-20 инстансов по размеру; бесплатные модели с тысячами инстансов убивают время входа. Ping: сетевой vs data ping (если data ping сильно выше — реплицируется слишком много); Shift+F3.

**Streaming** (`Workspace.StreamingEnabled` включён по умолчанию для новых мест, из скрипта не задаётся; применить рекомендованное: `Workspace:ApplyRecommendedStreamingSettings()`):
`ModelStreamingBehavior = Improved`, `StreamingIntegrityMode = PauseOutsideLoadedArea`, `StreamingMinRadius = 64`, `StreamingTargetRadius = 1024`, `StreamOutBehavior = Opportunistic`. Режимы модели: Nonatomic (по умолчанию), Atomic, Persistent («для очень редких случаев»), PersistentPerPlayer. Новое в 2026: SLIM (облачные LOD/композитные меши, `Model.LevelOfDetail = SLIM`, `EnableSLIMAvatars`, документ от 20.07.2026) и `PredictiveStreamingMode`. Клиентская физика, в том числе предсказание Server Authority, работает только в загруженных областях. Для хоррора: монстр, двери, ключи — Atomic; Persistent только для мелких HUD-якорей (вывод).

**Практики:**
- Пулы вместо `Instance.new/Destroy` для пуль, эффектов, NPC; свойства задавайте до установки Parent в Workspace; `table.create` при известном размере; кэшируйте ссылки вместо `FindFirstChild` в Heartbeat; без `print/warn` в продакшене. `--!optimize 2` уже по умолчанию на живых клиентах; кэширование глобальных в локальные даёт мало.
- NPC: больше ≈100 Pathfinding-NPC, скорее всего, лагают; `AnimationController` для статичных; `SetStateEnabled` отключает лишние состояния Humanoid; анимировать на клиенте; спавнить и убирать NPC по близости игроков; пул NPC; `updateInvalidatedFastClusters` >4 мс — лишние перестройки аватаров/слоёной одежды; не менять размер/масштаб в рантайме.
- Рендер: встроенные материалы дешевле кастомных текстур; лимиты ассетов — меш ≤20 000 треугольников, ≤4 влияний костей на вершину, текстуры до 4096² (для UV-карт аксессуаров 1024²) — `builder/art-ui-audio.md`.
- **Parallel Luau:** код выполняется параллельно только под Actor после `task.desynchronize()`/`ConnectParallel`, назад — `task.synchronize()`; `require()` в параллельной фазе нельзя; скрипты под одним Actor идут последовательно (документация советует 64+ Actor для валидации лучей даже на 4 ядрах); связь — `Actor:SendMessage`/`BindToMessage`, `SharedTable`. Если через границу потоков передаётся много данных, параллелизм медленнее последовательного (сжимайте через buffer/bit32). Применение: валидация попаданий по лучам, процедурный терраин, восприятие NPC.
- **Native codegen** (`--!native` / `@native`): только серверные скрипты (документация от 22.10.2026); эффективен на числовом горячем коде с типами и `buffer`; стоит памяти и времени старта, есть общий потолок размера нативного кода; не подходит `getfenv/setfenv`, брейкпоинты отключают его; лимиты 64K инструкций на блок, 32K блоков на функцию, 1M инструкций на модуль. Включать выборочно после профилирования.
- **MicroProfiler:** Ctrl+Alt+F6 (Cmd+Opt+F6), Ctrl+P — пауза/детальный режим, Ctrl+Shift+F5 — Performance Summary. На мобильном: включить в настройках и открыть в браузере `<IP устройства>:1338` (по умолчанию 30 кадров, `/90` — больше); «мобильный клиент — лучшее место для профилирования». Свои метки: `debug.profilebegin("label")` / `debug.profileend()`. Данные доступны и через Studio MCP; сохранение — `microprofile-<date>.html`. Навык `rbx-perf-profiling` разбирает трассы. Scene Analysis (`SceneAnalysisService`, навык `rbx-scene-analysis`): память скриптов, утечки неприкреплённых инстансов, состав треугольников.
- Телеметрия Roblox (08.2026): встроенные crash rate, память, CPU, FPS по версиям и оповещения в реальном времени (Early Harm Detection для экспериментов — первые 24 ч).

Источники: create.roblox.com/docs/performance-optimization/identify, .../improve, .../design, .../test-on-hardware, .../microprofiler, .../scene-analysis; .../workspace/streaming, .../streaming/slim; .../luau/native-code-gen; .../scripting/multithreading; DevForum 4629258.

<a id="8"></a>
## 8. Библиотеки и их статус в 2026

Данные: последние коммиты/теги на 26.10.2026 и зависимости в индексе Wally (6 131 пакет; считает зависимости между пакетами, а не использование в играх; звёзды/скачивания недоступны).

| Библиотека | Статус | Рекомендация |
|---|---|---|
| **ProfileStore** | стабильна, обновляется редко (31.07.2025) | данные игроков |
| **Replica** (MadStudio) | редко (08.2025); `.rbxm`, не в Wally | репликация серверного состояния при необходимости |
| **Signal** (sleitnick, 2.0.3) / **Trove** (1.8.0) / Janitor | активно / поддерживается | базовые утилиты (+ Promise, `t`) |
| **Promise** (evaera) | заморожена с 2022–2023, «закончена» | можно, новых функций нет |
| **Jest Roblox** (`roblox/jest` 3.20.1) | активна, официальная | тесты; форк jsdotlua/jest (3.10.0) устарел, TestEZ заброшен |
| **React Luau** (Roblox) | активна (10.2026) | UI; форк jsdotlua/react-lua заброшен с 12.2024 |
| **Vide** (0.4.1) | очень активна | реактивный UI, типобезопасен |
| **Fusion** (0.3) | медленно (последний тег 08.2024) | работает, развитие вялое |
| **Charm** | активна | state-атомы |
| **Jecs** (0.11.0) | очень активна | ECS для игр с большим числом сущностей |
| **Matter** | оригинал не поддерживается (07.2024), форк тихий с 11.2024 | не брать |
| **Zap** (0.6.29), **Blink** (1.0.0-pre.10) | активны | буферные IDL-генераторы remotes (CLI через Rokit, не пакеты Wally) |
| **ByteNet** | низкая активность | не брать |
| **Knit** | архив с 31.07.2024 (ещё есть зависимые пакеты) | не брать |
| **Flamework / roblox-ts** | поддерживаются, релизы редкие (roblox-ts 3.0.0 от 09.2024) | если команда на TypeScript |
| **TopbarPlus, Cmdr, Packet** | де-факто стандарт сообщества (по числу переупаковок) | верхняя панель, админ-консоль, сеть |

Каноничный набор по умолчанию: Signal + Trove (или Janitor) + Promise + `t`; ProfileStore; React Luau либо Vide/Fusion; Charm; Jecs при необходимости; Roblox Jest; сеть — ModuleScript-обёртка (шаблон), для горячих путей Zap/Blink.

Источники: сводка репозиториев и индекса wally (26.10.2026); github.com/Roblox/jest-roblox; github.com/Roblox/react-lua; github.com/Ukendio/jecs; github.com/red-blox/zap; github.com/1Axen/blink.

<a id="9"></a>
## 9. Тестирование

**Пирамида.**
1. **Чистая логика** (математика экономики, миграции, машина состояний трейда, `NumberFormat`) — Jest Roblox, запуск в CI через Luau Execution на каждый PR. Выносите логику в модули без обращений к Roblox API — тогда тесты быстрые и надёжные.
2. **Интеграция:** `StudioTestService` (только Studio): `ExecutePlayModeAsync`, `ExecuteRunModeAsync`, **`ExecuteMultiplayerTestAsync`** (сервер + до 8 клиентов), `AddPlayers`, `GetTestArgs`, `EndTest`; `VirtualInput` (`UserInputService:CreateVirtualInput()`) для мыши/клавиатуры; `StudioDeviceSimulatorService` для проверки устройств; Network Simulator (задержка, джиттер, потери) и Party Simulator. Мультиклиентные тесты скриптуются через `StudioTestService`, а не через MCP-инструмент `start_stop_play`.
3. **Smoke:** `RobloxStudio --task RunScript --placeId P --universeId U --runScriptFile smoke.luau --outputFile out.log --quitAfterExecution` либо Luau Execution на только что опубликованной staging-версии.
4. **Прод:** Error Reporting API, дашборд Performance, оповещения, Early Harm Detection экспериментов.

**Jest Roblox.** Тесты `*.spec.luau` в `__tests__/`; `jest.config.luau` обязателен (`return { testMatch = { "**/*.spec" } }`); запуск `require(Packages.Jest).runCLI(root, {ci = true}, {projects}):awaitStatus()`, провал при `numFailedTests > 0`. Готовые `runTests.luau`, `test.project.json`, пример spec и workflow — `assets/automation/`; лимиты Luau Execution и порядок — `project-setup.md`, §9. Навык Assistant `rbx-unit-test` определяет Jest/TestEZ и имеет встроенный запасной прогон.

**Что покрыть в первую очередь:** `Guard`/валидаторы remote (NaN, ±inf, невалидный UTF-8, `"__index"`, ёмкость token bucket), порядок миграций (миграции → Reconcile), идемпотентность чека (повтор `PurchaseId` не выдаёт дважды; 150 чеков → кольцо 100), трейд (дубль ID, самообмен, locked, невалидная сторона не трогает другую), откат возврата (одна выдача откатывается один раз). Именно эти сценарии на моках выявили реальные баги в раунде 3.

**Предрелизный тест-лист SKU (пакет пользователя: 10 §18, 04 §7).** Каждый платный товар прогнать до публикации: отказ от покупки в окне (ничего не выдано, ничего не списано); повторный `receipt` с тем же `PurchaseId` (выдача один раз); рестарт/краш сервера между выдачей и сохранением; сбой DataStore (профиль не затёрт, чек не закрыт); повреждённое сохранение (миграция/дефолт); entitlement после перезахода и на другом сервере; Plus/региональная цена в UI (без хардкода); возрастные и PolicyService-ограничения; мобильный UX (кнопка, цена, подтверждение на 844×390). Для экономики: 1000 случайных попыток без NaN, монотонность прогрессии, ×10 запросов награды (выдача один раз), два параллельных апгрейда (без дубля).

Источники: create.roblox.com/docs/studio/testing-modes, .../studio/cli; github.com/Roblox/jest-roblox; github.com/Roblox/place-ci-cd-demo.

<a id="10"></a>
## 10. Типизация и возможности Luau

**Решатель типов.** New Type Solver — общий релиз 20.11.2025: по умолчанию для nocheck/nonstrict; strict-скрипты остаются на старом решателе, пока `Workspace.UseNewLuauTypeSolver = Enabled` (кнопка Beta в Studio удалена 07.01.2026; старый решатель остаётся в 2026). `Workspace.LuauTypeCheckMode` (Default/NoCheck/Nonstrict/Strict) задаёт режим по умолчанию для места; `--!strict` в скрипте переопределяет. Возможности нового решателя: read-only свойства таблиц (`read` — только в новом), type functions, лучше refinements, singleton-типы, более мягкие касты. Известные проблемы: многословные ошибки, нагрузка на Studio, редкие «blocked type»; проверка работает только на этапе редактирования и не влияет на живую игру. **Политика:** новый проект — `--!strict` везде + `UseNewLuauTypeSolver = Enabled` + luau-lsp в CI; унаследованный — решатель по умолчанию и постепенный `--!strict`. Шаблон проверен на обоих решателях; чтобы так и осталось, не используйте `read` в типах и аннотируйте `local ok: boolean, err: any = pcall(...)`.

**Что можно использовать в Roblox сейчас (документировано):** `const` (с 08.2026; значение не неизменно — для таблиц `table.freeze`), `buffer` (`create/fromstring/tostring/len`, `read/write` i8–f64, `readstring/writestring`, `copy`, `fill`, `readbits/writebits`; через remote приходит копией, между Actor'ами не разделяется; замена `string.pack`), `vector` (неизменяемые векторы, нативная генерация кода), `math.lerp/map/isnan/isinf/isfinite`, константы `math.e/phi/sqrt2/tau/nan`, require по строке. `coroutine.finally` — в справочнике с 20.10.2026, проверять `if coroutine.finally then`.
**Нельзя полагаться:** классы (`class ... end`), `export` значений, 64-битный `integer`, циклические require, негативные типы — только RFC/внутренние флаги. Ловушка: open-source CLI `luau` и сборки luau-lsp включают все неэкспериментальные флаги и принимают синтаксис, которого Roblox ещё не выпустил; правило — использовать только то, что описано на create.roblox.com/docs.

**Стиль:** строгие типы на границах сервисов, `export type` в `shared/Types`, `unknown` для входящих аргументов remote (а не `any`), структурные типы для внешних пакетов вместо импорта их generic-типов, `table.freeze` для констант (`Config`).

Источники: DevForum 4084991 (New Type Solver); create.roblox.com/docs/luau/variables; .../reference/engine/libraries/buffer, .../vector, .../math, .../coroutine; luau.org/news/2025-12-19-luau-recap-runtime-2025.

<a id="11"></a>
## 11. Ввод (Input Action System)

Для кроссплатформенного (особенно мобильного) ввода используйте IAS: `InputContext` (Enabled, Priority, Sink — например Priority 2000 + Sink перекрывает контексты PlayerScripts), `InputAction` (`Bool`, `Direction1D/2D/3D`, `ViewportPosition`; события `Pressed/Released` для Bool и `StateChanged`; `GetState()`, `Fire()`, `PreferredBinding`, `DisplayName`), `InputBinding` (`KeyCode`, составные Up/Down/Left/Right, `Scale`, **`UIButton`** — привязка touch-кнопки к действию). Рекомендуемая раскладка: `ReplicatedStorage/Inputs/PlayContext` и `NavContext` для меню; переключать контексты при открытии/закрытии меню; у каждого действия должны быть привязки для геймпада, клавиатуры/мыши и касаний. `Workspace.PlayerScriptsUseInputActionSystem = Enabled` — стандартное управление на IAS. Input Action Manager (beta, Window → Input) подсвечивает отсутствующие (жёлтые) и дублирующиеся (красные) привязки. Character Controller Library (beta) заменяет автомат состояний Humanoid модульными «способностями». При Server Authority InputAction клонируется под `Player` на сервере. Дизайн управления для мобилок — `advisor/psychology-retention.md`, UI — `builder/art-ui-audio.md`.

Источник: create.roblox.com/docs/input/input-action-system.

<a id="12"></a>
## 12. Лимиты MessagingService/MemoryStore и платные Extended Services

**MemoryStore** (на весь experience, не на сервер): квота памяти **64 KB + 1,2 KB × пользователи** (в старых заметках встречалось 1 KB — неверно; после ухода игроков квота падает только через 8 дней); запросы **1000 + 120 × CCU единиц в минуту** (`SortedMap:GetRangeAsync` — 1 единица за элемент, `Queue:ReadAsync` — 1 за элемент + 1 за каждые 2 с ожидания, `HashMap:UpdateAsync` — минимум 2); один sorted map/queue — до 1 000 000 элементов и 100 MB; на партицию ≈30 000 единиц/мин (sorted map и queue — одна партиция, hash map — распределены; у ключа hash map ≈5 000 записей и 15 000 чтений/мин; ошибка `PartitionRequestsOverLimit`; документация называет цифры оценочными); hash map: ключ ≤128 символов, значение ≤32 KB; sorted map: sort key ≤128, максимальный TTL 3 888 000 с (45 дней). Ошибка квоты — `TotalMemoryOverLimit`. Вывод: 1 000 CCU дают ≈1,26 MB квоты и ≈121 000 единиц/мин — хватает на матчмейкинг и межсерверные блокировки, не на хранение; глобальный лидерборд на одном sorted map упрётся в партицию — шардируйте.

**MessagingService** (может измениться): сообщение ≤1 KB (тема ≤80 символов); отправка с сервера 600 + 240×игроки в минуту; получение по теме 40 + 80×серверы в минуту; по всей игре 400 + 200×серверы в минуту; подписок на сервер 20 + 8×игроки; запросов подписки 240/мин. Open Cloud публикует только на живые серверы.

**Extended Services** (платно сверх бесплатных лимитов; нужен ID-verified 18+ аккаунт в поддерживаемой стране; минимальный бюджет $0,50/мес; счёт в конце месяца или при достижении $10):

| Сервис | Цена |
|---|---|
| Standard DataStore Get / Set / List / Remove | $0,08 / $0,80 / $0,60 / $0,80 за 1 млн |
| Хранилище DataStore | $0,12 за GB-месяц |
| MemoryStore запросы / хранение | $0,003 за 1 млн / $0,10 за GB-час |
| TTS / STT | $5 / $1 за 1 млн |
| Compute | первые 100 тыс. playtime-часов/мес бесплатно, затем $0,001 за playtime-час (счёт, пока включено) |

Compute «более чем удваивает CPU на игрока»; «подавляющему большинству игр не нужен» — кандидаты: тяжёлая серверная физика или Server Authority с постоянной просадкой heartbeat ниже 60. На странице Extended Services остались устаревшие бесплатные квоты DataStore (250 + CCU×…); канонична страница лимитов (300 + CCU×…).

**HttpService:** 2 500 Open Cloud-запросов/мин на сервер + 500/мин на прочее; ключи — в Secrets.

Источники: create.roblox.com/docs/cloud-services/memory-stores, .../per-partition-limits, .../extended-services; .../reference/engine/classes/MessagingService; .../cloud-services/http-service, .../secrets.

<a id="13"></a>
## 13. Конфликты источников и открытые вопросы

**Разрешено (позднее перекрывает раннее):**
- ProcessReceipt **может yield'ить** (ранняя заметка «не должен» относилась к трансформации `UpdateAsync`).
- Rewarded ads: порог ≈2 000 уникальных посетителей/мес. (не 100K DAU).
- Per-server DataStore лимиты ×40 (не ×10) и настраиваемые; экспириенс-бюджет — связывающее ограничение.
- MemoryStore квота 64 KB + 1,2 KB×users (не 1 KB).
- Официальное руководство по трейдингу/дюпу есть («Data store manipulation»); ранее считалось отсутствующим.
- `Player.AgeChecked` существует (API-дамп); возраст игрока недоступен.
- Jest Roblox 3.20.x в Wally (jsdotlua-форк 3.10.0 и TestEZ устарели); MCP-инструмент `set_active_studio` удалён.
- Баг в исходном `TradeService` (дубли/самообмен) исправлен; `TradeLog` ограничен.
- Custom Events: данные доступны на странице Explore (вкладка Custom Events в Analytics удалена).

**Открыто:**
- Точный JSON/EventType вебхука Transaction Refunded и совпадение transaction id с `PurchaseId` — залогировать первое событие.
- Как включается Android Remote Attestation; статус Hyperion на macOS/iOS/Xbox; статистики эффективности нет.
- Нативный codegen на клиенте — не документирован; сроки выхода `class`/`export`/`integer`.
- Квоты Assistant (суточный лимит существует, число видно только в интерфейсе Studio; форумные утверждения о «5 днях» и «500 Robux» не подтверждены).
- Звёзды/скачивания библиотек — недоступны (использованы зависимости Wally).
- Живой плейтест шаблона и всей цепочки в Studio — не выполнен.
- Внутренняя архитектура топ-студий и MB-бюджеты клиента по устройствам — не публикуются.
