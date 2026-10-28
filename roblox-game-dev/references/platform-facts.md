# Platform facts: быстрая шпаргалка по числам и правилам Roblox (2026)

Назначение: один экран на тему. Самые решающие для дизайна и разработки числа и правила платформы, каждое с датой и указателем на подробный файл. Если нужна причина или контекст, иди по указателю. Если число расходится с подробным файлом, верь более позднему и подробному, а здесь исправь.

**Актуально на: октябрь 2026 (26.10.2026).** Перепроверять в первую очередь: порог и сборы Kids/Select (менялись 4 раза за 2026: 16.06, 16.07, 20.08, 12.09), ставку DevEx и налоговый режим (с 01.11.2026), RFY-сигналы и вес монетизации (менялись 20.08.2026), правила лент и наград (25.08.2026), срок бесплатного Plus (около ноября 2026), версии тулчейна, CCU-пороги чартов (недельный дрейф), комиссию brand deals (с 01.01.2027), платформенный чат (обязателен с мая 2027).

Пометки: **(оф.)** официальные доки Roblox; **(пр.)** практики, пресса, трекеры; **(оц.)** оценка или вывод исследования, не закон.

## Содержание
1. [Аудитория и возрастной гейтинг](#1-аудитория-и-возрастной-гейтинг)
2. [Выплаты, DevEx, налоги](#2-выплаты-devex-налоги)
3. [Сигналы discovery](#3-сигналы-discovery)
4. [Технические лимиты](#4-технические-лимиты)
5. [Правила и цифры монетизации](#5-правила-и-цифры-монетизации)
6. [Запрещённые и рискованные паттерны](#6-запрещённые-и-рискованные-паттерны)
7. [Жизненный цикл: бенчмарки распада](#7-жизненный-цикл-бенчмарки-распада)
8. [Удержание и аналитика: бенчмарки](#8-удержание-и-аналитика-бенчмарки)
9. [Размер сервера по жанру](#9-размер-сервера-по-жанру)
10. [Реклама: стоимость и механика](#10-реклама-стоимость-и-механика)
11. [Тайминг: релизы, апдейты, ивенты](#11-тайминг-релизы-апдейты-ивенты)
12. [Жанровые пороги чарта](#12-жанровые-пороги-чарта)
13. [Календарь изменений правил](#13-календарь-изменений-правил)
14. [Известные расхождения источников](#14-известные-расхождения-источников)

---

## 1. Аудитория и возрастной гейтинг

| Факт | Значение | Дата / тип | Подробности |
|---|---|---|---|
| Доля мобайла среди DAU | около 80% (FY2024) | пр. | builder/art-ui-audio.md; проектируй под Android 2–4 GB |
| Возрастной микс age-checked DAU | 35% младше 13, 38% 13–17, 27% 18+; стабильно Q4 2025 → Q2 2026 | пр. (письмо акционерам) | advisor/psychology-retention.md |
| Платформа | около 123M DAU, около 155 мин на DAU в день, соотношение DAU : средний CCU ≈ 9 : 1 (Q2 2026) | пр. | advisor/discovery-growth.md §12 |
| Релиз «только 16+» | аккаунт в хорошем статусе, старше 2 дней, age-checked, ответ на первый вопрос questionnaire. Бесплатно | оф., окт 2026 | builder/studio-config.md §6 |
| Новая all-ages игра сначала видна только age-checked 16+ | до 250 уникальных plays от highly engaged age-checked игроков за 60 дней + safety review | оф.; порог 500 → **250 с 20.08.2026** | advisor/discovery-growth.md §4, §13 |
| Highly engaged | стаж аккаунта + время в вашей игре + **любая покупка Robux на платформе за 60 дней** (игра сама может быть бесплатной) | оф. | builder/compliance.md |
| Допуск к all-ages | ID-верификация (face, если младше 18) + 2FA + **Plus/Premium 2 месяца подряд ИЛИ возвратный сбор 1 000 R$** на игру | оф. | builder/studio-config.md §6.3 |
| Апдейты | Age check (face/ID) нужен и для публикации новых игр и апдейтов 16+ (DevForum 16.06.2026). Для **all-ages** апдейта нужны Plus/Premium или сбор; игра без них остаётся live, но апдейт не выйдет. Просроченная подписка не снимает игру | оф. (DevForum 16–17.06.2026; доки 13.10.2026) | builder/studio-config.md §6.1 |
| Возврат сбора 1 000 R$ | по докам: 25 highly engaged игроков 60 дней или авто через ~90 дней; считай депозитом | оф., две страницы докладов расходятся | см. §14 |
| Expedited review | **50 000 R$**, ревью 48 ч, возвратный (было 100 000 R$ до **12.09.2026**) | оф. | builder/studio-config.md §6.3 |
| Порог поддержания допуска | 25 игроков (был 100 до 16.07.2026) | оф. | там же |
| Бесплатный Plus | около 100 000 креаторов получили 6 мес. Plus (май 2026), засчитывается вместо сбора; **истекает около ноября 2026**. Перед оплатой сбора смотри зелёный баннер | пр./оф. | builder/studio-config.md §6.3 |
| Аккаунты | Kids 5–8: Minimal/Mild. Select 9–15: до Moderate. 16+ age-checked: всё кроме Restricted | оф. | builder/compliance.md |
| Лейблы контента | Granny-стиль (погоня, jump scare, жуткие NPC) = Mild fear. Любая реалистичная кровь = Moderate; тяжёлая реалистичная кровь = только 18+ | оф. | builder/compliance.md |
| Social hangout и свободное рисование | 16+ (hangout с приватными пространствами 18+) | оф. | builder/compliance.md |
| Лимит релизов | 5 никогда не выпускавшихся игр в день; до 10 early testers | оф. | builder/studio-config.md §6 |

Правило для решений: детская игра (tycoon, obby, pet sim) первые дни видит только 16+. Ранний D1 на этой когорте нерепрезентативен, не убивай по нему. Для запуска у инфлюенсера младше-16 аудитории оплати expedited review до выхода видео.

Источники: [Kids and Select](https://create.roblox.com/docs/production/publishing/kids-and-select) · [Publish games and places](https://create.roblox.com/docs/production/publishing/publish-games-and-places) · [Content maturity](https://create.roblox.com/docs/production/promotion/content-maturity)

---

## 2. Выплаты, DevEx, налоги

| Факт | Значение | Дата / тип | Подробности |
|---|---|---|---|
| Доля создателя | **70%** от цены в Robux: passes, dev products, подписки (Robux), private servers | оф. | advisor/monetization.md §3 |
| DevEx стандарт | **$0.0038 за R$** | оф., с 05.09.2025 10:00 PT (прежняя $0.0035; остатки до этой даты выводятся по старой; проверено по доке DevEx, 07.2026) | advisor/monetization.md §4 |
| DevEx 18+ | **$0.0054 за R$** (+42%) на траты age-checked US 18+ в подходящих играх, **с 08.06.2026** | оф. | там же |
| Условие 18+ ставки | Avatar Settings = **R15 Only**. Любой R6-вариант в любой момент лишает ставки. NPC исключены. Кастомный человекоподобный рига: 15+ частей или суставов, торс ≥2 части | оф. | builder/studio-config.md §2.9 |
| Реальная доля разработчика | около 24.5% трат игроков (21–27% по стандартной ставке, до 38% при 18+) | пр./оц. | advisor/monetization.md §3 |
| Минимальный вывод | 30 000 R$ | оф. | там же |
| **С 01.11.2026** | DevEx считается royalties. Не-US креаторам нужна **W-8BEN** (Creator Hub → Finances → Taxes). Без неё **24% backup withholding со всей выплаты**. С анкетой 0–30% применяется к US-доле игроков | оф. | advisor/monetization.md §4 |
| Creator Rewards (с 24.07.2025) | 5 R$ за день на Active Spender, если ваша игра среди его первых 3 за день и он играл 10+ мин. Active Spender = покупки ≥$9.99 за 60 дней. Плюс 35% от первых $100 нового/вернувшегося пользователя по Share Link, прямой ссылке или поиску по точному имени (нужна игра со средним 100+ DAU за 60 дней). Выплата в Earned Robux, hold 60 дней | оф. (док обновлён 15.10.2026) | advisor/monetization.md §5 |
| Paid-access игры | получают Creator Rewards, платный хоррор/сюжетка не наказан по выплатам | оф. | advisor/monetization.md §9 |
| Brand deals | **с 01.01.2027** Roblox берёт CPTV от $1.50 (US) до $0.05, после дня 28 по $0.10. Креаторы обычно просят $4–5 CPTV. Регистрируйте брендовые ассеты в Ads Manager | оф. | advisor/monetization.md §11 |
| Robux transfers | игре идёт **10%** (DevEx-eligible); сумма 10–500 R$, отправитель с Plus; лимиты 500/день, 1 000/мес (5 000/10 000 с 2SV); награда идемпотентна по `TransferRequestId` | оф. | advisor/monetization.md §13 |
| Cross-game sales | отключены **29–30.05.2026** (PLS DONATE потерял канал; теперь 10% с transfers) | оф. | advisor/case-studies.md §3 |
| Plus как доход | 250 R$/мес × 3 за подписчика, оформившего Plus в вашей игре через `PromptRobloxSubscriptionPurchase`; до 100 R$ за подписчика на ≥60 мин в платном private server. Plus стоит $4.99/мес | оф. | advisor/monetization.md §6 |
| Подписки в местной валюте | 70% в первый месяц, 100% со второго (Robux-подписки: 70% всегда); hold 30 дней; недоступны в AR, CN, CO, IN, ID, JP, RU, TW, TR, AE, UA, VN | оф. | advisor/monetization.md §6, builder/compliance.md |
| Покупка аватарного предмета внутри игры | создатель предмета 30%, владелец игры 40% (affiliate), Roblox 30%; прогрессивная доля только в Marketplace; escrow 30 дней | оф. (док 09.10.2026) | builder/animation.md (Marketplace fees) |
| Commerce products (Shopify, физические товары) | только US-покупатели 13+ (в Техасе 18+); создатель 18+, ID + email + 2FA, Business Information; ≤500 товаров на игру, ≤100 в продаже. Digital benefit: >100K DAU и >1M R$/мес за 90 дней | оф. (док 07.2026) | advisor/monetization.md §12 (Commerce) |
| Ориентиры выручки | платформа около $0.14 gross на DAU в день; один самоотчёт: около $63/день на 1K среднего CCU (одна точка) | пр. | advisor/discovery-growth.md §12 |

Источники: [Developer Exchange](https://create.roblox.com/docs/production/monetization/developer-exchange) · [18+ DevEx rate](https://create.roblox.com/docs/production/monetization/18-plus-devex-rate) · [Tax information](https://create.roblox.com/docs/production/monetization/tax-information) · [Creator Rewards](https://create.roblox.com/docs/creator-rewards) · [Roblox Plus](https://create.roblox.com/docs/production/monetization/roblox-plus)

---

## 3. Сигналы discovery

| Факт | Значение | Дата / тип | Подробности |
|---|---|---|---|
| Доля трафика | Home/RFY **>90%**, чарты <5% (2024; в 2025 повторено «90% starts on Home») | оф. | advisor/discovery-growth.md §1 |
| Самые важные RFY-сигналы | PTR; first-play **bounce** (<60 с и 61–180 с); play days на пользователя; playtime на пользователя (**кап 60 мин на пользователя в день на игру**); каждый по D1, D2–7, D8–28 | оф. | advisor/discovery-growth.md §2 |
| Важные сигналы | intentional co-play days, qualified sessions, spend days, Robux per user | оф. | там же |
| Окно | **28 дней** (с апреля 2026 удержание оценивается за 28+ дней). Метрики берутся как средние на пользователя | оф. | там же §3 |
| Кто считается | только **органические пользователи из RFY**. Ad-acquired не считаются никогда (даже если вернулись через Home). Today's Picks и Teleport-трафик исключены | оф. | там же |
| С 20.08.2026 | retention + monetization вместе дают самое широкое распространение («long-term value») | оф. | там же |
| Age-aware ranking | короткие игры для младших, глубокие возвратные для старших; оценка 28+ дней. Веса не опубликованы | RDC 2026 | advisor/discovery-growth.md §4 |
| Новая игра | сигналы идут сразу; плохой старт не даёт постоянного штрафа (алгоритм тестирует ежедневно) | оф. | там же |
| Non-unique игры | не продвигаются; побеждает первая, давшая уникальные метаданные/place file | оф. | advisor/idea-evaluation.md §2 |
| Story/finite игры | не штрафуются за низкий D8–28 | оф. (FAQ) | advisor/genres-trends.md |
| Genre | менять можно не чаще раза в 3 месяца; определяет жанровые чарты | оф. | builder/studio-config.md §4.2 |
| Thumbnail Personalization | ≥2 активных thumbnails; средний +8.5% qPTR (до +50%) | оф. | builder/packaging.md §8 |
| Gameplay-видео | показывается первым; отклонённые загрузки считаются в квоту **3 в месяц** | оф. | builder/packaging.md §4 |
| Top Trending | рост времени за 2 недели; Top Playing Now: живой CCU | оф. | advisor/discovery-growth.md §5 |
| Trending Events | публичный ивент, начатый ≤7 дней назад, **≥1 000 RSVP**; подавать на Featuring ≥7 дней вперёд | оф. | там же |
| Today's Picks / Standout | редакционные, по номинации опросом; номинируй на каждый заметный апдейт | оф. | там же |
| Search | семантический; нужен описательный жанровый заголовок; search ads до 10 точных ключей на ad set | оф. | advisor/discovery-growth.md §6 |
| Формула | **средний CCU = DAU × минут на DAU ÷ 1440**. Правило «DAU ≈ 4×CCU» неверно | идентичность | advisor/discovery-growth.md §12 |
| Матчмейкинг | веса по умолчанию: Friends 15, Latency 3, Text chat 3, Occupancy 2, Play history 2, Language 2, Age 1, Voice 1; до 2 кастомных сигналов | оф. | advisor/discovery-growth.md §10 |
| Первые минуты | довести до fun «за 5 минут или меньше»; 60 с = «настоящая сессия» | оф. | advisor/psychology-retention.md |

Правило: если D1 слабый, чини ядро; монетизация поднимает показы только поверх сильного удержания (Discovery FAQ).

Источники: [Discovery](https://create.roblox.com/docs/discovery) · [Discovery FAQ](https://create.roblox.com/docs/discovery-faq) · [DevForum 2026-08-06](https://devforum.roblox.com/t/boost-your-discovery-by-building-games-people-want-to-play/4779042) · [RDC 2026 keynote (GamesBeat)](https://gamesbeat.com/?p=334452)

---

## 4. Технические лимиты

| Область | Лимит | Подробности |
|---|---|---|
| Память сервера | **6.25 GiB + 100 MiB × пиковые игроки**; держи ниже 50%. Crash rate выше 2–3% расследовать | builder/code-architecture.md |
| DataStore (per server, в минуту) | Standard read/write = 60 + 40 × игроки (настраивается `SetRateLimitForRequestType` с апр 2026) | builder/code-architecture.md |
| DataStore (на весь опыт) | 300 + 20 × CCU записей в минуту: это реальный предел | там же |
| Размер ключа | 4 194 304 байт. Ограничивай все append-only списки (TradeLog, PurchaseIds, Grants, RefundsApplied) | там же |
| Автосейв | каждые 180–300 с; не на каждое действие | там же |
| Remotes | около 500 запросов/с на клиента; лишние reliable задерживаются, unreliable теряются; payload unreliable ≤1 000 байт | там же |
| HttpService | 500 запросов/мин на сервер; Open Cloud из серверов игры отдельно 2 500/мин | builder/code-architecture.md |
| Webhooks | ответ 2xx за 5 с; 5 ретраев; дедуп по `NotificationId`; HMAC-SHA256 `roblox-signature`; до 5 вебхуков | там же |
| Mesh | ≤20 000 треугольников (union автоупрощается до 20k); целься в ≤10k для пропсов | builder/art-ui-audio.md |
| Текстуры | память растёт с числом пикселей: 1024² = 4 × 512². UI ≤512², большинство ≤256² | там же |
| Аудио | лимит загрузки 2 000 за 30 дней при ID-верификации (иначе 100); файл ≤7 мин, ≤20 MB. Использовать новый Audio API | там же |
| Тени | отключены на качестве графики ниже 4: темноту хоррора делай через Ambient, Exposure, fog, звук | там же |
| Иконки | игра ≤512×512 (thumbnails 1920×1080); иконка пасса круглая | builder/packaging.md |
| Бейджи | 5 бесплатных в сутки на игру, дальше 100 R$; `AwardBadgeAsync` лимит 50 + 35 × игроки/мин, только с сервера; `CheckUserBadgesAsync` до 10 за вызов, 10 + 5 × игроки/мин; игрок может удалить и получить бейдж снова, держи флаг в DataStore | builder/studio-config.md §8 |
| Max players | задаётся только в Creator Dashboard (Places); **≤100 для голосового чата**; больше 100 допустимо без голоса | builder/studio-config.md §3 |
| Обновления | уведомление об апдейте ≤60 символов, раз в 3 дня; строка уведомления ≤99 | builder/liveops.md |
| События | максимум 10 ивентов; подавать на Featuring ≥7 дней вперёд | builder/liveops.md |
| Luau Execution (CI) | ≤10 задач на place, 5 создания задач/мин на ключ, таймаут 5 мин | builder/project-setup.md |
| Open Cloud publish | 30/мин, BETA; не публикует EditableImage/Mesh, PartOperation, SurfaceAppearance, BaseWrap | builder/studio-config.md §12 |
| Нельзя через Open Cloud | security-тумблеры, avatar, genre, questionnaire, подписки, Shop-листинг, первый publish | builder/studio-config.md §12 |
| Текст-фильтр | обязателен для любого видимого игрокам пользовательского текста; без него игру снимают | builder/code-architecture.md |
| Данные игрока | ключи `Player_{UserId}` и RTBF-шаблон с дня 1 | там же |
| Чат | Legacy chat удалён 30.04.2025; **platform-integrated chat обязателен с мая 2027** | builder/studio-config.md §2.2 |
| Native codegen | `--!native` только сервер (с 22.10.2026) | builder/code-architecture.md |
| Тулчейн (окт 2026) | Rojo 7.7.1, Rokit 1.2.0, Wally 0.3.2, Lune 0.11.1, luau-lsp 1.70.1, Selene 0.32.0, StyLua 2.6.0; ProfileStore 1.0.3 | builder/project-setup.md |
| Физика | гравитация 196.2 studs/с²; WalkSpeed 16; JumpHeight 7.2 | builder/studio-config.md §2.8 |

Источники: [DS limits](https://create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits) · [Identify performance issues](https://create.roblox.com/docs/performance-optimization/identify) · [Remote events](https://create.roblox.com/docs/scripting/events/remote) · [Art specifications](https://create.roblox.com/docs/art/modeling/specifications) · [Audio assets](https://create.roblox.com/docs/audio/assets) · [Badges](https://create.roblox.com/docs/production/publishing/badges)

---

## 5. Правила и цифры монетизации

| Правило | Значение | Подробности |
|---|---|---|
| Выдача dev product | **только** в `ProcessReceipt` / `BindReceiptHandler(DeveloperProduct)`, идемпотентно по `PurchaseId`, подтверждать после записи в `LastSavedData`. Не по `PromptProductPurchaseFinished` | builder/code-architecture.md |
| Refunds | passes отзываются Roblox автоматически; **grants dev products отзываешь ты** (webhook Transaction Refunded, сентябрь 2026; храни `{PurchaseId → payload}`) | builder/code-architecture.md |
| Цены | читать `GetProductInfoAsync`, не хардкодить (Plus-скидка 10–20%, региональные цены до −70%) | builder/studio-config.md §7 |
| Лимиты цен | подписка в Robux ≥49 R$ (макс 50 на игру); paid access 25–1 000 R$; Buy-Robux pass >49 и <801 R$ | builder/studio-config.md §7.0 |
| Starter pack | в первые минуты, **не на первом загрузочном экране**; диапазон 3–149 R$, всегда есть товар ≤100 R$ | advisor/monetization.md §16 |
| Старт магазина | магазин с дня 1, входные цены 3–49 R$, лестница с удвоением. P2W после запуска вызывает бэклэш | advisor/monetization.md §15 |
| Season pass | 249–799 R$, около месяца, старт с ~10 тиров (топы 50); RIVALS 799 R$ и 150 R$ за пропуск тира | advisor/monetization.md §15 |
| VIP-подписка | месячная ≈ 35–40% от постоянной (DTI 299 vs 799). Без тиров подписки; одинаковые блага на всех платформах | advisor/monetization.md §7 |
| Private servers | 100–150 R$/мес; смена цены отменяет все подписки | advisor/monetization.md §8 |
| Premium currency | около 5 R$ за единицу на малых паках, 3.6–4.5 на больших; паки не совпадают с ценами предметов; всё должно добываться бесплатно | advisor/monetization.md §15 |
| Gacha-бандлы | 1/3/10/50: лучшая цена за штуку на 10; один anchor 1 500–3 500 R$ | advisor/monetization.md §15 |
| Rewarded video | допуск **≥2 000 monthly unique visitors** + одобренная анкета + 13+ зрители + ID и 2FA владельца. Награда = детерминированный dev product около 3–10 R$, click-to-watch, без RNG и Robux, без мид-файт промптов | advisor/monetization.md §10 |
| RV-цели | obby 15–25% opt-in и 3/день; tycoon/RPG/sports 15%+ и 3+; incremental 13% и 2.8; survival 13% и 2.5; shooter 10% и 3 | advisor/monetization.md §10 |
| Price optimization | нужно ≥60 000 транзакций за 30 дней; ниже: A/B через Experiments + Configs. Early-harm флаги: ARPU или conversion −20%, playtime −10% | advisor/monetization.md §17 |
| Experiments | 14–60 дней; ненадёжны ниже ~10K участников | advisor/discovery-growth.md §11 |
| Дневная конверсия плательщика | 0.5–1.5% норма-сильно; платформа около 1.25% | advisor/monetization.md §14 |
| Сильные игры не продают силу | топ-1–3 по доходу продают косметику, статус, время: RIVALS, Brookhaven, MM2 | advisor/top-games.md §11 |
| Эффективные продуктовые образцы | Server Luck дешевле личной удачи; приоритет роли в асимметрии (Forsaken Killer Chance 319 R$); evolving items (MM2 1 699 R$) | advisor/monetization.md §16 |

Источники: [MarketplaceService](https://create.roblox.com/docs/reference/engine/classes/MarketplaceService) · [Monetization](https://create.roblox.com/docs/production/monetization) · [Rewarded video ads](https://create.roblox.com/docs/production/promotion/rewarded-video-ads) · [Season pass design](https://create.roblox.com/docs/production/game-design/season-pass-design) · [Price optimization](https://create.roblox.com/docs/production/monetization/price-optimization)

---

## 6. Запрещённые и рискованные паттерны

Каждая строка: запрет, дата, последствие. Подробности → builder/compliance.md.

| Паттерн | Правило / последствие | Дата |
|---|---|---|
| Награда за просмотр авто-загружаемой или бесконечной ленты (autoplay/infinite scroll видео и картинок) | запрещено в Kids и Select; Steal An Egg снят с #1 за 3 ч 20 мин. Используй user-started rewarded video | **с 25.08.2026** |
| Симулированный gambling (слоты, рулетка, ставки) | запрещён даже с внутриигровыми предметами; хэтчи всегда дают предмет | Community Standards |
| Paid random items | показать шансы (сумма 100%, включая pity/бустеры), каждый исход даёт пользу, гейт `PolicyService.ArePaidRandomItemsRestricted` (кэш на игрока) | оф. |
| Давление при покупке | без вечных «sales», авто-перезапуска таймеров, ложного дефицита, флеш-скидок; кнопки «View Item» / «Open Shop», не «BUY NOW» | апр 2026 |
| Таймеры, продающие скип | дискурейджатся, получают дизлайки. Фоновые таймеры, награждающие возвращение, допустимы | оф. |
| Урезание платной функции без уведомления | fraud по Standards; объявляй и grandfather покупателей | оф. |
| Конкурсы с Robux | нет Robux/real-money конкурсов; не открывай метаданные раздачами (reduced exposure) | оф. |
| Reskin/клон | non-unique не продвигаются, возможен отказ в рекламе; IP/DMCA: контр-нотис возвращает контент примерно за 14 рабочих дней; AI-изменённые копии репортабельны | оф. |
| Чужой IP | TTD, Anime Adventures, Skyblox, Piggy-ремоделинг заплатили | advisor/case-studies.md |
| Обход платформенных механик для дохода | cross-game sales закрыты 29.05.2026 | оф. |
| Приоритетные регуляторные риски | запрос FTC 20.05.2026 (манипулятивный дизайн: многослойные валюты, искусственный дефицит, loot wheels, видимые инвентари): показывай цены в Robux, ≤2 слоя валют, выставляй заработанное, не купленное | пр. |
| Нет текст-фильтра | игра снимается | оф. |
| Уведомления | 13+, опт-ин не чаще раза в 30 дней, не блокировать игру отказом | оф. |
| Несоответствие questionnaire | искажение ведёт к модерации; переотправляй после апдейтов, меняющих ответы | оф. |
| Не R15-only | теряешь $0.0054 ставку навсегда, пока опция R6 есть | оф. |

Источники: [Community Standards](https://about.roblox.com/community-standards) · [Paid random items](https://create.roblox.com/docs/production/monetization/paid-random-items) · [DevForum 2026-08-25](https://devforum.roblox.com/t/roblox-kids-and-select-new-restrictions-on-reward-driven-media-feeds/4829188) · [IP guidelines](https://create.roblox.com/docs/production/publishing/ip-guidelines)

---

## 7. Жизненный цикл: бенчмарки распада

Все числа про вирусные хиты 2026 это наблюдения по ~20 точкам, не закон. Подробнее → advisor/genres-trends.md §5.

| Показатель | Значение |
|---|---|
| Запуск → пик (вирусный хит 2026) | 4–8 недель |
| Пик → −90% | в медиане 1–1,5 месяца (диапазон 2 недели – 3 месяца) |
| Ускорение распада | 2020: ~6 мес до −80% (Piggy); 2025: 3–4 мес до −90%; 2026: 1–1,5 мес |
| Без мета-слоя | меньше 10% пика за 1–2 мес |
| Игры с глубиной (battlegrounds, RPG, трейдинг, floors) | оседают на 3–12% пика, держатся годами |
| Мега-хиты через год | около 1% пика (SaB 25.9M → ~108–325K; GaG 22.3M → ~17K) |
| Вторая волна копий нового глагола | около 1/10 пика оригинала (Sell Fries 112K vs Animal Hospital 0.74–1.2M) |
| Новые форматы ≥1M CCU в 2026 | примерно раз в 4–6 недель |
| Fast-follow окно | лидеру цикла **<8 недель** и он ещё растёт; иначе поздно |
| Импорт Steam-хитов | 1–3 недели после демо/трейлера; выигрывает первая чистая адаптация |
| Живучесть цикла | steal/collect/raid 17+ месяцев через 3+ скина; каждый следующий скин пикует ниже (SaB 25.9M → SaE 14.3M) |
| Падение без контента | Big-bang без runway: −90% за ~5 недель (Slayers 2: 268K → 24K). Держи 4–6 недель контента к запуску |
| «Тепло», достойное масштабирования | ~500–1 000 CCU с ростом неделя к неделе или ×10 за ≤3 недели |
| Апдейты | игра без апдейтов теряет игроков за недели; выжившие выпускают раз в неделю–две и держат запас 2–3 месяца |
| Трекеры | «all-time peak» RoWatcher/RoTrends надёжен только для игр с 2024 года; старые занижены в 5–10 раз (Blade Ball 60K vs 418K) |
| Платформенный сдвиг | перераспределение показов в июле 2026 срезало показы новичкам ~10× за ночь: мониторь new-user impressions ежедневно |

→ advisor/idea-evaluation.md §1 (скоринг) · advisor/case-studies.md §4 (пороги решений).

Источники: [Roblox Discovery FAQ](https://create.roblox.com/docs/discovery-faq) · [RoWatcher](https://rowatcher.com) · [Plagiarism Today 2026-09-17](https://www.plagiarismtoday.com/2026/09/17/the-attack-of-the-roblox-clones/)

---

## 8. Удержание и аналитика: бенчмарки

**Медианы D1 по средней длине сессии** (GameAnalytics 2025 Roblox report, игры >1M MAU; по жанрам не делится):

| Сессия | D1 median | D1 top 25% | D1 top 10% |
|---|---|---|---|
| 0–3 мин | 4.31% | 7.44% | 9.25% |
| 4–6 мин | 6.20% | — | 11–13% |
| 7–12 мин | 7.91% | 9.82% | 11.55% |
| 13–18 мин | 10.24% | 12.16% | 14.96% |
| 19–24 мин | 11.46% | 13.55% | 18.20% |
| 25+ мин | 10.76% | 12.32% | 18.86% |

D7 median: 0.41% при сессии 0–3 мин, 1.82% при 25+ мин. D30 при 25+ мин: 0.50 / 1.20 / 1.45% (median / top 25% / top 10%).

| Показатель | Значение |
|---|---|
| Платформа 2025 | медианная сессия 6.62 мин; медианный дневной playtime 16.77 мин (P90 64.91) |
| Официальный пример полосы D1 similar-games | 12.11–18.73% (P50–P90; иллюстрация, пул ≥100 DAU) |
| Dashboard бенчмарки | доступны при **≥100 DAU**: retention, session time, CVR, ARPPU, ARPDAU, PTR, play-through. Ниже P50 = доработка, к P90 = масштабирование |
| Полные KPI | >10 DAU и 10 play hours 7 дней подряд |
| Практики: D1 малых разработчиков (2026) | 3–8% на запуске; **D1 <5% рекомендаций не получит**; ~16% после починки прогрессии держал пик ~20K CCU |
| Bounce | 21% → 15% дал +50% CCU (3K → 4.5K) |
| Воронка FTUE | ниже 70–80% конверсии шага = расследуй (Plant потерял 70% на одном шаге) |
| 5-минутная воронка | у разработчиков в игре остаются 50–82% |
| PTR/qPTR (анекдоты) | около 1% низко, 3%+ хорошо (метрика меняла определение 12.10.2026) |
| Игнорировать | жанровые таблицы D1 у RoWatcher (obby 25–35% и т.п.): методологии нет, в 2–3 раза выше GameAnalytics |
| Средняя сессия по жанрам | runner ~9 мин, FPS ~13 (RIVALS), steal-tycoon ~15 (SaE), кооп-хоррор ~8.7, AFK-рыбалка ~90 (Fish It!) |
| Alerts | 100+ DAU, до 20; пример: client crash rate >5% 5 мин |

Источники: [GameAnalytics 2025 Roblox report](https://www.gameanalytics.com/cn/reports/2025-roblox-report) · [Analytics dashboard](https://create.roblox.com/docs/production/analytics/analytics-dashboard) → advisor/discovery-growth.md §11

---

## 9. Размер сервера по жанру

Вывод по 27 подтверждённым точкам (profitable.app, 25–26.10.2026). Ни одной игры в топ-25 с сервером больше 50.

| Социальная функция | Max Players | Примеры |
|---|---|---|
| Кооп-ран (хоррор/выживание) | 1–5 на ран | Pressure 1–3, Animal Hospital ≤4, 99 Nights ≤5 |
| Кража, визиты на участки; асимметрия | 6–10 | SaE 7, SaB 8, Forsaken 9, PS99 10, VD 6 |
| Раундовые социальные, open-world гринд | 12–13 | MM2 12, Blox Fruits 12, DTI 13 |
| Баттлграунды | 15–25 | TSB 15, JJS 25 |
| Рыбалка, AFK-симы | около 20 | Fish It! 20 |
| Roleplay, трейдинг-хабы | 30–35 | Brookhaven 30, Adopt Me! 35 |
| Лобби, ведущее в раны 1–8 | 35–50 | Dandy's World 35, DOORS 50 |

Правила: на малом запуске ставь 8–12, пока серверы не начнут заполняться (оц.). Server Fill = Maximum только для battle royale/матчей. `PreferredPlayers` ниже `MaxPlayers` на размер friend headroom. Тайкун: max players = число плотов. Больше 100 = нет голоса. → advisor/top-games.md §12, builder/studio-config.md §3.

---

## 10. Реклама: стоимость и механика

| Факт | Значение | Подробности |
|---|---|---|
| Аукцион | второй цены по adjusted eCPM; «ads system discounts» вовлекающим играм | advisor/discovery-growth.md §7 |
| Learning / лаг | первые 24 ч learning; данные запаздывают до 48 ч; для engagement нужно 3–5 дней | там же |
| Ad credit | 1 credit ≈ US$1 (раньше 263 R$ по $0.0038). Robux по ставке 18+ конвертируются первыми. Конвертация необратима. Карта: лимит $300/день | там же |
| CPP | Naavik 2025: Maximize plays $0.008; Drive retention $0.007; Reactivate $0.011. Тест DevForum 27.07.2026: $0.044. **Планируй $0.01–0.05 за play**; $100 ≈ 2K–10K plays | там же |
| Оценка креатива | play rate и CPP, не CTR (в одном тесте разброс click→play 34×) | там же |
| Аудитории | New / Recent (нужно ≥10K) / Lapsed (≥20K) | там же |
| Search ads | до 10 точных ключей на ad set; для сравнения используй 1 ключ на ad set | там же |
| Реклама и RFY | ad-пользователи не влияют на RFY-сигналы, но дают когорту и Engagement-цель для порога Kids/Select | там же |
| Фрод-возвраты | приходят на 16-й день к той же кампании | там же |
| Concept test | fake page + Plays-кампания: 10K plays ≈ $80 при $0.008 (оценка 2025; реальный диапазон шире) | advisor/idea-evaluation.md §6 |
| Правило | D1 рекламной когорты ниже P50 similar-games = чинить FTUE и core loop, а не рекламу | там же |
| Ориентир 2023 | Blade Ball: $1 500 рекламы + TikTok → 15K → 100K CCU за 3 дня (исторический, не норма) | advisor/case-studies.md |

Источники: [Ads Manager](https://create.roblox.com/docs/production/promotion/ads-manager) · [Reporting and billing](https://create.roblox.com/docs/production/promotion/reporting-and-billing) · [Search ads](https://create.roblox.com/docs/production/promotion/search-ads)

---

## 11. Тайминг: релизы, апдейты, ивенты

| Факт | Значение | Подробности |
|---|---|---|
| День недели | 7 из 12 крупных запусков пришлись на пт–сб; почти все рекорды CCU на выходных | advisor/top-games.md §13 |
| Апдейты лидеров | Brookhaven пт, SaE/PS99/Blade Ball сб, Fish It! вс; RIVALS мета-апдейт ~раз в 5 недель | там же |
| Окно сб | 14:00–16:00 UTC, до глобального пика ~19:00 UTC (кривая третьей стороны) | advisor/discovery-growth.md §9 |
| Каденс | хиты раз в неделю; малые команды раз в 2 недели–месяц; мажоры раз в 2–3 месяца; официальная база 2–4 недели; арт-дроп ≤~3 недели усилий | builder/liveops.md |
| Сезон / ивент | окно ~4 недели с жёстким концом (MM2 Halloween 18.10–16.11.2026), своя валюта; окончание ивента роняет CCU (MM2 −64%) | advisor/top-games.md §13 |
| Релиз-механика | publish не переносит игроков; рестарт только устаревших серверов с bleed-off 1–60 мин; контент прячь за config и включай в момент дропа | builder/liveops.md |
| Инфраструктура | запас ×10 к дневному уровню в день ивента | advisor/top-games.md §13 |
| Анонс | 60 символов, не чаще 1 раза в 3 дня; Trending Events ≥1 000 RSVP | builder/liveops.md |
| Daily rewards | Engagement Rewards: 7-дневная лестница, заканчивается долговечным предметом | advisor/psychology-retention.md |

---

## 12. Жанровые пороги чарта

RoWatcher, 26.10.2026, ±20%. → advisor/top-games.md §6, advisor/idea-evaluation.md §3.

| Жанр | CCU для #10 в жанре | #20 | Форма |
|---|---|---|---|
| Simulation | ~75K | 38K | глубокий, дорогой вход |
| Survival (с хоррором) | 33K | 13K | лучшая медиана в топ-100 (31K) |
| Roleplay & Avatar Sim | 16K | 7K | #1 ≈ 10× #5 |
| Shooter | 9K | 4K | winner-take-all |
| RPG | ~6K | 3K | #1 ≈ 10× #2 |
| Action | 10K | 6K | умеренный |
| Obby & Platformer | 7K | 4K | перенаселён (~27 игроков на игру) |
| Sports & Racing | 11K | 5K | плоский |
| Strategy (TD) | ~8K | 3K | плоский топ-5 |
| Party & Casual | ~6K | 4K | самый плоский |
| Adventure | ~5K | 3K | тонкий, ~5 игроков на игру |

Пороги общего чарта: #10 ≈ 90–110K, #50 ≈ 20–23K, #100 ≈ 14K.

---

## 13. Календарь изменений правил

| Дата | Изменение |
|---|---|
| 24.07.2025 | Creator Rewards: 5 R$ за Active Spender, 10+ мин, первые 3 игры дня |
| Фев–апр 2026 | RFY: удержание оценивается за 28+ дней; апрельская перестройка рекомендаций |
| 19.05.2026 | Сбор/подписка для all-ages (пилот), в июне глобальный запуск |
| 16.06.2026 | Глобальный запуск Kids/Select: порог 500 HEP, expedited 100 000 R$, сбор 1 000 R$; age check (FAE/ID) для публикации и апдейтов |
| 20.05.2026 | Запрос FTC по манипулятивному дизайну |
| 29–30.05.2026 | Cross-game sales закрыты; Robux transfers (10%) |
| 08.06.2026 | DevEx $0.0054 для US 18+ (R15 Only) |
| 16.07.2026 | Порог поддержания Kids/Select 100 → 25 |
| 20.08.2026 | Порог допуска 500 → 250; retention + monetization для распространения |
| 25.08.2026 | Запрет наград за авто-ленты в Kids/Select |
| 12.09.2026 | Expedited review 100 000 → 50 000 R$ |
| Сентябрь 2026 | Webhook Transaction Refunded |
| 12.10.2026 | Изменение измерения PTR/qPTR |
| 22.10.2026 | `--!native` только на сервере |
| ~Ноябрь 2026 | Заканчивается бесплатный Plus для ~100K креаторов |
| 01.11.2026 | DevEx как royalties, W-8BEN, 24% backup withholding без анкеты |
| 01.01.2027 | Комиссия Roblox с brand deals (CPTV) |
| Май 2027 | Platform-integrated chat обязателен |

---

## 14. Известные расхождения источников

1. **Возврат сбора 1 000 R$.** Publishing-страница: 25 highly engaged игроков 60 дней; FAQ Kids and Select: авто через ~90 дней после допуска. Относись как к депозиту на 60–90 дней (builder/studio-config.md §6.3).
2. **Пик Animal Hospital.** 736 948 (05.07, Rolimons) против >1,2M (12.07, Know Your Meme). Более поздний и высокий правдоподобнее (advisor/genres-trends.md).
3. **Пики Dandy's World.** 238.9K / 319K / 607K у разных источников; не использовать как жёсткий якорь.
4. **Стоимость play.** Naavik $0.008 против RoWatcher $0.015–0.046 (старый курс DevEx) и тестов $0.044. Закладывай $0.01–0.05.
5. **«D1 должен быть 30%+».** Миф из RoWatcher, не подтверждается GameAnalytics (см. §8).
6. **Expedited 100K в старых статьях.** Актуально 50 000 R$ (с 12.09.2026).
7. **Старые материалы про «500 age-checked spenders».** Устарело; порог считается в plays (250).
8. **Пакет пользователя (окт 2026) пишет «500 Highly Engaged Players» и «100 000 R$ expedited».** Это цифры DevForum от 16.06.2026; устарели (250 с 19–20.08.2026, 50 000 с 12.09.2026). Остальное в пакете (сбор 1 000 R$/Plus 2 мес, поддержание 25, FAE для апдейтов, DevEx, Creator Rewards, RV 2 000 MUV, подписки 49 R$/70%, Price Optimization 60 000) совпадает с докой.
