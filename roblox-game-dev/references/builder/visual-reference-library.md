# Внешняя библиотека визуальных референсов (izzyfrm/roblox-ai): что внутри, чем можно пользоваться, как брать по запросу

**Назначение.** Скилл не хранит чужие картинки. Вместо этого он знает, что лежит во внешней библиотеке `izzyfrm/roblox-ai`, в какой папке искать эталон под какой шаг конвейера и как скачать **только нужную папку** (десятки файлов, а не 1.3 ГБ). Референсы дают AI-генератору и человеку конкретное визуальное направление вместо «сделай красиво». Этот файл — карта и правила; сами картинки в скилл, в репозиторий игры и в Roblox не копируются.

**Актуально на: 28.10.2026 (клон просмотрен целиком по структуре и README, 10 картинок открыты глазами).** Перепроверять: (1) библиотека сторонняя, одиночного мейнтейнера, папки могут переименоваться или исчезнуть, а счётчики в её README это «каталожные цифры, не живая инвентаризация»; (2) отсутствие общей лицензии репозитория; (3) доступность `raw.githubusercontent.com` из вашей среды (в песочнице Claude Code он был закрыт прокси, а `git clone` с github.com работал).

## Оглавление
1. Что это за библиотека (по факту, а не по README)
2. Правила лицензий (жёсткие)
3. Полный индекс: папка → подпапки → кто из справочников использует
4. Жанры: game-refs → `advisor/genres/` и семейства A–I
5. Как брать по запросу: скрипт, sparse checkout, raw URL
6. Шаблон промпта для AI-генераторов с референсом
7. Рабочие рецепты по шагам конвейера
8. Чек-лист и оговорки

---

## 1. Что это за библиотека

Репозиторий https://github.com/izzyfrm/roblox-ai: «Visual Reference Library», независимый (не Roblox), около 5.9 тыс. картинок (по README 5 885) плюс 5 коротких mp4-клипов; на диске с историей git около 1.3 ГБ. Текста почти нет: у каждой папки README — это список картинок, в game-refs ещё название игры, автор и ссылка на страницу в Roblox. Общей лицензии репозитория нет, у групп файлов разный правовой статус (раздел 2).

Что **на самом деле** лежит в папках (проверено открытием файлов):

| Папка | Фактически | Как читать |
|---|---|---|
| `ui-styles/` | рекламные превью **чужих платных/бесплатных UI-паков** с сайтов-каталогов: «Cute Cartoony UI Pack V5» (инвентарь, достижения, win/lose), «+260 Icons» (магазин, логин, полоски HP), «Grow a UI Pack by uxbyadrian» (окно Codes), скриншоты Roblox-магазина с градиентными карточками. Это витрины продуктов третьих лиц, не лицензионные ассеты | образец раскладки, цвета, формы, иерархии; **не** исходник для воспроизведения конкретного пака |
| `game-refs/` | публичные thumbnails 16:9 реальных игр (331 игра, 602 картинки), например ночной кадр хоррора с машиной и воротами и логотипом поверх. Рядом имя игры, автор, ссылка | как жанр «выглядит на витрине»: композиция, свет, где логотип, насыщенность |
| `style-refs/` | 25 стилей; **оригинальные** мокапы авторов библиотеки (9 экранов на стиль: HUD, shop, palette, settings, inventory, loading, reward, leaderboard, dialogue; шрифт Kenney Future) + листы-превью **Kenney CC0** (UI-паки, курсоры, эмоуты, спорт) | единственная папка, которую можно брать как стилевой якорь для генератора без оговорок (см. §2) |
| `vfx/`, `animations/`, `cutscenes/`, `sfx/` | промо-картинки и гифки сторонних эффектов (Brackeys «FREE VFX» для Unity, pixel-VFX, спрайт-листы, скриншоты редакторов звука), **не** готовые текстуры Roblox и не аудио | куда смотреть и какой эффект имеется в виду; текстуры и звук берите из Creator Store или генерируйте |
| `visual-refs/` | иконки (32), спортивные UI (6), **studs-ui (377 файлов) в стиле классического Roblox**, 5 mp4 с анимационными референсами (бой, баскетбол, катсцена) | stud-стиль и иконки; mp4 — тайминги боя и катсцен |
| `previews/` | 61 тег по ~12 обложек (UI-стили, VFX, SFX, музыка, анимации, катсцены) | быстрый «обзор по тегу»; перекрывается с `ui-styles/` |
| `roblox-docs/` | 3 730 скриншотов официальной документации Roblox (CC BY 4.0), 29 тем | только когда нужна иллюстрация к конкретному окну Studio; текст докс надёжнее |
| `logos/`, `thumbnails/` | по 8 файлов: Adopt Me, Blox Fruits, Brookhaven, DOORS, Dress to Impress, Fisch, Murder Mystery 2, RIVALS | узнаваемость и композиция **топов**; копировать нельзя вдвойне |
| корень | `Day1-Day100.webp` (небольшой лист «дней») и README | не нужен |

Размеры на диске: roblox-docs ≈ 408 МБ, visual-refs ≈ 119 МБ, game-refs ≈ 49 МБ, previews ≈ 27 МБ, ui-styles ≈ 23 МБ, style-refs ≈ 16 МБ, vfx ≈ 9 МБ, остальное по 2–3 МБ.

---

## 2. Правила лицензий (жёсткие)

| Группа | Статус | Что можно | Что нельзя |
|---|---|---|---|
| `game-refs/`, `thumbnails/`, `logos/` | права у создателей игр, лицензии на повторное использование нет; названия и Roblox — торговые марки | смотреть, брать **идею композиции, жанровые коды, палитру, расстановку** | перезаливать в Roblox/магазин/соцсети, обводить и трейсить, вставлять как образ-референс с просьбой «сделай так же», копировать логотип, персонажа, шрифт-логотип, узнаваемую сцену; использовать чужое название |
| `ui-styles/`, `previews/`, `vfx/`, `animations/`, `cutscenes/`, `sfx/`, `visual-refs/` | «принадлежат авторам, проверьте лицензию» (README библиотеки); внутри — витрины чужих паков и игр | вдохновляться раскладкой, формой кнопок, иерархией, ритмом; уточнять лицензию у первоисточника и **покупать/скачивать пак там**, если нужен именно он | выдавать картинку за свой ассет, нарезать иконки из превью, использовать превью как текстуру, брать из них шрифт или значки |
| `style-refs/` (мокапы) | оригинальные работы авторов библиотеки, шрифт Kenney Future CC0; общей лицензии нет, права явно не оговорены | как стилевой якорь для генератора (раздел 6), как образец сетки экранов | редистрибуция в составе платного продукта без отдельного разрешения автора библиотеки |
| `style-refs/` (листы `sheet-*`, `*-preview`, `*-sample`) | Kenney, **CC0 1.0**: можно всё, в том числе коммерчески, без указания авторства (указать всё равно вежливо) | использовать как ассеты или якоря; для ассетов лучше скачать оригинальный пак на kenney.nl | не считать CC0 любые другие файлы той же папки |
| `roblox-docs/` | © Roblox, **CC BY 4.0**: нужны указание автора, ссылка на лицензию и пометка об изменениях | брать иллюстрацию с атрибуцией: «© Roblox Corporation, github.com/Roblox/creator-docs, CC BY 4.0» | убирать атрибуцию; выдавать за свои; считать скриншот правилом: **правило берите из текстовой документации** (create.roblox.com/docs), скриншот может быть старым |

Дополнительно:
- **Изображения не отправлять в генератор как «сделай копию».** Референс отвечает на вопрос «какой уровень плотности, какой тип формы, какая иерархия», а не «нарисуй это».
- **Не складывать скачанные референсы в репозиторий игры и в скилл** (`refs/` держать в `.gitignore`).
- Стиль, который проверяют на модерации Roblox (иконка, thumbnail, UI), должен быть своим: похожесть на топ-игру — риск IP и алгоритмического «клона» (`builder/packaging.md` §14, `builder/compliance.md`).
- Если заказчик хочет выпускать результат как продукт: для каждого референса записать источник и статус в `art/refs-log.md` (имя файла, путь в библиотеке, что взято: «палитра», «раскладка»).

---

## 3. Полный индекс: папка → подпапки → где используется

Счётчики = число картинок (без README) на 28.10.2026.

| Папка (файлов) | Подпапки (число) | Кто использует в скилле |
|---|---|---|
| `ui-styles/` (69) | 30 стилевых наборов, у каждого 1–4 картинки: `08-stud-wood-metal` 2, `09-modern-cartoon-simulator` 2, `10-chunky-candy-buttons` 2, `11-glossy-bubble` 2, `13-pet-collector-grid` 1, `16-garden-farm-cozy` 3, `22-modern-medieval` 3, `23-parchment-scroll` 3, `31-neon-cyberpunk` 3, `32-holographic-hud` 3, `40-futuristic-racing` 3, `41-glassmorphism` 3, `42-flat-material` 2, `43-dark-mode-pro` 4, `44-ios-soft` 2, `52-gothic-horror` 4, `53-vhs-found-footage` 2, `55-minimal-survival-hud` 3, `57-pixel-art-retro` 2, `58-8-bit-arcade` 2, `59-16-bit-jrpg-box` 3, `66-fighting-game` 3, `68-racing-dashboard` 3, `73-steampunk-brass` 3, `74-kawaii-pastel` 1, `85-cosmic-cartoon-space` 1, `90-anime-fighter-menu` 1; функциональные: `103-settings-menu` 1, `108-damage-numbers` 1, `111-codes-redeem-box` 1 | `ui-canon.md` §4 (диалекты жанров: проверить, какой диалект выбираете), `ui-figma-workflow.md` §11 (UI-art brief: «стиль» и «референсы»), `ui-implementation.md` (какую тему `Theme.luau` собирать), `ai-art-generation.md` §3 (подбор якоря) |
| `style-refs/` (293) | 25 стилей: `anime` 9, `candy` 9, `cartoon` 32, `cyberpunk` 9, `dark-pro` 9, `fantasy` 17, `glass` 9, `horror` 20, `input-prompts` 3, `kawaii` 9, `medieval` 9, `pirate` 9, `pixel` 8, `retro-pixel` 9, `sci-fi` 8, `simulator` 17, `space` 9, `speed` 24, `sports` 20, `studs` 9, `survival` 9, `tower-defense` 9, `tycoon` 9, `western` 9, `winter` 9 | `ai-art-generation.md` §3–§4 (style bible, master reference), `ui-figma-workflow.md` (набор экранов-сетка: HUD/shop/inventory/…), `3d-asset-canon.md` §2 (семейства), `ui-implementation.md` (проверка полноты экранов); безопасно как якорь (§2) |
| `game-refs/` (602) | 15 жанровых папок (раздел 4) | `packaging.md` §2–§3 и §14 (иконка и thumbnails: что у жанра на витрине), `advisor/genres/00_index.md`, `advisor/genres/NN_*.md` (референсы), `level-design.md` §7 (стили карт), `visual-audit.md` (сравнение с жанровым ожиданием) |
| `thumbnails/` (8), `logos/` (8) | плоские файлы: adopt-me, blox-fruits, brookhaven-rp, doors, dress-to-impress, fisch, murder-mystery-2, rivals | `packaging.md` §3 (композиция thumbnail), §2 (читаемость иконки в 128 px); только анализ |
| `vfx/` (28) | 18 эффектов: `01-hit-spark`, `02-slash-arc-trail`, `04-speed-lines-dash`, `05-anime-impact-frame`, `09-magic-circle-cast`, `10-heal-aura`, `13-water-splash`, `14-fireball-explosion`, `15-black-hole-vortex`, `17-teleport-portal`, `19-rain-and-snow`, `21-smoke-puff`, `22-torch-fire`, `26-level-up-burst`, `30-damage-number-pop`, `33-powerup-aura-flames`, `35-particle-texture-library`, `36-cartoon-vfx-spritesheets` | `animation.md` §16 (бой, числа урона, hit freeze), §13 и §15 (вылупление, награды); `3d-asset-canon.md` §13 (VFX как часть ассета) |
| `animations/` (13) | 9 паттернов: `01-button-hover-scale`, `11-tab-switch`, `16-idle-breathing`, `17-run-cycle-lean`, `19-punch-combo`, `20-sword-swing-combo`, `27-cast-spell`, `29-dash-and-slide`, `33-2d-sprite-reference-sets` | `animation.md` §9 (какие анимации нужны жанру), §10 (UI-моушн кодом), §14 (кнопки, вкладки) |
| `cutscenes/` (4) | `05-over-the-shoulder-dialogue` 1, `10-impact-hit-stop` 1, `17-visual-novel-dialogue-scene` 2 | `animation.md` §16 (hit-stop), раздел про диалоги и катсцены; `art-ui-audio.md` (диалоговое окно) |
| `sfx/` (10) | `01-button-click` 3, `14-sword-swing-whoosh` 3, `15-sword-hit-metal` 2, `27-spell-cast-charge` 2 | `3d-audio-pipeline.md` §18 (канон звука по событиям), §16 (источники): это скриншоты, **звука тут нет** |
| `visual-refs/` (413 + 5 mp4) | `studs-ui` 377, `icons` 31, `sports` 5, `animation-refs` 5 mp4 (Tough-Animation, Basketball-Ref, Fighting-Ref-2, CutScene, Battle-Animation) | `ui-canon.md` (stud-диалект), `ai-art-generation.md` (иконки как ориентир контура), `animation.md` §16 (клипы боя) |
| `previews/` (707) | 61 тег по ~12 картинок: `*-user-interface` (cyberpunk, dark, fantasy, glass, gothic, horror, medieval, neon, pixel-art, racing, retro, tower-defense, tycoon, western, wood, …), `vfx-*` (confetti, fire, hit, magic, water, weather), `sound-effects-*` (ui, swords, weapons, whoosh, …), `animation*`, `cinematic`, `cutscene`, `loading`, `intro`, `music`, `sprite-sheet-*` | быстрый обзор тега до выбора точной папки; те же ограничения, что у `ui-styles/` |
| `roblox-docs/` (3 730) | 29 тем: `studio` 441, `tutorials` 669, `education` 452, `modeling` 312, `resources` 212, `ui` 206, `engine-api` 133, `art` 120, `feeds` 118, `avatar` 114, `analytics` 111, `lighting-and-effects` 101, `publishing` 95, `animation` 83, `accessories` 67, `developer-modules` 65, `monetization` 51, `makeup` 61, `game-design` 39, `optimization` 37, `localization` 34, `avatar-anatomy` 32, `developer-jumpstart` 31, `promotion` 31, `physics` 27, `creator-dashboard` 26, `players` 24, `landing` 21, `getting-started` 17 | `studio-config.md`, `mcp-studio.md`, `ui-implementation.md`, `animation.md` §3: **сначала текст документации**; скриншоты — когда нужно показать человеку, где кнопка |

---

## 4. Жанры: `game-refs/` → жанровые главы → семейства A–I

Семейства — единый словарь из `3d-asset-canon.md` §2.1: A кубо-chibi, B воксель/studs, C гладкая игрушка, D тёмный PBR, E тематическая плитка/obby, F милый хоррор/плюш, G аниме, H greybox-соревновательный, I реалистичный. Соответствие ориентировочное (папки библиотеки названы по теме, а не по таксономии Roblox); перед решением сверяйтесь с таблицей §2.3 в `3d-asset-canon.md`.

| `game-refs/` (картинок) | Главы `advisor/genres/` | Семейства (основные → возможные) | Что искать в референсах |
|---|---|---|---|
| `simulator` (23) | `01_simulation.md`, `07_party_casual.md` | A, C → B | «+1»-билборды, валюта в верхней плашке, зона-хаб, эскалация редкостей на thumbnail |
| `cartoon` (36) | `01_simulation.md`, `07_party_casual.md`, `10_roleplay_avatar_sim.md` | A, C | плотные яркие композиции, крупный персонаж-лицо, плоская заливка |
| `candy-sweet` (25) | `06_obby_platformer.md`, `07_party_casual.md`, `01_simulation.md` | E, A | тематические плиты, градиентное небо, пастельно-кислотная палитра |
| `studs-obby` (53) | `06_obby_platformer.md`, `01_simulation.md` | B, E | baseplate и studs на витрине, «коробочный» аватар, светлые небеса |
| `roleplay-town` (44) | `10_roleplay_avatar_sim.md`, `16_social.md`, `15_shopping.md` | C, I | вид сверху на город, много аватаров, персонализация на кадре |
| `horror` (70) | `02_survival.md` (1 vs All, побег), `05_adventure.md` | D, F | свет и тьма, один источник света, монстр у края кадра, зерно, логотип сверху; держим «Mild» (`compliance.md`) |
| `survival` (46) | `02_survival.md`, `09_rpg.md` (open world и survival RPG) | D, B | природа или руины, инвентарь/крафт-намёки, тёплый свет у костра |
| `anime-fighting` (51) | `04_action.md` (battlegrounds), `09_rpg.md` (Action RPG), `03_strategy.md` (аниме TD) | G (→ D, H) | радиальные лучи, кольца призыва, герой крупным планом, насыщенный контраст |
| `fantasy-rpg` (63) | `09_rpg.md`, `05_adventure.md` | C, G, D | замки и драконы, градиент неба, герой + босс, золотые детали |
| `sci-fi-space` (56) | `11_shooter.md`, `05_adventure.md`, `01_simulation.md` | H, D, I | неон по кромке, силуэты техники, космос в тёмных тонах |
| `pirate-ocean` (37) | `05_adventure.md`, `01_simulation.md` (рыбалка, корабль), `09_rpg.md` | C, I | вода и закат, корабль, цвет моря как якорь палитры |
| `tower-defense` (15) | `03_strategy.md` (Tower Defense) | G, B, D | поле с трассой, юниты крупным планом, UI-плашки волн |
| `speed-racing` (17) | `12_sports_racing.md` (Racing), `06_obby_platformer.md` (Runner) | I, H | динамичный ракурс машины, линии скорости, спидометр |
| `sports` (41) | `12_sports_racing.md` (Sports) | C, G | поза игрока, табло и ленты команд, цвет команд |
| `winter-holiday` (25) | любой жанр: сезонный слой | любое | сезонная замена thumbnail и иконки: `packaging.md` §12, события: `liveops.md` |

Для классов 3D-ассетов (питомцы, яйца, оружие, окружение) таблица жанр→семейство и правило выбора лежат в `3d-asset-canon.md` §2.3; здесь нужен только выбор **папки референсов** под выбранное семейство.

---

## 5. Как брать по запросу

### 5.1 Скрипт (основной путь)

```bash
# из корня скилла; dest по умолчанию ./refs/<путь с / -> _>
scripts/fetch_refs.sh ui-styles/13-pet-collector-grid
scripts/fetch_refs.sh game-refs/horror /tmp/horror_refs
scripts/fetch_refs.sh style-refs/candy ./refs/candy
```
Скрипт: `git clone --depth 1 --filter=blob:none --sparse` + `sparse-checkout set <путь>`; на диск попадает только выбранная папка, README корня и мелкие файлы корня; повторный вызов в тот же каталог **добавляет** папку. Проверено 28.10.2026: `ui-styles/13-pet-collector-grid` занял около 2 МБ вместе с метаданными git. Работа идёт через обычный `git`, ничего не нужно настраивать (в облачной песочнице работает через общий прокси).

### 5.2 Ручной sparse checkout
```bash
git clone --depth 1 --filter=blob:none --sparse https://github.com/izzyfrm/roblox-ai.git refs && cd refs
git sparse-checkout set game-refs/horror style-refs/horror ui-styles/52-gothic-horror
```

### 5.3 Отдельный файл по прямой ссылке
Шаблон: `https://raw.githubusercontent.com/izzyfrm/roblox-ai/main/<путь>`, например `.../main/style-refs/candy/mockup-hud.png`. Имена файлов уточнять в README нужной папки (`https://raw.githubusercontent.com/izzyfrm/roblox-ai/main/game-refs/horror/README.md`). **Оговорка:** в песочнице Claude Code `raw.githubusercontent.com` был закрыт прокси (403), а git с github.com работал; если raw не открывается, используйте 5.1. Через браузер (Claude in Chrome / встроенный) открывается страница `github.com/izzyfrm/roblox-ai/tree/main/<папка>` для просмотра галереи.

### 5.4 Как выбирать, чтобы не качать лишнее
1. Прочитать README верхнего уровня нужной папки (маленький файл) и взять **одну–три** подпапки.
2. Для стилевого якоря хватает 2–4 картинок: мокап HUD, мокап shop, палитра. Остальное не нужно.
3. Смотреть картинки через Read/браузер, не заливать в чат все подряд.
4. После работы каталог `refs/` не коммитить.

---

## 6. Шаблон промпта: «референс как направление, дизайн свой»

Для Nano Banana (Gemini) и ChatGPT Images (процесс в браузере, style bible и master reference: `ai-art-generation.md` §2–§4). Прикрепить 1–3 референса (предпочтительно `style-refs/` мокапы и CC0-листы), затем:

```text
I'm designing UI/art for an original Roblox experience: <GAME NAME, genre, one-line theme>.

Attached are style references. Use them ONLY for these qualities:
- <e.g. layout rhythm: pill currency counters top-left, stacked side buttons>
- <e.g. shape language: very round corners, thick outlines, bottom-heavy shadows>
- <e.g. density and hierarchy: one dominant call-to-action per screen>
Do NOT reproduce: logos, characters, mascots, lettering, icons, copyrighted
artwork, or any recognisable scene from the references.

Our palette (hex): <primary, secondary, accent, bg, text outline>.
Our own motifs: <3-5 original motifs, e.g. mushroom lanterns, jelly pets>.
Output: <what exactly: one 4x4 icon sheet / one shop screen 1920x1080 / game icon 512x512>,
flat <#FF00FF> background for cut-out, no text unless specified, readable at 64 px.
Create an ORIGINAL design that fits this game. Then list in 3 lines which
reference qualities you applied and which you deliberately changed.
```

Правила: (1) референс называем «стиль-направление», не «копия»; (2) в промпте всегда явный список «не копировать»; (3) результат сверяем с источником: если узнаётся логотип, персонаж или раскладка один в один, перегенерировать с другим якорем; (4) для thumbnails/логотипов из `game-refs/`, `thumbnails/`, `logos/` в генератор **ничего не прикладываем**, а пересказываем словами (композиция, свет, ракурс), см. §2.

---

## 7. Рабочие рецепты по шагам конвейера

| Шаг | Что взять из библиотеки | Как использовать |
|---|---|---|
| Этап 1 (GDD), стиль | `game-refs/<жанр>` + раздел 4 | выбрать семейство A–I; записать в GDD 3 слова про палитру и свет, без вложения картинок |
| Этап 5, UI | `ui-styles/<набор>`, `style-refs/<стиль>` (9 экранов-сетка) | диалект по `ui-canon.md` §4; в UI-art brief (`ui-figma-workflow.md` §11) указать стиль и 2–3 якоря; список экранов сверить с 9 мокапами; функциональные элементы (закрыть, покупка, ребёрс) всё равно по канону, не по референсу |
| Этап 5, иконки/питомцы | `style-refs/<стиль>`, `visual-refs/icons` | master reference для генератора (§6), нарезка и альфа по `ai-art-generation.md` §5 |
| Этап 5, анимации и VFX | `animations/`, `vfx/`, `visual-refs/animation-refs/*.mp4` | понять *какой* эффект имеется в виду; тайминги брать из `animation.md` §13–§16; текстуры частиц — из Creator Store или сгенерировать свои |
| Этап 5, звук | `sfx/` | только как напоминание о типах; источники и лицензии: `3d-audio-pipeline.md` §16–§17 |
| Этап 8, упаковка | `game-refs/<жанр>`, `thumbnails/`, `logos/` | 10–20 thumbnails жанра на одну доску сравнения: что общего у всех (жанровые коды), что можно сделать иначе (ваша ось); размеры и правила: `packaging.md` §2–§3 |
| Аудит (режим A) | `game-refs/<жанр>` | сравнить витрину игры с жанровым ожиданием (`visual-audit.md`) |
| Нужна иллюстрация к Studio | `roblox-docs/<тема>` | показать человеку, где кнопка; указать атрибуцию CC BY 4.0 |

---

## 8. Чек-лист и оговорки

- [ ] Взято минимум папок (по скрипту), `refs/` в `.gitignore`, ничего не скопировано в скилл или в игру.
- [ ] Для каждой использованной картинки понятен статус (§2); для `game-refs/thumbnails/logos` в генератор не прикладывалось ничего.
- [ ] В промпте явно сказано, что брать (раскладка, форма, плотность) и что нет (логотипы, персонажи, шрифт, сцена).
- [ ] Результат не узнаётся как копия конкретной игры или пака; иконка и thumbnail проходят `packaging.md` §14.
- [ ] Функциональный UI сверён с `ui-canon.md`, а не только с референсом.
- [ ] Где лицензия нужна (Kenney CC0, roblox-docs CC BY), атрибуция записана в `art/refs-log.md`.

**Оговорки.** (1) Библиотека сторонняя и может измениться; фиксируйте в `refs-log.md` коммит (`git -C refs rev-parse HEAD`), с которого брали. (2) Папка `ui-styles/` небольшая (69 картинок на 30 стилей) и показывает витрины паков, а не готовые экраны игр; под экономику и поведение игрока она ничего не говорит. (3) `game-refs/` кодирует то, что вышло на витрину, а не то, что работает по метрикам (ошибка выжившего); решение по жанру принимается по `advisor/`, а не по красоте thumbnail. (4) Папки `vfx/`, `animations/`, `sfx/` малы (1–4 файла на тему) и состоят из чужой рекламы; не заменяют Animation Editor, Creator Store и реальные звуки. (5) Если вы публикуете результат за пределами Roblox (сайт, видео), атрибуция и права на референсы не меняются.
