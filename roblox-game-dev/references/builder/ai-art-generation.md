# 2D-арт через AI-генераторы в браузере: иконки, UI, game icon, thumbnails, loading screen

**Назначение.** Стандартный путь Builder-роли для 2D-арта игры: агент работает с Google «Nano Banana» (Gemini) и ChatGPT Images через браузер пользователя (уже залогиненный), держит единую «style bible», режет результат локально (Python Pillow), готовит точные размеры и загружает в Roblox. Здесь: выбор модели, браузерный процесс, система консистентности, готовые промпты, постобработка, загрузка, риски. Не дублируем: размеры, правила иконки/thumbnail и модерацию → [builder/packaging](packaging.md) (§2, §3, §13, §14); UI-кит, 9-slice, манифест, Open Cloud upload → [builder/ui-figma-workflow](ui-figma-workflow.md) (§4.3, §7); палитра, style guide, бюджеты → [builder/art-ui-audio](art-ui-audio.md) (§3, §5, §9).

**Актуально на: октябрь 2026 (проверено 26.10.2026).** Перепроверять в первую очередь: (1) какая именно модель сейчас работает в приложении Gemini и в AI Studio: Nano Banana 2.1 вышла 06.10.2026, раскатка в приложении постепенная, у бесплатных аккаунтов возможна облегчённая модель; (2) выдаёт ли ChatGPT Images 2.5 настоящий альфа-канал в интерфейсе ChatGPT (у API заявлено, у UI не проверено); (3) лимиты бесплатных тарифов обоих сервисов: числа не публикуются и меняются без анонса; (4) точные размеры выдачи в приложениях (в API: до 4K у Google и до 3840 px по длинной стороне у OpenAI; в чат-интерфейсах не подтверждено); (5) расположение кнопок интерфейсов (меняется чаще всего); (6) формулировки Terms of Use о коммерческом использовании.

## Оглавление

0. [Главные правила (TL;DR)](#0-главные-правила)
1. [Модели октября 2026: факты, выбор, запасные пути](#1-модели)
2. [Браузерный процесс агента](#2-браузерный-процесс)
3. [Система консистентности: style bible, master reference, сетки, варианты редкости](#3-система-консистентности)
4. [Шаблоны промптов (English, готовы к вставке)](#4-шаблоны-промптов)
5. [Постобработка: прозрачность, нарезка, размеры, 9-slice, проверка](#5-постобработка)
6. [Загрузка в Roblox и манифест](#6-загрузка-в-roblox)
7. [Правила и риски](#7-правила-и-риски)
8. [Чек-лист](#8-чек-лист)
9. [Что не проверено](#9-что-не-проверено)

---

## 0. Главные правила

1. **Один раз закрепить стиль, потом генерировать.** Сначала `art/style-bible.md` и один утверждённый пользователем master reference (иконка-эталон). Любая следующая генерация идёт с этим референсом и блоком style bible в промпте. Без этого набор иконок «плывёт» уже на пятом предмете.
2. **Всегда фон-ключ или альфа, и проверка альфы.** Ни Nano Banana, ни интерфейсы чатов не гарантируют настоящую прозрачность; «шахматка» на картинке часто нарисована пикселями. Стандарт: плоский фон `#FF00FF` (или `#00FF00` для розовых/фиолетовых объектов) + локальное вырезание (§5.1). Альфу проверять кодом, не глазами.
3. **Генерировать крупнее, отдавать меньше.** Иконка 256 px получается из 1K-генерации, game icon 512 из 1K-2K, thumbnail 1920×1080 из 2K 16:9. Точный размер выдачи в чате не контролируется: итоговый размер всегда делает Pillow.
4. **Не рисовать текст моделью, если можно текстом Roblox.** Надписи в UI делаются `TextLabel` (локализация, чёткость). Текст в game icon/thumbnail: 0-3 слова, проверять орфографию на каждом кадре.
5. **Лимиты сайта уважать, обходов нет.** Нет второго аккаунта «под лимит», нет обхода CAPTCHA, нет ввода паролей. Упёрлись в лимит: сохранить прогресс (лог промптов), сообщить пользователю, продолжить позже.
6. **Арт не лучше игры и без чужого IP.** Thumbnail из AI, показывающий то, чего нет в игре, снижает PTR/удержание и грозит reduced exposure ([packaging](packaging.md) §0, §7, §13.3). Никаких персонажей, логотипов, брендов, мем-IP в промптах.
7. **Для hero-ассетов (game icon, thumbnail #1) AI даёт черновик, финал проверяет человек.** Для UI-иконок набор из AI в стандартном порядке работает напрямую после правки артефактов. Это синтез (§7.2), не данные Roblox.
8. **Лог каждой генерации.** `art/prompt-log.jsonl`: модель и версия, режим (Gemini app / AI Studio / ChatGPT), промпт, референсы, выбранный вариант, sha256 результата, ID ассета. Без лога стиль невоспроизводим, когда модель обновится.

---

## 1. Модели

### 1.1 Что есть на 26.10.2026

| | **Google «Nano Banana»** | **OpenAI «ChatGPT Images»** |
|---|---|---|
| Актуальная версия | **Nano Banana 2.1** (API id `gemini-nano-banana-2.1`, GA 06.10.2026, страница дока обновлена 06.10.2026). Предшественники: Nano Banana 2 (= Gemini 3.1 Flash Image, 26.02.2026), Nano Banana Pro (= Gemini 3 Pro Image, 20.11.2025) | **ChatGPT Images 2.5** (08.09.2026). API: `gpt-image-2.5-flare` (по умолчанию) и `gpt-image-2.5-sunburst` (точнее, медленнее). Предшественник: Images 2.0 / `gpt-image-2` (апрель 2026) |
| Где в браузере | gemini.google.com (приложение Gemini) и Google AI Studio (aistudio.google.com) | chatgpt.com |
| Разрешение | 1K (по умолчанию), 2K, 4K (NB 2: ещё 512 px). В AI Studio есть выбор; в приложении — по умолчанию, может быть ниже (не подтверждено) | API: произвольные размеры до 3840 px по длинной стороне. В чате размер не задаётся, выдача около 1-2K (оценка) |
| Соотношения сторон | у NB 2: 1:1, 1:4, 4:1, 1:8, 8:1, 2:3, 3:2, 3:4, 4:3, 4:5, 5:4, 9:16, 16:9, 21:9. У 2.1 документ называет только панорамные 1:4/4:1/1:8/8:1 (исправлены полосы на 2K/4K), полный список не повторён | В чате соотношение задаётся словами в промпте («16:9 wide», «square 1:1»); точность не гарантирована |
| Референсы | до **14** изображений на запрос; консистентность до **4 персонажей** и **10 объектов** (NB 2: 5 и 14) | Загрузка изображений + правки «только то, что указано»; можно оставлять комментарии прямо на картинке; заявлено сохранение качества при серии правок |
| Прозрачный фон | В документации **не заявлен**. Известная ловушка: «шахматка» как часть картинки | **Заявлен** для Images 2.5 (launch-страница OpenAI). В API нужен `background=transparent` + PNG/WebP. Для UI ChatGPT поведение не подтверждено: проверять альфу. Сторонний источник пишет, что прозрачность у старой `gpt-image-2` отключена с 30.09.2026 (не подтверждено официально) |
| Текст в картинке | У 2.1 заявлено улучшение текста и инфографики. Короткие надписи обычно ок, длинные требуют проверки | Заявлено улучшение; документация OpenAI всё ещё называет размещение/чёткость текста ограничением. Точный текст писать в кавычках |
| Редактирование | Многошаговые правки в диалоге, смешивание референсов, режим thinking (minimal/medium/high) в API | Точечные правки, inpainting-подобные комментарии на картинке, маска в API |
| Водяные знаки | SynthID (невидим) + C2PA | C2PA-метаданные + невидимый watermark |
| Лимиты (бесплатно) | Числа **не опубликованы**: вычислительные лимиты, обновление примерно каждые 5 часов + недельный потолок. Бесплатному аккаунту доступна генерация на NB 2, «переделать через Nano Banana Pro» только на платных планах. Сообщение 9to5Google (03.10.2026): free может быть привязан к Flash-Lite, ему соответствует «Nano Banana 2 Lite», которая «не рассчитана на несколько референсов и несколько правок» (источник — вторичный, не подтверждено) | Числа **не опубликованы**. Сообщения сообщества: 2-3 картинки в сутки (апрель 2026) или 3-10 за 3 часа (разные периоды); авторитетный лимит — баннер в вашем аккаунте. Платные Plus/Pro: выше лимиты, режим Thinking |
| Платные планы | Google AI Plus / Pro / Ultra: ×2 / ×4 / ×5-20 к стандартным лимитам | ChatGPT Plus ($20/мес), Pro ($100-200/мес по акциям) |
| Коммерческое использование | Права на результат переданы пользователю по условиям (вторичный источник terms.law); free-tier по умолчанию участвует в обучении. Прочитать актуальные Terms | То же: права на результат за пользователем, коммерческое использование разрешено на всех планах (вторичный источник) |

Практические выводы:
- **Для набора иконок с общим референсом** (много картинок, 10+ правок подряд) нужны платные планы или хотя бы проверенный запас лимита. Бесплатный режим годится для разведки стиля (3-6 картинок), не для производства набора на 40 иконок (вывод).
- **AI Studio удобнее для точных параметров** (выбор модели, соотношения сторон, разрешения, количество референсов). Приложение Gemini проще, но параметры задаются словами.
- Если не уверены, какая модель сейчас отвечает: спросить в интерфейсе («Which image model are you using?» — ответ может быть неточным) и записать в лог то, что показывает селектор модели. Если селектора нет, записать «auto».

Источники: ai.google.dev/gemini-api/docs/models/gemini-nano-banana-2.1; techcrunch.com/2026/02/26/google-launches-nano-banana-2-model-with-faster-image-generation/; techcrunch.com/2025/11/20/google-releases-nano-banana-pro-its-latest-image-generation-model; support.google.com/gemini/answer/16275805; openai.com/index/introducing-chatgpt-images-2-5/; developers.openai.com/api/docs/models/gpt-image-2; datanorth.ai/news/openai-launches-chatgpt-images-2-5; docs.apiyi.com/en/live/2026-08/gpt-image-2-transparent-background (сторонний); findskill.ai/blog/nano-banana-2-1-still-free-gemini-after-oct-9-2026 (сторонний); terms.law/ai-output-rights/comparison (сторонний).

### 1.2 Когда какую модель брать

| Задача | Первый выбор | Почему (вывод по заявленным возможностям, проверить на тестовой генерации) |
|---|---|---|
| Набор иконок с общим референсом, серия правок | **Nano Banana (2.1, на платном плане Pro-режим)** | До 14 референсов, заявленная консистентность персонажей/объектов, многошаговые правки |
| Иконка с прозрачным фоном «из коробки» | **ChatGPT Images 2.5** | Прозрачность заявлена; всё равно проверять альфу, при отсутствии — chroma key |
| Короткая надпись внутри картинки (title на баннере, «x2» в иконке) | Пробовать **обе** (по 2-3 варианта), выбрать читаемый | Обе заявляют улучшение; независимых сравнений нет. Надпись всегда проверять по буквам |
| Точечная правка («убрать лишний палец», «заменить цвет бант») | **ChatGPT** (комментарии на картинке) или Gemini диалогом | Оба умеют; выбрать то, где уже идёт диалог со стилем |
| Серия вариаций «что если» (20 концептов thumbnails) | Любая, где есть запас лимита | Для идей точность не нужна |
| Нужны точные соотношения/размер | **AI Studio** | Явные параметры |

### 1.3 Запасные пути

1. Исчерпан лимит основного сервиса: переключиться на другой, **повторив референс-пакет** (master reference + style bible) и записав смену модели в лог; ожидать лёгкий дрейф стиля, поэтому один набор не смешивать между моделями.
2. Оба недоступны или стиль не сходится: Figma `generate_image` (кредиты Figma AI, → [ui-figma-workflow](ui-figma-workflow.md) §3.2), встроенный AI generate в Ads Manager ([packaging](packaging.md) §10, §13.3), процедурные UI-инстансы без картинок ([ui-figma-workflow](ui-figma-workflow.md) §1.2).
3. Нужен pixel-perfect/векторный результат: рисовать в Figma, не генерировать.
4. Hero-арт: художник по заказу ([packaging](packaging.md) §13.2).

---

## 2. Браузерный процесс

### 2.1 Выбор браузера и подготовка

1. **Claude in Chrome** (`mcp__claude-in-chrome__*`) — основной вариант: работает в настоящем Chrome пользователя со всеми его входами. Перед первым шагом **загрузить скилл `chrome-browser`**, затем одним вызовом ToolSearch загрузить нужные инструменты (tabs_context, navigate, computer, read_page, find, file_upload, upload_image, tabs_create). Работать в **новой вкладке**, не трогая открытые.
2. **Встроенный браузер приложения Claude** — запасной вариант. Перед первым шагом загрузить скилл `built-in-browser`. Входы в нём хранятся постоянно, но пользователь должен залогиниться вручную.
3. Пользователь должен быть **залогинен** на gemini.google.com / aistudio.google.com / chatgpt.com. Если открылась страница входа: остановиться и попросить пользователя войти самому. **Никогда не вводить пароли, коды 2FA, не нажимать «согласен» на условия от имени пользователя, не принимать новые Terms без него.**
4. Если сайт показал **CAPTCHA или проверку «вы человек?»**: остановиться, передать пользователю, ждать подтверждения. Не обходить.
5. Куда падают скачанные файлы: в папку «Загрузки» компьютера пользователя. Попросить пользователя (один раз) указать рабочую папку проекта или забрать файлы оттуда через инструменты устройства (`device_stage_files` и `device_list_dir` работают только в папках, подключённых к сессии). Если доступа нет, прямо сказать пользователю и не изобретать обходы.

### 2.2 Пошагово: одна серия иконок

1. Прочитать `art/style-bible.md` и `art/refs/master_*.png`; собрать промпт из блока STYLE (§3.1) и шаблона (§4).
2. Открыть новую вкладку, зайти на выбранный сайт, убедиться, что аккаунт тот (проверить по интерфейсу, не вводя данных). Начать **новый чат на серию** (чтобы контекст был чистым и в нём лежал master reference).
3. Загрузить референс: кнопка «+»/скрепка → загрузка файла (`file_upload`/`upload_image`). Первым сообщением дать референс и фразу: «This is the style reference. Match its line weight, palette, lighting and shading exactly. Do not copy its subject.»
4. Вставить промпт, отправить. Ждать завершения генерации (смотреть, что кнопка остановки пропала и появилась картинка; обычно десятки секунд, до пары минут — оценка).
5. Открыть результат в полном размере, осмотреть (§7.3 чек артефактов). Если пригодно, скачать оригинал (не скриншот). Если нет — правка в том же чате конкретной фразой («Make outline 20% thicker; keep everything else identical»), не пересоздание с нуля.
6. Сразу переименовать файл по схеме (§3.5) и перенести в `art/raw/`, записать строку в `prompt-log.jsonl`.
7. Следующий предмет: **тот же чат**, если консистентность держится; если дрейфует — новый чат с master reference + последней утверждённой иконкой серии (две референсные картинки).
8. После серии: показать пользователю контактный лист (все иконки сеткой на тёмном и светлом фоне, размер 64 px), только потом обрабатывать дальше.

### 2.3 Партии и лимиты

- **Размер партии:** 4-6 запросов подряд, затем проверка. Не запускать десятки параллельных вкладок и не повторять отправку при ошибке: ждать, смотреть сообщение сайта.
- **Лимит достигнут:** сайт пишет об этом сам (баннер/сообщение). Остановиться, записать в лог «остановлено на: <имя ассета>, <время>», сообщить пользователю, когда сбросится (Gemini: окно ~5 ч; ChatGPT: по сообщению). Не создавать новые аккаунты и не использовать чужие.
- **Экономия:** сначала сетка из 6-12 иконок в одном запросе (§3.4), затем точечные правки лучших; не генерировать по одному предмету, пока стиль не утверждён.
- **Эксплуатация:** без скрейпинга ответов, без автоматизации через неофициальные API, без расширений для обхода лимитов. Если нужен объём, это путь через официальный API с ключом пользователя (отдельное решение пользователя, платный).

### 2.4 Где что делать

| Нужно | Где |
|---|---|
| Точное соотношение сторон/разрешение, выбор модели | Google AI Studio |
| Быстрая разведка стилей, правки диалогом | Gemini app или ChatGPT |
| Прозрачный фон из коробки, комментарии на картинке | ChatGPT |
| 14 референсов одновременно | Gemini / AI Studio |

Источники: скиллы `chrome-browser`, `built-in-browser` (сессионные инструкции); support.google.com/gemini/answer/16275805; openai.com/index/introducing-chatgpt-images-2-5/.

---

## 3. Система консистентности

### 3.1 Style bible (файл `art/style-bible.md`)

Заполняется один раз после выбора стиля ([art-ui-audio](art-ui-audio.md) §3.2 style guide и палитра; цвета брать из UI-кита/Figma-переменных, [ui-figma-workflow](ui-figma-workflow.md) §4.2). Из него строится блок `{STYLE}`, вставляемый в каждый промпт целиком. Шаблон:

```
STYLE BLOCK (paste into every prompt, unchanged):
Glossy cartoon game-icon style for a Roblox game, kid-friendly, bold and simple.
- Shapes: chunky rounded forms, soft bevels, one clear silhouette, no tiny details.
- Outline: thick dark outline, uniform weight (about 4% of image width), color = very dark
  shade of the object's own hue (not pure black).
- Shading: 2-step cel shading + one soft highlight at top-left, subtle bottom shadow inside the shape.
- Lighting: single light source from top-left, same on every asset.
- Camera: front view, slightly from above (3/4 angle), object centered, fills ~80% of the canvas.
- Palette (use only these as base colors): primary #FFC93C, secondary #3DA5F5, accent #FF5C8A,
  dark #2B1F3D, light #FFF6E0. Rarity glow colors listed separately.
- Background: flat solid #FF00FF magenta, no gradient, no shadow on the floor, no text, no border.
- Never include: real brands, characters from other games, watermarks, photoreal skin, text.
```

Замечания:
- Одна фраза «0 elements outside the object» бесполезна; пишите конкретно (что на фоне, где свет).
- Палитру давать hex, но модели повторяют hex **приблизительно**; финальную сверку цвета делать пипеткой/кодом (§5.5) и при необходимости цветокорректировать.
- Если в палитре игры есть пурпурный/розовый: фон-ключ `#00FF00`, смена в одном месте style bible.

### 3.2 Master reference

1. Сгенерировать 6-10 вариантов **одного** предмета-эталона (например, «coin» или «basic pet egg») в нескольких стилях. Показать пользователю, утвердить один.
2. Довести его до эталонного состояния (правки линии, свет), сохранить как `art/refs/master_icon.png` (+ при необходимости `master_ui_button.png`, `master_character.png`).
3. Любая новая серия: master reference + 1-2 последние утверждённые иконки той же категории. Максимум референсов у Gemini — 14, но практичны 2-4: больше размывает указания (вывод).
4. После обновления модели (смена версии Nano Banana/Images) стиль может сдвинуться: перегенерировать master reference на новой модели и сравнить с эталоном до массовой работы. Смену версии записывать в лог.

### 3.3 Правила консистентности

1. Один блок STYLE, слово в слово, во всех промптах серии.
2. Один чат на серию (контекст держит стиль); при дрейфе: новый чат + референсы.
3. Один ракурс и угол (3/4) для всех предметов категории; питомцы — front 3/4 с одинаковым разворотом.
4. Правки: просить менять одну вещь и добавлять «keep everything else identical».
5. Цвета редкостей — через постобработку (§3.6), не через регенерацию.
6. Разные категории (иконки предметов, кнопки/рамки, фоны) имеют разный master reference, но общую палитру и толщину линии.

### 3.4 Сетка иконок в одном изображении, затем нарезка

Зачем: все иконки одной сетки разделяют контекст, поэтому внутри листа стиль почти идентичен; дешевле по лимитам (1 запрос вместо 12).

Рецепт:
1. Просить сетку `N columns × M rows`, **до 12 ячеек** (4×3), одна иконка в ячейке, равные ячейки, широкие поля между иконками, без линий сетки, без подписей, сплошной фон-ключ.
2. Запрашивать 2K (AI Studio) или самое крупное, что даёт сервис. Ячейка ~500 px достаточна для итоговых 256.
3. Резать скриптом §5.2 по равной сетке. Если модель сместила предметы за границы ячеек: перегенерировать лист (ячейки не двигать вручную), либо запрашивать меньшую сетку (3×3, 2×3). Надёжность равной нарезки зависит от модели (оценка: на 4×3 чаще нужны 1-2 переделки).
4. Названия предметов перечислить в промпте в порядке «слева направо, сверху вниз» и дублировать в `names.txt` для скрипта.
5. Для hero-предметов (яйцо легендарки, главный питомец) делать **отдельный** запрос с референсом из листа.

### 3.5 Именование

`<Категория>_<Предмет>[_<Вариант>]_<Размер>.png`, PascalCase, без пробелов, совпадает с именем в манифесте и в Luau-модуле `UIAssets` ([ui-figma-workflow](ui-figma-workflow.md) §7.3).

| Тип | Пример |
|---|---|
| Иконка валюты | `Icon_Coin_256.png`, `Icon_Gem_256.png` |
| Питомец | `Pet_Dragon_Common_256.png`, `Pet_Dragon_Golden_256.png` |
| Яйцо | `Egg_Forest_256.png` |
| Кнопка 9-slice | `BtnPrimary_Default_9s.png` |
| Рамка | `Frame_Shop_9s.png` |
| Бейдж | `Badge_FirstWin_150.png` |
| Game icon | `GameIcon_v3_512.png` |
| Thumbnail | `Thumb_01_Mechanic_1920x1080.jpg` |
| Исходники | `art/raw/<имя>__gen03.png` (номер генерации) |

### 3.6 Варианты редкости и «золотые/радужные» питомцы: перекраска, не регенерация

Почему: регенерация меняет форму и мелкие детали, и «Golden Dragon» перестаёт быть тем же драконом. Перекраска сохраняет силуэт и позволяет генерировать варианты автоматически. Схема:

1. Базовый питомец генерируется один раз в серой/нейтральной палитре или в цвете Common (по style bible).
2. Golden: градиентная карта (gradient map) яркости в золото + усиление блика. Rainbow: смещение hue по диагонали (hue ramp). Shiny/Void/Neon и т.д.: аналогично.
3. Мелкие эффекты (звёздочки, свечение, рамка редкости) — отдельными слоями в Roblox (`ImageLabel`, `UIGradient`, частицы), не запекать.
4. Название тира всегда дублируется текстом на карточке (не полагаться на один цвет: доступность, [art-ui-audio](art-ui-audio.md) §3.2).
5. Если перекраска смотрится «грязно» на сложной текстуре, регенерировать один раз с промптом «same pet, same pose, recolored in solid gold» и референсом базового.

Код перекраски — §5.4.

---

## 4. Шаблоны промптов

Все промпты на английском. `{STYLE}` — блок из §3.1 целиком. `[…]` — подстановка. Референс (master) прикладывать к каждому запросу серии. Моделям нельзя задать negative prompt отдельным полем, поэтому ограничения пишутся в тексте положительно («plain background», «no text»).

### 4.1 UI-иконка (кнопка меню, настройка, предмет интерфейса)

```
Create one game UI icon: [SUBJECT, e.g. "a treasure chest, closed, gold trim"].
{STYLE}
Single object centered, filling about 80% of the canvas, square 1:1 composition,
generous margin on all sides so nothing touches the edge. Plain flat #FF00FF background.
No text, no frame, no shadow on the floor.
Match the attached style reference exactly in outline weight, shading and palette; do not copy its subject.
```

### 4.2 Иконка валюты (coins, gems, tokens)

```
Create one currency icon for a Roblox game: [e.g. "a round gold coin with an embossed star"].
{STYLE}
Hero view: slightly rotated 3/4, readable at 64x64 pixels. Bold simple shape, 2-3 colors plus
one highlight. Strong silhouette and contrast against both dark and light backgrounds.
Plain flat #FF00FF background. No digits, no letters, no sparkles outside the object.
Match the attached style reference.
```

Для набора валют (coin/gem/ticket/key) использовать сетку (§4.10).

### 4.3 Питомец / предмет по редкости

Базовая генерация (рекомендую в цвете Common; редкости потом через §3.6):

```
Create one collectible pet icon: [e.g. "a chubby baby dragon, big round eyes, tiny wings, smiling"].
{STYLE}
Full body, front 3/4 view, cute proportions (large head, small body), friendly expression,
clean readable silhouette. Rarity: Common - simple plain colors, no glow, no accessories.
Centered, 80% of canvas, plain flat #FF00FF background. No text, no frame.
Match the attached style reference.
```

Если по геймдизайну нужны разные внешние атрибуты по редкости (корона у Legendary), добавить строку с атрибутом и держать остальной промпт идентичным:

```
Rarity: Legendary - same pet, same pose and proportions as the reference, add a small golden crown
and a soft golden glow behind it. Everything else identical to the attached image.
```

### 4.4 Яйцо (egg)

```
Create one egg icon for a pet-hatching game: [e.g. "a forest egg, green base, leaf pattern, moss at the bottom"].
{STYLE}
Upright egg, front view, symmetrical, slightly glossy, with a distinct pattern readable at 96x96 pixels.
Size relation: similar visual weight across the whole egg family.
Centered, 80% of canvas, plain flat #FF00FF background. No text, no frame.
Match the attached style reference (previous eggs in the same set).
```

### 4.5 Game icon 512×512

Принцип из [packaging](packaging.md) §2 и §2.5 (выборка 152 игр): один фокус, ≤5 элементов, читаемость на ~150 px, поле 5-8%, жанровая логика. **Дефолт топ-полосы — mixed-композиция: герой/аватар + ключевой объект или существо игры на фоне игровой сцены, без обводки** (топ: 40% mixed, 95% без обводки; крупное лицо лишь 8%). Крупный план лица — жанровый вариант (хоррор, аниме-RPG/TD) или по прямому запросу.

```
Create a square game icon (1:1) for a Roblox game called "[GAME NAME - do NOT render text]".
Genre: [simulator / horror / obby / tycoon]. Hero: [e.g. "a Roblox-style blocky avatar, waist-up, excited expression,
holding up a glowing rare pet"]. Key object/creature: [the game's core thing, e.g. "a giant cracked golden egg"].
{STYLE_ICON_VARIANT}
Composition: hero + key object fill ~70% of the frame, clear focal point, set in a simplified in-game scene
([SCENE], saturated colors, bright rim light separating the hero from the background, depth blur on the scene).
Maximum 4 visual elements. No outline around the characters - separation comes from rim light and contrast.
Variant B (horror / anime genres): close-up face and shoulders, strong emotion, dark or dramatic background.
Safe margin: keep all important details at least 6% away from every edge.
It must stay readable when shrunk to 150x150 pixels.
No text, no logo, no UI, no watermark, no real brands.
```

Обводка из style bible (§3) — для внутриигровых UI-иконок, предметов и петов; для иконки игры её убрать. `{STYLE_ICON_VARIANT}` — тот же style bible без обводки, фон не magenta, а цветной (иконка идёт с фоном). Для хоррора: «dark palette, one cold light source, stylized spooky, no gore, no blood, no realistic skin». Генерировать 1K, затем уменьшить до 512; проверять на 150 px (§5.6). Текст/название добавлять вручную поверх, только если это решено ([packaging](packaging.md) §2.3).

### 4.6 Thumbnail 1920×1080 (16:9)

Принципы ([packaging](packaging.md) §3): читается в маленьком тайле, фантазия игрока понятна сразу, **нижняя полоса пустая** (метаданные), без промо и обещаний, графика **не лучше реальной игры**. Референсы: реальные скриншоты из Studio/игры и master reference стиля.

```
Create a 16:9 key art illustration for a Roblox game thumbnail, showing REAL gameplay: [e.g. "a player's blocky avatar
mid-jump collecting glowing coins on floating platforms above a lava canyon"].
Use the attached game screenshots as the truth for characters, environment style and colors; match the game's real look
(do not make it more detailed or realistic than the game).
{STYLE_NO_BG}
Composition: main action in the center and upper two thirds; leave the bottom 15% of the image calm and simple
(no important details, no text there). Strong silhouette, high contrast, one clear focal point, motion cue
(speed lines or dynamic pose). Bright saturated colors suited to the genre.
No text, no logo, no UI, no prices, no "free"/"new"/"x2" claims, no watermark, no real brands.
```

Варианты концептов для теста ([packaging](packaging.md) §3.3, §8): (1) mechanic-explainer, (2) лицо + эмоция + действие, (3) power fantasy/редкий питомец, (4) сцена мира/новый контент. Для каждого — отдельный запрос с общим STYLE.

После генерации: резать до 16:9 (1920×1080), <3 МБ ([packaging](packaging.md) §3.1). Каждый кадр сопоставлять с реальной игрой (§7.2).

### 4.7 Loading screen art

```
Create a 16:9 loading screen background for a Roblox game: [WORLD, e.g. "a sunny cartoon forest clearing with
a giant glowing egg in the center"]. 
{STYLE_NO_BG}
Wide composition with a calm area at the center-bottom and left/right edges for UI (progress bar, tips).
Soft depth of field, no characters in the center, not too busy, colors consistent with the game palette.
No text, no logo, no UI elements, no watermark.
```

Брать 2K, сжимать в JPEG q85-90 (полноэкранный фон без альфы, [ui-figma-workflow](ui-figma-workflow.md) §7.2). Помнить про эффективный потолок ~1024 px у UI-картинок (проверено не явно, там же): для фонов использовать 1024×576 или 1024×1024 в `ImageLabel` с `ScaleType = Crop`, проверить на тесте.

### 4.8 Текстуры кнопок и рамок для 9-slice

Требование: углы с деталями, **центр и края однородные**, строгая симметрия, никаких деталей в центре (иначе растянется).

```
Create one UI button texture for a game: [e.g. "a chunky green 'primary' button, rounded rectangle, glossy"].
{STYLE_NO_BG}
Flat front view, perfectly horizontally symmetric, 2:1 aspect ratio.
Layers: dark outer outline, vertical gradient body (lighter at top, darker at bottom), thin highlight strip
in the top third, subtle inner bottom shadow.
The middle of the button must be a plain smooth gradient with NO patterns, NO icons, NO text.
Plain flat #FF00FF background around the button. No drop shadow outside the outline.
```

Для рамки/панели: «ornamented corners only, edges plain, center a flat color». После генерации: симметризация и подготовка слайса (§5.5); чаще надёжнее взять **только угол** из AI и собрать панель кодом. Состояния (Default/Hover/Pressed/Disabled) — перекраской/затемнением в Pillow, не регенерацией.

### 4.9 Иконки бейджей (Badge)

```
Create one achievement badge icon: [e.g. "first win - a golden trophy with a small star ribbon"].
{STYLE}
Circular medallion composition (the badge will be cropped to a circle), subject centered inside a round emblem,
margins 10% from the circle edge, bold shapes readable at 150x150 pixels.
Background: flat solid [COLOR] filling the full square (no transparency needed). No text, no digits.
Match the attached style reference.
```

Бейджи — отдельные ассеты ([studio-config](studio-config.md)); один семейный frame, цвет по категории.

### 4.10 Сетка иконок (лист)

```
Create a sprite sheet of [N] separate game icons in a grid of [C] columns x [R] rows on one square canvas.
Icons, left to right, top to bottom: 1) [coin], 2) [gem], 3) [ticket], 4) [key], 5) ..., N) ...
{STYLE}
Each icon is one separate object centered in its own equal cell, with wide empty margin around it
(objects never touch each other or cross cell borders). Same size, same angle, same light direction for all.
No grid lines, no labels, no numbers, no text. One plain flat #FF00FF background for the whole sheet.
```

### 4.11 Правки (готовые фразы)

| Проблема | Фраза |
|---|---|
| Линия тонкая/разная | `Make the outline thicker and uniform, about 4% of image width. Keep shape, colors and pose identical.` |
| Артефакт текста | `Remove all letters and symbols from the image. Keep everything else identical.` |
| Лишние пальцы/кривые руки | `Fix the hands: exactly five fingers per hand, simple blocky Roblox-style hands. Keep everything else identical.` |
| Свет не оттуда | `Relight with a single light from the top-left. Keep shapes and colors.` |
| Не тот цвет | `Change only the [belt] color to #3DA5F5. Do not change anything else.` |
| Слишком детально | `Simplify: remove small details, keep large readable shapes and the same silhouette.` |
| Фон не плоский | `Replace the background with a perfectly flat solid #FF00FF, no gradient, no shadow.` |

Источники: [packaging](packaging.md) §2, §3, §8, §13; [ui-figma-workflow](ui-figma-workflow.md) §4.3, §7; create.roblox.com/docs/production/promotion/game-icons; create.roblox.com/docs/production/publishing/thumbnails; create.roblox.com/docs/ui/9-slice.

---

## 5. Постобработка

Локально: Python 3 + Pillow (проверено на Pillow 12.3, numpy 2.5 в окружении Builder; сторонний `rembg` ставить только по необходимости: скачивает модель, объёмно). Запускать с флагом `-I` на недоверенных входах: `python3 -I script.py …`. Скачанные файлы класть в отдельную папку (`art/raw/`), скрипты хранить в другой (`tools/art/`).

### 5.1 Прозрачность: три способа, по убыванию надёжности

| Способ | Когда | Проверка |
|---|---|---|
| 1. **Chroma key по плоскому фону** `#FF00FF`/`#00FF00` | Стандарт для иконок и предметов | Вырезание заливкой от краёв (не трогает внутренние пиксели того же цвета), despill каймы (код §5.2). Предмет не должен содержать цвет-ключ |
| 2. **Нативная альфа ChatGPT** | Если интерфейс отдал PNG с альфой | `python3 -I -c "from PIL import Image; im=Image.open('x.png').convert('RGBA'); print(im.getchannel('A').getextrema())"` — если `(255, 255)`, альфы нет, это «шахматка»/сплошной фон: идти к способу 1 |
| 3. **Удаление фона нейросетью** (rembg и аналоги) | Фон сложный (сцены), хотя для иконок лучше ключ | Проверять края на тёмном и светлом, волосы/блики часто рвутся |

Нельзя доверять превью в браузере: серо-белая шахматка в окне просмотра может быть частью пикселей. Никогда не использовать для UI JPEG-файлы с «прозрачностью».

### 5.2 Нарезка листа и вписывание (рабочий скрипт, проверен на синтетическом листе)

`tools/art/slice_sheet.py` (запуск: `python3 -I tools/art/slice_sheet.py art/raw/sheet.png art/out --cols 4 --rows 3 --names names.txt --size 256 --key magenta`):

```python
#!/usr/bin/env python3
"""Лист иконок -> отдельные PNG с альфой, трим, паддинг, ресайз, частичный манифест."""
import argparse, hashlib, json, pathlib
from collections import deque
from PIL import Image

KEYS = {"magenta": (255, 0, 255), "green": (0, 255, 0), "white": (255, 255, 255)}

def key_out(img, key_rgb, tol=60):
    """Фон -> прозрачность заливкой от краёв; внутренние пиксели цвета-ключа не трогаются."""
    img = img.convert("RGBA"); w, h = img.size; px = img.load()
    bg = lambda p: all(abs(p[i] - key_rgb[i]) <= tol for i in range(3))
    seen = bytearray(w * h); q = deque()
    for x in range(w): q.extend(((x, 0), (x, h - 1)))
    for y in range(h): q.extend(((0, y), (w - 1, y)))
    while q:
        x, y = q.popleft()
        if x < 0 or y < 0 or x >= w or y >= h or seen[y * w + x]: continue
        seen[y * w + x] = 1
        if not bg(px[x, y]): continue
        px[x, y] = (0, 0, 0, 0)
        q.extend(((x+1, y), (x-1, y), (x, y+1), (x, y-1)))
    if key_rgb == (255, 0, 255):          # despill: убрать розовую кайму у края
        for y in range(h):
            for x in range(w):
                r, g, b, a = px[x, y]
                if a and any(0 <= x+dx < w and 0 <= y+dy < h and px[x+dx, y+dy][3] == 0
                             for dx, dy in ((1,0),(-1,0),(0,1),(0,-1))) and g < max(r, b) - 25:
                    px[x, y] = (r, g, int(b * 0.6 + g * 0.4), a)
    return img

def trim_pad_fit(img, size, pad=0.06):
    bbox = img.getchannel("A").getbbox()
    if bbox: img = img.crop(bbox)
    inner = int(size * (1 - 2 * pad)); img.thumbnail((inner, inner), Image.LANCZOS)
    canvas = Image.new("RGBA", (size, size), (0, 0, 0, 0))
    canvas.paste(img, ((size - img.width) // 2, (size - img.height) // 2), img)
    return canvas

def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("sheet"); ap.add_argument("out")
    ap.add_argument("--cols", type=int, required=True); ap.add_argument("--rows", type=int, required=True)
    ap.add_argument("--names"); ap.add_argument("--size", type=int, default=256)
    ap.add_argument("--key", choices=list(KEYS)); ap.add_argument("--inset", type=float, default=0.02)
    a = ap.parse_args()
    sheet = Image.open(a.sheet).convert("RGBA"); out = pathlib.Path(a.out); out.mkdir(parents=True, exist_ok=True)
    names = [n.strip() for n in open(a.names, encoding="utf-8") if n.strip()] if a.names else []
    cw, ch = sheet.width / a.cols, sheet.height / a.rows; manifest = {}
    for r in range(a.rows):
        for c in range(a.cols):
            i = r * a.cols + c; name = names[i] if i < len(names) else f"Icon_{i:02d}"
            ix, iy = cw * a.inset, ch * a.inset
            cell = sheet.crop((round(c*cw+ix), round(r*ch+iy), round((c+1)*cw-ix), round((r+1)*ch-iy)))
            if a.key: cell = key_out(cell, KEYS[a.key])
            f = out / f"{name}.png"; trim_pad_fit(cell, a.size).save(f, optimize=True)
            manifest[name] = {"file": f.name, "w": a.size, "h": a.size,
                              "sha256": hashlib.sha256(f.read_bytes()).hexdigest(), "assetId": 0}
    (out / "ui-assets.partial.json").write_text(json.dumps(manifest, indent=2, ensure_ascii=False), encoding="utf-8")
    print(f"ok: {len(manifest)} icons -> {out}")

if __name__ == "__main__":
    main()
```

Ограничения: ключ с допуском 60 может «съедать» близкие к ключу цвета предмета (розовые бантики при `#FF00FF`): тогда фон `#00FF00` или меньший `tol`. Нарезка равной сеткой, а не поиском объектов: см. §3.4. Для одиночных иконок использовать `--cols 1 --rows 1`.

### 5.3 Размеры и сжатие

| Ассет | Итог | Источник размера |
|---|---|---|
| UI-иконка | 256×256 (крупные 512), PNG-32, поле 2-6% | [ui-figma-workflow](ui-figma-workflow.md) §7.2 |
| Hero-панель/логотип | ≤1024 по стороне | там же (эффективный потолок ~1024, проверить на тесте) |
| Кнопка 9-slice | 256×128 … 512×256 | там же |
| Game icon | ≥512×512 (шаблон 512×512); проверка на 150 px | [packaging](packaging.md) §2.1 |
| Thumbnail | 1920×1080, <3 МБ, jpg/png | [packaging](packaging.md) §3.1 |
| Loading/фон без альфы | JPEG q85-90 | [ui-figma-workflow](ui-figma-workflow.md) §7.2 |
| Спрайт-лист иконок | ≤1024×1024 (`ImageRectOffset/Size`) | там же |

```python
from PIL import Image
im = Image.open("art/raw/Thumb_01__gen02.png").convert("RGB")
w, h = im.size                           # приводим к 16:9 центр-кропом, затем к 1920x1080
target = 16 / 9
if w / h > target:  im = im.crop(((w - int(h * target)) // 2, 0, (w + int(h * target)) // 2, h))
else:               im = im.crop((0, (h - int(w / target)) // 2, w, (h + int(w / target)) // 2))
im.resize((1920, 1080), Image.LANCZOS).save("Thumb_01_Mechanic_1920x1080.jpg", quality=90, optimize=True)
```

Если JPEG >3 МБ, уменьшать `quality` (85 → 80). Иконка 512: `im.resize((512, 512), Image.LANCZOS)`; при апскейле маленького источника не пытаться «улучшать» (мыло): перегенерировать крупнее.

### 5.4 Перекраска редкостей (Golden/Rainbow без регенерации)

```python
from PIL import Image, ImageOps
import numpy as np

def gradient_map(img, stops):                    # stops: [(0.0,(r,g,b)), (0.5,(..)), (1.0,(..))]
    rgba = np.array(img.convert("RGBA")); lum = np.array(ImageOps.grayscale(img.convert("RGB"))) / 255.0
    out = np.zeros_like(rgba, dtype=np.float32); out[..., 3] = rgba[..., 3]
    for (p0, c0), (p1, c1) in zip(stops, stops[1:]):
        m = (lum >= p0) & (lum <= p1); t = ((lum - p0) / (p1 - p0 + 1e-9))[m][:, None]
        out[..., :3][m] = np.array(c0) * (1 - t) + np.array(c1) * t
    return Image.fromarray(out.astype("uint8"), "RGBA")

def rainbow(img, strength=0.65):                 # диагональная смена hue, сохраняя яркость/форму
    hsv = np.array(img.convert("RGB").convert("HSV")).astype(np.float32)
    h, w = hsv.shape[:2]; ramp = (np.add.outer(np.arange(h), np.arange(w)) / (h + w)) * 255
    hsv[..., 0] = (hsv[..., 0] * (1 - strength) + ramp * strength) % 255
    rgb = Image.fromarray(hsv.astype("uint8"), "HSV").convert("RGB"); rgb.putalpha(img.getchannel("A")); return rgb

base = Image.open("Pet_Dragon_Common_256.png")
gradient_map(base, [(0, (70, 40, 0)), (0.55, (255, 190, 40)), (1, (255, 245, 190))]).save("Pet_Dragon_Golden_256.png")
rainbow(base).save("Pet_Dragon_Rainbow_256.png")
```

Значения подбирать под палитру игры и проверять на 64 px; код — шаблон, поведение на реальных иконках проверить глазами и контактным листом. Выпуск вариантов фиксировать в манифесте (`derivedFrom`).

### 5.5 9-slice: симметризация и разметка

1. Взять AI-кнопку/рамку после вырезания фона (§5.1); обрезать по альфе без паддинга внутри (паддинг только для теней).
2. **Симметризация:** оставить верхний-левый квадрант и отзеркалить, чтобы углы были идентичны:

```python
from PIL import Image, ImageOps
im = Image.open("BtnPrimary_Default_raw.png").convert("RGBA")
w, h = im.size
q = im.crop((0, 0, w // 2, h // 2))
top = Image.new("RGBA", (w, h // 2)); top.paste(q, (0, 0)); top.paste(ImageOps.mirror(q), (w - q.width, 0))
sym = Image.new("RGBA", (w, h)); sym.paste(top, (0, 0)); sym.paste(ImageOps.flip(top), (0, h - top.height))
sym.save("BtnPrimary_Default_9s.png")
```

3. Определить margins L,T,R,B (по углу: до начала однородной части) и записать в манифест; `SliceCenter = Rect.new(L, T, W-R, H-B)` (**абсолютные координаты**, не отступы; → [ui-figma-workflow](ui-figma-workflow.md) §4.3). Угол должен быть без элементов, которые должны растягиваться.
4. Состояния: Pressed = затемнение/сдвиг градиента в Pillow, Disabled = десатурация, Hover = `UIScale`. Не регенерировать.
5. Проверить в Studio на трёх размерах (мелкая, средняя, на всю ширину): на растяжении не должно быть швов и деформации узора.

Если AI-кнопка не симметрична после симметризации (глянцевый блик «ломается»), собрать кнопку из инстансов, а AI использовать только для иконки внутри ([ui-figma-workflow](ui-figma-workflow.md) §1.2).

### 5.6 Проверка на размере телефона

1. Контактный лист: все иконки набора в сетке на тёмном (`#1B1B1B`) и светлом фоне, размеры 48, 64 и 150 px. Показать пользователю.
2. Game icon: уменьшить до **150×150**, затем до 96 — читается ли фокус, эмоция, силуэт; ≤5 элементов; поле 5-8% ([packaging](packaging.md) §2.3).
3. Thumbnail: уменьшить до ширины ~400 px (тайл поиска) и проверить: понятен ли жанр, пустая ли нижняя полоса.
4. В Studio (Play Test в эмуляции телефона) проверить иконку в реальном UI на 840×390 points (оценка из [ui-figma-workflow](ui-figma-workflow.md) §7.2).

Источники: Pillow docs (pillow.readthedocs.io); create.roblox.com/docs/ui/9-slice; [ui-figma-workflow](ui-figma-workflow.md) §7.2; [packaging](packaging.md) §2.3.

---

## 6. Загрузка в Roblox

1. **Куда:** UI-ассеты и иконки предметов (Decal/Image) — через Open Cloud Assets API (скрипт/Asphalt) или Asset Manager Studio; game icon и thumbnails — Game Settings в Studio / Creator Hub (Experience → Settings → Icon, Thumbnails) либо EXPERIMENTAL-эндпоинты Open Cloud. Точные curl, scopes, лимиты, Decal против Image ID и квоты → [project-setup](project-setup.md) §7-8 и [ui-figma-workflow](ui-figma-workflow.md) §7.5.
2. **Формат/лимиты:** PNG/JPEG/BMP/TGA, <8000×8000, до 20 MB; **новые версии получают новый ID**, обновить нельзя ([project-setup](project-setup.md) §8).
3. **Перед массовой загрузкой** прогнать один ассет и проверить `rbxassetid://<id>` в `ImageLabel` (Decal против Image ID, [ui-figma-workflow](ui-figma-workflow.md) §7.5 п. 4).
4. **Группа, а не личный аккаунт**, если игра командная.
5. **Модерация.** Картинки проходят автоматическую и ручную проверку, обычно часы; пока в очереди — игроки не видят ([ui-figma-workflow](ui-figma-workflow.md) §7.6). AI-арт модерируется как любой другой. Известный риск: ложные срабатывания на «реалистичную кожу» и крупные планы конечностей ([packaging](packaging.md) §14.1). Загружать **заранее**, держать запасной одобренный вариант. Скрипт-гейт `moderationResult` → [project-setup](project-setup.md) §7.
6. **Манифест `art/ui-assets.json`.** Ключ — имя ассета; идентификатор содержимого — `sha256`. Если нужно искать по хэшу (дедуп/пропуск неизменных), вести второй индекс `byHash`:

```json
{
  "assets": {
    "Pet_Dragon_Common_256": { "file": "Pet_Dragon_Common_256.png", "sha256": "ab12…", "assetId": 0,
      "w": 256, "h": 256, "model": "nano-banana-2.1", "promptLogId": "2026-10-27-0012",
      "derivedFrom": null, "status": "uploaded|moderation_pending|approved|rejected" },
    "Pet_Dragon_Golden_256": { "file": "Pet_Dragon_Golden_256.png", "sha256": "cd34…", "assetId": 0,
      "derivedFrom": "Pet_Dragon_Common_256", "recolor": "gradient_map:gold-v1" }
  },
  "byHash": { "ab12…": "Pet_Dragon_Common_256", "cd34…": "Pet_Dragon_Golden_256" }
}
```

Перезаливать только при смене `sha256`; `assetId` записывать после `done` операции; из манифеста генерируется Luau-модуль `UIAssets` ([ui-figma-workflow](ui-figma-workflow.md) §7.3).
7. **Prompt log и манифест хранить в репозитории.** Исходные `art/raw/` можно держать вне git (большие), но sha256 в манифесте.

Источники: create.roblox.com/docs/cloud/guides/usage-assets; create.roblox.com/docs/projects/assets; [project-setup](project-setup.md); [ui-figma-workflow](ui-figma-workflow.md).

---

## 7. Правила и риски

### 7.1 Что требует Roblox (на 26.10.2026)

- **Страница Roblox о generative AI** (create.roblox.com/docs/generative-AI) описывает игры, где AI работает во время игры (чат-боты, генерация по вводу игрока): модерация, maturity questionnaire, раскрытие игроку, что он говорит с AI. Про **AI-арт, загруженный создателем** (иконки, thumbnails), там ничего нет; специальных правил о метке «AI-generated» для ассетов я не нашёл. Не утверждать, что метка требуется или не требуется; действуют общие Community Standards, модерация изображений и IP-политика.
- **Thumbnails и иконка:** правила содержания, запрет промо/субъективных заявлений, «misleading metadata» → reduced exposure; чужие тайтлы и копии арта → demotion ([packaging](packaging.md) §3.2, §7, §14).
- **Сигналы рекомендаций** (PTR, first-play bounce) наказывают арт, обещающий больше игры ([packaging](packaging.md) §0 п. 1).

### 7.2 Честность и аудитория

1. Thumbnail показывает **настоящий геймплей и настоящих персонажей** игры; качество рендера не выше игры (отзыв разработчиков 2025: игроки быстро уходят, если игра хуже картинки).
2. Игроки замечают и осуждают «AI slop» (термин из DevForum, [packaging](packaging.md) §13.3). Заметно: лишние пальцы, мыльные текстуры, нечитаемый текст, «не-Roblox» персонажи, одинаковые «глянцевые» лица. Нужны реальные Roblox-риги в референсах.
3. Схема из [packaging](packaging.md) §13.3: AI для идей и множества концептов, 6-10 лучших в Ads Manager, победителя финализирует художник. Для UI-иконок и внутриигровых предметов допустим прямой AI-путь с ручной проверкой (синтез).

### 7.3 Чек артефактов на каждой картинке (перед скачиванием)

1. Руки/пальцы/лапы: нормальное число, форма простая.
2. Текст: нет случайных букв/символов; если надпись нужна, проверить побуквенно.
3. Силуэт: читается при заливке в один цвет (мысленно) и на 64 px.
4. Свет: источник совпадает с style bible; нет «лишнего солнца».
5. Края: нет следов фона-ключа, ореола, лишних пикселей.
6. Симметрия там, где нужна (яйцо, кнопка).
7. Нет watermark/подписи, нет узнаваемых персонажей и логотипов.
8. Стиль и толщина линии совпадают с master reference (положить рядом).
9. Нет крупных планов кожи и жестокости (модерация, [packaging](packaging.md) §14.1).

### 7.4 IP и копирование

1. В промптах **нет** названий франшиз, персонажей, брендов, имён художников, мем-героев с активным правообладателем (Spyder Games против клонов «Steal a Brainrot», [packaging](packaging.md) §14.2). Описывать форму и характер словами («cute round blue monster»), не именем.
2. Не загружать чужие thumbnails/иконки как референс для «сделай такое же». Референс — только свои материалы (скриншоты своей игры, master reference). Идея «в духе жанра» допустима, копия композиции и арта конкретной игры — нет.
3. Права на результат: по условиям сервисов права на выдачу передаются пользователю (вторичный источник; **читать текущие Terms**), но **юридически чистой исключительности нет**: по позиции Бюро авторских прав США результаты без достаточного человеческого участия не защищаются авторским правом, а похожие картинки могут получить другие пользователи (вторичный источник, не юридическая консультация). Следствие для решений: уникальность бренда игры (логотип, талисман, основной герой) делать с художником или с существенной ручной доработкой.
4. Free-tier Gemini по умолчанию использует диалоги для обучения: **не загружать** в него неопубликованные материалы, которые нельзя раскрывать, и персональные данные.
5. Все AI-картинки несут скрытые метки (SynthID у Google; C2PA у обоих): не удалять и не обходить, не выдавать за ручную работу, если об этом спрашивают.

### 7.5 Типичные ошибки и обход (без «хаков»)

| Ошибка | Признак | Исправление |
|---|---|---|
| Дрейф стиля | к 5-й иконке другая толщина линии | Новый чат + master reference + 2 последние иконки; STYLE слово в слово |
| «Шахматка» вместо альфы | `A.extrema == (255,255)` | Chroma key (§5.1) |
| Розовая кайма | Кромка после вырезания | Despill, другой цвет фона (`#00FF00`) |
| Мелкие детали исчезают на 64 px | Контактный лист | Упростить промпт: «chunky, fewer details» |
| Золото «грязное» | Перекраска сложной текстуры | Градиентная карта по яркости, регенерация с референсом базового |
| Текст в иконке искажён | Побуквенная проверка | Убрать текст из арта; добавить `TextLabel` |
| Thumbnail «красивее игры» | Сравнение со скриншотом | Привязать референсы к реальным скриншотам; урезать рендер |
| Дубли/плагиат | Reverse image search по ключевому кадру (по желанию) | Переделать с описанием формы |

### 7.6 Лог промптов

Файл `art/prompt-log.jsonl`, одна строка на принятый ассет:

```json
{"id":"2026-10-27-0012","asset":"Pet_Dragon_Common_256","date":"2026-10-27","service":"gemini-app","model":"nano-banana-2.1 (as shown in UI)",
 "mode":"new chat","refs":["art/refs/master_icon.png"],"prompt":"…full text incl. STYLE…","edits":["thicker outline"],
 "chosen":"gen03","raw":"art/raw/Pet_Dragon_Common__gen03.png","sha256":"ab12…","post":["key_out magenta","trim_pad 256"]}
```

Зачем: воспроизвести стиль, когда модель обновится; доказать происхождение при споре об IP; повторить успешный промпт.

Источники: create.roblox.com/docs/generative-AI; create.roblox.com/docs/production/publishing/ip-guidelines; [packaging](packaging.md) §13-14; terms.law/ai-output-rights/comparison (вторичный).

---

## 8. Чек-лист

**До старта серии**
1. `art/style-bible.md` заполнен (hex из UI-кита, линия, свет, угол, фон-ключ).
2. Утверждён master reference; пользователь залогинен в нужном сервисе; загружен скилл `chrome-browser` (или `built-in-browser`).
3. Известны сегодняшние лимиты (баннер в аккаунте); определён размер партии.

**Во время**
4. Новый чат на серию; референс загружен первым; STYLE вставлен целиком.
5. Каждая картинка проходит §7.3; принятая скачана оригиналом, переименована, залогирована.
6. Лимит достигнут: остановка, запись в лог, сообщение пользователю.

**После**
7. Вырезание фона, альфа проверена кодом, трим, паддинг, размеры по §5.3.
8. Контактный лист (48/64/150 px, тёмный/светлый фон) показан пользователю.
9. Game icon проверен на 150 px; thumbnail — на ~400 px ширины, нижняя полоса пустая, <3 МБ.
10. Манифест и prompt-log обновлены; загрузка заранее, модерация проверена; один ассет проверен в Studio перед пакетом.
11. Нет чужого IP, нет обещаний/промо на thumbnail, арт не лучше игры.

---

## 9. Что не проверено

1. **Живое поведение интерфейсов** (кнопки, размеры выдачи, соотношения сторон, чат-прозрачность ChatGPT, наличие селектора модели в Gemini app): сведения из документации и новостей, интерфейсы не открывались. Первый прогон делать на тестовой серии из 2-3 картинок.
2. **Какая модель отвечает в приложении Gemini** после 06.10.2026 (2.1 против 2 против «Lite» у free) и бесплатный доступ AI Studio к генерации картинок: источники расходятся или умалчивают. Для API-пути (если пользователь решит) сначала смотреть страницу цен.
3. **Лимиты бесплатных тарифов** обоих сервисов: официальных чисел нет.
4. **Дата снятия `gemini-3.1-flash-image`:** один источник даёт 29.10.2026, другой «дата не объявлена»; для браузерного пути не критично.
5. **Прозрачность `gpt-image-2` отключена 30.09.2026:** утверждает сторонний документ, у OpenAI не подтверждено.
6. **Права на результат и free-tier условия:** читались вторичные сводки, не сами Terms of Use.
7. **Метка «AI-generated» для загружаемых создателем картинок в Roblox:** требований не найдено; повторно проверить Community Standards/Creator Terms.
8. **Эффективный потолок 1024 px у UI-картинок** — наследуется из [ui-figma-workflow](ui-figma-workflow.md) §7.2 (оценка).
9. **Скрипты §5** запускались только на синтетических данных (Pillow 12.3, numpy 2.5): нарезка, вырезание ключа, кроп 16:9, перекраска и симметризация отрабатывают без ошибок; качество на реальных AI-иконках не проверялось.

## Проверено на практике: Pet Legends (26.10.2026)

Пример полного прогона — 37 ассетов для UI-пака (логотип, фон загрузки, 7 питомцев, 3 яйца, 16 UI-иконок, 9 иконок магазина) за один заход, ~10 минут работы агента в Chrome пользователя.

- **Браузер:** использовать Chrome пользователя (Claude in Chrome), где он уже вошёл в Gemini и ChatGPT. Встроенный браузер Claude имеет отдельный профиль и обычно не залогинен. Если в Gemini несколько Google-аккаунтов — переключиться через меню аккаунта на нужный, не входить заново.
- **Листы-сетки работают:** 4×4, 3×3, 4×2, 3×1 в одном изображении — стиль на листе получается единым, а генераций в 5–10 раз меньше. Gemini иногда «сжимает» сетку в верхние 2/3 квадрата (так было с питомцами 4×2) — нарезать по фактической области.
- **Что у кого получилось:** Gemini (Nano Banana) — питомцы, яйца, иконки магазина; ChatGPT — 4×4 лист UI-иконок (Gemini дважды зависал на нём), логотип с текстом, фон. Логотип ChatGPT сделал в две строки вместо одной — для иконки игры это даже лучше.
- **Пурпурный фон `#FF00FF` + вырезание** — надёжно, НО только заливкой от краёв изображения. Глобальный цветовой ключ съедает розовые/фиолетовые объекты (гем, мифическое яйцо, кучу гемов). Готовый скрипт: `scripts/slice_sheet.py` (заливка от краёв, удаление «осколков» соседей в ячейке, вывод 512×512 с прозрачностью).
- **Вариации без новых генераций:** Golden / Rainbow / «не открыт» (силуэт) — фильтрами из базовой картинки (в Roblox — `ImageColor3`, `UIGradient`, отдельная тёмная копия), а не новыми запросами.
- **Gemini отдаёт JPEG** (лёгкие артефакты по краю после вырезания), ChatGPT — PNG. Для финальных иконок предпочтительнее PNG-источник.
- **Ввод текста в Gemini** надёжно работает после клика по полю через ссылку элемента (find → ref), а не по координатам. Если запрос «завис» без надписи «Creating your image» — перезагрузить и отправить снова.
