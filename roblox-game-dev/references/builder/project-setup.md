# Проект с нуля: тулчейн, Rojo/Wally/Rokit, CI/CD и автоматизация через Open Cloud

**Назначение.** Файл говорит Builder-роли, как поднять файловый Roblox-проект, который агент может собирать, проверять и публиковать без Studio: какие инструменты и версии, какие точные конфиги, какие команды, что Rojo не умеет, что делается через Open Cloud (с curl-примерами, scopes, лимитами), что остаётся людям, как устроен CI/CD и какие квоты не дадут сломать пайплайн. Готовый проект-шаблон лежит в `assets/template/` (копировать целиком), CI-набор и скрипты — в `assets/automation/`. Код и архитектура — в `builder/code-architecture.md`, работа внутри Studio — в `builder/mcp-studio.md`.

**Актуально на:** октябрь 2026 (версии — git-теги на 26.10.2026; Open Cloud — OpenAPI-спецификация creator-docs от 24.10.2026).
**Перепроверять:**
- версии инструментов (Rojo 7.7.1, Rokit 1.2.0, Wally 0.3.2/0.4-alpha, Selene 0.32.0, StyLua 2.6.0, luau-lsp 1.70.1, Lune 0.11.1, Jest Roblox 3.20.1);
- статусы стабильности эндпоинтов (Place publish, Passes/Products, Configs — BETA; Experiments, Badges, иконки/thumbnails — EXPERIMENTAL): они меняются без анонса;
- Script Sync (beta или GA), перечень classes, которые Place Publishing API не обновляет;
- поведение `activate` и «gameId = universeId» у legacy-эндпоинтов иконки/thumbnails (выведено, не проверено);
- квоты аудио (2 000/100 за 30 дней), лимиты Luau Execution (5 создания/мин, 10 незавершённых на place);
- доступность создания universe/place через API (в спецификации октября 2026 такого эндпоинта нет).

Ни один артефакт этого файла (YAML, curl, скрипты) не запускался против живой вселенной — их синтаксис проверен, поведение нет. Первый прогон делайте на тестовой вселенной.

## Содержание
0. [Главные правила (TL;DR)](#0)
1. [Тулчейн и версии](#1)
2. [Точные конфиг-файлы](#2)
3. [Команды: bootstrap, сборка, анализ, syncback](#3)
4. [Что Rojo не умеет и как это обойти](#4)
5. [Open Cloud: ключ, scopes, что автоматизируется](#5)
6. [Публикация плейса и настройки experience](#6)
7. [Game passes, products, badges, иконка, thumbnails (curl)](#7)
8. [Assets API, Asphalt, модерация, квоты](#8)
9. [Luau Execution: облачные тесты и headless-генерация](#9)
10. [Live-ops API: Configs, Experiments, Messaging, рестарты, уведомления](#10)
11. [Analytics Query и Benchmarks API](#11)
12. [DataStore через Open Cloud и общие бюджеты](#12)
13. [Что обязан сделать человек](#13)
14. [CI/CD: пайплайн, секреты, human gate](#14)
15. [Таблица лимитов и квот](#15)
16. [Конфликты источников и открытые вопросы](#16)

<a id="0"></a>
## 0. Главные правила (TL;DR)

1. **Файловый проект по умолчанию.** Полностью управляемый Rojo-проект — единственный вариант, который поддерживает `rojo build` без Studio и публикацию через Open Cloud. Script Sync (встроенный в Studio) годится как дополнение, когда Studio открыт и «источник правды» — облачный плейс.
2. **Версии пинуем в `rokit.toml`**, ставим `rokit install`; никаких глобальных установок. Агент не угадывает версии, а берёт из таблицы §1 и проверяет `rokit update --dry`/теги перед обновлением.
3. **Два universe: PROD и TEST.** Тесты и CI-публикации «Saved» идут в TEST; Luau Execution делает реальные вызовы DataStore, поэтому тест в продовой вселенной рискует боевыми данными.
4. **Создать universe/place через API нельзя** (на окт. 2026). Человек один раз делает File → Publish и копирует Universe ID и Place ID. Всё остальное, что в §5–§11 помечено API, агент делает сам.
5. **Не использовать cookie-эндпоинты** (`.ROBLOSECURITY`): хрупко и опасно. Жанр, friends-only, avatar-настройки, аудитории, возрастные/региональные ограничения — это человеческие шаги в Dashboard.
6. **Ключ API — секрет.** Только `secrets` в CI, scopes минимальные, ключ ограничен двумя вселенными, не IP-ограничивать, если ключ используют серверы Roblox; ключ умирает через 60 дней неиспользования — держите еженедельный плановый job.
7. **Place Publishing API не обновляет** `EditableImage`, `EditableMesh`, `PartOperation` (unions), `SurfaceAppearance`, `BaseWrap`. Если карта их содержит и они менялись — публикация из Studio.
8. **Одна пачка тестов — одна Luau Execution задача.** Создание задач ограничено 5/мин на владельца ключа; «2 на universe» из старого CI-демо устарело, сейчас 10 незавершённых задач на place.
9. **Анкета возрастного рейтинга (Content maturity) — только UI.** Любое изменение ответов после обновления контента требует пересдачи; CI должен блокировать автопубликацию, если аудит кода изменил предполагаемые ответы (§13).
10. **Первый прогон всего пайплайна — на тестовой вселенной вручную.** Все артефакты здесь «проверены по синтаксису», но не запускались живьём.

<a id="1"></a>
## 1. Тулчейн и версии

| Инструмент | Роль | Версия (26.10.2026) | Статус |
|---|---|---|---|
| **Rokit** | менеджер версий инструментов (замена Aftman/Foreman, читает их файлы) | v1.2.0 | активен |
| **Rojo** | сборка `.rbxl` из файлов, live-sync в Studio, sourcemap, syncback, upload | v7.7.1 (01.10.2026) | активен |
| **Wally** | пакетный менеджер (реестр UpliftGames/wally-index) | v0.3.2 stable, v0.4.0-alpha.1 | активен; используем 0.3.2 |
| **Selene** | линтер (`std = "roblox"`) | 0.32.0 | активен |
| **StyLua** | форматтер (`syntax = "Luau"`) | v2.6.0 | активен |
| **luau-lsp** | LSP и `analyze` для CI | 1.70.1 | активен |
| **Lune** | Luau-рантайм для скриптов вне Roblox | v0.11.1 | активен |
| **Asphalt** | загрузка ассетов, генерация модуля с ID | v2.0.2 | опционален |
| **rbxcloud** | CLI для Open Cloud | v0.17.0 | опционален (мы используем `scripts/rbx.py`) |
| **setup-rokit** | GitHub Action установки Rokit | v0.2.1 (`CompeyDev/setup-rokit`) | для CI |
| **Jest Roblox** (официальный) | тесты | v3.20.1 (30.08.2026), в Wally как `roblox/jest` | активен |
| **pesde** | альтернатива Wally | v0.7.4 | не используем по умолчанию |

Что устарело и не брать: Aftman, Foreman (в официальном демо CI всё ещё Foreman + Rojo 7.4.1 — репозиторий не обновлялся с 09.2024), TestEZ, форк `jsdotlua/jest` (3.10.0, заброшен с 12.2024), open-source `Roblox/studio-rust-mcp-server` (README: «no longer being actively developed», заменён встроенным MCP — см. `mcp-studio.md`).

Установка Rokit: macOS/Linux `curl -sSf https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.sh | bash`; Windows `Invoke-RestMethod https://raw.githubusercontent.com/rojo-rbx/rokit/main/scripts/install.ps1 | Invoke-Expression`. Команды Rokit: `init`, `add`, `install`, `update`, `list`, `authenticate`, `self-update`.

Roblox сам рекомендует эту схему (страница Third-party tools): Rokit → Rojo (+ плагин) → Wally → Selene/StyLua/luau-lsp → Git. Оговорка из документации: эти инструменты Roblox не поддерживает.

**Рекомендуемый стек библиотек (по данным индекса Wally, 26.10.2026; зависимости считаются между пакетами, не играми):** Signal + Trove/Janitor + Promise + `t`; данные — ProfileStore; UI — React Luau либо Fusion 0.3/Vide 0.4; state — Charm; ECS при необходимости — Jecs; тесты — `roblox/jest@3.20.x`. Подробности и статус каждой библиотеки — `code-architecture.md`, §12.

Источники: create.roblox.com/docs/projects/external-tools; github.com/rojo-rbx/rokit; github.com/rojo-rbx/rojo; github.com/UpliftGames/wally; Roblox/place-ci-cd-demo.

<a id="2"></a>
## 2. Точные конфиг-файлы

Полные рабочие версии лежат в `assets/template/` (`default.project.json`, `rokit.toml`, `wally.toml`, `selene.toml`, `stylua.toml`, `.luaurc`, `.styluaignore`, `.gitignore`) и `assets/automation/` (`test.project.json`, `asphalt.toml`, `config/live.json`). Ниже — содержание и пояснения, чтобы агент понимал каждое поле.

### rokit.toml
```toml
[tools]
rojo     = "rojo-rbx/rojo@7.7.1"
wally    = "UpliftGames/wally@0.3.2"
selene   = "Kampfkarren/selene@0.32.0"
stylua   = "JohnnyMorganz/StyLua@2.6.0"
luau-lsp = "JohnnyMorganz/luau-lsp@1.70.1"
lune     = "lune-org/lune@0.11.1"
asphalt  = "jacktabscode/asphalt@2.0.2"   # только если загружаете ассеты через Asphalt
```

### wally.toml
```toml
[package]
name = "yourstudio/mygame"          # scope/name, строго lowercase
version = "0.1.0"
registry = "https://github.com/UpliftGames/wally-index"
realm = "shared"

[dependencies]                      # -> Packages/        (ReplicatedStorage)
[server-dependencies]               # -> ServerPackages/  (ServerScriptService)
ProfileStore = "lm-loleris/profilestore@1.0.3"
[dev-dependencies]                  # -> DevPackages/     (только тестовый плейс)
Jest = "roblox/jest@3.20.1"
JestGlobals = "roblox/jest-globals@3.20.1"
```
Имена папок `Packages` / `ServerPackages` / `DevPackages` — из исходников Wally (`installation.rs`). Секции: `[package]`, `[dependencies]`, `[server-dependencies]`, `[dev-dependencies]`; lock-файл `wally.lock` коммитим. ProfileStore объявлен `realm = "server"`, поэтому он лежит в `server-dependencies`.

### default.project.json (суть)
```json
{
  "name": "MyGame",
  "globIgnorePaths": ["**/*.spec.luau", "**/__tests__/**"],
  "tree": {
    "$className": "DataModel",
    "ReplicatedStorage": { "Shared": {"$path": "src/shared"}, "Packages": {"$path": "Packages"} },
    "ServerScriptService": { "Server": {"$path": "src/server"}, "ServerPackages": {"$path": "ServerPackages"} },
    "StarterPlayer": { "StarterPlayerScripts": { "Client": {"$path": "src/client"} } },
    "Workspace": { "$properties": {"StreamingEnabled": true} },
    "Lighting": { "$properties": {"Technology": "Future"} }
  },
  "syncbackRules": { "ignorePaths": ["Packages/**", "ServerPackages/**"], "syncCurrentCamera": false, "syncUnscriptable": true }
}
```
Поля проекта: `name`, `tree`, `servePort` (по умолчанию 34872), `servePlaceIds`, `placeId`, `gameId`, `serveAddress`, `globIgnorePaths`, `emitLegacyScripts` (по умолчанию true). Ключи узла: `$className`, `$path`, `$properties`, `$ignoreUnknownInstances`. Свойства можно задавать неявно (`"Anchored": true`) или явно (`{"Bool": true}`) — явный формат нужен для свойств, которых Rojo не знает. `$path` на несуществующую папку ломает сборку: в шаблоне `Packages/` и `ServerPackages/` содержат `.gitkeep`.

Если у игры есть бинарный мир, добавьте в `Workspace`: `"Map": {"$path": "world/Map.rbxm"}, "Terrain": {"$path": "world/Terrain.rbxm"}` (см. §4). Если есть Studio-authored GUI: `"StarterGui": {"$path": "src/gui"}`, `"ReplicatedFirst": {"$path": "src/first"}`.

### Соответствие файлов и инстансов (Rojo Sync Details)
`*.server.luau` → Script; `*.client.luau` → LocalScript; `*.luau` → ModuleScript; `init.*` превращает папку в скрипт; `*.rbxm/*.rbxmx` → модель; `*.csv` → LocalizationTable; `*.txt` → StringValue; `*.json`/`*.toml` → ModuleScript с таблицей; `*.model.json` → рукописное дерево инстансов (RemoteEvent, Folder и т.п.); `*.meta.json` → доп. свойства и className. Пример model.json: `{"ClassName":"Folder","Children":[{"Name":"SendMoney","ClassName":"RemoteEvent"}]}`.

### selene.toml
```toml
std = "roblox"
roblox-std-source = "pinned"      # selene generate-roblox-std, коммитим roblox.yml — воспроизводимый CI
exclude = ["Packages/*", "ServerPackages/*", "DevPackages/*"]
```
Документация Selene: файл стандартной библиотеки Roblox обновляется на их стороне каждые 6 часов; `selene update-roblox-std` обновляет локальную копию.

### stylua.toml
```toml
syntax = "Luau"          # избегает конфликта с синтаксисом Lua 5.2 (`::`)
column_width = 120
line_endings = "Unix"
indent_type = "Tabs"
indent_width = 4
quote_style = "AutoPreferDouble"
call_parentheses = "Always"
```
`.styluaignore` (синтаксис gitignore): `Packages/`, `ServerPackages/`, `DevPackages/`. В CI: `stylua --check src`.

### .luaurc
```json
{ "languageMode": "strict", "lint": { "*": true } }
```
Новый конфиг-формат `.config.luau` (Luau-синтаксис вместо `.luaurc`) принят RFC, но для Roblox пока используйте `.luaurc`. Алиасы `.luaurc` указывают на файловые пути и в Studio не соответствуют DataModel — не используйте их для `require` внутри игры, берите Instance-пути.

### test.project.json (тестовый плейс)
Отдельный проект: те же `Shared`, `Packages`, плюс `DevPackages`, `Tests` (папка `tests/`) и `ServerScriptService.$properties.LoadStringEnabled = true`. `LoadStringEnabled` в тестовом плейсе безвреден (Jest в «менее привилегированных контекстах» использует loadstring); в продакшн-проекте его включать нельзя. Нужен ли он внутри Luau Execution — не подтверждено.

### asphalt.toml
```toml
[creator]
type = "group"     # или "user"; ключ API должен принадлежать этому владельцу
id = 0
[codegen]
style = "nested"
strip_extensions = true
[inputs.assets]
path = "assets/**/*"
output_path = "src/shared"
```
Asphalt: `asphalt sync` (+ `sync studio`, `sync debug`, `--dry-run`), ключ в `ASPHALT_API_KEY`, пишет `asphalt.lock.toml` и генерирует Luau-модуль с ID. Видео требует `--expected-price` (загрузка видео стоит 2 000 Robux).

Источники: rojo.space/docs/v7/project-format, rojo.space/docs/v7/sync-details; kampfkarren.github.io/selene; github.com/JohnnyMorganz/StyLua; github.com/jackTabsCode/asphalt.

<a id="3"></a>
## 3. Команды: bootstrap, сборка, анализ, syncback

```bash
# 1. Инструменты и пакеты
rokit install                       # всё из rokit.toml
rojo plugin install                 # плагин Studio (нужен, если Studio используется)
wally install                       # Packages/ ServerPackages/ DevPackages/
selene generate-roblox-std          # если roblox-std-source = "pinned"; коммитим roblox.yml

# 2. Разработка
rojo serve                          # live-sync в Studio (порт 34872), затем Connect в плагине
rojo build default.project.json -o build.rbxl
rojo sourcemap default.project.json --output sourcemap.json --watch   # для luau-lsp в редакторе

# 3. Проверки (то же самое делает CI)
selene src && stylua --check src
curl -sSfL https://luau-lsp.pages.dev/type-definitions/globalTypes.None.d.luau -o globalTypes.d.luau
luau-lsp analyze --platform roblox --sourcemap sourcemap.json \
  --definitions @roblox=globalTypes.d.luau --base-luaurc .luaurc \
  --ignore "Packages/**" --ignore "ServerPackages/**" --ignore "DevPackages/**" src

# 4. Загрузка ассетов (по желанию)
asphalt sync                        # пишет asphalt.lock.toml и src/shared/Assets.luau

# 5. Забрать правки из Studio обратно в файлы
rojo syncback default.project.json --input from_studio.rbxl --list     # показать, что изменится
rojo syncback default.project.json --input from_studio.rbxl -y         # применить без вопросов
```

**Подробности `luau-lsp analyze`.** Флаги: `--platform roblox`, `--sourcemap PATH`, `--definitions @NAME=PATH` (именованные определения обязательны; формат `--definitions:@roblox=...` с двоеточием тоже принимается), `--base-luaurc`, `--settings`, `--ignore GLOB`, `--flag:KEY=VALUE`. Команда **не скачивает определения сама** — их нужно взять по ссылке выше (или из Studio CLI: `RobloxStudio --apiV2 <path>` выдаёт JSON API). Без sourcemap `require` по Instance-путям не разрешается. Если Wally/Rojo недоступны (песочница), шаблон содержит `scripts/make_sourcemap.py --stubs` и заглушку ProfileStore в `analysis/` — см. README шаблона; это только для статического анализа.

**Важная ловушка.** Open-source CLI `luau`/`luau-analyze` и сборки luau-lsp включают **все неэкспериментальные флаги `Luau*`**, поэтому принимают синтаксис, который Roblox ещё не выпустил (например, `export function`). Правило: синтаксис проверять CLI, но использовать только то, что есть в create.roblox.com/docs. На окт. 2026 в Roblox можно: `const` (задокументирован с 08.2026), `buffer` (включая `readbits/writebits`), `vector`, `math.lerp/map/isfinite`, require по строке (`./`, `../`, `@self`, `@game`); `coroutine.finally` появился в справочнике 20.10.2026 — проверять через `if coroutine.finally then`. Нельзя: `class`, `export`, 64-битный `integer`, циклические require. В шаблоне `const` намеренно не используется (старые Selene/StyLua могут не разобрать).

**Решатель типов.** Шаблон проверен на обоих решателях (старый — по умолчанию в luau-lsp, `--flag:LuauSolverV2=true` — новый): 0 диагностик. Особенности: `read`-свойства в типах на старом решателе — ошибка; `local ok, err = pcall(f)` для функции без возвращаемого значения на старом решателе даёт ложное «Function only returns 1 value, but 2 are required», лечится аннотацией `local ok: boolean, err: any = pcall(...)`.

**Версия API в `globalTypes`.** Определения из luau-lsp могут отставать от движка: в сборке, на которой проверялся шаблон, нет `MarketplaceService:BindReceiptHandler` (метод добавлен 04.05.2026), поэтому вызов идёт через `(MarketplaceService :: any)`. Свежие определения тянет CI.

Источники: github.com/JohnnyMorganz/luau-lsp (README, editors/README.md, src/main.cpp); create.roblox.com/docs/projects/external-tools; Rojo CHANGELOG 7.7.x.

<a id="4"></a>
## 4. Что Rojo не умеет и как это обойти

**Не синхронизируются живьём (официально):** бинарные данные (Terrain, CSG/PartOperation), `MeshPart.MeshId`, `HttpService.HttpEnabled`. Обход по документации — «сгенерировать place-файл и открыть его». `rojo build` включает такие объекты, если они лежат внутри `.rbxm`, подключённых через `$path`.

**Публикация API их не обновляет:** `EditableImage`, `EditableMesh`, `PartOperation`, `SurfaceAppearance`, `BaseWrap`. Что именно делает API-публикация с уже существующими такими объектами (сохраняет или стирает) — **не проверено**: перед использованием на карте с union'ами сделайте тест на тестовом плейсе (Studio-публикация → API-публикация → осмотр).

**Матрица «чем делать — где хранить — как выкатывать»:**

| Контент | Автор | В репозитории | Выкатка |
|---|---|---|---|
| Скрипты, RemoteEvent, конфиг, UI из кода | файлы | `.luau`, `.model.json`, `.json/.toml` | API-публикация |
| Parts/Models без union и SurfaceAppearance | Luau-генератор (MCP `execute_luau` или Luau Execution) | генератор `.luau` + `world/*.rbxm` | API-публикация |
| Terrain | `Terrain:FillBlock/FillBall/FillRegion`, импорт heightmap | `world/Terrain.rbxm` | API-публикация (Terrain не в списке исключений публикации, он только в ограничениях live-sync Rojo) |
| Unions/CSG, SurfaceAppearance, EditableMesh/Image, layered clothing | Studio (человек или MCP) | `.rbxm` | **публикация из Studio** при каждом изменении |
| Меши, картинки, аудио | AI-генерация или DCC | `assets/` + `asphalt.lock.toml` | Asphalt → ID в `src/shared/Assets.luau` |

**Rojo vs Script Sync.** Script Sync синхронизирует только Script/LocalScript/ModuleScript/Folder, до 10 000 скриптов на корень и 128 корней, игнорирует атрибуты и теги, работает с Team Create и требует открытой Studio; отладчик Studio из внешней IDE не управляется. Rojo — для полного контроля версий и headless-сборки. Страница Script Sync с 24.06.2026 без пометки beta; официальный туториал «Build with a coding harness» (28.07.2026) ещё говорит «enable the Script Sync beta» — считать устаревшим: если пункт есть в File → Beta Features, включите, иначе он уже включён. Roblox-рецепт для агента: Script Sync для ServerScriptService/ReplicatedStorage/StarterPlayerScripts + MCP для того, что Script Sync не покрывает (StarterGui, StarterPack); проверка — `game:GetService("InstanceFileSyncService"):GetStatus(instance)`.

**Rojo syncback (с 7.7.0-rc.1).** `rojo syncback [PROJECT] --input <place.rbxl|.rbxlx|model.rbxm|.rbxmx> [--list] [--dry-run] [-y]`. `--list` печатает файлы, которые будут добавлены или удалены; `--dry-run` ничего не пишет; `-y` пропускает подтверждение (нужен агенту и CI). Весь обычный вывод идёт в stderr. Куда пишутся инстансы: объекты из дерева проекта — по соответствующим путям; часть классов (Actor, Sound, SoundGroup, Sky, Atmosphere, эффекты постобработки, ParticleEmitter, TextChat-конфиги, варианты RemoteEvent/BindableEvent с 7.7.0) — как `*.model.json`; то, что не может быть директорией, — `.rbxm` с предупреждением. Syncback отказывается писать в `.json`/`.toml`-модули. Правила: `syncbackRules.ignoreTrees` (пути внутри Roblox-файла), `ignorePaths` (glob по файловой системе, с `!`-отрицанием с 7.7.0), `ignoreProperties` (по классам), `syncCurrentCamera` (false), `syncUnscriptable` (true).

**Headless-снимок мира без Studio** (описано в документации, не тестировалось): задача Luau Execution (§9) запускает генератор; результат сериализуется `SerializationService:SerializeInstancesAsync({workspace.Map})` (доступно только плагинам Studio и сессиям Luau Execution), возвращается как `{ BinaryOutput = buf, ReturnValues = {...} }` при `enableBinaryOutput: true` (до 256 MiB; ссылка `binaryOutputUri` живёт 15 минут); файл кладётся в `world/Map.rbxm`. В обратную сторону `DeserializeInstancesAsync` + бинарный вход (presigned URL до 100 MiB, 15 минут; читается как `({...})[1].BinaryInput`). Гарантий стабильности формата `.rbxm`, созданного так, нет. `AssetService:SavePlaceAsync` работает только для мест, созданных `CreatePlaceAsync`, либо при включённой настройке «Allow place to be updated using Save Place API»; активная Team Create блокирует сохранение.

Источники: rojo.space/docs/v7/sync-details; Rojo CHANGELOG; create.roblox.com/docs/scripting/sync; create.roblox.com/docs/ai/coding-harness; create.roblox.com/docs/cloud/guides/usage-place-publishing.

<a id="5"></a>
## 5. Open Cloud: ключ, scopes, что автоматизируется

**Ключ создаёт человек** (Creator Hub → Credentials). Правила: ограничить ключ нужными вселенными; авто-истечение через 60 дней неиспользования; IP-ограничение (CIDR) нельзя ставить на ключ, используемый серверами Roblox; лимиты считаются суммарно по всем ключам одного владельца; для групповой автоматизации Roblox советует отдельный alt-аккаунт, ограниченный группой. Секреты игры (ключи для вызовов изнутри игры) хранить в **Secrets store**, не в скриптах и не в DataStore.

**Минимальный набор scopes** для пайплайна этого файла:

| Цель | Scope |
|---|---|
| Публикация плейса | `universe-places:write` (через дефис; в README старого демо написано `universe.places:write`) |
| Cloud-тесты | `universe.place.luau-execution-session:write` (+ read для логов) |
| Универсум/рестарты/Configs/Experiments | `universe:write`, `universe:read` |
| Настройки place (имя, описание, serverSize) | `universe.place:write` |
| Ассеты | `asset:read`, `asset:write` |
| Passes / Products | `game-pass:read/write`, `developer-product:read/write` |
| Иконка, thumbnails, локализация, activate | `legacy-universe:manage` |
| Badges (могут тратить Robux!) | `legacy-universe.badge:manage-and-spend-robux` |
| Messaging | `universe-messaging-service:publish` |
| DataStore v2 | `universe-datastores.objects:{create,read,update,delete,list}` |
| Аналитика | `universe.analytics:read` (+ `write` для Error Reporting) |
| Уведомления | `user.user-notification:write` |

**Что можно API-ключом, а что нет:**

| Действие | Как | Стабильность |
|---|---|---|
| Публикация/сохранение версии плейса | `POST /universes/v1/.../versions` | BETA |
| Имя/описание (через корневой place), `serverSize` | `PATCH /cloud/v2/universes/{u}/places/{p}` | STABLE (409, если place открыт в Team Create) |
| Соцссылки, voice chat, цена приватных серверов (не задана = выключены), устройства desktop/mobile/tablet/console/VR | `PATCH /cloud/v2/universes/{u}?updateMask=...` | STABLE |
| Localized name/description, supported languages | `legacy-game-internationalization/...` | EXPERIMENTAL |
| Activate/deactivate universe | `POST /legacy-develop/v1/universes/{u}/activate` | EXPERIMENTAL |
| Passes, products | `game-passes/v1`, `developer-products/v2` | BETA |
| Badges, иконка, thumbnails | `legacy-badges/v1`, `legacy-game-internationalization/v1` | EXPERIMENTAL |
| Жанр, avatar-настройки, friends-only, аудитории, регионы, paid access, rewarded ads toggle, demo mode | `PATCH develop.roblox.com/v2/universes/{u}/configuration` | **только cookie, API-ключ не принимается** |
| Анкета рейтинга, возрастные/гео-ограничения, notification strings, видео-thumbnails, early testers (≤10), DevEx, создание ключа | Dashboard UI | человек |
| Создать universe/place | Studio: File → Publish / Publish As → Add as a new place | человек (эндпоинта нет) |

`visibility` и `ageRating` в Universe v2 — **read-only**. Что делает `activate` — выведено по кодам ошибок («root place under review», «maximum number of places active») и соседнему `activation-eligibility`: вероятно, «открыть универсум из private в public»; **требования релиза он не обходит**. Использовать только для аварийного `deactivate`/повторного открытия, не как способ публикации.

Источники: create.roblox.com/docs/cloud/auth/api-keys; create.roblox.com/docs/cloud/reference/features/universes; reference/cloud/openapi.json в Roblox/creator-docs.

<a id="6"></a>
## 6. Публикация плейса и настройки experience

### Publish
```bash
curl -sS -X POST "https://apis.roblox.com/universes/v1/$U/places/$P/versions?versionType=Published" \
  -H "x-api-key: $KEY" -H 'Content-Type: application/octet-stream' --data-binary @prod.rbxl
# -> {"versionNumber": 7}
```
`versionType=Saved` сохраняет версию, не публикуя (используется для тестового плейса). Для `.rbxlx` — `Content-Type: application/xml`. Только существующие place. Лимит 30/мин на владельца ключа. Размер плейса — до 100 MB. Исключённые классы — §4.

### Установить имя/описание/размер сервера
```bash
curl -sS -X PATCH "https://apis.roblox.com/cloud/v2/universes/$U/places/$P?updateMask=displayName,description,serverSize" \
  -H "x-api-key: $KEY" -H 'Content-Type: application/json' \
  --data '{"displayName":"My Game","description":"First sentence = the hook.","serverSize":12}'
```
Имя и описание universe меняются через корневой place. Правила метаданных (не спамить ключевыми словами, суть в первом предложении) — `builder/packaging.md`.

### Universe: устройства, voice, приватные серверы
```bash
curl -sS -X PATCH "https://apis.roblox.com/cloud/v2/universes/$U?updateMask=privateServerPriceRobux,consoleEnabled" \
  -H "x-api-key: $KEY" -H 'Content-Type: application/json' \
  --data '{"privateServerPriceRobux":0,"consoleEnabled":false}'
```
Что куда ставить по смыслу (чек-листы Experience Settings) — `builder/studio-config.md`.

### Релиз и рестарт
После публикации серверы остаются на старой версии. Выкатка — §10 (`:restartServers`, bleed-off). Если формат данных игрока изменился, рестарт обязателен («Restart only servers with outdated versions»), иначе старые серверы продолжат писать старый формат.

Источники: create.roblox.com/docs/cloud/guides/usage-place-publishing; create.roblox.com/docs/cloud/reference/features/universes; create.roblox.com/docs/projects/update-games.

<a id="7"></a>
## 7. Game passes, products, badges, иконка, thumbnails (curl)

Все примеры: `U` — Universe ID, `KEY` — API-ключ. Эти эндпоинты анонсированы 04.12.2025 (passes, products; только API-ключ); cookie-версии пока не удаляются.

### Game pass (BETA, `game-pass:write`, 5/сек)
```bash
curl -sS -X POST "https://apis.roblox.com/game-passes/v1/universes/$U/game-passes" -H "x-api-key: $KEY" \
  -F name='VIP' -F description='2x coins forever' -F isForSale=true -F price=399 \
  -F isRegionalPricingEnabled=true -F imageFile=@assets/passes/vip.png
```
Ответ содержит `gamePassId` и `iconAssetId`. Обновление: `PATCH .../game-passes/{id}` с теми же multipart-полями. Существует и поле `isManagedPricingEnabled`.

### Developer product (BETA, `developer-product:write`, 3/сек)
```bash
curl -sS -X POST "https://apis.roblox.com/developer-products/v2/universes/$U/developer-products" -H "x-api-key: $KEY" \
  -F name='500 Coins' -F description='Coin pack' -F isForSale=true -F price=99 -F isRegionalPricingEnabled=true \
  -F imageFile=@assets/products/coins500.png
```
Ответ: `productId`, `isImmutable`, `storePageEnabled`. **Удалить продукт нельзя** — только `isForSale=false`. Выданный `productId` агент вносит в `Config.Products` шаблона.

**Managed Pricing** объединяет price optimization (Roblox сам проводит ценовые тесты) и regional pricing в одном opt-in (Creator Hub → Monetization → Managed Pricing). При включении игра один раз проходит проверку «захардкоженных цен». **Правило для кода:** не хардкодить цены в UI; читать на клиенте через `MarketplaceService:GetProductInfoAsync`, чтобы игрок видел персонализированную/региональную цену. Региональные цены passes включены по умолчанию (не ниже 30% от базовой). Подробности политики цен — `advisor/monetization.md`.

### Badge (EXPERIMENTAL, 100/мин)
```bash
curl -sS -X POST "https://apis.roblox.com/legacy-badges/v1/universes/$U/badges" -H "x-api-key: $KEY" \
  -F name='Escaped the Basement' -F description='Beat chapter 1' -F paymentSourceType=1 \
  -F expectedCost=0 -F isActive=true -F files=@assets/badges/ch1.png
```
`paymentSourceType`: 1 — пользователь, 2 — группа. **Первые 5 бейджей на игру за 24 часа (GMT) бесплатны, дальше 100 Robux за каждый.** Агент не создаёт больше 5 в сутки и всегда ставит `expectedCost` явно, чтобы не потратить Robux без спроса.

### Иконка (EXPERIMENTAL, `legacy-universe:manage`, 100/мин)
```bash
curl -sS -X POST "https://apis.roblox.com/legacy-game-internationalization/v1/game-icon/games/$U/language-codes/en" \
  -H "x-api-key: $KEY" -F Files=@release/icon_512.png
```

### Thumbnails (тот же scope)
```bash
B="https://apis.roblox.com/legacy-game-internationalization/v1/game-thumbnails/games/$U/language-codes/en"
curl -sS -X POST "$B/image" -H "x-api-key: $KEY" -F Files=@release/thumb1_1920x1080.png     # -> {"mediaAssetId":"..."}
curl -sS -X POST "$B/images/order" -H "x-api-key: $KEY" -H 'Content-Type: application/json' --data '{"mediaAssetIds":[111,222,333]}'
curl -sS -X POST "$B/alt-text" -H "x-api-key: $KEY" -H 'Content-Type: application/json' --data '{"thumbnailId":111,"altText":"Player hides from the monster in the kitchen"}'
```
Параметр `gameId` в пути — по соглашению legacy-сервисов это Universe ID (**не проверено**, сделайте один тестовый вызов). Спецификации: иконка квадратная, не меньше 512×512; thumbnails 16:9, 1920×1080, до 10 штук, jpg/gif/png/tga/bmp, всё проходит модерацию; видео-thumbnails — только через Dashboard. Размеры, композиция, A/B — `builder/packaging.md`.

### Локализованные название/описание и языки (EXPERIMENTAL)
`PATCH .../legacy-game-internationalization/v1/name-description/games/{gameId}` с телом `{"data":[{"name","description","updateType":"Name|Description","languageCode"}]}`; языки — `PATCH .../supported-languages/games/{gameId}` с `[{"languageCodeType":"Language","languageCode":"es","delete":false}]`. Таблицы перевода — Rojo превращает `*.csv` (Key, Source, Context, Example, коды языков) в LocalizationTable; `POST /cloud/v2/universes/{u}:translateText` (BETA, 10 000/мин).

### Gate: ассет одобрен ли модерацией
```bash
curl -sS "https://apis.roblox.com/assets/v1/assets/$ASSET_ID?readMask=moderationResult" -H "x-api-key: $KEY"
# {"moderationResult":{"moderationState":"Reviewing"|"Rejected"|"Approved"}}
```
Ассет в состоянии Reviewing при публикации невидим игрокам. CI должен падать, пока что-то Reviewing или Rejected.

Источники: create.roblox.com/docs/cloud/reference/features/game-passes, .../developer-products; DevForum 4114297 (анонс 04.12.2025); create.roblox.com/docs/production/monetization/managed-pricing; .../publishing/badges.

<a id="8"></a>
## 8. Assets API, Asphalt, модерация, квоты

`POST https://apis.roblox.com/assets/v1/assets` (multipart, `x-api-key`, scopes `asset:read` + `asset:write`; 120/мин; BETA). До 20 MB за вызов. Ответ `{"path":"operations/{id}"}`; опрашивать `GET /assets/v1/operations/{id}` до `assetId`.
```bash
curl https://apis.roblox.com/assets/v1/assets -H "x-api-key: $KEY" \
  --form 'request={"assetType":"Model","displayName":"Rock","description":"...","creationContext":{"creator":{"userId":"123"}}}' \
  --form 'fileContent=@rock.fbx;type=model/fbx'
```
Для группы — `"groupId"` вместо `"userId"`.

| Тип | Форматы и ограничения |
|---|---|
| Audio | mp3/ogg/wav/flac, ≤7 мин; **не обновляется** |
| Decal/Image | png/jpeg/bmp/tga, <8000×8000; не обновляется |
| Model | fbx/gltf/glb/rbxm/rbxmx; загружается как **пакет** (Model из MeshPart) |
| Animation | rbxm/rbxmx |
| Video | mp4/mov, ≤5 мин, ≤4096×2160, 20/сутки для 13+ с ID; каждая загрузка стоит 2 000 Robux |
| Mesh | сырые меши отклоняются, если контент не скачан из Asset Delivery API; используйте Importer или Model (FBX/glTF) |

Правило: **скриптовый контент поставляйте внутри плейса, собранного Rojo, а не как Model-ассеты**; `.rbxm`, изменённые вне Studio, «might not upload or function». Через API грузим меши, картинки, аудио, анимации.

**Квота аудио (конфликт источников разрешён).** Использовать **2 000 загрузок за 30 дней для ID-verified и 100 для неверифицированных** — страница Audio assets изменена 17.03.2026 и явно включает Open Cloud в то же правило. Страница Assets API Guide всё ещё говорит «100/мес и 10/мес» — это устаревший текст. Ошибка квоты/429 при загрузке аудио = «исчерпана месячная квота», запасной путь — переиспользовать существующие ID. Генерация TTS: `POST /cloud/v2/universes/{id}:generateSpeechAsset` (BETA, 4/сек, scopes `universe:write`, `asset:read`, `asset:write`).

**Creator Store и безопасность.** Стор ограничивает ассеты с `getfenv/setfenv`, `require(assetId)`, `loadstring`, `InsertService:LoadAsset`, `AssetService:LoadAssetAsync`, обфускацией и огромными скриптами. Через MCP `search_asset/insert_asset` вставляйте только безскриптовые меши либо прогоняйте grep по вставленным скриптам на эти паттерны.

**Лимиты генерации (Assistant/MCP):** документирована только квота 50 procedural models за скользящие 24 часа; квоты `generate_mesh` (по умолчанию до 10 000 треугольников) и `generate_material` нигде не опубликованы.

Источники: create.roblox.com/docs/cloud/guides/usage-assets; create.roblox.com/docs/audio/assets; create.roblox.com/docs/production/creator-store; github.com/jackTabsCode/asphalt.

<a id="9"></a>
## 9. Luau Execution: облачные тесты и headless-генерация

Luau Execution исполняет скрипт в облаке с полным доступом к DataModel заданной версии place.

```bash
# создать задачу (STABLE; scope universe.place.luau-execution-session:write)
curl -sS -X POST "https://apis.roblox.com/cloud/v2/universes/$U/places/$P/versions/$V/luau-execution-session-tasks" \
  -H "x-api-key: $KEY" -H 'Content-Type: application/json' \
  --data "$(python3 -c 'import json;print(json.dumps({"script":open("tasks/runTests.luau").read(),"timeout":"300s"}))')"
# затем: GET /cloud/v2/{task.path} до state COMPLETE|FAILED|CANCELLED;  GET /cloud/v2/{task.path}/logs
```
Путь без `/versions/{v}` — последняя версия place. Состояния: `QUEUED`, `PROCESSING`, `CANCELLED`, `COMPLETE`, `FAILED`; ошибки: `SCRIPT_ERROR`, `DEADLINE_EXCEEDED`, `OUTPUT_SIZE_LIMIT_EXCEEDED`, `INTERNAL_ERROR`. Логи — `luauExecutionSessionTaskLogs[].messages[]` (или `structuredMessages`).

**Лимиты (спецификация окт. 2026):** скрипт ≤4 MB; выполнение до 5 минут (по умолчанию 5); возвращаемое значение ≤4 MB JSON; логи — хранится 450 KB; информация о задаче 24 часа; **не более 10 незавершённых задач на place** (иначе 429); создание задачи **5/мин** на владельца ключа, GET task 200/мин, logs 45/мин. Физика не работает, скрипты места не запускаются автоматически, изменения DataModel не сохраняются, **вызовы DataStore реальные**. Бинарный вход (presigned, ≤100 MiB, 15 минут) и выход (≤256 MiB).

**Вывод для CI:** узкое место — 5 созданий в минуту, поэтому весь набор тестов собираем в **одну** задачу (`tasks/runTests.luau` запускает Jest и падает при красных тестах). Конкурентность в GitHub Actions ограничиваем `concurrency`. Старое демо Roblox говорило «2 одновременных на universe» — устарело.

**Jest.** `require(DevPackages.Jest).runCLI(root, {ci = true}, {root}):awaitStatus()`; файл `jest.config.luau` с `return { testMatch = { "**/*.spec" } }` **обязателен**; тесты — `*.spec.luau` в `__tests__/`. Пакеты `roblox/jest` и `roblox/jest-globals` версии 3.20.x доступны в Wally с 03.08.2026 (в старых заметках встречается «3.8.0» — устарело). Что тестировать в первую очередь: чистую логику (экономика, миграции, валидация трейдов) — этого достаточно, чтобы поймать большинство регрессий без Studio.

**Тестовая пирамида.** (1) чистая логика — Jest в Luau Execution на каждом PR; (2) интеграция — `StudioTestService:ExecuteMultiplayerTestAsync` (сервер + до 8 клиентов, только Studio) или playtest-субагент MCP локально; (3) smoke — `RobloxStudio --task RunScript --placeId P --universeId U --runScriptFile smoke.luau --outputFile out.log --quitAfterExecution` либо Luau Execution на только что опубликованной staging-версии; (4) прод — Error Reporting API, дашборд Performance и Early Harm Detection экспериментов.

Источники: create.roblox.com/docs/cloud/reference/features/luau-execution; github.com/Roblox/jest-roblox; github.com/Roblox/place-ci-cd-demo; create.roblox.com/docs/studio/cli, .../studio/testing-modes.

<a id="10"></a>
## 10. Live-ops API: Configs, Experiments, Messaging, рестарты, уведомления

Стратегия, расписание и контент-цикл — `builder/liveops.md`. Здесь только вызовы.

### Configs (BETA; `universe:read/write`; publish 10/мин)
База: `https://apis.roblox.com/creator-configs-public-api/v1/configs/universes/$U/repositories/InExperienceConfig`.
```bash
# перезаписать draft целиком; PATCH /draft — частичное обновление (previousDraftHash для оптимистичной блокировки)
curl -sS -X PUT "$BASE/draft:overwrite" -H "x-api-key: $KEY" -H 'Content-Type: application/json' --data '{"entries":{"EventActive":true,"bossHealth":300}}'
# -> {"draftHash":"..."}
curl -sS -X POST "$BASE/publish" -H "x-api-key: $KEY" -H 'Content-Type: application/json' \
  --data '{"draftHash":"...","message":"halloween on","deploymentStrategy":"GradualRollout"}'   # Immediate | GradualRollout (15 мин)
```
`GET` отдаёт значения, `GET /full` — метаданные, `GET /revisions?MaxPageSize=10`, `POST /revisions/{id}/restore` возвращает новый `draftHash` и **не публикует** — после restore обязателен `/publish`. Лимиты: 100 ключей на репозиторий, ключ ≤256 символов, значение string/JSON ≤100 000 символов. В игре значения доходят за ~15 с – 1 мин. В коде: серверный `ConfigService:GetConfigAsync()`/`GetConfigForPlayerAsync(player)`, снимок не обновляется сам (`snapshot.UpdateAvailable:Connect(function() snapshot:Refresh() end)`); `GetConfigAsync` всегда оборачивать в `pcall` с fallback-значениями.

### Experiments (EXPERIMENTAL; 10/мин)
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
Жизненный цикл: DRAFT (можно PATCH/DELETE) → `:start` либо `:schedule` (`{"scheduledStartTime":"...Z"}`; после этого конфигурация неизменна) → `/stats` через ≥24 ч (смотреть `isSrmDetected`) → `:complete` с `{"variantId":...}` раскатывает победителя (без него — откат). Любой изменяющий вызов возвращает `operation`, опрашиваемую на `/v1/experimentation/universes/{id}/operations/{opId}`. Метрики-цели: `..._AVERAGE_SESSION_TIME`, `..._PLAYTIME_PER_USER`, `..._DAY_1_RETENTION`, `..._DAY_7_RETENTION`, `..._PAYER_CONVERSION_RATE`, `..._AVERAGE_REVENUE_PER_USER`, `..._AVERAGE_REVENUE_PER_PAYING_USER`. Ограничения: длительность 14–60 дней, 1 baseline + **не больше 2 treatment**, один активный эксперимент на ключ конфига, один matchmaking-эксперимент на universe; чтение ключа в игре (`GetValue`) = момент зачисления в эксперимент. Игры меньше ~500 DAU могут не иметь статистической мощности.

### MessagingService (STABLE; `universe-messaging-service:publish`; 5 000/мин)
```bash
curl -sS -X POST "https://apis.roblox.com/cloud/v2/universes/$U:publishMessage" -H "x-api-key: $KEY" \
  -H 'Content-Type: application/json' --data '{"topic":"announce","message":"{\"text\":\"Halloween event live!\"}"}'
```
Тема ≤80 символов, сообщение ≤1 KiB; в игре нужен `MessagingService:SubscribeAsync(topic)`; доходит только до живых серверов.

### Рестарты после публикации
- **Простой** (STABLE, `universe:write`, 30/мин): `POST /cloud/v2/universes/$U:restartServers` с `{"bleedOffServers":true,"bleedOffDurationMinutes":10}`; `placeIds[]` необязателен; `closeAllVersions:false` по умолчанию — перезапускаются только серверы устаревших версий; bleed-off 1–60 минут.
- **Расширенный** (BETA, 100/мин): `POST /server-management/v1/universes/{u}/restarts` с `bleedOffDurationMinutes` 1–240, `places` (`{"<placeId>":{"excludeCurrentVersion":true}}` или `{"versions":[12,13]}`), `attributes` (JSON ≤500 байт; доходят до `DataModel.ServerRestartScheduled(restartTime, source, attributes)`); `GET .../restarts:forecast` показывает охват, `GET .../restarts` — статус.
- В игре подписывайтесь на `ServerRestartScheduled`, показывайте отсчёт и принудительно сохраняйте данные. Игроки с одного старого сервера переезжают вместе на один новый.
- Для постоянного отключения игры — закрыть публичный доступ (или `deactivate`, §5).
- **Паттерн для срочных обновлений:** выкатить код заранее, спрятать контент за Config-флагом и перевернуть флаг.

### Уведомления (STABLE; 4 000/сек)
Строки уведомлений создаются **только в Dashboard** (API создания нет).
```bash
curl -sS -X POST "https://apis.roblox.com/cloud/v2/users/$USER_ID/notifications" -H "x-api-key: $KEY" -H 'Content-Type: application/json' \
  --data '{"source":{"universe":"universes/'"$U"'"},"payload":{"message_id":"<notificationStringAssetId>","type":"MOMENT","parameters":{"points":{"string_value":"5"}}}}'
```

**Часы для событий.** Для старта события в реальное время — `os.time()`/`DateTime.now()` на сервере; на клиенте `workspace:GetServerTimeNow()` (монотонно, документация рекомендует именно для «событие стартует в нужное реальное время»). Хранить время старта в Config (`EventStartUnix`).

### Прочее
- **Error Reporting API:** детали ошибок (сообщение, стек, серьёзность, платформа, версия первой встречи), правила группировки; scope `universe.analytics:read/write`, 60/мин на ключ; хэши — из метрики `ErrorCount` по `MessageHash`.
- **Flush MemoryStore:** `POST /cloud/v2/universes/{id}/memory-store:flush` (scope LIVE/TEST) очищает все структуры — только для тестовой вселенной.
- **Из игры в Open Cloud:** 2 500 запросов/мин на сервер (не засчитываются в лимит 500/мин для прочего HTTP); ключи — в Secrets.

Источники: create.roblox.com/docs/cloud/guides/configs, .../experiments, .../usage-messaging, .../experience-notifications, .../error-reporting; create.roblox.com/docs/projects/update-games; DevForum «Studio MCP / Configs» (08.2026).

<a id="11"></a>
## 11. Analytics Query и Benchmarks API

Документация добавлена 07.07.2026; BETA; scope `universe.analytics:read`. Позволяет агенту сам строить еженедельный отчёт.

```bash
curl -sS 'https://apis.roblox.com/analytics-query-api/v1/universes/'"$U"'/metrics' \
  -H "x-api-key: $KEY" -H 'Content-Type: application/json' \
  --data '{"metric":"ForwardD1Retention","granularity":"OneDay",
           "startTime":"2026-10-12T00:00:00Z","endTime":"2026-10-26T00:00:00Z",
           "breakdown":["Platform"],
           "filter":[{"dimension":"Country","values":["US","BR"],"operation":"In"}]}'
```
- Обязательны `metric`, `granularity`, `startTime` (включительно); `endTime` — **исключающий**. `breakdown[]`, `filter[]`, `limit` (только при `granularity:"None"` с breakdown) — необязательны. Операции фильтра: `In`, `NotIn`, `GreaterThan(OrEqual)`, `LessThan(OrEqual)`, `Match`.
- Гранулярность: `OneMinute`/`HalfHour` — только метрики производительности; `OneHour` — производительность и часть монетизации; `OneDay` — все; `OneWeek`/`OneMonth`/`None` — большинство. Недельные значения считают **уникальных** пользователей, а не сумму дневных. Диапазон больше 2 лет — только неделя/месяц/None.
- Ответ: `200 {done:true, response.values[{breakdowns[], dataPoints[{time,value,status}]}]}` либо `202 {done:false, path}` → опрашивать `GET https://apis.roblox.com/analytics-query-api/{path}`. `status`: `Valid`, `Projected`, `NotStatisticallySignificant`.
- История: стандартные метрики 4 года (1 468 дней), метрики производительности 28 дней.
- Ошибки: 400/2001 (неверное поле или вне хранения), 429/3000 (превышен бюджет точек данных — сузить диапазон/гранулярность или использовать `limit`), 503/2002 (повторить), 504/1000 (таймаут). Значения измерений — `POST .../dimension-values` с `{metric, dimensions[], startTime, endTime}`.

**Идентификаторы метрик (регистр важен):**
- Retention: `ForwardD1Retention`, `ForwardD7Retention`, `ForwardD30Retention`, `DailyCohortRetention`, `WeeklyCohortRetention`, `DauMauStickiness`.
- Engagement: `DailyActiveUsers`, `MonthlyActiveUsers`, `AveragePlayTimeMinutesPerDAU`, `AverageSessionLengthMinutes`, `TotalPlayTimeHours`, `Visits`.
- Monetization: `DailyRevenue`, `AverageRevenuePerUser`, `AverageRevenuePerPayingUser`, `PayingUsers`, `PayingUsersCVR`, `ItemMonetizationRevenue`.
- Acquisition: `ImpressionCVR`, `ClickCVR`, `EndToEndCVR`, `QualifiedEndToEndCVR`, `UniqueUsersWithImpressions`, `UniqueUsersWithClicks`.
- Сигналы рекомендаций (те же, что, по описаниям, использует Home): `RFYPlayThroughRate`, `RFYDuration0To60`, `RFYDuration61To180`, `RFYD1Playtime`, `RFYD2To7PlayDays`, `RFYD1CoplayDays`, `RFYD1QualifiedPlaySessions`, `RFYD1SpendDay`, `RFYD1RobuxSpend` (+ варианты D2To7 и D8To28). Использование для диагностики — `advisor/discovery-growth.md`.
- Performance: `ClientCrashRate15m`, `ClientCrashCount`, `ClientFpsAvg`, `ClientMemoryUsageAvg`, `ClientCpuTimeAvg`, `ServerFrameRateAvg`, `ServerCrashCount`, `MemoryUsageAvg`, `OomUnexpectedExits`, `PeakConcurrentPlayers`.
- Economy/Funnels/Custom: `EconomyTransactionAmount`, `EconomyTransactionCount`, `FunnelStepCompletionRate`, `FunnelStepChurnRate`, `FunnelUserChurnRate`, `CustomEventAvgPerUserValue`.
- Thumbnails: `ThumbnailImpressions`, `ThumbnailQualifiedPTR`, `ThumbnailL7QualifiedPTR`, `ThumbnailWinningSegments`.
- Хранилища: `DataStoreRequests`, `DataStoreRequestsByStatus` (монитор throttling), `DataStoreStorageUsageBytes`, `MemoryStoreMemoryUsageBytes`.

**Benchmarks:** `POST https://apis.roblox.com/analytics-benchmark/v1/universes/$U/benchmarks` с `{metric, startTime, endTime (включительно), benchmarkType: BENCHMARK_TYPE_GENRE|BENCHMARK_TYPE_SIMILARITY|BENCHMARK_TYPE_TOP_EXPERIENCES, percentiles: [до 10]}`. По умолчанию p50 и p90 (для метрик «меньше — лучше» — p10 и p50); в ответе `objective` (MAXIMIZE/MINIMIZE).

**Рецепт еженедельного отчёта (вывод):** каждый понедельник запрашивать `DailyActiveUsers` (`breakdown:["IsNewUser"]`), `ForwardD1Retention`, `ForwardD7Retention`, `AveragePlayTimeMinutesPerDAU`, `PayingUsersCVR`, `AverageRevenuePerPayingUser`, `RFYPlayThroughRate`, `ClientCrashRate15m`, `FunnelStepChurnRate`; сравнить с p50/p90 жанра; флажок при значении ниже p50 или падении неделя-к-неделе хуже −10% (порог — оценка). Результат определяет конфиг-твик или эксперимент недели.

Источники: create.roblox.com/docs/cloud/guides/analytics, .../analytics/metrics, .../analytics/benchmarks.

<a id="12"></a>
## 12. DataStore через Open Cloud и общие бюджеты

Open Cloud v2 (`/cloud/v2/universes/{u}/data-stores/...`) **не имеет отдельного бюджета**: делит экспириенс-бюджет с живыми серверами. С 29.07.2026 лимиты унифицированы между Open Cloud и игровым API.

| Тип запроса | Бюджет на весь experience, в минуту |
|---|---|
| Read | 300 + CCU×40 |
| Write (create/update/increment) | 300 + CCU×20 |
| List | 300 + CCU×2 |
| Remove/Delete/Undelete | 300 + CCU×40 |

`UpdateAsync` расходует и read, и write. Старый Open Cloud v1 (`/datastores/v1/`) — фиксированно на universe: 300 запросов/мин на каждый тип, 10 MB/мин запись, 20 MB/мин чтение; для нового инструментария использовать v2. Пропускная способность на ключ: 25 MB/мин чтение и 4 MB/мин запись (округление вверх до KB). Размер значения до 4 194 304 символов; имя/ключ/scope ≤50 символов; метаданные ≤300. Хранилище: 500 MB + 1 MB × lifetime-пользователи (сжатая последняя версия; заранее не сжимать). `:snapshot` — 60/мин. Записи PATCH не поддерживают частичное обновление (`attributes`/`users` обнуляются, если не переданы); для оптимистичной блокировки есть `etag`.

**Правила агента:** массовые миграции и бэкфиллы — вне пиковых часов; не более 20% от `300 + CCU×20` записей в минуту (по `PeakConcurrentPlayers`); перед разрушительной операцией — `:snapshot`; во внешнем инструменте обязателен собственный rate limiter (пауза `60 / желаемых_в_минуту` секунд или leaky bucket); мониторить `DataStoreRequestsByStatus`. Версионирование: первая запись в ключ в каждый UTC-час создаёт версию-бэкап; бэкапы живут 30 дней после замены; восстановление — `ListVersionsAsync` → `GetVersionAsync` → запись обратно.

Игровая сторона (лимиты на сервер, ProfileStore, RTBF, миграции) — `builder/code-architecture.md`, §2.

Источники: create.roblox.com/docs/cloud-services/data-stores/error-codes-and-limits; .../cloud/guides/data-stores/throttling; DevForum 4739240 (унификация лимитов).

<a id="13"></a>
## 13. Что обязан сделать человек

**Один раз:**
1. Возраст/ID-верификация и 2FA аккаунта (для Kids/Select — обязательно; для 16+ достаточно age check, аккаунт не младше 2 дней и в good standing).
2. Создать две игры в Studio (File → Publish): PROD и TEST; скопировать Universe/Place ID в GitHub `vars`.
3. Создать API-ключ (Credentials), ограничить двумя вселенными, положить в `secrets.ROBLOX_API_KEY`.
4. В обеих играх включить «Enable Studio Access to API Services» (для локальных тестов данных) и, только при необходимости, «Allow HTTP Requests».
5. Выбрать жанр/поджанр — **менять можно не чаще раза в 3 месяца**; Roblox может переназначить жанр сам (апелляция через roblox.com/support → «Experience Genre»).
6. Создать строки уведомлений в Dashboard (API нет).
7. Зарегистрировать RTBF-шаблон `Player_{UserId}` (Creator Hub → Configurations → Data stores manager).
8. Платёжные/налоговые данные и DevEx (13+, ≥30 000 заработанных Robux, подтверждённый email, налоговая форма W-9/W-8).

**На каждый релиз, если изменились ответы анкеты:** пройти Content maturity заново (Dashboard → Publish settings → Content rating). Анкета есть только в UI, API нет; отвечать надо по **самому экстремальному** контенту, который может встретить игрок (контент игроков — например, аватарные вещи — исключён). Для 16+ достаточно первого вопроса («Content May Vary»); для Kids (5–8)/Select (9–15) и региональных требований — вся анкета. Подача Restricted перезапускает серверы и оставляет только 18+ с ID; после этого рейтинг менять нельзя. Категории: насилие, кровь, страх, грубый юмор, неигровой гэмблинг (играбельный запрещён), крепкие выражения, романтика, алкоголь, social hangout, свободное творчество игроков, чувствительные темы, платные случайные предметы (учёт `ArePaidRandomItemsRestricted`), платный трейдинг (`IsPaidItemTradingAllowed`), медиа, AI-взаимодействие. Подробности меток и аудитории — `builder/compliance.md`.

**Аудит кода перед публикацией (вывод, агентская часть):** grep по `src/` и именам ассетов: `Humanoid.Health`/`TakeDamage` → насилие; красные декали/частицы → кровь; `jumpscare`, погоня, shake+scream → страх; `MarketplaceService` с RNG на пути покупки → платные случайные предметы; trade-ремоуты с купленными предметами → платный трейдинг; код рисования/canvas → свободное творчество; `TextChatService` как основной цикл → social hangout; вызовы LLM через `HttpService` → AI-взаимодействие. Результат пишется в `release/QUESTIONNAIRE.md` (ответ, доказательство file:line, итоговая метка); при расхождении с последней поданной анкетой **автопубликация блокируется**, пока человек не пересдаст. Пример для хоррора: джампскейры, жуткие NPC и саспенс — Mild fear даже при повторяемости; реалистичная кровь/внутренности → Moderate; без реалистичной крови игра остаётся доступной аудитории Select 9–15.

**Первый публичный релиз:** Dashboard → Publish settings → Manage Audience → открыть для публики (не больше 5 никогда не выпускавшихся игр в сутки). Для Kids/Select: подтверждённый создатель (оценка по лицу <18, ID ≥18), 2FA, Plus/Premium два месяца подряд либо возвращаемый взнос 1 000 Robux, анкета с рейтингом Minimal/Mild/Moderate, оценка «250 уникальных игр высоко вовлечённых age-checked пользователей за 60 дней» (трекер Audience Reach), опционально ускоренная проверка за 50 000 Robux (возвращаемая). Новая игра без этого стартует только для age-checked 16+.

**Click sheet.** Агент кладёт в репозиторий `release/HUMAN_STEPS.md` с пронумерованным списком выше, заполненными ответами анкеты, готовыми текстами метаданных и файлами иконки/thumbnails; человек выполняет шаги и ставит отметки.

Источники: create.roblox.com/docs/production/publishing/publish-games-and-places, .../kids-and-select, .../promotion/content-maturity, .../publishing/experience-genres, .../monetization/developer-exchange.

<a id="14"></a>
## 14. CI/CD: пайплайн, секреты, human gate

Готовый workflow: `assets/automation/.github/workflows/cicd.yml`. Хелпер без зависимостей: `assets/automation/scripts/rbx.py` (`test`, `publish`, `restart`, `config`; повторы при 429/5xx с учётом `retry-after`). Структура:

1. **static** (каждый PR и push): `setup-rokit` → `wally install` → `rojo sourcemap` → `selene src` → `stylua --check src` → скачать `globalTypes.d.luau` → `luau-lsp analyze` с `--ignore` на Packages. (Шаг Asphalt `sync cloud --dry-run` — закомментирован до внедрения Asphalt.)
2. **cloud-tests**: `rojo build test.project.json -o test.rbxl` → `rbx.py test` загружает версию `Saved` в TEST place, запускает `tasks/runTests.luau` через Luau Execution, печатает логи, падает при любом состоянии, кроме COMPLETE. `concurrency` группа предотвращает превышение 10 незавершённых задач.
3. **deploy** (только push в main, `environment: production` с обязательными ревьюерами = **human gate**): `rojo build default.project.json` → `rbx.py publish` (версия Published) → `rbx.py restart 10` (только серверы устаревших версий, bleed-off 10 минут) → `rbx.py config config/live.json GradualRollout`. Ручной запуск с `config_only=true` публикует только конфиг.

**Настройки.** Secrets: `ROBLOX_API_KEY`. Variables: `TEST_UNIVERSE_ID`, `TEST_PLACE_ID`, `PROD_UNIVERSE_ID`, `PROD_PLACE_ID`. Два universe лучше, чем тестовый place внутри боевого: Saved-версия не утечёт в любом случае, но DataStore общий.

**Порядок выката (важно).** Сначала publish, затем restart, затем Configs: так новый код уже есть на серверах к моменту, когда флаг включается. Контент, привязанный ко времени, выкатывается «выключенным» (`EventActive=false`) и включается конфигом.

**Недельный live-ops цикл агента** (подробности — `builder/liveops.md`): понедельник — отчёт из Analytics Query (§11); вторник–среда — контент за флагом, ассеты через Asphalt; CI выкатывает «спящую» сборку; четверг/пятница — переключение конфига (`GradualRollout`, либо запланированное время UTC); `publishMessage` с анонсом и уведомления; наблюдение за алертами; при регрессии метрики — откат ревизии конфига (`restore` + `publish`).

**Предрелизный чек-лист ([A] — проверяет агент, [H] — человек):**
- [A] CI зелёный: статика и облачные тесты; [A] все ID ассетов `Approved`; [A] `QUESTIONNAIRE.md` не изменился относительно последней поданной анкеты (иначе [H] пересдать до публикации);
- [A] PolicyService-гейты (платные случайные предметы, трейдинг, реклама, подписки), показ шансов процентами с суммой 100%; [A] у каждого Developer Product идемпотентная обработка чека; [A] нет захардкоженных цен в UI;
- [A] smoke по производительности на TEST-вселенной (`ClientCrashRate15m`, `ClientFpsAvg`, `ClientMemoryUsageAvg`; данные производительности хранятся 28 дней);
- [A] иконка/thumbnails перезагружаются только если изменились; [A] метаданные без спама ключевыми словами;
- [A] publish → restart (bleed-off 5–10 мин, UI отсчёта по `ServerRestartScheduled`) → публикация Configs;
- [H] анкета, релиз и аудитория; [H] публикация из Studio, если менялись unions/SurfaceAppearance/Editable*.

Официальной единой страницы «launch checklist» у Roblox нет (проверено по репозиторию документации); чек-лист выше — сводный. Этапы всей продакшн-цепочки — `builder/pipeline.md`.

Источники: github.com/Roblox/place-ci-cd-demo; github.com/CompeyDev/setup-rokit; assets/automation.

<a id="15"></a>
## 15. Таблица лимитов и квот

Лимиты Open Cloud считаются на владельца ключа (сумма по всем его ключам); есть недокументированные лимиты — обрабатывайте 429 по `retry-after`/экспоненциальной паузе. Заголовки: `x-ratelimit-limit`, `x-ratelimit-remaining`, `x-ratelimit-reset`.

| Эндпоинт | Лимит | Стабильность |
|---|---|---|
| Place publish | 30/мин | BETA |
| Assets create | 120/мин | BETA |
| Luau Execution create / get task / logs | 5/мин / 200/мин / 45/мин; ≤10 незавершённых на place | STABLE |
| Universe PATCH, Place PATCH | 100/мин | STABLE |
| `:restartServers` | 30/мин | STABLE |
| `server-management` restarts | 100/мин | BETA |
| Game pass create/update | 5/сек | BETA |
| Developer product create/update | 3/сек | BETA |
| Badge create | 100/мин | EXPERIMENTAL |
| Иконка/thumbnails (legacy) | 100/мин | EXPERIMENTAL |
| Homepage thumbnails (personalization) | 50/мин | EXPERIMENTAL |
| Configs (все), publish | publish 10/мин | BETA |
| Experiments (все) | 10/мин | EXPERIMENTAL |
| `:publishMessage` | 5 000/мин | STABLE |
| Notifications | 4 000/сек | STABLE |
| translateText | 10 000/мин | — |
| generateSpeechAsset | 4/сек | BETA |
| Analytics Query / Benchmarks | бюджет точек данных (429/3000) | BETA |
| Error Reporting | 60/мин на ключ | — |
| DataStore v2 | общий бюджет experience; `:snapshot` 60/мин | STABLE |

Прочие квоты: аудио 2 000/100 за 30 дней (ID/без ID); видео 20/сутки и 2 000 Robux за штуку; procedural models 50 за 24 ч; бейджи 5 бесплатных/сутки/игра; новые релизы 5/сутки; ключ API истекает через 60 дней простоя; HttpService из игры — 2 500 запросов/мин к Open Cloud + 500/мин прочее на сервер; Extended Services (платные сверх лимитов, требуют ID-verified 18+) — цены в `code-architecture.md`.

Узкое место CI — **Luau Execution (5/мин)**, а не публикация (30/мин): объединяйте тесты в одну задачу.

<a id="16"></a>
## 16. Конфликты источников и открытые вопросы

**Разрешено (позднее перекрывает раннее):**
- Квота аудио: 2 000/100 за 30 дней (страница Audio, 17.03.2026) — а не 100/10 в месяц (устаревший Assets API Guide).
- Конкурентность Luau Execution: 10 незавершённых на place — а не «2 на universe» из демо.
- Scope публикации: `universe-places:write` (дефис).
- Версия Jest Roblox: 3.20.1 — а не 3.8.0/3.10.0.
- Script Sync: страница без beta (с 24.06.2026), туториал coding-harness устарел.
- Configs — BETA, Experiments — EXPERIMENTAL (в ранних заметках стабильность была не указана); два разных API рестартов (`:restartServers` и `server-management`).
- Нет единого официального launch-checklist; публикационные требования разбросаны по страницам.
- MCP: `set_active_studio` удалён 19.08.2026, каждый вызов требует `studio_id` — см. `mcp-studio.md`.

**Открыто (не проверено):**
- Живой прогон всей цепочки (publish Saved → Jest → publish → restart → config) — нужен ключ и тестовая вселенная.
- Что делает API-публикация с уже существующими unions/SurfaceAppearance/EditableMesh/BaseWrap (сохраняет или стирает).
- Совпадает ли `gameId` у legacy-эндпоинтов иконки/thumbnails с Universe ID (вероятно, да).
- Точный смысл `activate` и обход ли он требований релиза (вероятно, нет).
- Нужен ли `LoadStringEnabled` для Jest внутри Luau Execution.
- Квоты `generate_mesh`/`generate_material`, сроки модерации ассетов, цена кредитов Roblox Build — не опубликованы.
- Появление публичного эндпоинта создания universe/place.
- Android Remote Attestation: как разработчик включает проверку — в документации не найдено.

**Дополнительно (контекст на окт. 2026):** Roblox Build — мобильный AI-создатель простых 2D/2.5D игр с публикацией в одно касание (страница документации от 11.06.2026) — не производственный путь для нашего пайплайна (экспорта кода нет), но конкурент для тривиальных форматов вроде кликеров.

Источники: create.roblox.com/docs/ai/build; сводки раундов исследования (09_round2/3, 15_round1).
