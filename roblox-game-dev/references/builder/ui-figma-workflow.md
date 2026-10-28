# UI-арт через Figma + AI-агента: от макета до Roblox UI, который не выглядит «сделанным кодом»

Назначение: дать агенту (Builder) воспроизводимый процесс получения UI уровня топ-игр Roblox. Агент не рисует «на глаз» в Luau, а работает через макет в Figma (read и write через Figma MCP), экспортирует растровые ассеты, собирает UI в Studio и проверяет результат скриншотами и lint-скриптом. Здесь процесс, соглашения, таблица соответствий Figma → Roblox, шаблоны. Базовые правила UI (HUD, шрифты, обводки, доступность) уже в [builder/art-ui-audio](art-ui-audio.md), раздел 9; здесь не повторяются.

**Актуально на: октябрь 2026.** Перепроверять в первую очередь: (1) набор инструментов и лимиты Figma MCP (меняются часто, write-инструменты в beta); (2) статус и версии Figma→Roblox плагинов (RoImport, UILint, GuiForge: все моложе 4 месяцев); (3) эффективный лимит разрешения изображений UI (1024 px; официальной одной строки нет); (4) что именно попадает в `screen_capture` Studio MCP в Play mode; (5) бета-статус UIShadow / Upgraded UIGradients / StyleSheets.

## Оглавление

1. [Планка качества: почему UI «из кода» выглядит дёшево](#1-планка-качества)
2. [Три рабочих процесса A / B / C и выбор](#2-три-рабочих-процесса)
3. [Figma MCP (октябрь 2026): что умеет, лимиты, бюджет вызовов](#3-figma-mcp)
4. [Соглашения для Figma-файла (что требовать у дизайнера/агента)](#4-соглашения-для-figma-файла)
5. [Таблица соответствий Figma → Roblox](#5-таблица-соответствий-figma--roblox)
6. [Шрифты: Figma против Roblox](#6-шрифты)
7. [Экспорт ассетов и загрузка в Roblox](#7-экспорт-ассетов-и-загрузка)
8. [Плагины Figma → Roblox: что есть и что брать](#8-плагины-figma--roblox)
9. [Визуальный цикл итераций через Studio MCP](#9-визуальный-цикл-через-studio-mcp)
10. [Чек-лист ревью UI](#10-чек-лист-ревью-ui)
11. [Шаблон UI-art brief](#11-шаблон-ui-art-brief)
12. [Чего Figma MCP не умеет и запасные пути](#12-чего-figma-mcp-не-умеет-и-запасные-пути)
13. [Конфликты источников и открытые вопросы](#13-конфликты-источников-и-открытые-вопросы)

---

## 1. Планка качества

### 1.1 Почему UI «из кода» выглядит generic

Типичный результат агента без макета: прямоугольники с `UICorner`, плоская заливка, дефолтный шрифт, один тонкий `UIStroke`, текст вместо иконок, нет состояний кнопок, отступы «на глаз». Причины (вывод из практики, не из данных Roblox):

| Симптом | Причина | Что делают топ-игры (см. art-ui-audio §9.3) |
|---|---|---|
| Плоско, «как форма в вебе» | Одна заливка, нет глубины | Многослойная кнопка: тёмная внешняя обводка, градиент светлый верх / тёмный низ, блик, тень |
| Нечитаемо поверх 3D | Тонкий текст, нет обводки | Жирный закруглённый display-шрифт, толстый `UIStroke` 2-4 px на тексте |
| «Пусто», много текста | Агент подписывает всё словами | Крупные иконки с контуром, минимум текста (дети, не любят читать, локализация) |
| Несогласованность | Каждый экран с нуля | Один набор токенов: палитра, радиусы, обводки, размеры кнопок |
| Нет «сока» | Нет состояний | Default / Hover / Pressed / Disabled / Locked у каждой кнопки, твин масштаба (juice → art-ui-audio §10) |
| Ломается на устройствах | Offset-размеры, нет constraints | Scale + `UIAspectRatioConstraint`, проверка на phone / tablet / PC |

### 1.2 Анатомия «жирной» кнопки (рецепт, вывод; значения подгонять под style guide игры)

Слои снизу вверх, всё достижимо стандартными инстансами без картинок:

1. **Тень** (`UIShadow`, beta, или картинка-9slice): смещение вниз, цвет — тёмный оттенок фона кнопки, не чёрный.
2. **Внешняя обводка**: `UIStroke` 2-4 px на каноническом разрешении, цвет очень тёмный оттенок цвета кнопки (правило из art-ui-audio §9.2: не чёрный).
3. **Тело**: `Frame` + `UICorner` + `UIGradient` (светлый верх → тёмный низ).
4. **Блик**: полупрозрачная светлая полоса в верхней трети (вложенный `Frame` с `UICorner` и transparency 0.7-0.85, оценка).
5. **Иконка/текст**: `ImageLabel` с контуром (обводка запечена в PNG) или `TextLabel` с `UIStroke`.
6. **Состояния**: Pressed = `UIScale` 0.95 + затемнение градиента; Disabled = десатурация + замок; Hover (PC) = `UIScale` 1.05.

Когда процедурной сборки недостаточно (орнамент, фактура, нарисованные рамки, пергамент, металл, ледяные/огненные панели): рисуйте в Figma или заказывайте у генератора/художника и режьте через 9-slice (раздел 7).

Источники: create.roblox.com/docs/ui/appearance-modifiers; create.roblox.com/docs/tutorials/curriculums/user-interface-design/choose-an-art-style. → см. builder/art-ui-audio §9 (HUD, шрифты, палитра), §10 (juice).

---

## 2. Три рабочих процесса

| | **A. Макет в Figma → агент собирает 1:1** | **B. Агент пишет spec + art brief → ассеты → сборка** | **C. UI-kit из Creator Store** |
|---|---|---|---|
| Кто рисует | Пользователь / дизайнер / сам агент через `use_figma` | Художник или генератор изображений по brief | Автор набора |
| Лучше всего | Есть конкретное видение, нужен pixel-match | Нет дизайнера, нужен свой стиль с нуля | Прототип, джем, ранний MVP |
| Риск | Лимиты чтения Figma; нужны соглашения (раздел 4) | Генераторы плохи в консистентности и в чистом alpha | Чужой стиль, скрытые скрипты, удалённые ассеты |
| Контроль стиля | Высокий | Средний | Низкий |
| Скорость до первого экрана | Средняя | Медленная (ассеты) | Быстрая |

**Правило выбора (вывод).**
- Есть макет или референс-скриншоты → A.
- Нет ничего, но нужен уникальный стиль → B, а в Figma собрать *sheet* стиля и экраны (агент умеет писать в Figma, п. 3), и дальше как A.
- Нужен быстрый прототип для проверки идеи (kill/scale gate → advisor/idea-evaluation) → C, но стиль потом перекрашивается или заменяется. Не выпускать с чужим UI-китом как «финальный».

### 2.1 Процесс A по шагам

1. **Intake.** Запросить у пользователя: ссылку на Figma-файл (`figma.com/design/:fileKey/...?node-id=...`), список экранов, референсы игр. Если файла нет, предложить сделать его самому агенту (шаг 2b).
2. **a) Файл есть.** Проверить соглашения (раздел 4), при отсутствии токенов/auto layout — запросить правку или принять риск пиксельного приближения.
   **b) Файла нет.** Агент создаёт файл (`create_new_file`) и строит UI-kit/экраны через `use_figma` по brief (раздел 11), стартуя от «Roblox UI Kit» (см. 3.5).
3. **Чтение (бюджет! п. 3.4).** `get_metadata` на секцию → дерево; `get_variable_defs` → токены; `get_design_context` на каждый экран → структура/стили; `get_screenshot` → эталон для сравнения.
4. **Экспорт ассетов** (`download_assets` или ручной экспорт, раздел 7), загрузка через Open Cloud, манифест `ui-assets.json`.
5. **Сборка в Studio** (Luau через Studio MCP `execute_luau` / `multi_edit`): таблица раздела 5, `ScreenGui` на экран, HUD/Menu-стек (art-ui-audio §9.4).
6. **Цикл проверки** (раздел 9): скриншоты, lint, сравнение с эталоном, правки.
7. **Состояния и анимации** (juice), локализация-тест, чек-лист раздела 10.

### 2.2 Процесс B по шагам

1. Агент пишет **layout spec** (список экранов, элементов, иерархия, размеры в Scale/aspect) и **UI-art brief** (раздел 11).
2. Ассеты делает художник или генератор (в Figma: `generate_image`, тратит Figma AI credits; либо внешние генераторы). Сначала один *style frame* (панель, кнопка, иконка, шрифт) → утверждение пользователем → потом остальное.
3. Результаты кладутся в Figma (`upload_assets`/ручной drag), оформляются по соглашениям раздела 4 (метки 9-slice, имена), дальше шаги 3-7 процесса A.
4. Если ассетов нет — собрать «временный» UI процедурно (раздел 1.2) с теми же именами слотов, чтобы позже подменить `Image`.

Советы по генерации (общеизвестные ограничения, не данные Roblox): генераторы редко дают настоящий alpha → нужна вырезка фона; текст внутри картинки не заказывать (локализация, ошибки глифов); иконки генерировать крупно и уменьшать; единообразие держать общим prompt-префиксом, палитрой в hex и референсом первого утверждённого ассета.

### 2.3 Процесс C: проверка Creator Store UI-кита

Использовать только после intake-проверки (общий чек-лист → art-ui-audio §14 и §17.1):

1. Вставить в **пустой** place; удалить **все** `Script`/`LocalScript`/`ModuleScript` из ассета до запуска (бэкдоры, см. art-ui-audio §14); при необходимости — sandboxing.
2. Проверить все `Image`: ссылаются ли на `rbxassetid`, принадлежащие автору; рабочие ли в чужом place (ассет автора может быть приватным/удалённым: тогда картинки пропадут у игроков). Надёжно только перезалить собственные копии (если лицензия позволяет).
3. Лицензия и IP: чужой бренд/персонажи/стиль известной игры нельзя (→ builder/compliance).
4. Привести к своим токенам: перекрасить, заменить шрифт, пересобрать constraints (кит часто на Offset).
5. Прогнать lint раздела 9 и чек-лист раздела 10 — киты обычно ломаются на phone-размерах.

Источники: create.roblox.com/docs/projects/assets (moderation, asset types); create.roblox.com/docs/scripting/security/third-party-vulnerabilities.

---

## 3. Figma MCP

### 3.1 Два сервера

| | Remote | Desktop (Dev Mode) |
|---|---|---|
| Адрес | `https://mcp.figma.com/mcp` | локально; десктоп-приложение Figma открыто с Design-файлом, в Dev Mode включить «Enable desktop MCP server» |
| Авторизация | OAuth через клиента MCP (браузер, аккаунт Figma) | локальная сессия приложения |
| Write (`use_figma`, `generate_figma_design`) | **Да**; эти инструменты только на remote | Нет (если их нет в списке, клиент подключён к desktop) |
| Работа по selection | нет, нужен URL/nodeId | да (selection-based) |

Для агента по умолчанию использовать **remote**: единственный с записью, не требует открытого приложения. Ссылки разбираются так: `figma.com/design/:fileKey/:name?node-id=1-2` → `fileKey`, `nodeId = "1:2"` (дефис → двоеточие); для branch — `branchKey` как `fileKey`.

### 3.2 Инструменты (по серверным инструкциям Figma MCP и FAQ, 26 окт 2026)

**Чтение (учитываются в rate limit):**

| Инструмент | Что даёт агенту для Roblox |
|---|---|
| `get_metadata` | XML-дерево слоёв: id, имя, тип, позиция, размер. Дёшево по токенам, нужен как карта экрана |
| `get_design_context` | Главный инструмент. Структурированное описание узла (по умолчанию как код React+Tailwind) — это **референс**, не итоговый код: из него агент берёт иерархию, размеры, цвета, радиусы, шрифты, auto layout. Перед вызовом загрузить skill `figma-design-to-code` (обязательно по инструкциям сервера) |
| `get_screenshot` | PNG узла для визуального сравнения |
| `get_variable_defs` | Переменные и стили (цвета, отступы, типографика) → в тему/токены Roblox |
| `get_figjam`, `generate_diagram` | FigJam (flow, схемы навигации); для UI-flow полезно, для ассетов нет |
| `download_assets` | Экспорт отрисованных узлов, SVG, исходных растров из файла |
| `search_design_system`, `get_libraries` | Поиск компонентов/переменных/стилей в библиотеках (вызывать перед созданием, чтобы переиспользовать) |
| `get_code_connect_map` | Связь Figma-узлов с кодом; для Roblox почти не нужен |
| `whoami` | Email, планы, тип места (seat) |

**Запись (в лимиты чтения не входят):**

| Инструмент | Назначение |
|---|---|
| `create_session` | Обязателен перед любым файловым инструментом: `fileKey` + краткое описание задачи → UUID `sessionId`, передавать дальше |
| `create_new_file` | Новый файл (в drafts) |
| `use_figma` | Выполняет JS Plugin API: создаёт/правит фреймы, компоненты, варианты, переменные, auto layout. **Сначала загрузить skill `skill://figma/figma-use/SKILL.md`** (обязательно) |
| `generate_figma_design` | HTML живого приложения/сайта → редактируемые слои (для Roblox мало полезен) |
| `upload_assets` | Добавить изображения в файл (`use_figma` сам не умеет вставлять новые изображения) |
| `generate_image` | Растровая картинка по prompt прямо в файл; **тратит Figma AI credits**, в MCP-лимиты не входит |
| `add_code_connect_map`, `send_prompt`, `send_code_to_figma`, `export_video` | Вспомогательные (Code Connect, Make-агент, импорт, видео); для Roblox UI вторичны |

Дополнительные skills Figma (сервер отдаёт их как ресурсы или они идут в плагине): `figma-generate-design`, `figma-generate-library` (построить дизайн-систему/кит), `figma-use-figjam`, `figma-generate-diagram`. Инструмент `create_design_system_rules` был в документации 2025 года, в актуальных серверных инструкциях октября 2026 не упомянут (вместо него skills): считать устаревшим, не рассчитывать.

### 3.3 Можно ли писать: да, с оговорками

- **Запись есть** (запуск 24 марта 2026, «the Figma canvas is now open to agents»). Агент может создать UI-кит, экраны, компоненты, переменные прямо в Figma.
- **Статус:** beta, бесплатно «в период беты», затем usage-based платная функция (Figma blog, FAQ). Качество beta, результат проверять глазами; крупные изменения делать порциями; сначала на копии файла.
- **Требования по документации** (страница write-to-canvas): план Professional, Education, Organization или Enterprise; доступ edit к файлу; клиент на remote. **Starter в этом списке не назван**, при этом коллега-координатор подтвердил живое подключение с write-инструментами; Full seat нужен для записи за пределами drafts, Dev seat пишет только в drafts. → Перед проектом сделать smoke test: `whoami` → `create_new_file` → `create_session` → тривиальный `use_figma` (один фрейм). Если отказ — запасной путь раздела 12.
- **Ограничения записи:** до 20 KB вывода на вызов; `use_figma` не вставляет новые изображения (нужны `upload_assets`/`generate_image`); не импортируются компоненты с картинками/видео; шрифты должны быть загружены в аккаунт Figma (локально установленные недоступны); GIF не создаются.

### 3.4 Лимиты и бюджет вызовов (критично для плана Starter)

Лимиты действуют на **инструменты чтения**; запись (`create_new_file`, `generate_figma_design`, `add_code_connect_map`, `whoami`, и, по всей видимости, `use_figma`: прямо не названо, FAQ лишь говорит, что запись бесплатна в beta) и инструменты на AI credits в лимит не входят.

| Seat | Starter | Professional | Organization | Enterprise |
|---|---|---|---|---|
| View, Collab | 20 вызовов/месяц | 20/мес | 20/мес | 20/мес |
| Full, Dev | **в таблице не указано** | 200/день, 10/мин | 200/день, 15/мин | 600/день, 20/мин |

Education = как Full/Dev на Professional. Figma оставляет право менять лимиты в любой момент. В более раннем снимке документации Starter/View/Collab значилось «6 вызовов в месяц»: старое значение. Для Starter Full seat точных цифр нет: **считать лимит неизвестным и малым**, планировать как для 20 чтений/месяц, пока `whoami` или практика не докажут большее (оценка).

**Экономия чтений (вывод):**

1. **Строить в Figma самим агентом** (`use_figma`): структура уже известна агенту из собственного скрипта, читать её обратно не нужно. Это главный способ обойти лимит чтения.
2. Минимум чтений на экран: 1 × `get_design_context` (по корневому узлу экрана) + 1 × `download_assets` (все ассеты экрана одним вызовом) + 1 × `get_screenshot`. Итого ~3 на экран; 5 экранов = ~15 чтений.
3. `get_metadata` один раз на страницу вместо чтения каждого узла; `get_variable_defs` один раз на файл; результаты сохранять в репозиторий (`design/figma-cache/*.json|xml`) и дальше работать с кэшем.
4. Скриншоты для визуального сравнения собирать пакетом: один `get_screenshot` на родительский фрейм с несколькими экранами, затем резать локально.
5. Ручной экспорт PNG из Figma (пользователь) в чтения не входит.
6. Не вызывать `get_design_context` повторно «на всякий случай»; сначала проверить кэш.

### 3.5 «Roblox UI Kit» в Figma

Skill поставляется с Figma-файлом «Roblox UI Kit», построенным через `use_figma` (кнопки с состояниями, панели с 9-slice метками, иконки-слоты, токены цветов/текста/радиусов, фреймы phone/tablet/PC). Использовать как стартовую дизайн-систему: дублировать файл пользователю, не править оригинал; ссылка/`fileKey` хранится в SKILL.md (здесь не хардкодить).

Источники: developers.figma.com/docs/figma-mcp-server/write-to-canvas; developers.figma.com/docs/figma-mcp-server/rate-limits-access; help.figma.com/hc/en-us/articles/39252411778583 (FAQ); figma.com/blog/the-figma-canvas-is-now-open-to-agents (24.03.2026); серверные инструкции Figma MCP (подключение, 26.10.2026).

---

## 4. Соглашения для Figma-файла

Это то, что агент требует у дизайнера (или создаёт сам). Размеры и имена — рекомендация (оценка/вывод), официального стандарта Roblox нет; опора на практику плагинов (имена-теги) и док Roblox (9-slice, constraints).

### 4.1 Страницы и фреймы

| Страница | Содержимое |
|---|---|
| `00 Tokens` | Переменные: цвета, радиусы, толщины обводок, отступы, текстовые стили |
| `01 Kit` | Компоненты: кнопки (все состояния), панели, иконки, бары, слоты, попапы |
| `02 Screens` | Экраны, каждый в 3-4 размерах |
| `03 Export` | Узлы, готовые к экспорту (плоские), с метками слайсов |

**Размеры фреймов на экран (landscape; Roblox мобильный — преимущественно landscape):**

| Устройство | Фрейм | Соотношение | Примечание |
|---|---|---|---|
| Phone | 1920×1080 | 16:9 | Базовый (канонический) |
| Phone wide | 2400×1080 | 20:9 | Проверка растягивания по ширине и выреза |
| Tablet | 1600×1200 | 4:3 | Проверка «зажатия» по ширине |
| PC | 1920×1080 | 16:9 | Мелкие элементы тут не мельче phone-эквивалента |

Базовый кадр 1920×1080 совпадает с каноническим разрешением из art-ui-audio §9.3. На каждом экране нарисовать **зону Roblox core UI** (кнопки меню/чата сверху слева, оценка: верхние ~8-10% высоты) полупрозрачным маркером `_SafeGuide` (не экспортируется). Сама безопасная зона обеспечивается `ScreenGui.ScreenInsets = CoreUISafeInsets`; макет должен её учитывать.

### 4.2 Структура и именование

1. **Auto layout везде**, где в Roblox будет `UIListLayout`/`UIGridLayout`; без «плавающих» слоёв внутри auto-layout контейнеров, кроме явных `absolute position` (иконки-бейджи).
2. **Frame, не Group.** Группы не несут размеров/clipping/fill.
3. Имя слоя = имя будущего `Instance` (PascalCase, без пробелов): `ShopPanel`, `BuyButton`, `CoinIcon`, `PriceLabel`. Дубли имён соседей запрещены (`Instance.Name` в Roblox используется скриптами).
4. **Теги типа** (совпадают с конвенцией плагинов RoImport/UILint, раздел 8): суффикс/префикс `_Button` (ImageButton/TextButton), `_Scroll` (ScrollingFrame), `_Grid`, `_Slice`, `_stroke`. Если плагины не используются, теги всё равно читает агент.
5. **Компоненты и варианты.** Кнопка = компонент с вариантами `State=Default|Hover|Pressed|Disabled|Locked`, `Size=S|M|L`, `Style=Primary|Secondary|Danger`. Вариант = одна запись в манифесте ассетов.
6. **Переменные (variables):** коллекции `Color/Brand`, `Color/Rarity`, `Color/State`, `Color/Text`, `Radius`, `Stroke`, `Spacing`. Все заливки и обводки привязаны к переменным, а не к hex. `get_variable_defs` → в Luau-модуль темы (или `StyleSheet` tokens, beta; art-ui-audio §9.5).
7. **Текстовые стили:** не больше 5-6 (Title, Header, Body, Caption, Number, Button). Шрифты только из таблицы раздела 6.
8. **Без скрытых слоёв**, масок, blur, blend modes, skew/3D-поворотов (в Roblox нет прямых аналогов, раздел 5).
9. **Скруглённые углы одного значения** (UICorner одно значение на все углы); разные углы — только в растровом ассете.

### 4.3 Метки 9-slice

Figma не умеет 9-slice. Фиксируем margin'ы в имени экспортируемого узла:

`Panel_Green[S=24,24,24,24]` → порядок **L,T,R,B** в пикселях **экспортированного изображения** (учесть масштаб экспорта, см. 7.2).

Преобразование в Roblox: `SliceCenter = Rect.new(L, T, W - R, H - B)`, где W,H — размер исходного PNG в пикселях. Критично: `SliceCenter` задаётся **координатами линий в исходном изображении, а не отступами от краёв**; редактор в Studio показывает отступы от краёв, а в свойстве хранятся абсолютные координаты (док 9-slice это отдельно подчёркивает). Центр слайса должен быть однородным (без орнамента) или тайлиться. Угловые части не масштабируются (док): внутри угла нельзя держать то, что должно растягиваться.

Если экспорт сделан @2x, а панель должна выглядеть как @1x: `ImageLabel.SliceScale = 0.5` (свойство уменьшает/увеличивает «края» как будто изображение перезалито в другом масштабе).

### 4.4 Что отправлять на экспорт

Отдельная страница `03 Export` из плоских узлов с постфиксом `@export`: каждая кнопка в каждом состоянии, иконки, панели, бары (фон и заливка отдельно), логотип. Это то, что `download_assets` скачивает одним вызовом.

Источники: create.roblox.com/docs/ui/9-slice; create.roblox.com/docs/ui/size-modifiers; create.roblox.com/docs/tutorials/curriculums/user-interface-design/implement-designs-in-studio; DevForum RoImport 4731967 и UILint v2 4765869 (конвенция тегов).

---

## 5. Таблица соответствий Figma → Roblox

Свойства Roblox проверены по локальным докам creator-docs (ui/*, reference/engine/classes). «Beta» — включается в Studio Beta Features.

| Figma | Roblox | Нюансы |
|---|---|---|
| Frame (fill) | `Frame` (`BackgroundColor3`, `BackgroundTransparency`) | Fill opacity → `BackgroundTransparency`. Opacity всего слоя с детьми → `CanvasGroup.GroupTransparency` (дороже по производительности) |
| Auto layout (direction, gap, padding) | `UIListLayout` (`FillDirection`, `Padding`, `HorizontalAlignment`, `VerticalAlignment`, `SortOrder=LayoutOrder`) + `UIPadding` | Wrap → `UIListLayout.Wraps`; сетка → `UIGridLayout`. «Hug contents» → `AutomaticSize`; «Fill container» → `UIFlexItem` (Flex Fill); док ui/list-flex-layouts. Gap в px переводить в Scale от высоты ряда или оставлять Offset малым |
| Corner radius (одно значение) | `UICorner.CornerRadius` (`UDim`) | Пилюля → `UDim.new(0.5,0)`. Разные углы не поддерживаются → картинка/9-slice |
| Stroke inside/center/outside | `UIStroke` у Frame (режим Border) | Толщина в px (`StrokeSizingMode`: фикс. px или относительно размера). Позиция внутри/снаружи в новых версиях через `BorderStrokePosition` (бета, семантику проверить скриншотом). Пунктир не поддерживается |
| Text stroke | `UIStroke` на `TextLabel` (режим Contextual / текст) | Не анимировать `Thickness` на тексте (док: мерцание и нагрузка) |
| Linear gradient | `UIGradient` (`Color` ColorSequence, `Transparency`, `Rotation`) | Угол Figma → `Rotation`; несколько стопов поддерживаются. Градиент красит родителя, поэтому `BackgroundColor3` ставить белым, иначе умножится |
| Radial / angular / diamond gradient | `UIGradient.Type` Radial / Conical / Elliptical (**beta**, «Upgraded UIGradients») либо PNG | RoImport растеризует радиальный, угловой и diamond (DevForum). Diamond всегда PNG |
| Gradient stroke / text gradient | `UIGradient` как ребёнок `UIStroke` / `TextLabel` | Для заливки и обводки градиенты независимы (док) |
| Drop shadow | `UIShadow` (**beta**: `BlurRadius`, `Offset`, `Spread`, `Color`, `Transparency`) либо 9-slice PNG тени | Режим Shape / Text; повторяет `UICorner` и Rotation. Тень без beta — картинкой под элементом |
| Inner shadow | `UIShadow.Inset` (beta) | Иначе в PNG |
| Layer / background blur | Нет аналога для отдельного элемента | В PNG или `BlurEffect` на весь экран (меню-оверлей) |
| Constraints Left/Right/Center | `AnchorPoint` + `Position` Scale | Задавать `AnchorPoint` до твина (art-ui-audio §9.3) |
| Constraints Scale | `Size` Scale | Всё в Scale от родителя; Offset только для бордеров/иконок фиксированного размера |
| Фикс. aspect (иконка, кнопка, слот) | `UIAspectRatioConstraint` (`AspectRatio`, `AspectType`, `DominantAxis`) | Обязательно на иконках, кнопках, квадратных слотах (ultra-wide) |
| Min/Max size | `UISizeConstraint` | Для панелей: не шире N px на PC |
| Масштаб всего экрана | `UIScale` на корневой Frame | Для подгонки под разрешения; не вместо constraints |
| Clip content | `ClipsDescendants = true` | Со скруглением clip остаётся прямоугольным: для круглых масок использовать картинку |
| Mask / boolean ops / vector | PNG | SVG как ассет Roblox не поддерживается (форматы изображений: PNG, JPEG, BMP, TGA) |
| Rotation | `Rotation` | Skew нет |
| Text (font, size, weight) | `TextLabel` + `FontFace` (`Font.fromName(...)`) + `TextSize` | Раздел 6. `TextScaled` + `UITextSizeConstraint` (Min/Max) для масштабирования; без ограничений текст растёт неконтролируемо |
| Text auto-width / hug | `AutomaticSize = X` или `XY` | Для локализации (длинные слова) |
| Line height | `LineHeight` | |
| Letter spacing, text case | Нет свойства / `string.upper()` | Spacing запечь в PNG-заголовок (не для локализуемых строк) |
| Rich text (цвет/вес слова) | `RichText = true` + `<font color=...>`/`weight` | Док ui/rich-text |
| Image fill | `ImageLabel`/`ImageButton` (`Image` или `ImageContent`) | `ScaleType`: Stretch/Slice/Tile/Fit/Crop; `ResampleMode = Pixelated` для пиксель-арта |
| 9-slice image | `ScaleType = Slice` + `SliceCenter` (+ `SliceScale`) | Раздел 4.3 |
| Image state variants | Подмена `Image` либо `ImageRectOffset/Size` (спрайт-лист) | Pressed: ещё и `UIScale` твин |
| Component | Шаблон `Frame` в `ReplicatedStorage`, клонирование | Properties варианта → атрибуты шаблона |
| Variables (color, number) | Модуль темы / `StyleSheet` tokens (частично beta) | Один источник правды на цвета; редкости/команды = данные (art-ui-audio §9.2) |
| Scroll (overflow) | `ScrollingFrame` + `UIListLayout` + `AutomaticCanvasSize` | Тег `_Scroll`. Scrollbar — свой через `ScrollBarImageColor3`/картинку |
| Prototype interactions | Нет | Поведение описывает spec/агент |

Источники: create.roblox.com/docs/ui/appearance-modifiers; /ui/size-modifiers; /ui/list-flex-layouts; /ui/labels; /ui/rich-text; /ui/9-slice; /reference/engine/classes/{ImageLabel,UIStroke,UIGradient,UIShadow,UICorner,UIAspectRatioConstraint}.

---

## 6. Шрифты

**Факт (док):** шрифты в Roblox импортировать нельзя; доступны встроенные (enum `Font`/Font Family) и около 80 шрифтов из Creator Store. Значит, «любой Google Font из Figma» в игру не попадёт.

Встроенные (enum `Font`, из reference): Legacy, Arial(+Bold), SourceSans(+Bold/Light/Italic/Semibold), Bodoni, Garamond, Cartoon, Code, Highway, SciFi, Arcade, Fantasy, Antique, **Gotham/GothamMedium/GothamBold/GothamBlack**, AmaticSC, Bangers, Creepster, DenkOne, Fondamento, **FredokaOne**, GrenzeGotisch, IndieFlower, JosefinSans, Jura, Kalam, **LuckiestGuy**, Merriweather, Michroma, **Nunito**, Oswald, PatrickHand, PermanentMarker, Roboto(+Condensed/Mono), Sarpanch, SpecialElite, TitilliumWeb, Ubuntu, **BuilderSans(+Medium/Bold/ExtraBold)**, Arimo(+Bold).

**Правило (вывод):** рисовать макет **только шрифтами, у которых есть двойник в Roblox**:

| Роль | Figma (Google Fonts) | Roblox |
|---|---|---|
| Жирный закруглённый display (заголовки, числа, кнопки) | Fredoka One / Fredoka Bold, Baloo, Lilita One | `FredokaOne` (Fredoka One в семействах Roblox) |
| Комикс/плакатный заголовок | Luckiest Guy, Bangers | `LuckiestGuy`, `Bangers` |
| Нейтральный UI-текст | Nunito, Gotham-подобные (Montserrat) | `Nunito`, `GothamMedium/Bold/Black` |
| Roblox-нативный вид | нет (Builder Sans не в Google Fonts) | `BuilderSans*`: использовать, если нужен «родной» вид; в макете подставить Nunito |

Проверка соответствия: в Studio открыть шрифт на `TextLabel` и сравнить со скриншотом (метрики немного отличаются; Figma-версия Fredoka может отличаться от FredokaOne). Дефолтный шрифт Roblox сменялся: наличие конкретных семейств в Font Picker всегда проверять в Studio (как отмечено в art-ui-audio §9.3).

**Кастомный шрифт нужен для логотипа/заголовка?** Растеризовать в PNG (не локализуемо, не использовать для динамического текста), либо подобрать ближайший встроенный. Для Figma-стороны: если пользователь хочет свой шрифт, в Figma он нужен загруженным в аккаунт, иначе `use_figma` его не увидит.

Размеры текста: в макете ≥ 24 px на каноническом 1920×1080 для основного текста phone (оценка из требований читаемости на телефоне; проверка в Device Emulator → раздел 10).

Источники: create.roblox.com/docs/projects/assets (Font: «You cannot import fonts», 80+ шрифтов в Creator Store); /reference/engine/enums/Font; /ui/rich-text.

---

## 7. Экспорт ассетов и загрузка

### 7.1 Что растеризовать, а что строить инстансами

| Растр (PNG) | Инстансы (без картинок) |
|---|---|
| Иконки (с контуром/тенью), орнаментальные рамки, фактура, пергамент, сложные многоцветные кнопки, логотип/заголовок, бейджи редкости с блеском, радиальные/угловые градиенты, тени без UIShadow | Простые панели (Frame+UICorner+UIStroke+UIGradient), текст, бары заполнения (Frame с Scale), затемнение/оверлей, разделители |

Принцип: чем больше картинок, тем лучше «арт», но тем больше памяти и загрузка (и хуже локализация). Золотая середина: рамки и иконки картинками, текст и заполнение инстансами.

### 7.2 Размеры и форматы

- **Формат:** PNG-32 с alpha (кнопки, иконки, панели). JPEG только для полноэкранных фонов без прозрачности. Входной формат по Open Cloud: PNG/JPEG/BMP/TGA; SVG не поддерживается.
- **Лимит загрузки (док Open Cloud):** изображение < 8000×8000 px, файл до 20 MB.
- **Эффективный потолок отображения: 1024 px по стороне** (оценка высокой уверенности): официальная валидация Creator Store называет 1024×1024 максимумом для `Decal.ColorMap`, док по средам разработки говорит «текстуры до 1024×1024», DevForum («Imported UI's are blurry?») связывает мыльность больших картинок с 1024. Одной явной строки «ImageLabel режет до 1024» в докумах нет, поэтому **проверить на тестовой картинке 2048 px** до массовой загрузки. `EditableImage` тоже ограничен 1024×1024.
- **Масштаб экспорта.** Канонический кадр 1920×1080. На телефоне (≈ 840×390 точек) картинка почти всегда показывается меньше исходных пикселей, поэтому: иконки 256-512 px, кнопки 9-slice 256×128..512×256, большие hero-панели ≤ 1024. Экспорт @1x с канона обычно достаточно; @2x только для крупных hero-элементов и только в пределах 1024 (оценка/вывод).
- **Память:** расход видеопамяти зависит от числа пикселей, а не размера файла; 1024×1024 съедает в 4 раза больше, чем 512×512 (док performance-optimization). Для UI-ассетов не заказывать 1024 там, где хватит 256.
- **Спрайт-листы (атласы):** иконки одного набора можно собрать в один лист до 1024×1024 и показывать через `ImageRectOffset` / `ImageRectSize`. Плюсы: меньше загрузок и ассетов в манифесте. Выигрыш по draw calls не проверялся (не утверждать). Для 9-slice-панелей атласы неудобны.
- **Паддинг:** оставлять 2-4 px прозрачного поля вокруг тени/свечения, иначе обрежется; трим остального пустого поля.
- **Pixel art:** `ResampleMode = Pixelated`.
- **Premultiplied/halo:** края с тёмной обводкой на светлом фоне экспортировать без белого ореола (alpha чистить в редакторе; проверка на тёмном и светлом фоне).

### 7.3 Имена и манифест

Файл: `ShopPanel_Green_9s.png`, `BtnPrimary_Pressed.png`, `IconCoin.png`. Для воспроизводимости ведём `ui-assets.json` (в репозитории рядом с Rojo-проектом, → builder/project-setup):

```json
{
  "BtnPrimary_Default": { "file": "BtnPrimary_Default.png", "sha256": "…", "assetId": 0, "w": 256, "h": 128,
                         "slice": { "l": 24, "t": 24, "r": 24, "b": 24 }, "sliceScale": 1.0 }
}
```

Агент генерирует из манифеста Luau-модуль `UIAssets` (`rbxassetid://<id>`, `SliceCenter`). Перезаливка только при изменении `sha256`. Ассеты изображений Open Cloud **не обновляются** (в таблице: «Not available for updating»): каждая новая версия получает **новый ID**; манифест обязателен, чтобы не терять соответствие.

### 7.4 Экспорт из Figma

1. **Через MCP:** `download_assets` на узлы страницы `03 Export` (чтение, считается в лимит; один вызов на экран). Проверить масштаб и формат в ответе.
2. **Вручную (не тратит лимит):** пользователь в Figma выделяет узлы → Export → PNG @1x (или @2x), либо плагином (раздел 8).
3. Автоматическая нарезка/оптимизация: локальный скрипт (trim, проверка размера ≤ 1024, sha256).

### 7.5 Загрузка через Open Cloud Assets API

1. Создать API key (Creator Hub → Open Cloud → API Keys): доступ **assets**, операции Read и Write (док usage-assets); ограничить по IP; хранить ключ как секрет (не коммитить). → builder/project-setup (Open Cloud).
2. `POST https://apis.roblox.com/assets/v1/assets`, заголовок `x-api-key`, multipart: `request` (JSON: `assetType` = `Decal` (в доках «Decal, Image»), `displayName`, `description`, `creationContext.creator.userId` или `groupId`) + `fileContent=@file.png;type=image/png`.
3. В ответе `operations/{operationId}`; опрашивать `GET https://apis.roblox.com/assets/v1/operations/{operationId}` до `done`, взять `assetId` из результата.
4. **Decal-ID против Image-ID:** при загрузке «Decal» возвращается ID декаля; в `ImageLabel` может потребоваться ID картинки. Студийный Asset Manager это скрывает. Для API путь не подтверждён в рамках исследования: **на первом ассете проверить** `rbxassetid://<id>` в `ImageLabel`; при пустой картинке выяснить Image-ID (Asset Manager / `AssetService`). Не загружать пакетом всё, пока не проверен один.
5. Альтернативы: перетаскивание в Studio Asset Manager (нет автоматизации); Studio MCP `upload_image` (грузит пакет изображений **по HTTP URL** и возвращает карту путь → asset ID; с локальными файлами не работает без хостинга).
6. Группа или пользователь: для командной игры загружать от имени **группы** (ассет принадлежит группе, а не личному аккаунту; нужны права в группе).

### 7.6 Модерация

Загруженные изображения проходят автоматическую и ручную модерацию, обычно в течение нескольких часов; пока ассет в очереди, игроки его не видят (док). Правила: не загружать кадры с чужим IP/логотипами, лица, текст с запрещённой лексикой, «эксплойт»-контент. Загружать **заранее**, до релизного окна, и после загрузки проверять статус (Creator Dashboard → Creations → Decals/Images). Отклонённый ассет → заменить и перезалить (новый ID, обновить манифест). → builder/compliance.

Источники: create.roblox.com/docs/cloud/guides/usage-assets (лимиты, ключи, operations); /projects/assets (moderation); /performance-optimization/improve (память текстур); /marketplace/validation-system (1024 для Decal.ColorMap); /reference/engine/classes/EditableImage; devforum.roblox.com/t/imported-uis-are-blurry/727482 (комьюнити, 1024).

---

## 8. Плагины Figma → Roblox

Состояние на 26.10.2026 по DevForum (проверено чтением тредов; популярность и качество независимо не измерялись). Все плагины запускаются в Studio/Figma с широкими правами: перед установкой читать код/описание, использовать на копии place.

| Инструмент | Автор / дата | Как работает | Статус / оговорки |
|---|---|---|---|
| **RoImport** | Stuxfian; пост 11.07.2026, релизы 12.07, 21.07, **19.09.2026** | Плагин Figma + плагин Studio. Теги в именах: `_Button`, `_Scroll`, `_Grid`, `_Slice`, `_stroke`. Auto layout → UIList/UIGrid; картинки → ImageLabel/Button; дубли ассетов определяются; поддерживает UIShadow, 9-slice, RichText/TextScaled, ScrollingFrame, BillboardGui/SurfaceGui. Радиальные/угловые/diamond градиенты — растром | Бесплатный, активно обновляется. Автозагрузка изображений требует **локальный bridge (EXE/BAT) и API key Creator Hub** (bridge open source на GitHub: прочитать исходники/собрать самим; ключ с минимальными правами). Туториала нет; «tintable icons» (`_gray`) могут глючить. Шрифты в посте не описаны |
| **UILint v2** | Kailorr1; 30.07.2026 | Figma-плагин: lint и экспорт полной иерархии + ZIP картинок; Studio-плагин восстанавливает иерархию (frames, text, buttons, layouts, constraints, ScrollingFrame). Free: локальный lint, ручной экспорт снапшота; Smart Sync / Deep Analyze / Smart Scale / Live Sync платные (цен нет) | Очень свежий, ответов в треде нет. Про 9-slice и auto layout в посте ничего. Хорошо как линтер макета (переполнение текста, перекрытия, ZIndex) даже без импорта |
| **GuiForge** | VenedishMac; 27.08.2026 | Веб-редактор Roblox UI → экспорт **Luau-кода** (LocalScript, Modules, React-Lua beta, .rbxmx beta); Figma-плагин импортирует фреймы (layout, text, stroke, gradient, 9-slice) и растеризует то, что Roblox не воспроизводит (skew, inside text stroke, смешанные шрифты) | Свой рантайм (~70 функций), «в активной разработке»; предпросмотр не пиксель-в-пиксель. Подходит, если хотите редактор + код-генерацию, но создаёт зависимость от чужого рантайма |
| **Figma Importer Assistant** | iGottic (GitHub MiaGobble/Figma-Import-Assistant); май 2024, док обновлён фев 2025 | Studio-плагин; режимы Opportunistic (strokes/colors/layout → инстансы) и Classic (всё картинками), Map Images, Auto Import (v1.1.x) | Открытый, но свежесть 2026 не подтверждена; полу-ручной |
| UI Designer Pro и др. | в поиске, не проверены | | Не рекомендовать без проверки |

**Рекомендация.**
- Для *пакетного* переноса большого макета, если у агента нет доступа к чтению Figma (лимит) или нужен предсказуемый результат: **RoImport**, при условии что дизайнер соблюдает теги (раздел 4) и bridge проверен. Сначала импорт одного экрана, сравнение со скриншотом, только потом остальные.
- **UILint** добавить как линтер макета до импорта.
- Основной путь для skill: агент сам читает Figma (раздел 3) и собирает UI Luau-кодом (воспроизводимо, код в репозитории, учитывает наши токены и HUD/Menu стек). Плагин — запасной/ускоряющий путь. Не смешивать два импортёра в одном экране.
- После плагинов всегда: lint (раздел 9.3) + чек-лист (раздел 10); автоимпорт часто даёт Offset-размеры и «мёртвые» слои.

Источники: devforum.roblox.com/t/free-figma-to-roblox-plugin-roimport/4731967; /t/plugin-uilint-v2-import-figma-ui-into-roblox-studio/4765869; /t/guiforge-roblox-ui-editorfigma-export/4834077; /t/2961561 (Figma Importer Assistant).

---

## 9. Визуальный цикл через Studio MCP

> Отдельного файла builder/mcp-studio.md в момент написания нет; инструменты взяты из create.roblox.com/docs/studio/mcp (локально: `studio/mcp.md`). После появления файла → builder/mcp-studio.

### 9.1 Инструменты, нужные для UI

| Инструмент | Для чего в UI-цикле |
|---|---|
| `list_roblox_studios` | Получить `studio_id` (передаётся в каждый вызов) |
| `execute_luau` (`datamodel_type`: Edit / Client / Server) | Построить и править ScreenGui; lint-скрипт; заполнение тестовыми данными |
| `multi_edit`, `script_read`, `script_grep` | Правка Luau-модулей UI |
| `search_game_tree`, `inspect_instance` | Проверить иерархию и свойства (размеры, `AbsoluteSize`) |
| `screen_capture` | Снимок вьюпорта Studio (опционально камера); основной «глаз» агента |
| `start_stop_play`, `get_console_output`, `get_studio_state` | Play-режим и ошибки |
| `user_mouse_input` (клики по инстансу или координатам), `user_keyboard_input` | Нажать кнопки, пройти меню, проверить hover/pressed |
| `upload_image`, `store_image`, `insert_asset` | Работа с ассетами (раздел 7.5) |
| `skill` | Получить встроенные знания, в докумах упоминается «device simulation»: **вызвать и прочитать до построения цикла по размерам** |
| `subagent` (`playtest`) | Сценарий «пройти FTUE и проверить UI» |

### 9.2 Известные проблемы `screen_capture` (DevForum, июль 2026)

- В Play mode снимок может **не содержать** BillboardGui, ProximityPrompt по умолчанию и верхнюю панель Roblox (меню); иногда пропадал и runtime-ScreenGui HUD (в тесте 10 из 11 снимков с HUD). Staff-ответа и обходного пути на момент проверки нет.
- Следствие (вывод): для статичной вёрстки делать проверку в **Edit mode** (в Studio ScreenGui из `StarterGui` рисуется оверлеем поверх 3D; док on-screen-containers; тумблер GUI overlay), а Play mode использовать для интерактива; перед выводами «элемента нет» повторить снимок и проверить `inspect_instance` (инстанс существует и `Visible`).
- Не доверять снимку для оценки безопасной зоны под верхней панелью Roblox: её на снимке может не быть. Для этого есть числовая проверка (9.3).

### 9.3 Цикл «собрать → увидеть → исправить»

1. **Собрать** экран (`execute_luau` Edit / правка модуля).
2. **Снимок** (`screen_capture`) → сравнить с `get_screenshot` из Figma (кэш, не перечитывать). Сравнивать: пропорции, отступы, иерархия, цвет, толщина обводок, шрифт.
3. **Разные размеры.** Прямой инструмент выставления размера окна/эмуляции устройства в MCP-списке не найден. Варианты:
   - (Надёжный) пользователь включает **Device Emulator** (Test → Device Emulator → *Actual Resolution*; выбрать минимум по одному устройству Phone, Tablet, Desktop, Console; док implement-designs) и агент делает снимки на каждом;
   - (Вывод, не проверено) *harness*: тестовый `ScreenGui`, в котором экран клонируется внутрь `Frame` фиксированного размера 844×390 (phone), 1024×768 (tablet), 1920×1080 (PC) с центрированием; Scale-вёрстка ведёт себя как на экране такого размера, но **ScreenInsets и текст `TextScaled` приблизительны**. Использовать как дымовой тест, не как заменитель эмулятора;
   - прочитать, что предлагает `skill` «device simulation».
4. **Lint числом** (`execute_luau`, Client/Edit) вместо «глазомера»; пример:

```lua
-- UI lint: запускать для корня экрана. Пороги подгонять под игру.
local MIN_TOUCH_FRAC = 0.14   -- ~9 мм ≈ 14-16% высоты phone-экрана (оценка, см. раздел 10)
local root = game.StarterGui.ShopGui  -- пример
local view = workspace.CurrentCamera.ViewportSize
for _, d in root:GetDescendants() do
	if d:IsA("GuiObject") and d.Visible then
		local p, s = d.AbsolutePosition, d.AbsoluteSize
		if p.X < 0 or p.Y < 0 or p.X + s.X > view.X or p.Y + s.Y > view.Y then
			warn("OFFSCREEN", d:GetFullName())
		end
		if (d:IsA("TextButton") or d:IsA("ImageButton")) and math.min(s.X, s.Y) < view.Y * MIN_TOUCH_FRAC * 0.6 then
			warn("SMALL TOUCH TARGET", d:GetFullName(), s)
		end
		if d:IsA("TextLabel") or d:IsA("TextButton") then
			if not d.TextFits then warn("TEXT OVERFLOW", d:GetFullName()) end
			if not d.TextScaled and d.TextSize * view.Y / 1080 < 14 then warn("TEXT SMALL", d:GetFullName()) end
		end
		if d:IsA("GuiObject") and d.Size.X.Offset ~= 0 and d.Size.X.Scale == 0 and not d:FindFirstChildWhichIsA("UIAspectRatioConstraint") then
			-- кандидаты на Offset-вёрстку (информационно)
		end
	end
end
```

   Скрипт — черновик: порог площади нажатия (`* 0.6`) и размер текста (14) — эвристики (оценка), подгонять после замеров в эмуляторе.
5. **Состояния:** `user_mouse_input` (move → hover, down/up → pressed), снимок после каждого; Disabled/Locked проверять установкой атрибутов через `execute_luau`.
6. **Длинная локализация:** подставить удлинённые строки (+40-50%, оценка), проверить `TextFits`/переносы.
7. **Итерации:** максимум 3-4 круга на экран, затем показать пользователю; фиксировать в `design/ui-review.md`.

Источники: create.roblox.com/docs/studio/mcp; devforum.roblox.com/t/mcp-screencapture-omits-billboardgui-default-proximityprompt-and-roblox-top-bar-ui-during-play-mode/4736693; create.roblox.com/docs/tutorials/curriculums/user-interface-design/implement-designs-in-studio (Device Emulator); /ui/on-screen-containers.

---

## 10. Чек-лист ревью UI

Нумерованный, проходить на phone / tablet / PC. Базовые правила и числа → art-ui-audio §9.

1. **Читаемость на phone.** Основной текст читается без приближения на Device Emulator *Actual Resolution*; нет тонких/script-шрифтов на мелком; текст на контрастном фоне или с `UIStroke` (контраст WCAG-подобный: текст/фон ≥ 4.5:1 для обычного, ≥ 3:1 для крупного и обведённого; оценка-ориентир, проверять по палитре).
2. **Touch targets ≥ 9×9 мм** (официально). Практический пересчёт (оценка): при плотности ≈ 160 ppi это ≈ 57 pt ≈ 14-16% высоты phone-экрана в landscape; проверять в эмуляторе и обеспечивать `UIAspectRatioConstraint`. Важные кнопки крупнее; между соседними кнопками зазор.
3. **Safe areas.** `ScreenInsets = CoreUISafeInsets` для интерактивных `ScreenGui`; `DeviceSafeInsets`/`None` только для фонов/оверлеев; ничего интерактивного под вырезом и верхней панелью Roblox; проверка на вырезах (реальное устройство).
4. **Масштабирование.** Нет Offset-размеров у крупных блоков; `UIAspectRatioConstraint` на иконках, слотах, кнопках; на 20:9 и 4:3 ничего не обрезается и не растягивается; `UITextSizeConstraint` у `TextScaled`.
5. **Контраст и фон.** Читаемо поверх светлого и тёмного 3D-фона; не только цветом (редкость = цвет + символ/название; состояния = форма/иконка).
6. **Консистентность.** Один набор токенов: цвета, радиусы (`UICorner`), толщина обводок, размеры кнопок S/M/L; close всегда одинаковый; цены красным только при недоступности (art-ui-audio §9.6).
7. **Иерархия.** Primary/secondary/tertiary различимы размером и акцентом; на экране одна главная CTA; одно меню за раз (HUD/Menu стек, art-ui-audio §9.4).
8. **Состояния.** У каждой кнопки Default / Hover / Pressed / Disabled (+ Locked если нужно), у списков пустое состояние и загрузка.
9. **Текст и локализация.** Строки не вшиты в картинки; запас +40-50% длины (оценка); `AutomaticSize`/переносы; числа сокращаются (art-ui-audio §10.6).
10. **Ассеты.** Нет мыльных картинок (проверить 1024-потолок), нет белых ореолов вокруг обводки, 9-slice не «плывёт» при растяжении, нет пустых/модерируемых ассетов (`Image` грузится), нет лишних 1024-текстур.
11. **Производительность.** Нет сотен видимых слоёв; не твинить `Thickness` у `UIStroke` на тексте; `CanvasGroup` только где нужен; скрытые экраны `Enabled=false`.
12. **Доступность.** Учёт `GuiService.PreferredTransparency`, `PreferredTextSize`, `ReducedMotionEnabled` (art-ui-audio §9.7).
13. **Сверка с макетом.** Скриншот Studio vs Figma: отступы, радиусы, обводки, шрифт отличаются не заметно; расхождения оформить списком правок.
14. **Ошибки в консоли.** `get_console_output` без warn/error от UI-скриптов.

Источники: create.roblox.com/docs/tutorials/curriculums/user-interface-design (choose-an-art-style, implement-designs-in-studio); /ui/on-screen-containers (safe insets); /production/publishing/accessibility.

---

## 11. Шаблон UI-art brief

Заполняется агентом, утверждается пользователем, отдаётся художнику/генератору (процесс B). Каждый пункт — измеримый.

```markdown
# UI-ART BRIEF: <название игры>

## 1. Контекст
- Жанр / аудитория / платформы (phone-first?): 
- Референсы (3-5 игр + что именно брать: форма кнопок, палитра, шрифт):
- Чего избегать (чужой IP, стиль конкретной игры):

## 2. Стиль
- Ключевые слова (3-5): например «жирный, мультяшный, сочный, глянцевый»
- Форма: радиус углов (px на 1920×1080): ___; толщина внешней обводки: ___ px; обводка = тёмный оттенок цвета, не чёрный
- Глубина: градиент верх→низ (светлый/тёмный), блик сверху, тень вниз (смещение/цвет)
- Освещение: источник света сверху-слева (единый для всех ассетов)
- Иконки: стиль (контурные / залитые с обводкой), размер сетки 256×256, поле 16 px, обводка ___ px
- Запрещено: градиентные «веб-2.0» блики, тонкие линии < 2 px, текст в картинках

## 3. Палитра (hex)
Основной ___ | Акцент ___ | Фон панелей ___ | Текст светлый ___ / тёмный ___
Состояния: success ___ danger ___ warning ___ disabled ___
Редкости: Common ___ Uncommon ___ Rare ___ Epic ___ Legendary ___ (+ символ/название тира)

## 4. Типографика
- Display (заголовки, числа, кнопки): <шрифт с двойником в Roblox> ; обводка ___
- Body: <шрифт> ; минимальный размер на каноне 1920×1080: ___ px

## 5. Список ассетов
| # | Имя файла | Тип | Размер PNG | 9-slice L,T,R,B | Состояния | Заметки |
|---|---|---|---|---|---|---|
| 1 | BtnPrimary | кнопка (9-slice) | 256×128 | 32,32,32,32 | Default, Hover, Pressed, Disabled | цвет Accent |
| 2 | BtnSecondary | кнопка | 256×128 | 32,32,32,32 | те же | |
| 3 | BtnClose | круглая | 128×128 | – | Default, Pressed | красная, белый X |
| 4 | PanelMain | панель (9-slice) | 512×512 | 48,48,48,48 | – | центр без орнамента |
| 5 | PanelHeader | плашка заголовка | 512×128 | 48,32,48,32 | – | |
| 6 | SlotItem | слот предмета | 192×192 | 24,24,24,24 | Empty, Filled, Selected, Locked | рамка редкости отдельно |
| 7 | BarBg / BarFill | прогресс-бар | 512×64 | 24,16,24,16 | – | Fill — отдельный слой |
| 8 | IconCoin, IconGem, IconStar … | иконки | 256×256 | – | – | список всех валют/действий |
| 9 | Badge_Rarity_* | бейджи | 192×64 | – | по тирам | |
| 10 | Logo | логотип | ≤ 1024×512 | – | – | текст запечён, не локализуется |
| 11 | ScreenBg_* | фон меню | 1024×576 | – | – | JPEG допустим |

## 6. Экспорт
- PNG-32, alpha чистая (без белого ореола), поле 2-4 px под тень
- Размеры ≤ 1024 по стороне
- Имена как в таблице; метки 9-slice в имени узла `[S=L,T,R,B]`

## 7. Приёмка
- Контраст текста/фона, читаемость в 64 px, вид на светлом и тёмном фоне
- 9-slice тест растяжением 1×..3× без артефактов
- Модерация: нет чужого IP/логотипов/лиц
```

Для процесса B перед полным списком утвердить *style frame*: 1 кнопка (2 состояния), 1 панель, 1 иконка, 1 заголовок на фоне игры.

---

## 12. Чего Figma MCP не умеет и запасные пути

| Ограничение | Следствие | Запасной путь |
|---|---|---|
| Нет Roblox-экспорта; `get_design_context` отдаёт код-референс (React+Tailwind) | Агент переводит вручную по таблице раздела 5 | Плагины раздела 8 |
| Нет понятия 9-slice, нет Roblox-свойств | Margin'ы только метками (4.3) | Метки в имени узла или в тексте-аннотации рядом |
| Чтение ограничено (Starter: жёсткий лимит, у Starter Full seat цифры не заданы) | Нельзя «листать» макет десятками вызовов | Раздел 3.4: строить самим, кэшировать, ручной экспорт PNG пользователем, пользователь присылает скриншоты |
| Запись: beta, платная в будущем; в документации требуется Professional+ (Starter не назван) | Возможен отказ на Starter | Smoke test (3.3); при отказе: макет делает пользователь/дизайнер, либо процесс B без Figma (spec + brief + процедурный UI), либо GuiForge-редактор |
| `use_figma` не вставляет изображения; `generate_image` на credits | Растровые ассеты не «сами» | `upload_assets`, внешний генератор, ручной drag |
| Свои шрифты: только загруженные в аккаунт Figma; в Roblox шрифты не импортируются | Расхождение типографики | Таблица раздела 6: рисовать только шрифтами с двойниками |
| Нет blur, skew, blend modes, угловых разных радиусов, SVG | Эти эффекты запекаются в PNG | Раздел 5/7.1 |
| Нет прототипных взаимодействий и анимаций | Поведение не переносится | Spec агента + juice (art-ui-audio §10) |
| Вывод `use_figma` ≤ 20 KB, большие изменения порциями | Нельзя построить весь кит одним вызовом | Строить по экранам/компонентам, `create_session` держать |
| `generate_figma_design` (HTML → Figma) для Roblox мало полезен | | Не использовать |

---

## 13. Конфликты источников и открытые вопросы

1. **Лимит чтения Figma на Starter:** снимок документации — «6 вызовов/мес.» для Starter/View/Collab; актуальная таблица (FAQ + rate-limits-access, 26.10.2026) — «20/мес.» для View/Collab на всех планах; для Full/Dev на Starter значения нет. Доверять актуальной таблице; для Starter Full seat неизвестно: проверять практикой.
2. **Write на Starter:** страница write-to-canvas требует Professional/Education/Organization/Enterprise; FAQ говорит про Full seat; координатор подтвердил живое подключение с write-инструментами. Не разрешено без smoke test.
3. **Потолок 1024 px для UI-картинок:** подтверждено косвенно (валидация Creator Store `Decal.ColorMap` 1024, комьюнити, EditableImage 1024), прямой строки про `ImageLabel` нет. Загрузка допускает до 8000×8000. Проверить на тестовой картинке.
4. **Decal-ID против Image-ID при загрузке через Open Cloud:** не проверено; тест на первом ассете.
5. **`create_design_system_rules`:** есть в документации 2025, отсутствует в актуальных серверных инструкциях; считать устаревшим.
6. **`screen_capture` в Play mode:** известные пропуски (топ-бар, BillboardGui, иногда HUD), staff-статуса нет; в Edit mode поведение для оверлея StarterGui не подтверждено документацией: проверить на первом экране.
7. **Установка размера окна/эмуляции устройства через MCP:** инструмента в списке нет; harness (9.3) — вывод.
8. **Плагины:** RoImport, UILint v2, GuiForge — все молодые (июль-сентябрь 2026), независимых отзывов мало; перед рекомендацией пользователю пробовать на одном экране.
9. **UIShadow, Upgraded UIGradients, часть StyleSheets** — beta; поведение и свойства могут измениться.
