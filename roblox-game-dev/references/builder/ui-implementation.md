# UI в коде: библиотека компонентов шаблона (Luau, без Studio-GUI)

**Назначение.** Как собрать HUD, окна, тосты, награды и офлайн-попап из готовой библиотеки `assets/template/src/client/ui/`, не теряя канон ([ui-canon](ui-canon.md)) и тайминги ([animation](animation.md) §14-§15). Файл отвечает на вопросы «какой модуль взять», «как вызвать», «какие значения по умолчанию», «что проверить перед сдачей». Что рисовать и какого цвета (иконки, редкости, расположение) решает [ui-canon](ui-canon.md); как выглядит макет «уровня топ-игр» из Figma и как резать графику, см. [ui-figma-workflow](ui-figma-workflow.md); иконки через AI см. [ai-art-generation](ai-art-generation.md).

**Актуально на: октябрь 2026.** Перепроверять: (1) `GuiService.ReducedMotionEnabled` и `ScreenGui.ScreenInsets` (поведение на новых устройствах с вырезами); (2) зоны `Theme.Zones` (приближённые доли экрана под DynamicThumbstick и кнопку прыжка); (3) глиф Robux `utf8.char(0xE002)` и шрифты Fredoka One / Builder Sans (набор встроенных шрифтов меняется); (4) всё из раздела «Что не проверено».

## Оглавление

1. [Главные правила](#1-главные-правила)
2. [Архитектура](#2-архитектура)
3. [Быстрый старт](#3-быстрый-старт)
4. [Компоненты: вызовы и поведение](#4-компоненты)
5. [Соответствие канону (ui-canon)](#5-соответствие-канону)
6. [Моушн: значения по умолчанию](#6-моушн-значения-по-умолчанию)
7. [Деньги и данные: границы компонентов](#7-деньги-и-данные)
8. [Производительность](#8-производительность)
9. [Читаемость и контраст на телефоне](#9-читаемость-на-телефоне)
10. [Замена плейсхолдеров на AI-иконки](#10-ai-иконки)
11. [Демо-контроллер и отладка](#11-демо-контроллер)
12. [Чек-лист перед сдачей](#12-чек-лист)
13. [Что не проверено](#13-что-не-проверено)

---

## 1. Главные правила

1. **Один `ScreenGui`, один `Screen`.** Всё живёт в слоях `Screen.Hud / Windows / Overlay / Toasts`; свои `ScreenGui` не плодить (порядок отображения и safe area решаются в одном месте).
2. **Размеры в «дизайн-единицах»**, а не в пикселях: `Screen` вычисляет `UIScale` по высоте экрана (`Theme.Sizes[device].refHeight`), компоненты читают `screen.Sizes`. Не писать `Offset` в пикселях под конкретный телефон.
3. **Компонент только сообщает о клике.** Покупка, награда, ребёрс, телепорт делаются вашим кодом и сервером (§7). Компонент никогда не вызывает `MarketplaceService` и не меняет данные игрока.
4. **Одно окно за раз** (`WindowManager`); открытие окна закрывает предыдущее без анимации.
5. **Каждый компонент владеет своими соединениями** (`Util.newCleaner`) и имеет `destroy()`. Подписка вне компонента на `screen.Resized` требует своего отключения.
6. **Никаких пересчётов по кадрам**, кроме трёх осознанных циклов: `CurrencyCounter:countTo` (только пока идёт счёт), `RewardFlyToCounter` (только пока летят спрайты), таймеры офферов (раз в секунду, только пока есть активный).
7. **Reduced motion обязателен:** все твины идут через `Util.tween*`, которые при `GuiService.ReducedMotionEnabled` применяют результат мгновенно ([animation](animation.md) §10.1 п. 7).
8. **Семантика цвета не меняется:** зелёный = купить/подтвердить, красный = закрыть/отмена, золотой = особое действие (ребёрс), серый = нейтральное. Идентичность игры задаётся в `Theme.luau` (палитра, шрифт, фон панели), а не в компонентах.

---

## 2. Архитектура

```
src/client/ui/
  Theme.luau            токены: цвета, варианты кнопок, шрифты, штрихи, радиусы, Sizes[phone|tablet|desktop], Zones
  Motion.luau           тайминги (окно, кнопка, счётчик, тост, полёт награды); см. §6
  Curves.luau           чистая математика кривых (countCurve, easeIn/Out); тестируется обычным Luau CLI
  Format.luau           K/M/B/T (через shared/NumberFormat), duration, clock, multiplier, percent, robux
  Util.luau             Cleaner, tween с reduced motion, билдеры (frame, text, stroke, pill, list, scale)
  Icons.luau            реестр иконок по ключу: ImageLabel с asset id либо глиф-плейсхолдер
  Screen.luau           ScreenGui + Root(UIScale) + слои; Size/Scale/Device; Resized; toLocal/centerOf
  Button.luau           кнопка «толстая» (тень, обводка, градиент, блик), варианты; Button.close; attachFeedback
  Badge.luau            красный кружок-уведомление
  CurrencyCounter.luau  пилюля валюты: set / countTo / bump; Icon как цель полёта
  LeftMenuStack.luau    левое меню: плитки с подписью под иконкой, бейджи, перенос в колонки
  TopTabs.luau          вкладки сверху по центру
  OfferButtons.luau     правая колонка офферов: плитка, зелёная цена, честный таймер
  ProgressBar.luau      полоса уровня/прогресса
  Window.luau           модальное окно канона: заголовок-вкладка, красный квадратный X
  WindowManager.luau    одно окно за раз, затемнение/размытие по DimMode
  Toasts.luau           стопка тостов, склейка «[X2]»
  RewardFlyToCounter.luau  спрайты летят к счётчику, пул, один цикл RenderStepped
  OfflineEarningsPopup.luau  «Welcome BACK!»: OKAY / DOUBLE IT, покупка только через колбэк
  ZoneAudit.luau        dev-проверка: нет кнопок в зонах стика и прыжка
src/client/controllers/UiDemoController.luau   пример сборки всего HUD (удалить в реальной игре)
```

**Слои `Screen`** (`ZIndex` слоя, всё внутри `Root` с `UIScale`):

| Слой | Что в нём | Заметка |
|---|---|---|
| `Hud` | валюты, левое меню, вкладки, офферы | интерактив вне `Theme.Zones` |
| `Windows` | затемнение и модальные окна | окна поверх HUD |
| `Overlay` | летящие спрайты наград | не перехватывает ввод |
| `Toasts` | тосты | поверх всего, `Active = false` |

**Поток данных.** `StateController` (зеркало серверных данных) → контроллер вашей игры → `component:set(...)` / `show(...)`. Клик: компонент → ваш колбэк → интент на сервер (`Remotes.get(...):FireServer(name)`) → сервер проверяет → `StateChanged` → UI обновляется. Клиент не считает цены и награды ([code-architecture](code-architecture.md) §1, §4).

**Safe area и масштаб.** `ScreenGui.ScreenInsets = CoreUISafeInsets` (верхняя панель Roblox, вырез, индикатор «домой» исключены). `UIScale = clamp(высота / refHeight, min, max)`, дополнительно `scale <= ширина / 420`, чтобы вкладки и окна не вылезали на узких окнах. Класс устройства: `desktop` (есть клавиатура или не тач), `phone` (тач, меньшая сторона < 600), иначе `tablet`. Переопределить для теста: `Screen.new(gui, { device = "phone" })`.

---

## 3. Быстрый старт

```lua
local ui = script.Parent.Parent.ui          -- из контроллера в src/client/controllers
local Screen = require(ui.Screen)
local WindowManager = require(ui.WindowManager)
local Toasts = require(ui.Toasts)

local screen = Screen.new(Players.LocalPlayer:WaitForChild("PlayerGui"), { name = "Ui" })
local windows = WindowManager.new(screen)
local toasts = Toasts.new(screen)
```

Порядок в `Main.client.luau`: сначала построить UI и подписаться на `StateController`, потом `StateController.start()` (он шлёт `ClientReady`, и начальное состояние не потеряется). Флаг `SHOW_UI_DEMO` в `Main.client.luau` включает пример; при старте своей игры поставьте `false`, удалите `require` демо и сам файл `UiDemoController.luau`.

---

## 4. Компоненты

Везде `sizes = screen.Sizes` (таблица `Theme.Sizes[device]`); размеры берутся при построении. Сигнатуры подробно в комментариях модулей.

### 4.1 Theme, Icons, Format

```lua
Theme.Colors.Green; Theme.Variants.primary.fill        -- токены
Theme.Sizes.phone.close                                -- 44 (цель касания)
Icons.new(parent, "coin", UDim2.fromOffset(32, 32))    -- ImageLabel (глиф, пока нет asset id)
Icons.register("ruby", utf8.char(0x1F534), Color3.fromHex("F2453D"))   -- игровой ключ
Format.abbreviate(1_999)      --> "1.9K"  (усечение, не округление; 3 знака максимум)
Format.duration(8375, 2)      --> "2h 19m"
Format.clock(75)              --> "1:15"  (таймеры «0:05» по канону)
Format.multiplier(1.5)        --> "x1.5"
Format.robux("99", Theme.RobuxGlyph)   --> "<глиф> 99"
```

### 4.2 Button

```lua
local buy = Button.new({
	text = "100", icon = "coin", variant = "primary",        -- primary зелёный | secondary серый | danger красный | gold | info
	size = UDim2.new(1, -16, 0, sizes.buttonHeight), textSize = sizes.buttonText,
	onClick = function() requestBuy("Flashlight") end,       -- только интент
})
buy.Instance.Parent = card            -- Instance: слот-Frame (его размер ваш), Button: сама TextButton
buy:setEnabled(false)                 -- серая, не кликается
Button.new({ robux = "99", variant = "primary", onClick = promptMyProduct })   -- «<глиф> 99», цена из ProductInfo
Button.close(sizes.close, function() ... end)                -- красный квадрат с X
```

Нажатие: масштаб 0.95 за 0.08 с, hover на ПК 1.05; обратная связь на `UIScale` внутри слота, поэтому списки не дёргаются. `Button.attachFeedback(guiButton, uiScale, cleaner)` даёт ту же реакцию любому своему `GuiButton`.

### 4.3 Window и WindowManager

```lua
local shop = Window.new(screen, { id = "shop", title = "Shop", size = Vector2.new(500, 250) })
windows:register(shop)
-- контент кладёте в shop.Content (Frame внутри панели, отступы уже учтены)
windows:open("shop"); windows:toggle("shop"); windows:close()
windows.Changed:Connect(function(id: string?) ... end)       -- id открытого окна или nil
```

Опции окна: `dim = "none" | "dim" | "blur" | "both"` (по умолчанию `both`), `closable` (красный X, по умолчанию да), `dismissOnDim` (тап вне окна закрывает; для платёжных диалогов не включать), `onOpen/onClose`. Открытие: `UIScale` 0.6 → 1 за 0.3 с Back Out; закрытие: 1 → 0.95 за 0.1 с Quad In. Размер подгоняется под экран (`fit`), минимум 200x120. `CanvasGroup` не используется (память на телефоне).

### 4.4 CurrencyCounter

```lua
local coins = CurrencyCounter.new({ id = "coins", icon = "coin", value = 0, height = sizes.currencyHeight,
	textSize = sizes.currencyText, onPlus = function() windows:open("shop") end })   -- зелёный «+» только для продаваемой валюты
coins.Instance.Parent = screen.Hud
coins:set(1234)             -- мгновенно: пассивный доход, мелкие изменения
coins:countTo(5_000_000)    -- ~1 с: ползучий старт (25% времени, до 8% пути), быстрый проход, мягкий хвост
coins:bump()                -- пульс 1.08 (вызывается при прилёте спрайтов)
coins.Icon                  -- цель полёта наград
```

Текст переписывается только при смене строки, поэтому секундный счёт стоит ~20 обновлений текста.

### 4.5 LeftMenuStack, Badge

```lua
local stack = LeftMenuStack.new(screen, {
	items = {                                        -- порядок по канону: Shop, затем Rebirth/Pass, Index/Settings последними
		{ id = "shop", label = "Shop", icon = "shop", badge = true },        -- true = "!", число = счётчик, 99+ сверху
		{ id = "rebirth", label = "Rebirth", icon = "rebirth", badge = 1 },
	},
	onClick = function(id: string) windows:toggle(id) end,
})
stack:setBadge("shop", nil)     -- скрыть бейдж
```

Колонка не опускается ниже `Theme.Zones.leftStackBottom` (58% высоты); если плитки не помещаются, они переносятся в соседнюю колонку (4 плитки на телефоне = 2x2). Пересчёт только при `screen.Resized`.

### 4.6 TopTabs

```lua
local tabs = TopTabs.new(screen, { tabs = { { id = "collect", label = "COLLECT" }, { id = "sell", label = "SELL" } },
	selected = "collect", onSelect = function(id: string) ... end })
tabs:setSelected("sell")
```

Состояние показано прозрачностью (выбранная 0, остальные 0.35) и размером (+4), а не только цветом. На телефоне 2-4 вкладки.

### 4.7 OfferButtons

```lua
OfferButtons.new(screen, { offers = {
	{ id = "starter", title = "Starter", icon = "starter", priceText = "99", timerSeconds = serverDeadline - os.time() },
}, onClick = function(id: string) windows:open("shop") end })
```

Цена: готовая строка из `ProductInfo`; зелёная пилюля с глифом Robux. Таймер показывает только реальный серверный дедлайн, сам не перезапускается, зачёркнутой «старой цены» нет ([compliance](compliance.md)). Колонка не ниже `Theme.Zones.rightColumnBottom` (55%). Методы `setTimer(id, seconds?)`, `setVisible(id, bool)`.

### 4.8 ProgressBar

```lua
local bar = ProgressBar.new({ size = UDim2.new(1, -24, 0, 26), level = 3, color = Theme.Variants.gold.fill })
bar:set(640_000, 1_000_000, false)      -- третий аргумент false = без анимации; текст «640K/1M»
```

### 4.9 Toasts

```lua
local toasts = Toasts.new(screen)
toasts:show("Not enough coins", { kind = "error" })                 -- info | success | error | reward
toasts:show("You successfully rebirthed!", { kind = "success", placement = "bottom", hold = 5 })
toasts:show("Item added!", { kind = "success", icon = "star" })
```

Текст с контуром без панели; вход 0.18 с, удержание 2.8 с, выход 0.25 с; повтор живого сообщения даёт «[X2]», «[X3]» и перезапускает таймер; не больше 4 живых (старейший уходит раньше срока). `placement = "top"` ниже вкладок; `"bottom"` занимает только середину ширины (28%), между стиком и прыжком. Ключ склейки по умолчанию равен тексту (`key =` для сообщений с переменными числами).

### 4.10 RewardFlyToCounter

```lua
local fly = RewardFlyToCounter.new(screen)
coins:countTo(newTotal)                                   -- старт счёта вместе с началом полёта
local handle = fly:play({ count = 12, icon = "coin", from = Vector2.new(screen.Size.X / 2, screen.Size.Y / 2),
	target = coins.Icon, onBump = function() coins:bump() end, onDone = function() ... end })
handle.cancel()                                           -- без вызова onDone
```

`from` задаётся в дизайн-единицах или `GuiObject` (берётся центр). Спрайты вылетают из точки на радиус ~56, затем ускоряются к цели (цель отслеживается каждый кадр). Старт по одному: шаг 0.04 с, весь запуск не дольше ~0.7 с; один полёт 0.55 с (минимум 0.15); одновременно не больше 30 спрайтов (`Motion.FlyMaxAlive`). Reduced motion: полёта нет, колбэки вызываются сразу.

### 4.11 OfflineEarningsPopup

```lua
local popup
popup = OfflineEarningsPopup.new(screen, {
	manager = windows, offlineSeconds = 8375, earned = serverEarned, capSeconds = 8 * 3600,
	doublePriceText = "25",                                 -- из ProductInfo
	onRequestDouble = function() myCode.promptDouble() end,    -- ТОЛЬКО ваш код вызывает покупку
	onCollect = function(multiplier, amount) playRewardChain(amount) end,   -- после закрытия попапа
})
popup:show()
-- по результату покупки (ProcessReceipt прошёл / игрок отменил):
popup:resolveDouble(true)    -- собрать x2;   resolveDouble(false) вернёт кнопки в обычное состояние
```

Поведение по [animation](animation.md) R29/R31: без затемнения и размытия (`dim = "none"`), HUD идёт позади; серая OKAY и зелёная «DOUBLE IT! x2» с ценой; во время покупки обе кнопки заблокированы; `onCollect` вызывается один раз через ~0.1 с после закрытия, и только тогда запускается награда (полёт + счёт). Если попап вытеснило другое окно, это считается OKAY (x1): заработанное не теряется. Красного X нет (ни «собрать», ни «потерять» он не выражает). Сама выдача x1/x2 происходит на сервере; `earned` на клиенте только для показа.

### 4.12 ZoneAudit

```lua
for _, problem in ZoneAudit.check(screen) do warn(problem) end      -- пусто = чисто; на desktop пусто, если не force
```

Запускать в Studio в эмуляторе телефона через ~1 с после построения HUD. Исключение для осознанной кнопки: атрибут `AllowInTouchZone = true`.

---

## 5. Соответствие канону

| Правило [ui-canon](ui-canon.md) | Где реализовано |
|---|---|
| Close = красный скруглённый квадрат, белый X, правый верхний угол, частично за рамкой | `Button.close`, `Window` (позиция `1, -6 / 0, 6`, якорь 0.5) |
| Buy/Claim/Confirm = зелёный; Cancel/Decline = красный; особое (Rebirth) = золото | `Theme.Variants`, `Button` (варианты) |
| Покупка за Robux: зелёная кнопка, глиф Robux, цена из ProductInfo | `Button` (`robux =`), `OfferButtons`, `Format.robux`, `Theme.RobuxGlyph` |
| Левое меню: иконка над подписью, Shop первым, бейдж-кружок | `LeftMenuStack`, `Badge` |
| Валюта: пилюля «иконка + число (K/M/B/T) + зелёное +» вверху слева | `CurrencyCounter`, `Format.abbreviate` |
| Rebirth = красно-белые круговые стрелки | ключ `rebirth` в `Icons` (плейсхолдер, затем AI-иконка по [ai-art-generation](ai-art-generation.md)) |
| Вкладки сверху по центру, состояние не только цветом | `TopTabs` |
| Заголовок окна: толстая тёмная обводка, плавающая синяя вкладка | `Window` (`TitleTab`), `Util.text` |
| Лестница редкостей серый/зелёный/синий/фиолетовый/оранжевый/красный + название текстом | `Theme.Rarity` |
| Офферы справа с зелёной ценой и честным таймером | `OfferButtons` |
| Офлайн: серый OKAY + зелёный DOUBLE IT x2 R$ | `OfflineEarningsPopup` |
| Мобильные зоны: не закрывать стик и прыжок | `Theme.Zones`, `LeftMenuStack`/`OfferButtons` (лимиты), `Toasts` (bottom), `ZoneAudit` |
| Отступление от канона записать в `art/style-bible.md` | вручную; менять только `Theme.luau` |

Не покрыто библиотекой (делайте по [ui-canon](ui-canon.md) §3 сами): карточки Game Pass со сложной раскладкой, сетка инвентаря/Index с силуэтами «???», колесо спина, панель Settings с переключателями.

---

## 6. Моушн: значения по умолчанию

Все значения в `Motion.luau`; менять там, а не в компонентах.

| Что | Значение | Правило |
|---|---|---|
| Открытие окна | 0.3 с, Back Out, `UIScale` 0.6 → 1 | R12 |
| Закрытие окна | 0.1 с, Quad In, 1 → 0.95, затем скрыть | R13 (≤ 0.15 с) |
| Затемнение / размытие | прозрачность 0.55; `BlurEffect` 12; 0.2 с | R12; офлайн-попап без обоих (R29) |
| Нажатие кнопки | 0.95 за 0.08 с | R14 |
| Hover (только ПК) | 1.05 за 0.12 с | R14 |
| Малые счётчики | мгновенно (`set`) | R16 |
| Крупная награда (`countTo`) | 1.0 с: ползучий 25% времени до 8% пути, быстрый проход, мягкий хвост | R16 |
| Пульс счётчика (`bump`) | 1.08, 0.1 с туда и обратно | R16/R17 |
| Тост | вход 0.18 с, удержание 2.8 с (не меньше 2.6), выход 0.25 с, максимум 4 | R19 |
| Ребёрс-тост | снизу по центру, `hold = 5` | R18 |
| Полёт награды | 0.55 с на спрайт, шаг 0.04 с, запуск ≤ 0.7 с, ≤ 30 живых | R17, R31 |
| Полоса прогресса | 0.25 с, Quad Out | не из правил, вкус |
| Бейдж | 1.25 → 1 за 0.2 с при смене значения | вкус |

Цепочка клейма ([animation](animation.md) R31): клик → попап закрывается (≤ 0.15 с) → `onCollect` → `countTo` и `fly:play` одновременно → пульсы по прилёту. Если награда приходит без попапа (сундук, квест), цепочка та же без первого шага.

---

## 7. Деньги и данные

| Что | Правило |
|---|---|
| Кто вызывает `PromptProductPurchase` | только ваш код, в ответ на `onClick`/`onRequestDouble`; компонент не знает ID продукта |
| Откуда цена | `ProductInfo` (`priceText`/`robux`), не хардкод; демо использует строки "99", "25" только для показа |
| Кто выдаёт награду | сервер: `ProcessReceipt` для x2, обычный интент для x1; `onCollect` лишь уведомляет |
| Что считает клиент | ничего: суммы и цены приходят с сервера, клиент показывает и шлёт интенты |
| Таймеры офферов | остаток серверного дедлайна; клиентский `os.clock()` только отсчитывает секунды |
| Результат покупки | `resolveDouble(true/false)` вызывайте после подтверждённого серверного ответа (не по `PromptProductPurchaseFinished`, который не гарантирует выдачу) |
| Платные случайные предметы, трейды | гейтятся `Policy.*` на сервере, а UI ещё и скрывается ([compliance](compliance.md)) |

Пока попап ждёт результат покупки, он должен получить `resolveDouble` в любом исходе (отмена, ошибка, таймаут своей логики), иначе кнопки остаются заблокированными.

---

## 8. Производительность

1. **Анимируем только `UIScale`, позицию, прозрачность** отдельных элементов; не размер вложенных layout-контейнеров и не `UIStroke.Thickness`.
2. **Layout пересчитывается по событию**, а не в цикле: `screen.Resized` (меняется редко), смена строки счётчика.
3. **Один цикл на подсистему.** Счётчик: `RenderStepped` только во время счёта, затем отключается. Полёт наград: одно соединение на все спрайты, отключается при пустой очереди. Офферы: `task.wait(1)` пока есть активный таймер.
4. **Пул спрайтов** (`RewardFlyToCounter`): `ImageLabel` создаются по мере необходимости и переиспользуются; лимит 30 живых.
5. **Окна без `CanvasGroup`**, скрытые окна строятся один раз с `Visible = false`; `BlurEffect` создаётся при первом использовании и далее только меняет `Size`.
6. **Число UI-инстансов** держите в узде и замеряйте (Memory, MicroProfiler); списки инвентаря делайте пулом или виртуальным списком ([art-ui-audio](art-ui-audio.md) §6).
7. **Тосты**: максимум 4 одновременно, склейка повторов вместо новых инстансов.
8. **Глиф-плейсхолдеры** (`TextLabel` с эмодзи) дороже `ImageLabel`; после загрузки иконок `Icons.apply` скрывает глиф, но не удаляет его: на экране, где иконок сотни, создавайте иконки без глифа своей функцией.
9. Замер: MicroProfiler (метки `RenderStepped`), вкладка Memory для GUI, эмулятор слабого устройства ([visual-audit](visual-audit.md)).

---

## 9. Читаемость на телефоне

| Правило | Значение |
|---|---|
| Минимальный размер текста | подпись плитки ≥ 11 (`tileLabel`), мелкий текст ≥ 13, основной 16-18 дизайн-единиц |
| Цель касания | X-закрытие 44 дизайн-единицы; кнопки 40-46; при `UIScale` < 1 реальный размер меньше, поэтому `Theme.ScaleRange.min` не опускать ниже 0.8 на тач-устройствах |
| Текст на цветном фоне | белый с тёмной обводкой 2-2.5 (`Theme.Stroke.Text`), не серый на сером |
| Текст на кремовой панели | `TextDark` (≈ 11:1 контраст) без обводки; `TextMuted` только для второстепенного |
| Зелёное число на тёмной вставке | `Colors.Pill` + зелёная рамка, число с обводкой (офлайн-попап) |
| Состояние не только цветом | выбранная вкладка: прозрачность и размер; редкость: цвет и название |
| Короткие подписи | 1-2 слова; `TextTruncate = AtEnd` стоит на плитках, кнопках, ценах |
| Safe area | `CoreUISafeInsets`; проверять в эмуляторе с вырезом |
| Зоны управления | левый нижний стик (x 0-40%, y 50-100%), прыжок (x 68-100%, y 52-100%); HUD вне них |

Проверка: эмулятор устройств Studio (телефон 16:9 и 20:9, планшет), скриншот в реальном размере; если подпись не читается на скриншоте 1:1, она не читается у игрока ([ui-figma-workflow](ui-figma-workflow.md) §1, [visual-audit](visual-audit.md)).

---

## 10. AI-иконки

Плейсхолдеры (эмодзи) нужны, чтобы прототип работал без загрузок. Для релиза:

1. Сгенерируйте набор по [ai-art-generation](ai-art-generation.md) §3-§4 (единый style bible, лист 4x3, нарезка §5.2, альфа проверена, 256 px). Ключи библиотеки и имена файлов стартового набора: `Icons.manifest()` (`shop` → `ic_shop.png`, `rebirth` → `ic_rebirth.png`, `coin` → `ic_coin.png`, `gem` → `ic_gem.png`).
2. Загрузите PNG ([ai-art-generation](ai-art-generation.md) §6), проверьте один `rbxassetid://` в `ImageLabel`, запишите ID в манифест `art/ui-assets.json`.
3. Подключите при старте клиента, до построения UI:

```lua
Icons.setAssets({ shop = "rbxassetid://123", rebirth = "rbxassetid://456", coin = "rbxassetid://789" })
Icons.register("ruby", "?", Color3.fromHex("F2453D"), "rbxassetid://321")   -- новый игровой ключ
```

4. Иконки, созданные после `setAssets`, сразу берут картинку; ранее созданные можно обновить `Icons.apply(label, key)`.
5. Держите канон формы: ребёрс = красно-белые круговые стрелки, Shop = корзина/тележка, Close не иконка, а `Button.close`. Надписи на картинках не рисовать, текст всегда `TextLabel`.
6. Плитки меню красятся `Icons.tint(key)`: после замены иконок подберите `tint` под фон картинки (`Icons.register` перезаписывает), чтобы иконка не сливалась с плиткой.
7. Для панелей и кнопок как 9-slice-картинок ([ai-art-generation](ai-art-generation.md) §4.8, §5.5) замените фон в `Window`/`Button` на `ImageLabel` с `SliceCenter`; логику компонентов менять не нужно.

---

## 11. Демо-контроллер

`controllers/UiDemoController.luau` собирает: валюты (монеты с зелёным «+», гемы), левый стек Shop/Pass/Rebirth/Index с бейджами, вкладки COLLECT/UPGRADE/SELL, офферы справа (Starter с таймером, x2 Cash, VIP), окна Shop (три карточки: две за монеты через настоящий `BuyItem`, одна «за Robux» как заглушка) и Rebirth (полоса, золотая кнопка, красная CANCEL), тосты, цепочку награды и офлайн-попап.

Только в Studio: клавиши **P** (офлайн-попап), **T** (тост; нажимайте повторно, чтобы увидеть «[X2]»), **R** (награда: полёт + счёт), те же действия тремя кнопками в нижней середине для эмулятора телефона; через секунду после старта `ZoneAudit` пишет предупреждения в Output. Фейковые суммы и «покупка» x2 (одобрение через 1.2 с) помечены в коде как DEMO.

Как использовать: скопировать нужные куски в свой контроллер, подписаться на `StateController.observe(...)`, остальное удалить. `HudController.start({ coinLabel = false })` отключает простую метку монет, когда UI строит библиотека.

---

## 12. Чек-лист

Перед сдачей экрана (дополняет чек-лист [ui-canon](ui-canon.md) §6):

1. [ ] Канон функций соблюдён (§5): красный X справа сверху, зелёная покупка, золото только для особых действий, ребёрс красно-белый.
2. [ ] Один `Screen`; одно открытое окно за раз; `windows:open` вместо ручного `Visible`.
3. [ ] Скриншоты в эмуляторе: телефон 16:9, 20:9 с вырезом, планшет, ПК 1080p. Ничего не обрезано, подписи читаются 1:1.
4. [ ] `ZoneAudit.check(screen)` пуст на телефоне (или исключения обоснованы).
5. [ ] На телефоне нет кнопок ниже 40 дизайн-единиц (X-закрытие 44) и текста меньше 11.
6. [ ] Все числа через `Format.abbreviate` (K/M/B/T), таймеры через `Format.clock/duration`.
7. [ ] Покупки: компонент не вызывает `MarketplaceService`; цены из `ProductInfo`; результат через сервер; `resolveDouble` вызывается в любом исходе.
8. [ ] Награда: цепочка закрытие → полёт → счёт → пульс; ≤ 30 спрайтов; `countTo` только для крупных сумм.
9. [ ] Reduced motion включён в настройках: UI остаётся рабочим без анимаций (проверить вручную).
10. [ ] Офферы: таймер из серверного дедлайна, без перезапуска и без зачёркнутой цены ([compliance](compliance.md)).
11. [ ] Иконки: asset id загружены и прошли модерацию, плейсхолдеров-эмодзи на экране нет ([ai-art-generation](ai-art-generation.md) §6, §8).
12. [ ] `destroy()` вызывается для всего, что создаётся не один раз (попапы, временные окна).
13. [ ] Демо удалено (`SHOW_UI_DEMO = false`, файл контроллера удалён), отладочные клавиши не попали в релиз (они только в Studio).
14. [ ] `scripts/analyze.sh` без ошибок, `selene src`, `stylua --check src`.

---

## 13. Что не проверено

- **Всё визуальное:** библиотека проверена статическим анализом (`luau-lsp`, 0 диагностик в старом и новом решателе типов), математика форматирования и кривых проверена тестами в Luau CLI. В Studio и на устройствах она не запускалась: внешний вид, расположение, перенос в колонки, отсечение текста, тайминги на глаз не подтверждены.
- `Theme.Zones` приблизительны; реальные размеры DynamicThumbstick, кнопки прыжка и вырезов не измерялись.
- Положение `ScreenInsets` и `AbsolutePosition` при `CoreUISafeInsets`: `Screen.toLocal` предполагает, что позиции `GuiObject` и `Root.AbsolutePosition` в одной системе координат. Если спрайты вылетают со смещением на устройстве с вырезом, исправляйте в `Screen.toLocal`.
- `RewardFlyToCounter` принимает точку в дизайн-единицах или `GuiObject`; старт из 3D-точки мира (`Camera:WorldToViewportPoint`) не реализован и не проверялся.
- Шрифты `FredokaOne` и `BuilderSansBold`, глиф Robux `0xE002` и эмодзи-плейсхолдеры могут отображаться иначе на разных платформах.
- `rojo build`, StyLua и Selene в среде разработки библиотеки не запускались (инструменты недоступны offline).
- Как ведёт себя `WindowManager` вместе с родными CoreGui-окнами (чат, меню паузы, эмоуты) и с геймпадом (навигация по кнопкам, `GuiService.SelectedObject`): не проверялось; консольный UI не поддержан.
- Лимит `Motion.FlyMaxAlive` взят из [animation](animation.md) (R17/R31), собственных замеров на слабых телефонах нет.
