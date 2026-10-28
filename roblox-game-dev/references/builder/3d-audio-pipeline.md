# Пайплайн 3D-ассетов и аудио: как ассет и звук физически попадают в игру и что при этом ломается

**Зачем этот файл.** Рабочий справочник Builder-роли (и фактура для Advisor): как провести меш из Blender / ИИ-генератора / Creator Store в Studio без поломок масштаба, цвета и производительности; как перекрасить готовые меши; какие ИИ-генераторы 3D и аудио можно использовать коммерчески; как устроить звук от источника до микса (шины, ducking, лимиты) и как озвучить события sim/pet-игр. Визуальный канон (стили, масштаб, питомцы, яйца) → `3d-asset-canon.md`; арт-дирекция, свет, UI, Audio API кратко и квоты → `art-ui-audio.md` (§12-14); анимация → `animation.md`. Здесь только то, чего там нет, или то, что там нужно уточнить.

**Актуально на: октябрь 2026** (снимок доков Roblox 24.10.2026, раунды исследования 27.10.2026). **Перепроверять (самое волатильное):** цены, планы и лицензии ИИ-сервисов (Meshy, Tripo, Rodin, Suno, ElevenLabs, Udio); квоты ИИ-генерации Roblox (числа не публикуются); правила публичности аудио; условия SFX-библиотек; статус `GenerateMeshAsync` (помечен на будущее удаление); SLIM (новое).

Метки: `[док]` официальная документация Roblox (репозиторий creator-docs); `[URL]` внешний источник; `оценка` / `вывод` = моя рабочая эвристика без прямого источника; `[вендор]` = маркетинг производителя; H/M/L = уверенность.

## Оглавление
1. [Главные правила](#1-главные-правила)
2. [Blender → Studio: настройки импорта](#2-blender--studio-настройки-импорта)
3. [Жёсткие лимиты и спецификации 3D](#3-жёсткие-лимиты-и-спецификации-3d)
4. [Vertex colors и MeshPart.Color](#4-vertex-colors-и-meshpartcolor)
5. [Рецепт: перекрасить готовые меши в Studio](#5-рецепт-перекрасить-готовые-меши-с-вшитыми-vertex-colors-в-studio)
6. [Материалы: что выбрать](#6-материалы-что-выбрать)
7. [Коллизия, рендер, стриминг, инстансинг](#7-коллизия-рендер-стриминг-инстансинг)
8. [Бюджеты для телефона](#8-бюджеты-для-телефона)
9. [Creator Store, backdoors, Asset Privacy](#9-creator-store-backdoors-asset-privacy)
10. [ИИ-генерация 3D](#10-ии-генерация-3d)
11. [Загрузка ассетов, Open Cloud, манифест](#11-загрузка-ассетов-open-cloud-манифест)
12. [Аудио: права, загрузка, публичность](#12-аудио-права-загрузка-публичность)
13. [Архитектура звука: шины, ducking, 2D/3D](#13-архитектура-звука-шины-ducking-2d3d)
14. [Громкость и нормализация](#14-громкость-и-нормализация)
15. [Мобильный звук, память, лимит голосов](#15-мобильный-звук-память-лимит-голосов)
16. [Источники SFX и музыки: лицензии](#16-источники-sfx-и-музыки-лицензии)
17. [ИИ-аудио: условия и политика](#17-ии-аудио-условия-и-политика)
18. [Канон звука по событиям](#18-канон-звука-по-событиям)
19. [Чек-листы](#19-чек-листы)
20. [Конфликты, пробелы, что неизвестно](#20-конфликты-пробелы-что-неизвестно)
21. [Источники](#21-источники)

---

## 1. Главные правила

1. **Один меш = один импорт.** Importer не дедуплицирует: импорт целой карты даёт отдельный asset и draw call на каждую плитку. Импортируйте уникальные меши по одному, размножайте в Studio, ведите манифест `имя → assetId`. [док] H
2. **Blender: Unit System = None, 1 BU = 1 stud (1 stud = 28 см).** Импорт в Studio со Scale Unit = Studs. Для glTF/GLB пляски с масштабом не нужны; FBX только с Apply Scalings = FBX Unit Scale. [док] H
3. **Жёсткий потолок: 20 000 tris на меш**, один материал, один UV set в 0..1, watertight, без n-gons. Рабочий потолок текстуры для PBR-таблицы доков 1024². [док] H
4. **Цвет вариантов = Color / vertex color / `SurfaceAppearance.Color` на одном mesh ID**, а не новые меши и не новые текстуры (instancing → один draw call). [док] H
5. **`MeshPart.Color` умножается на vertex colors.** Серый по умолчанию тускнит всё; для авторских цветов ставьте белый. Умножение только затемняет или тонирует, ярче не сделает. [DevForum + док] M-H
6. **Colour space импортированных vertex colors не описан нигде.** Один раз калибруйте 3-цветным тест-мешем (§4.4), храните эталонную палитру.
7. **Чёрный меш после экспорта = второй/битый Color Attribute или слишком много материалов.** Держите ровно один Color Attribute (Domain Vertex, Type Color) и один материал. [DevForum 2026] M
8. **Бесплатные модели: берите меш, удаляйте все скрипты.** Модерация не гарантирует отсутствие backdoors. [док] H
9. **Ассеты (особенно аудио) загружать от группы, владеющей игрой.** Аудио приватно по умолчанию и работает только в experiences владельца-загрузчика. [док] H
10. **Для ИИ-3D и ИИ-музыки только платный коммерческий план**; Free у Meshy = публичная лицензия CC BY 4.0, у Tripo по ToS на Free права остаются у Tripo (блог говорит CC BY), Free у Suno и ElevenLabs некоммерческий. Хранить скрин плана, дату, ID генерации. [URL] M
11. **Официального бюджета «треугольники/draw calls для телефона» у Roblox нет**, есть метод: выбрать baseline-устройство и мерить Shift+F2 / F9 10-15 минут. Цифры в §8 помечены как оценка. [док] H
12. **В новом коде аудио: `AudioPlayer` + `Wire` + `AudioEmitter/AudioListener/AudioDeviceOutput`.** `Sound/SoundGroup/SoundEffect` discouraged. Клик по аудио в Toolbox вставляет legacy `Sound`: копируйте только ID. [док] H
13. **Шины через `AudioFader`**: Music / SFX / UI / Ambience → Master → `AudioLimiter` → `AudioDeviceOutput`; громкость по категориям в настройках игрока = `Fader.Volume`. (вывод из доков)
14. **Нормализуйте ассеты до загрузки по категориям**, потом подстраивайте `Volume`. Официальных LUFS нет. (оценка)
15. **Тест на динамике телефона обязателен.** Бас < 120 Гц на нём не слышен, всё важное дублируйте визуалом. [док] H
16. **Не полагайтесь на ИИ-политику Roblox: официального заявления о загрузке ИИ-мешей и ИИ-музыки нет.** Действуют общие гарантии прав и Community Standards; ответственность на вас.
17. **Ранее одобренное аудио может быть позже снято** (жалобы сообщества на автодетект). Храните исходники и план замены.
18. **GenerationService:** для нового кода `GenerateModelAsync`; `GenerateMeshAsync` помечен на будущее удаление. Квоты не опубликованы.

---

## 2. Blender → Studio: настройки импорта

| Шаг | Настройка | Источник |
|---|---|---|
| Формат | `.fbx`, `.gltf/.glb`, `.obj`. FBX и glTF несут несколько мешей, иерархию, PBR, cages, риги, анимацию, **vertex colors**. OBJ только геометрия | `studio/importer.md` [док] H |
| Единицы | Scene > Units > **Unit System = None**, Rotation = Degrees → 1 BU = 1 stud | `art/blender.md`, `physics/units.md` [док] H |
| Оси | Studio Y вверх, Blender Z вверх. Экспорт: Forward = Z Forward, Up = Y Up; на импорте World Forward = Front, World Up = Top, **Scale Unit = Studs** | `art/blender.md` [док] H |
| FBX scale | Export > Transform > **Apply Scalings = FBX Unit Scale** (рекомендовано). Альтернативы: Scale 0.01 при экспорте или Unit Scale 0.01 в сцене (второе ломает камеру и модификаторы). **glTF без этих плясок** | `art/blender.md#adjust-scale-fbx` [док] H |
| FBX прочее | Path Mode = **Copy** + **Embed Textures**; **Add Leaf Bones = off**; **Bake Animation = off**, если анимации нет | `art/modeling/export-requirements.md` [док] H |
| Прямая передача | Официальный open-source **Roblox Blender plugin** (Open Cloud) шлёт объекты в Studio без файла | `art/modeling/roblox-blender-plugin.md` [док] H |
| Importer / General | **Import Only As Model** (вкл.), **Upload to Roblox** (вкл.; на итерациях выключайте, чтобы не плодить копии), **Import as Package** (для переиспользуемого), **Creator = группа игры**, **Set Pivot to Scene Origin** (вкл.), **Anchored** (выкл.) | `studio/importer.md` [док] H |
| Importer / Object | **Use Imported Pivot** (вкл.), **Make Double Sided** (выкл.; дороже, только листва/плоскости), **Ignore Vertex Colors** (выкл.), Merge Meshes (выкл.), Invert Negative Faces | там же [док] H |
| Presets | Studio Default / Last Imported; свой пресет можно сделать default | там же [док] |

**Pivot (вывод):** pivot модели = origin сцены Blender; pivot меша = его origin (Use Imported Pivot). Пропсы на земле: origin в центре основания. Вращающиеся и парящие пикапы: центр масс. Питомец под follow-логику: origin у основания ног.

**Имена-триггеры:** `_Att`, `_OuterCage`, `_InnerCage` в именах превращаются в Attachment/WrapTarget/WrapLayer. Обычные пропсы так не называть. [док] H

**Чек-лист «перед экспортом из Blender»:** (1) Apply All Transforms (Ctrl+A), scale 1,1,1; (2) нормали наружу, нет non-manifold и дыр; (3) один материал, один UV set; (4) ровно один Color Attribute (если нужны vertex colors); (5) имена латиницей, уникальные; (6) origin по правилу выше; (7) экспорт glTF (или FBX с настройками выше).

Источники: create.roblox.com/docs/studio/importer, /art/blender, /art/modeling/export-requirements, /art/modeling/gltf-export, /physics/units.

---

## 3. Жёсткие лимиты и спецификации 3D

| Параметр | Значение | Источник |
|---|---|---|
| Треугольники на меш | **≤ 20 000** (жёсткий) | `art/modeling/specifications.md` [док] H |
| Геометрия | watertight, квады без n-gons, ненулевой объём; для marketplace-валидации ещё: центр в origin, не слишком тонкий, нет zero-area triangles | specifications.md, `marketplace/validation-system.md` [док] H |
| Материал / UV | **один материал на меш**, **один UV set**, всё в 0..1, перекрытия разрешены | texture-specifications.md [док] H |
| Форматы текстур | png, jpg, tga, bmp | там же [док] H |
| Разрешение | загрузка до 4096²; PBR-таблица доков **максимум 1024²** (на 8×8×8 юнитов; 512² на 4×4×4; 256² на 2×2×2). Рабочий потолок 1024² | там же [док] H |
| Texel density | Parts: 1024² на грань 8×8 stud; Terrain: 512² на 8×8 | там же [док] |
| Память текстуры | зависит от числа пикселей, не от размера файла: 1024² = 4× памяти 512². Сжатие и удаление альфы до загрузки память не уменьшают (транскодируется в фиксированный формат) | `performance-optimization/improve.md` [док] H |
| PBR-карты | Albedo RGB 24-bit; Normal RGB **только OpenGL (tangent space)**; Roughness/Metalness/Emissive Mask 8-bit grayscale | texture-specifications.md [док] H |
| Кости | ≤ 4 влияния на вершину; не нагружать Root; freeze scale 1,1,1; одна анимация на экспорт | specifications.md [док] H |
| Лимит вершин | числового лимита нет; ограничение через 20k tris | пробел |
| Open Cloud | 20 MB на вызов; изображения < 8000×8000 | `cloud/guides/usage-assets.md` [док] H |

Albedo = «little to no lighting»: вшитые тени и свет из ИИ-текстур вычищать (§10.4).

---

## 4. Vertex colors и MeshPart.Color

### 4.1 Что известно
- **Создание в Blender (официально):** Data > Color Attributes > **+**, **Domain = Vertex, Data Type = Color**; в Viewport Shading Solid > Color = Attribute; заливка выделенного: Ctrl+X в Vertex Paint. Сохраняется при FBX/glTF-экспорте. «Lightweight»-окраска: меньше памяти текстур и draw calls, сочетается с Materials, MaterialVariant, SurfaceAppearance. [док `art/blender.md#vertex-painting`] H
- **Импорт:** Importer > Object > **Ignore Vertex Colors** по умолчанию выключен (цвета читаются). [док] H
- **Умножение:** vertex color «will be multiplied against the BrickColor or Color property of the meshPart»; новый MeshPart серый (Medium Stone Grey 163,162,165), поэтому для точных цветов `Color = 255,255,255`. [DevForum «Vertex Colored Meshes using Blender and Studio», https://devforum.roblox.com/t/3050119] M-H
- **С SurfaceAppearance:** в режиме Overlay (по умолчанию) `MeshPart.Color` проступает там, где альфа ColorMap прозрачна, и vertex colors модулируют эти пиксели. `SurfaceAppearance.Color` тонирует ТОЛЬКО ColorMap, не `MeshPart.Color`; TintMask не зависит от `MeshPart.Color`. [док `art/modeling/surface-appearance.md`] H
- **Свойство `VertexColor`** есть у `DataModelMesh` (SpecialMesh/FileMesh, Vector3, «changes the hue of a mesh's texture»). У `MeshPart` в API-справке его **нет**: не скриптуйте `MeshPart.VertexColor`. [док reference] M-H (поправка к старым заметкам)
- Для аватарных предметов (UGC) не-белые vertex colors дают ошибку валидации; для игровых ассетов нормально. [док `marketplace/validation-system.md`] H

### 4.2 Что это значит (математика умножения)
Итоговый цвет вершины ≈ vertex × Color покомпонентно (R, G, B раздельно). Следствия: (a) белый Color не меняет vertex; (b) Color никогда не делает ярче: белая вершина (1,1,1) × Color (0,0,1) = синяя, красная (1,0,0) × синий (0,0,1) = чёрная; (c) тонировка работает тем лучше, чем светлее и ненасыщеннее базовая палитра. (вывод)

### 4.3 Ловушки
1. **Тусклые цвета** = забыли белый `Color` (серый дефолт). Первое, что проверять.
2. **Чёрный меш:** второй/битый Color Attribute (после Join или копирования мешей между .blend) или куча материалов (чаще в FBX). Лечение: удалить лишние материалы, удалить лишний атрибут кнопкой «−», оставить один. [DevForum 4734973, 13-15.07.2026, комьюнити] M
3. **Ignore Vertex Colors** включён → цвета не видны.
4. **Colour space:** в доках нет; в Blender/glTF/three.js «вершинные цвета темнее/бледнее» обычно путаница sRGB и linear ([пример](https://blenderartists.org/t/vertex-color-exported-by-gltf-glb-is-darker/1199970)). Как Studio декодирует цвета, Roblox не сообщал: **калибровать тестом** (§4.4).
5. Join/Merge объектов может создать второй атрибут; после объединения проверять список атрибутов.

### 4.4 Калибровка цвета (5 минут, делать один раз на проект)
1. В Blender создать куб с гранями, закрашенными vertex colors: #808080, #FF0000, #00FF00, #0000FF, и ваши 3-4 ключевых цвета палитры.
2. Экспорт glTF (потом тот же куб через FBX, если используете оба), импорт в Studio, `MeshPart.Color = 255,255,255`, Material = SmoothPlastic или Plastic.
3. Рядом поставить Part с теми же hex в `Color` (тот же Material) при том же освещении.
4. Сравнить: совпало → ничего не делать. Отличается систематически (темнее/светлее) → записать поправку (например гамма-коррекция палитры в Blender перед покраской) и сохранить «палитровый лист» в проекте.
5. Повторить при смене Lighting / Technology / формата экспорта.

Источники: create.roblox.com/docs/art/blender#vertex-painting, /studio/importer, /art/modeling/surface-appearance; devforum.roblox.com/t/3050119; /t/4734973.

---

## 5. Рецепт: перекрасить готовые меши с вшитыми vertex colors в Studio

**Задача:** есть меши (купленные, сгенерированные, из старого проекта) с вшитыми vertex colors; нужны другие цвета или набор вариантов (редкости, команды, сезоны).

**Шаг 0. Диагностика (1 минута).** Вставьте меш, выставьте `Color = 255,255,255`. Если цвета тусклые или не те — вот ваш реальный исходник. Если чёрный — §4.3 п.2 (в Studio не лечится: вернуться в Blender).

**Шаг 1. Тонировка через `MeshPart.Color` (в Studio, без перезагрузки).** Цвет умножается, поэтому:
- хотите слегка сменить оттенок/тепло/холод всей модели: ставьте **почти белый тинт**, например тёплый 255,235,200, холодный 200,225,255, «ночной» 150,160,200;
- хотите затемнить: серый (190,190,190 → 75%);
- насыщенные цвета (255,0,0) убьют остальные каналы: красный тинт оставит только красную составляющую.
Вариации редкости: общий mesh ID, разные `Color`-тинты (instancing сохраняется). Лестницу и пороги → `3d-asset-canon.md` §5.2 и §8.

**Шаг 2. Когда тинта мало.** Признаки: нужна смена оттенка отдельных частей (глаза, шерсть, броня), а не всей модели; исходная палитра насыщенная; нужны цвета ярче исходных. Тогда один из путей:

| Путь | Когда | Цена |
|---|---|---|
| A. Blender: перекрасить Color Attribute и ре-экспорт | палитра фиксирована, вариантов мало (1-3) | новый mesh ID на вариант → +1 draw call на вариант; время |
| B. Blender: привести вшитые цвета к «светло-серой базе» (оттенки яркости), потом тинтить `Color` в Studio | нужно много вариантов цвета | один раз перекрасить, дальше без ре-экспорта |
| C. `SurfaceAppearance`: серый ColorMap + `SurfaceAppearance.Color` тинт | нужен детальный рисунок + много цветов | текстура 512²-1024²; доки: тинт `SA.Color` «does not affect performance»; ключи инстансинга по доке: тот же mesh + идентичный SurfaceAppearance (или текстура), `.Color` как ключ не упомянут — при сотнях вариантов мерить Draw (scene) в Shift+F2 |
| D. Material + Color на Parts вместо меша | простые формы | меньше художественности, зато дёшево |

**Шаг 3. Если путь A/B.** Blender: Vertex Paint (кисть Average/Mix) или Attribute > Hue/Saturation/Value на Color Attribute (Geometry Nodes bake) или заново Ctrl+X по граням. Оставить ровно один Color Attribute. Экспорт glTF, импорт Studio с Creator = группа, Import as Package, `Color` белый. Проверить Shift+F2 (draw calls) и калибровку (§4.4).

**Шаг 4. Проверки:** на телефоне цвета читаются при контраст-проверке (силуэт, палитра стиля); нет чёрных мешей; число уникальных mesh ID не выросло лишнее; манифест обновлён.

**Памятка:** перекраска `Color`-тинтом = быстро и бесплатно, но потолок по яркости = исходная палитра; поэтому новую палитру для питомцев сразу красить «светлой базой» (§1 п.4, §4.2).

---

## 6. Материалы: что выбрать

- **SurfaceAppearance** = PBR для UV-меша (ColorMap, NormalMap, RoughnessMap, MetalnessMap, EmissiveMask + `Color`, `AlphaMode`). Перекрывает `MeshPart.TextureID`. AlphaMode: Overlay (по умолчанию), Opaque, Transparency, TintMask. [док] H
- **MaterialVariant** (в `MaterialService`) = тайлящийся PBR-материал **+ физика** (density, friction, elasticity); на Part/MeshPart либо как override базового Material места. При наличии и SA, и MV: текстуры из SA, физика из MV. [док] H
- Built-in Materials «используют гораздо меньше памяти, чем кастомные текстуры» → для обычных поверхностей Material + Color. [док `design.md`] H
- Генераторы: **Material Generator** (текст → MaterialVariant), **Texture Generator** (Fast = 1K diffuse, Quality = 4K PBR; через Assistant `/generate_texture` и Studio MCP). Квоты не опубликованы. [док] H

**Рецепт по жанрам (оценка по докам):**

| Жанр | Рецепт |
|---|---|
| Sim / pets (кубо-chibi) | Material (Plastic/SmoothPlastic/Neon) + Color + vertex colors; SurfaceAppearance только на hero (яйцо, босс, дорогой питомец); пол/стены: trim sheet 1024² + MaterialVariant |
| Tycoon | модульный кит + trim sheet на тему, MaterialVariant для пола/стен, Parts + Material для здания |
| Obby | почти только Parts с Material и MaterialVariant-override; меши редко |
| Хоррор / PBR | SA на hero, 3-6 уникальных 1024² на зону; тени и свет дороже геометрии |

---

## 7. Коллизия, рендер, стриминг, инстансинг

- **CollisionFidelity** [док `parts/meshes.md`, `improve.md`] H: Box (мелкое, неинтерактивное), Hull (выпуклые), Default (аппроксимация), PreciseConvexDecomposition (самый дорогой, считается долго), **Tunable** (+`CollisionPrecision`). Для декора: `CanCollide=false` (+ `CanQuery/CanTouch=false`) и Box/Hull, **потому что геометрия коллизии всё равно хранится в памяти**. Для больших сложных объектов — собственные коллайдеры из Parts.
- **RenderFidelity** (Automatic по умолчанию): < 250 studs высшее, 250-500 среднее, ≥ 500 низшее. `Precise` на многих мешах = типичная проблема. [док] H
- **StreamingEnabled** по умолчанию в новых местах; рекомендация доков: `ModelStreamingBehavior = Improved`, `StreamOutBehavior = Opportunistic` («значительно снижает память, помогает от OOM»), `StreamingMinRadius = 64`, `StreamingTargetRadius = 1024`. Критичные модели: `ModelStreamingMode = Persistent`. Для tycoon: база игрока Persistent/PersistentPerPlayer (оценка). [док `workspace/streaming/index.md`] H
- **SLIM** (облачная транскодировка в composite meshes с LOD): `Workspace.EnableSLIMAvatars` + `Model.LevelOfDetail = SLIM`; нужен StreamingEnabled, сохранённое в облако место, Team Create. Новое (2026): тестировать на целевом устройстве. [док `workspace/streaming/slim.md`] H
- **Инстансинг:** одинаковый `MeshContent` собирается в один draw call, если одинаковы SurfaceAppearance (либо TextureContent), либо материалы. Следствие: **вариации = Color / vertex color на одном mesh ID.** [док `improve.md`] H
- **Draw-call ловушки:** Decals/Textures/ParticleEmitters плохо батчатся; частичная прозрачность → overdraw (оставляйте 0 или 1); много теней; несколько копий одного меша с разными ID. [док] H
- **Packages** (`projects/assets/packages.md`): auto-updating, sharable, против дубликатов с разными ID. Open Cloud загружает Model-файлы как packages. [док] H
- Sprite sheets для UI через `ImageRectOffset/Size`. [док] H

---

## 8. Бюджеты для телефона

### 8.1 Что официально известно [док `performance-optimization/test-on-hardware.md`, `design.md`, `identify.md`, `production/analytics/performance.md`]
- **Аудитория устройств (по докам Roblox):** Android ≈ **65%** игроков типичной игры; из них ≈ 60% имеют **2-4 ГБ RAM**, ≈ 35% 4-8 ГБ, ≈ 5% > 8 ГБ; **> 50% всех игроков** на устройствах **10 000-20 000 баллов Passmark**. Рекомендованные тестовые устройства: Infinix Smart 9, Motorola Moto G05, Oppo A18, Amazon Fire HD 10 (2023), Samsung Galaxy S22 Ultra. H
- **Единого бюджета нет.** Метод: выбрать «baseline» устройство, смотреть Shift+F2 (Render, Summary), F9 Memory. Пример в доках: «stay below 1,000 draw calls and 1,000,000 triangles» **для их примера baseline-устройства**, не рекомендация. Эмулятор Studio неточен по памяти (клиент+сервер в одном процессе); Roblox не получает всю RAM устройства. H
- **Диагностика памяти ассетов (Developer Console, PlaceMemory):** `GraphicsMeshParts`, `GraphicsTexture`, `Sounds`. **Crash rate выше 2-3% → расследовать**; в Performance Dashboard есть Client memory usage по типам устройств и «процент доступной памяти» (линия Android около 100% = большинство под риском OOM). H
- **Сервер:** RAM ≈ `6.25 GiB + 100 MiB × пиковое число игроков` (30 игроков ≈ 9.18 GiB), держать < 50%; не уменьшается при уходе игроков. H
- **Кадр:** 60 FPS = 16.67 мс; тяжёлые задачи резать на куски (пример 5 мс на кадр). Тест 10-15 минут непрерывно (thermal throttling). H
- Самый действенный рычаг по памяти ассетов: **instance streaming**. H

### 8.2 Якоря сообщества (мнение, mid-2024, не официально)
DevForum «Real World Building and Scripting Optimization» (https://devforum.roblox.com/t/3127146): цель ≥ 2 ГБ телефоны, «Quality 10 @ 60 FPS на большинстве телефонов», **≤ 500k tris и ≤ 500 draw calls в сцене** (300k/300 карта + 200k/200 игроки-питомцы-монеты-эффекты), клиентская память **< 1.3 ГБ**, сеть **< 50 KB/s**, UI тревожно выше ~150 draw calls; пример: 100+ частей домика и 12 DC → 6 мешей и 6 DC. M

### 8.3 Рабочая таблица (оценка = якоря выше + канон; **заменить собственными замерами на baseline-телефоне**)

| Жанр | Видимые tris | Draw calls (сцена) | Уникальных 1024² на зону | Размер ассета | Комментарий |
|---|---|---|---|---|---|
| Sim с питомцами | ≤ 250-400k | ≤ 300-500 | 1-3 | питомец 800-3000 tris, яйцо 500-2000, монета 100-400 | расход = число видимых питомцев × игроков; один mesh ID + Color-варианты |
| Tycoon | ≤ 200-350k | ≤ 300-450 | 2-4 (кит + trim sheet) | модуль 300-1500, дропер 200-800 | базы 6-12 игроков: общий кит, Persistent только своя база |
| Obby | ≤ 100-250k | ≤ 150-300 | 0-2 | детали 50-500 | риск = длина карты и прозрачность, не tris |
| Хоррор / PBR | ≤ 400-700k | ≤ 500-800 | 3-6 | hero 3-8k | тени и свет дороже геометрии |

«Чем меньше уникальных мешей, тем лучше» [док]. Реальный потолок определяет ваше baseline-устройство, а не эта таблица.

Источники: create.roblox.com/docs/performance-optimization/{design,identify,improve,test-on-hardware}, /production/analytics/performance, /workspace/streaming; devforum.roblox.com/t/3127146.

---

## 9. Creator Store, backdoors, Asset Privacy

- **Что бесплатно в Creator Store:** Models, MeshParts, Decals, **audio (только SFX публичные)**. Условия: соблюдать Community Rules, ToS, IP guidelines. Платные Models и Plugins продаются за **USD** (Model $2.99-$49.99; Plugin $4.99-$249.99), продавец получает 100% net; Robux не поддерживается. Creator Store Terms (Help Center, п. 1.5): лицензия на покупку = использовать ассет «in Roblox Studio» и «in Experiences» согласно User/Creator Terms; про модификацию, редистрибуцию, отзыв ассета, бесплатные ассеты, ИИ и аудио документ молчит. Публиковать/продавать можно только ассеты для Studio. [док `production/creator-store.md`] M-H
- **Зависимости:** композиции можно раздавать с Open Use зависимостями; нельзя с Restricted-зависимостями не ваших. [там же]
- **Asset Privacy (opt-in, 2026):** новые **Images, Decals, Meshes** по умолчанию Open Use; в Creator Dashboard > Settings > Advanced можно включить создание как *Restricted*; Open Use необратим; права выдаются друзьям/группам/играм; для аватарных предметов зависимости должны быть Open Use. **На Audio, Video, Models, MeshParts, Animations, Packages не влияет.** Совет: включить для группы игры, чтобы чужие не вставляли ваши меши/текстуры по ID (вывод). [док `projects/assets/privacy.md`] H
- **Backdoors** [док `scripting/security/third-party-vulnerabilities.md`] H. Чек-лист:
  1. Toolbox помечает модели со скриптами; для визуальных ассетов **удалить все Script/LocalScript/ModuleScript** (или `Disable Scripts`).
  2. Если скрипты нужны: `Workspace.SandboxedInstance = Experimental`, у модели `Sandboxed = true`, минимум `Capabilities`; не давать **Network, DataStore, AssetRequire, CapabilityControl, LoadString**.
  3. Искать обфускацию, `require(число)`, `getfenv/loadstring`, `HttpService`, длинные пустые строки, прячущие код за краем экрана.
  4. Популярность и рейтинг не гарантия.
  5. Берите меш/текстуру, префаб пересоберите сами; пройдите intake-QA (§19).
  6. Авто-sandbox всех Creator Store ассетов — «в будущем», пока не полагаться.
- Чужие дубликаты тяжелы: free models тихо раздувают ReplicatedStorage и время загрузки. [док `improve.md`] H
→ см. также `code-architecture.md` (безопасность) и `art-ui-audio.md` §14.

---

## 10. ИИ-генерация 3D

### 10.1 Решение: чем генерировать
| Задача | Рекомендация | Почему |
|---|---|---|
| Блокаут, фон, средний план, прототип | Roblox `/generate_mesh` в Assistant (или `GenerateModelAsync`) | бесплатно в Studio, сразу пайплайн Roblox, модерация встроена; квоты не опубликованы |
| Hero-питомец, тематический ассет, редкий предмет | Ручная доводка в Blender (или внешний ИИ на платном плане + доводка) | единый стиль, топология, UV |
| Много однотипных пропсов | Модульный кит + trim sheet вручную | дешевле по памяти, воспроизводимо |
| Текстура на свой меш | Texture Generator (Fast 1K / Quality 4K PBR) | для stylized лучше вообще vertex colors + Material |

### 10.2 Инструменты Roblox (первая сторона) [док] H
| Инструмент | Что | Лимиты |
|---|---|---|
| **Assistant `/generate_mesh`** | Текстурированный меш из текста **или** картинки (не обе); можно выделить Part как bounding box; опциональный **max triangle count, по умолчанию 10 000**; сегментация до **8 частей** с планом имён | квоты не опубликованы |
| **`/generate_procedural_model`** | Параметрические модели (ProceduralModel) | **50 за скользящие 24 ч** |
| **`GenerationService:GenerateModelAsync`** (схемы Car5, Body1, SchemaDefinition) | In-experience генерация (Cube 3D); ошибки: Rate limit exceeded (за минуту), Moderation failed, Character limit exceeded, Service overloaded | числа не опубликованы. **`GenerateMeshAsync` помечен «scheduled for future deprecation»** |
| **Texture / Material Generator** | Текстуры и материалы по тексту/картинке | не опубликованы |
| **Roblox Build** (ai/build) | Генерация целой игры; бесплатные промпты в день (число не указано), Robux-кредиты не сгорают; для 9+ с age check; раскатка поэтапно, начиная с Новой Зеландии | не инструмент для ассет-пайплайна, но ускоритель прототипа |

Правило планирования: **считайте генерацию Roblox ограниченным удобством, а не конвейером** (числа не опубликованы; вывод). Сгенерированные объекты реплицируются всем игрокам, размер произвольный → масштабировать скриптом (`ScaleTo`) и `Anchored` для многочастных [док `parts/model-generation.md`].

**Политика ИИ внутри игры** [док `generative-AI.md`, `content-maturity.md`] H: весь вход/выход Roblox API (GenerationService, TextGenerator) проходит модерацию; для не-Restricted игр модели ориентированы на All Ages, без дескрипторов вроде Horror; если игроки вызывают ответы модели (включая 3D-генерации), **раскрыть в Content Maturity**; «extended interactions» (чат-бот как суть игры или память между сессиями) → **Restricted (18+)**; видимое уведомление «This is an AI-powered conversation, not human. It may make mistakes.» и перенаправление к кризисным ресурсам; при третьих сторонах ответственность на вас. **ИИ как инструмент разработки в Content Maturity не учитывается.**

### 10.3 Внешние генераторы (снимок окт 2026, **проверять перед покупкой**)
| Сервис | Планы | Лицензия (суть) | Источник / уверенность |
|---|---|---|---|
| **Meshy** | Free $0 (100 кредитов); Pro $20; Premium $40; Ultra $100; Studio $70/команда | **Free = CC BY 4.0** (коммерческое с атрибуцией, публично); платные = «private & customer owned». Roblox Bridge, Remesh, PBR ≤ 1024² — платные функции [вендор] | meshy.ai/pricing M |
| **Tripo** | Free (ограниченный пробный лимит); Pro $19.90 (3 000 кредитов, до ~120 моделей); Max $89.90 (25 000, до ~1 000); API 1 цент/кредит | **ToS (tripo3d.ai/terms): п. 5.2.1 Free Users «Tripo retains all rights»; п. 5.2.2 Paid «generally have all rights»; п. 3.2 коммерческое использование outputs разрешено; в ToS нет CC BY 4.0.** Блог (маркетинг) говорит «Free = public CC BY 4.0»; платные = приватные + без атрибуции. Для игры только платный план | tripo3d.ai/terms + блог M-H |
| **Hyper3D Rodin** | Free, Creator, Business, Education (цены см. страницу) | «Unlimited export and any use» входит в **Creator и выше**, **на Free его нет**; Business добавляет коммерческую лицензию для ChatAvatar; ToS (hyper3d.ai/legal/terms) п. 2: экспорт «for private or commercial use depending on your subscription plan»; п. 5(b) для Rodin использование Output не ограничено сверх Agreements; **владение не заявлено** (права = лицензия, без гарантии copyrightability); результат можно сделать private | hyper3d.ai/pricing + /legal/terms M-H |
| **Pic2Mesh** (плагин сообщества, TripoSR) | бесплатно | на ответственности автора плагина | DevForum 4645458 L-M |

Вывод для Roblox: коммерческая игра = **платный план** + скрин плана, дата, ID генерации. Free-результат публичен и требует атрибуции (CC BY) — не подходит для эксклюзивных hero-ассетов. Вендорская цифра «21K tris на меш» противоречит жёсткому 20k в доках → принимать **20k**.

### 10.4 Пайплайн очистки ИИ-меша (док + вывод)
1. **Лицензия:** платный/private план, скрин, дата.
2. **Импорт в Blender** (glTF/GLB): Unit System None, масштаб под аватар (R15 ≈ 5 studs; питомец 0.25-0.4 аватара, см. `3d-asset-canon.md` §4).
3. **Топология:** убрать внутренние/плавающие вершины, non-manifold, дыры; watertight; Remesh/Decimate до бюджета (питомец 800-3000, пропс 150-1200 tris: оценка). Сохранить силуэт и лицо.
4. **UV/текстура:** один UV set в 0..1, один материал; запечь/пересохранить albedo ≤ 1024² (hero) или 512²/256² (массовые); **убрать вшитый свет и тени из albedo**; normal только OpenGL; для stylized чаще лучше **без текстуры** (vertex colors + Material; §5).
5. **Pivot, масштаб, имя:** origin по §2; Apply Transforms; имена латиницей.
6. **Импорт в Studio:** Scale Unit Studs, Creator = группа, Import as Package; `Color` белый (если vertex colors), `CollisionFidelity` Box/Hull или CanCollide=false, `RenderFidelity` Automatic.
7. **Intake-QA** (§19.1).
8. **Модерация:** меш идёт в moderation queue; пока не одобрен, виден только вам.

### 10.5 Политика Roblox в отношении ИИ-ассетов
- Отдельного запрета или разрешения на загрузку мешей/текстур от сторонних ИИ в доках **нет** (проверено: docs, IP guidelines, Marketplace docs, DevForum). Действуют права на контент, Community Rules, IP guidelines; модифицированные копии (в т.ч. сделанные ИИ) всё равно могут быть заявлены как нарушение. [док IP guidelines] H
- Данные creators используются для обучения моделей Roblox, есть opt-out [док `ai-data-sharing.md`]. Платные Models участвуют только по opt-in.

---

## 11. Загрузка ассетов, Open Cloud, манифест

- Studio/Asset Manager/Dashboard: импорт идёт в moderation queue; до одобрения виден только владельцу; потом доступен во всех проектах владельца. [док] H
- Стоимость: загрузка мешей/изображений/аудио из Studio бесплатна в доках (платные upload fees только для публикации Marketplace/UGC-предметов). Бесплатность — отсутствие упоминания платы, не явная гарантия. [док] M
- **Open Cloud Assets API** (`POST https://apis.roblox.com/assets/v1/assets`, `x-api-key`, права `assets` Read/Write; OAuth `asset:read/write`) [док `cloud/guides/usage-assets.md`] H:
  - 1 ассет на вызов, **≤ 20 MB**.
  - Model: `.fbx .gltf .glb .rbxm .rbxmx` (загружается как package). **Mesh: только контент из Asset Delivery API** (обычные меши через Model/Importer). Image/Decal: png/jpeg/bmp/tga, < 8000×8000. Audio: mp3/ogg/wav/flac, до 7 мин; **Audio и Image обновлять нельзя** (только новый ассет). Video до 5 мин, 20/день для 13+ ID-verified.
  - Update Asset — beta endpoints.
- **Конфликт квот аудио:** таблица Open Cloud (100/мес с ID, 10 без) устарела против страницы Audio assets (**2 000 / 100 за 30 дней**). Принимать audio-страницу. [док] H
- **Скрипт-пайплайн (вывод):** Blender → glTF → Open Cloud Create Asset (Model) → ждать операцию → записать asset ID в манифест. Манифест `assets.json` (`имя → assetId`, версия, дата, источник/лицензия, плечо ИИ-плана) обязателен, раз нет дедупликации. Детали CI и ключей → `project-setup.md`.
- Время модерации официально не публикуется.

Источники: create.roblox.com/docs/cloud/guides/usage-assets, /projects/assets/manager, /marketplace/publish-to-marketplace.

---

## 12. Аудио: права, загрузка, публичность

Квоты, форматы, шаги загрузки в таблице → `art-ui-audio.md` §12.2 (не дублирую). Здесь только то, что меняет решения.

- **Приватность:** с 22.03.2022 загруженное аудио private; работает только в experiences владельца-загрузчика (user или group) + тем, кому выданы права; лицензированный каталог Roblox публичен. Asset Privacy 2026 на Audio не влияет. [DevForum 1701697; док] H
- **Классификация:** при загрузке аудио автоматически = *sound effect* или *song*. **SFX можно сделать публичными (Creator Store), музыку публичной сделать нельзя** [док `audio/assets.md`; DevForum июль 2026, staff: «distribution supported only for sound effects, not music»; по комьюнити предел SFX около 10 с] M-H.
- **Окт 2025, staff:** проигрывание чужого загруженного аудио (boombox) «intentionally not supported… not planning foreseeable future». Легальные пути: Creator Store audio, DistroKid-партнёрство, публичные SFX, выдача прав. H
- **Следствие:** все звуки загружать от группы-владельца; при смене группы выдать права заново; не использовать чужие «song ID»; тестировать в опубликованной игре под другим аккаунтом (вывод).
- **Лицензия, которую вы даёте** (Audio Upload License Agreement): бессрочная всемирная лицензия Roblox на передачу, воспроизведение, синхронизацию, производные, с правом сублицензии; вы гарантируете права/оплаченные лицензии (в т.ч. public performance), **отзываете аудио по окончании лицензии**, indemnity в пользу Roblox; про ИИ-аудио там ничего нет; платы нет. [URL en.help.roblox.com/.../23359485439124] H
- **Модерация:** очередь, автодетект авторских прав; «bypassed» запрещён; повторные нарушения → эскалация банов. **Одобренное аудио может быть снято позже** (жалобы сообщества, без ответа staff; возможные причины: трек уже в библиотеке Creator Store, загружен без флага распространения, пересечение с другим аплоадом). Храните исходники. [DevForum 4089305] L-M
- **Витрина песен:** при ID-verified, принятых Audio Terms, пройденной модерации и порогах песня может показаться на странице игры (превью 15 с); есть поле Song Artist. [док] H
- **Лицензированная музыка Roblox:** Creator Store > Audio, **> 100 000 SFX и треков партнёров** (APM, Monstercat и др.), бесплатно для игр; ID через Copy Asset ID. Монстеркэт-модуль сообщества — не лицензионное заявление; «250 APM-треков на игру» не подтверждено. **Риск:** правообладатель может убрать трек → храните резерв. H/L
- **ID-verify** стоит делать ради квоты 2 000/30 дней и витрины песен.

---

## 13. Архитектура звука: шины, ducking, 2D/3D

**API:** `AudioPlayer` (`Volume` 0-10, `PlaybackSpeed` 0-20 = питч, `Looping`, `LoopRegion`, `PlaybackRegion`, `AutoLoad`, `AutoPlay`, `IsReady`, `TimeLength`, `Asset`), `AudioEmitter` (`DistanceAttenuation` кривая, `AngleAttenuation`, `AudioInteractionGroup`, `AcousticSimulationEnabled`/`SimulationFidelity` — дорого), `AudioListener`, `AudioDeviceOutput`, `AudioFader`, `AudioCompressor`, `AudioLimiter`. [док reference] H

**Схема шин (вывод из доков):**
```
AudioPlayer(Music)   ─Wire→ AudioFader "Music"    ─┐
AudioPlayer(SFX)     ─Wire→ AudioFader "SFX"      ─┤
AudioPlayer(UI)      ─Wire→ AudioFader "UI"       ─┼→ AudioFader "Master" → AudioLimiter → AudioDeviceOutput
AudioPlayer/Emitter  ─Wire→ AudioFader "Ambience" ─┘
Stinger/диалог ─Wire(TargetName="Sidechain")→ AudioCompressor на Music/Ambience
```
Громкость по категориям для UI настроек = `Fader.Volume`. Legacy `SoundGroup` оставлять только если ассеты заведены на `Sound`.

**Каркас шин в коде** (не запускалось; свойства проверить в Studio; Wire соединяет `SourceInstance` → `TargetInstance`):
```lua
-- SoundBus.client.luau (фрагмент)
local SoundService = game:GetService("SoundService")
local function wire(src: Instance, dst: Instance, targetPin: string?)
	local w = Instance.new("Wire")
	w.SourceInstance, w.TargetInstance = src, dst
	if targetPin then w.TargetName = targetPin end
	w.Parent = dst
	return w
end
local master = Instance.new("AudioFader"); master.Name = "Master"; master.Parent = SoundService
local limiter = Instance.new("AudioLimiter"); limiter.Parent = SoundService
local out = Instance.new("AudioDeviceOutput"); out.Parent = SoundService
wire(master, limiter); wire(limiter, out)
local buses = {}
for _, name in {"Music", "SFX", "UI", "Ambience"} do
	local f = Instance.new("AudioFader"); f.Name = name; f.Parent = SoundService
	wire(f, master); buses[name] = f
end
-- настройки игрока: buses.Music.Volume = 0.5 и т.д.
```

**Ducking (sidechain):** `AudioCompressor` имеет пины Input, Sidechain, Output; Threshold −60..0 dB, Ratio 1-50, Attack/Release, MakeupGain. Паттерн: высокоприоритетный стрим (stinger, диалог, ключевой UI) → Wire с `TargetName = "Sidechain"` на компрессоре шины Music/Ambience. **Настройки не переносятся между проектами** («everything is relative to the volume of your content»). Стартовые значения (оценка): Threshold −24..−18 dB, Ratio 3-6, Attack 0.01-0.05 с, Release 0.3-0.8 с, ducking 3-6 dB. [док reference/AudioCompressor.yaml] H

**Лимитер:** `AudioLimiter` (MaxLevel, Release) на мастере против клиппинга при каскаде звуков (вывод).

**Когда 3D, когда 2D:**
- 3D (`AudioEmitter` + `DistanceAttenuation`) только для того, что имеет источник в мире: дроппер, портал, враг, водопад, питомцы других игроков. 2D для UI, уведомлений, ваших собственных наград.
- Затухание под масштаб: мелкие 15-30 studs, средние 40-80, ambient-зоны 60-120 (оценка; в доке пример 20 = 0.8, 40 = 0.4, 80 = 0). Комнаты/команды: `AudioInteractionGroup`.
- UI/награды играть на клиенте (локальный `AudioPlayer`), мировые события (взрыв босса) — серверный Part с эмиттером (вывод).
- Родные звуки персонажа: `SoundService.CharacterSoundsUseNewApi` переводит шаги/прыжки на новый API. M

**Официальные относительные примеры громкости** (для их ассетов): фоновый луп Volume 0.2; ключевой фидбек (сбор желейки) Volume 3; TTS-диалог Volume 3. Это относительные значения.

**Legacy-параметры** (если остались `Sound`): `RollOffMinDistance/MaxDistance/Mode`, `SoundService.RolloffScale`, `DopplerScale`, `RespectFilteringEnabled`, `AmbientReverb`. [док] H

Источники: create.roblox.com/docs/audio/objects, /audio/effects, /reference/engine/classes/{AudioPlayer,AudioEmitter,AudioCompressor,AudioFader,AudioLimiter,SoundService}, /resources/beyond-the-dark/sound-design, /tutorials/use-case-tutorials/audio.

---

## 14. Громкость и нормализация

- **Официальных LUFS-целей Roblox нет** («no standards»); есть относительные значения и совет теста на динамике телефона. [док] H
- **Внешние ориентиры:** Audiokinetic/Skywalker для консолей: музыка, амбиент, SFX, UI около −16 dB RMS, диалог −12 dB, пики ниже −3 dB, короткие climax музыки ≤ −14 dB RMS. Мобильные: динамик устройства ≈ −16.2 LUFS, наушники тихо −24, шумно −18..−16 LUFS (Sony mobile −18). [URL audiokinetic.com loudness ch.3; audiomediainternational.com] M
- **Рабочий стандарт для Roblox-проекта (оценка):**
  1. Нормализовать **до загрузки** по категориям: музыка ≈ −18..−16 LUFS integrated; амбиент ≈ −24..−20; короткие SFX/UI по пикам −3..−1 dBFS (true peak ≤ −1 dBTP: транскод в lossy может дать overs); стингеры на 3-6 dB громче музыки.
  2. В игре `Volume`-множители как финальная подстройка: Music 0.3-0.6, Ambience 0.2-0.5, SFX 0.8-1.2, UI 0.6-1.0, Stinger 1.0-1.5.
  3. Мастер: `AudioLimiter`. Проверка: громкая сцена (массовый hatch + музыка + амбиент) не клиппит, фон не пропадает.
  4. Тест: динамик телефона на низкой громкости + наушники + шумное окружение. HPF ≈ 120 Гц на UI-звуках. [URL violetrecording.com]
- В sim-играх музыка не центр микса: основная loop-награда — SFX, музыка «под». (оценка)

---

## 15. Мобильный звук, память, лимит голосов

- Динамик телефона режет низ и «мылит» середину; ясное в наушниках на ПК может быть неразличимо. [док test-on-hardware] H
- Многие играют без звука (транспорт): событие не должно существовать только в звуке, дублируйте визуалом/haptics. [док] H
- Нет hover на touch: hover-звуки не проектировать. (вывод)
- **Память:** аудио — «surprising contributor»; `AutoLoad=false` для редких, не `PreloadAsync` всего подряд, крупные аудио держать в ServerStorage до нужды; метрика `Sounds` в Developer Console. [док improve.md] H
- Короткие SFX хранить **mono** (экономия размера; 3D-эмиттеру нужен моно), музыку stereo; не грузить 48k/24-bit WAV для 1-секундных кликов, если не нужно. (оценка)
- Музыка: 1-2 лупа на зону.
- **Одновременные голоса:** документированного лимита нет (пробел). Ограничивайте сами: ≤ 8-12 одновременных коротких SFX, дедуп одинаковых за 50-80 мс; шаги дальних питомцев/игроков отключать; не вешать 3D-эмиттер на каждого питомца. (оценка)

**Лимитер голосов (каркас, не запускалось):**
```lua
local last: {[string]: number} = {}
local active = 0
local MAX_ACTIVE, MIN_GAP = 10, 0.06
local function playSfx(key: string, player: AudioPlayer)
	local now = os.clock()
	if now - (last[key] or 0) < MIN_GAP or active >= MAX_ACTIVE then return end
	last[key] = now
	active += 1
	player.PlaybackSpeed = 1 + (math.random() - 0.5) * 0.08 -- ±4%
	player:Play()
	task.delay(player.TimeLength / math.max(player.PlaybackSpeed, 0.01), function() active -= 1 end)
end
```
**Combo-лестница монет:** `PlaybackSpeed = 2^(n/12)`, n = число подряд собранных (+1 полутон за хит до +12), сброс через 1-2 с без сбора; лимит ≤ 8-10 звуков/сек.

---

## 16. Источники SFX и музыки: лицензии

**Общее правило:** загрузка = вы гарантируете права и даёте Roblox сублицензию (§12). Лицензии с запретом «redistribution as standalone files» или обязательной атрибуцией требуют осторожности. Таблица собрана из вторичного агрегатора (cinevva, продаёт конкурирующие инструменты): **перед использованием проверять страницу правообладателя**. M

| Источник | Лицензия (суть) | Условие для Roblox |
|---|---|---|
| **Roblox Creator Store audio** | бесплатно для игр | лучший старт; без квоты загрузки [док] H |
| **Kenney** | CC0 | минимальный риск |
| **Freesound** | per-file CC0 / CC-BY / CC-BY-NC | брать **только CC0** (CC-BY требует атрибуцию, NC запрещена) |
| **OpenGameArt** | per-item CC0 / CC-BY / OGA-BY / GPL | CC0 ок; избегать GPL |
| **Pixabay** | Pixabay Content License (владелец, license-summary): бесплатно, без атрибуции, правки можно; запрещена продажа/раздача «on a Standalone basis» (= без творческой обработки); про Content ID и ИИ молчит | допустимо; **не** выкладывать файл публично в Creator Store как есть |
| **Mixkit SFX** | Mixkit free license, игры разрешены (по обзорам; с сайта владельца не проверено) | ок, проверять текущую версию |
| **Sonniss GDC Bundle** | (sonniss.com/gameaudiogdc) royalty-free, пожизненная лицензия, без атрибуции; **нельзя** распространять как SFX (оригинал и правки, в т.ч. «sound library, sample pack, asset pack»); можно «as part of your finished game»; **ML-обучение запрещено**; только для media production (игры, кино, ТВ, интерактив) | загрузка приватно для своей игры ок; **не публиковать SFX в Creator Store** |
| **ZapSplat** | free: обязательная атрибуция («Sound effects obtained from zapsplat.com»); Gold без | кредит в описании/Credits |
| **Incompetech** | CC BY 4.0; без атрибуции платно от $30/трек | атрибуция в игре |

**Epidemic Sound** (FAQ владельца): музыку можно использовать «in games, mobile apps» и в коммерческих целях, ограничение только на explicit/illegal контент; условия плана и судьба треков после отмены подписки на странице не указаны, читать план. Soundly и Splice не проверены (Splice-страница не открылась): смотреть пункты «в играх/интерактивных проектах» и «загрузка в закрытые платформы». **Если вы публикуете SFX в Creator Store как публичные, они доступны всем как отдельные файлы** — для лицензий с запретом отдельной раздачи не делать публичными.

Кредиты: CC-BY, ZapSplat free, Incompetech — в описании игры или на экране Credits.

---

## 17. ИИ-аудио: условия и политика

| Сервис | Условия (окт 2026) | Для Roblox |
|---|---|---|
| **Suno** | Free: личное **некоммерческое**, Suno владеет песнями. **Pro ($10/мес, $8 годовой; 2 500 кредитов; 20 скачиваний/мес)** и **Premier ($24 годовой; 10 000 кредитов; 60 скачиваний/мес)**: Suno передаёт права на Output; коммерческое использование **только для Output, полученного через разрешённое скачивание** (запрещены stream-ripping и удаление водяных знаков/метаданных); права остаются после отмены подписки; нет гарантии авторского права; **с 3.09.2026 кап скачиваний** (бесплатным до 7 пробных на всю жизнь) | платный план на момент генерации и скачивания; хранить скрин плана, дату, ID трека [suno.com/terms; dupple.com 10.10.2026] M-H |
| **Udio** | платные: коммерция без атрибуции; бесплатные: коммерция с кредитом Udio (по обзору). Окт 2025 соглашение с UMG; 2026 курс на «walled garden» (экспорт сужается) | проверить, доступно ли скачивание на вашем плане [dubspot 12.06.2026]; ToS Udio с сайта не прочитан (страница отдала только метаданные) M-L |
| **Warner/Suno** (ноя 2025) | урегулирование иска, Suno обещала лицензированные модели | риск смены условий; Sony не урегулировала (по обзору) L |
| **ElevenLabs SFX/Music** | Free (10 000 кр./мес): **не коммерчески**, атрибуция «elevenlabs.io»; Starter $6/мес (30 000 кр.): коммерческая лицензия; SFX ≈ 200 кредитов за генерацию | для SFX в игре платный план [dupple.com] M |
| **Авторское право** | в США чисто машинный выход трудно зарегистрировать; нужен значимый человеческий вклад | **эксклюзивность не гарантирована**; не строить бренд-тему на сыром Suno-треке; хранить промпты и правки (вывод) |
| **Политика Roblox** | Audio Upload License Agreement молчит про ИИ; официального заявления о принятии/запрете ИИ-музыки **нет**; автодетект схожести (возможны ложные срабатывания); одобренное аудио может быть снято позже | платный план + человеческая обработка (монтаж лупа, EQ, укорочение), оригинальные тексты без имён артистов; **не использовать voice/artist-клоны** |

ИИ-SFX хороши для foley-слоёв и разовых стингеров, плохи для UI-семейства, где нужен единый звуковой бренд (вывод). Озвучка внутри игры: Roblox `AudioTextToSpeech` (300 символов за запрос) проходит модерацию. Headless-генерация речи: Open Cloud `generateSpeechAsset` (английская речь, в Generative AI-разделе API). [док] H

---

## 18. Канон звука по событиям

**Что здесь измерено:** длительности UI из violetrecording (тапы 30-150 мс, уведомления до ≈ 500 мс, большинство UI-реплик < 300 мс; HPF < 120 Гц; приглушить 2-5 кГц; подтверждение — восходящая терция/квинта; ошибка ниже/фальшивее; ошибка не громче тапа в 2 раза; семейство выравнивать по воспринимаемой громкости) и Audiokinetic (рандомизировать ассеты/параметры; отдельные press/release/cancel; не поощрять слишком частое действие); Roblox-доки: ±10% pitch, мультисенсорность. **Остальное в таблице — оценка** (ремесленные ориентиры, не измерения топ-игр). Уровни относительно SFX = 0 dB.

| Событие | Длина | Уровень | Дизайн | Правила |
|---|---|---|---|---|
| UI click / tap | 30-150 мс | 0..−6 | сухой «pop/tick», моно, HPF 120 Гц | 2-3 варианта, pitch ±2-4%; не звучать на каждое касание 10 раз/сек |
| Toggle on/off | 60-150 мс | −3 | on выше, off ниже | пара восходящая/нисходящая |
| Open/close панели | 150-300 мс | −3 | whoosh + мягкий тон | в такт анимации UI |
| Error/denied | 100-250 мс | 0..−3, не громче click×2 | низкий тупой тон, без 2-5 кГц | + shake UI; не карающий |
| Collect coin/orb/gem | 80-200 мс | −3..−6 | яркий bleep + короткий хвост | combo-лестница (§15), ≤ 8-10 звуков/сек |
| Purchase / buy | 250-500 мс | 0 | «ka-ching» или поп + coin tail, восходящий интервал | единый для покупок; для Robux-покупок отдельный, богаче |
| Upgrade / equip | 200-400 мс | 0 | металл/щелчок + восходящий тон | |
| Hatch charge/shake | 1.5-3 с (под анимацию 1-2 с) | −3..0 | riser с питч-вверх | не обрезаться при скипе |
| Hatch reveal hit | 0.3-0.6 с | 0..+3 | тяжёлый impact + sub, пауза-ducking музыки | точно в кадре раскрытия |
| Rarity stinger | Common: нет или 0.2-0.4 с; Uncommon/Rare 0.6-1.0; Epic 1.2-2.0; Legendary 2.0-3.5; Mythic/Secret 3.0-5.0 с | +3..+6 над музыкой | тембровая лестница: глок → хор/синт → оркестровый hit; один «ключ» на всю игру | **в auto-hatch/×N common отключать, остальные сжимать до 40-60%**; ducking музыки 4-8 dB |
| Level up | 0.8-1.5 с | 0..+3 | восходящее мажорное арпеджио, shimmer | 1 раз; не совпадать с монетным дождём (приоритет) |
| Quest/reward claim | 0.5-1.0 с | 0 | fanfare-lite | |
| Notification | ≤ 500 мс | −3..−6 | мягкий chime | редко |
| Timer tick / warning | 50-100 мс | −6 | ритмичный, ускоряется | |
| Footsteps | 150-300 мс | −10..−15 | 4-6 вариантов на поверхность, pitch ±8% | у других игроков отключать далее ≈ 30-40 studs; на телефоне не громче SFX наград |
| Jump/land | 100-250 мс | −9 | | |
| Combat hit | 80-250 мс | 0..+3 | transient + body + tail; слой «hit confirm» | чек-лист Weapons Kit: Fired, Reload, Bolt, Casing, Flying, HitSound, Charge/Discharge |
| Ambience | лупы 30-90 с (бесшовные); 2 лупа разной длины (6+5 с → 30 с уникальных) | −24..−30 LUFS | wind/room tone/birds, LPF | 2D bed + 3D spot-эмиттеры; ducked под ключевые события |
| Музыка loop | 60-120 с (бесшовный), ≤ 48 кГц | −18..−16 LUFS | 1 лейтмотив + вариации по зонам | без вокала; `LoopRegion`; не заглушать SFX |
| Boss/danger stinger | 1-3 с | +3 | низкий, диссонанс | с ducking амбиента |

**Жанровые акценты (оценка):** sim/tycoon — плотный loop монет/кликов, каждый тир дохода со своим тембром; gacha/pet — анти-усталость стингеров (см. строку Rarity); obby — короткий фидбек checkpoint (0.5 с) и fail (0.3 с), лёгкий loop музыки; хоррор — «ambience was king», абстрактное + реалистичное, 3D-эмиттеры на объектах, sidechain (`art-ui-audio.md` §12.3, §12.5).

---

## 19. Чек-листы

### 19.1 Intake 3D-ассета (любой источник)
1. Лицензия/план зафиксированы (скрин, дата, ID); для Creator Store — скрипты удалены.
2. ≤ 20k tris жёстко; рабочие ориентиры: питомец 800-3000, пропс 150-1200 (оценка); watertight; без n-gons.
3. Один материал, один UV set 0..1; текстура ≤ 1024² (массовые 512²/256²); нет вшитого света.
4. Один Color Attribute; `Color` белый или осознанный тинт; Ignore Vertex Colors выключен.
5. Origin и масштаб по §2; Unit System None; Scale Unit Studs.
6. Collision Box/Hull или CanCollide=false для декора; RenderFidelity Automatic.
7. Импорт один раз (Import as Package), Creator = группа; запись в манифест.
8. Силуэт читается на телефоне; палитра стиля; сравнение с эталоном (§4.4).
9. Shift+F2: draw calls и tris в пределах baseline-бюджета; F9: `GraphicsMeshParts/GraphicsTexture` без скачка.

### 19.2 Intake аудио
1. Источник и лицензия записаны (CC0 / платный план / Creator Store ID); атрибуции вынесены в Credits.
2. Формат mp3/ogg/wav/flac, < 20 MB, < 7 мин, ≤ 48 кГц; SFX моно.
3. Нормализовано по категории (§14), true peak ≤ −1 dBTP; HPF для UI; loops бесшовны.
4. Загружено от группы-владельца; права выданы нужным experiences; ID-verify на аккаунте.
5. Подключено через `AudioPlayer.Asset`, не legacy `Sound`; `AutoLoad=false` для редких.
6. SFX из Sonniss и подобных **не** сделаны публичными.
7. Резерв/исходник хранится (на случай снятия аудио).

### 19.3 Релиз-проверка 3D+аудио
1. Тест 10-15 минут на baseline-телефоне (FPS не деградирует, температура), Performance Dashboard: crash rate < 2-3%, OOM exits не растут.
2. Нет объектов с чёрным/серым цветом; цвета вариантов совпадают с палитрой.
3. Streaming настроен; критичные модели Persistent; нет дубликатов mesh ID.
4. Микс: массовый hatch не клиппит; ducking работает; динамик телефона и наушники проверены; все важные события дублируются визуалом.
5. Нет `require(число)`, loadstring и скриптов в импортированных визуальных ассетах.
6. Content Maturity: если есть ИИ-генерация для игроков, раскрыта.

---

## 20. Конфликты, пробелы, что неизвестно

**Конфликты и решения:**
- Текстуры 4096 (загрузка) vs 1024 (PBR-таблица) → рабочий потолок 1024.
- Квоты аудио: Open Cloud 10/100 vs audio-страница 2 000/100 за 30 дней → audio-страница.
- Sample rate: док ≤ 48 кГц; DevForum упоминает 96 → док.
- Порог публичных SFX: 6 с (2022) vs 10 с (комьюнити 2026) → «около 10 с», уточнять в Dashboard.
- Лимит tris: док 20k vs вендор 21K → 20k.
- Tripo Free: ранее «ограничен коммерцией» → блог: «public CC BY 4.0» → **ToS: на Free права у Tripo, CC BY в ToS нет**; верить ToS.
- `MeshPart.VertexColor` не существует в справке (только `DataModelMesh`).

**НЕИЗВЕСТНО / не публикуется (говорить честно):**
- Colour space импортированных vertex colors (нужна калибровка §4.4).
- Числовые квоты Cube / `/generate_mesh` / Texture & Material Generator / Build.
- Официальная позиция Roblox по загрузке ИИ-мешей и ИИ-музыки.
- Официальные числовые бюджеты tris/draw calls/памяти для устройств.
- Время модерации ассетов; лимит одновременных голосов; реальный кодек/битрейт после транскода (комьюнити: OGG Vorbis).
- Измеренные громкость и длительности звука в топ-играх (таблица §18 — оценка).

**Не проверено (можно проверить):** условия Soundly, Splice, Mixkit и Udio (страницы закрыты/JS); план-уровневые условия Epidemic; полный текст Roblox Creator Terms и лицензия на бесплатные Creator Store ассеты; влияние `SurfaceAppearance.Color` на инстансинг (доки: тинт не влияет на производительность, ключи батчинга о `.Color` молчат; проверка Shift+F2).

---

## 21. Источники

Локальные доки (creator-docs, снимок 24.10.2026): `studio/importer`, `art/blender`, `art/modeling/{specifications,texture-specifications,export-requirements,surface-appearance,gltf-export,roblox-blender-plugin}`, `parts/{meshes,materials,model-generation}`, `performance-optimization/{design,identify,improve,test-on-hardware}`, `production/analytics/performance`, `workspace/streaming/{index,slim}`, `physics/units`, `cloud/guides/usage-assets`, `projects/assets/{privacy,manager}`, `production/creator-store`, `scripting/security/third-party-vulnerabilities`, `generative-AI`, `ai/build`, `ai-data-sharing`, `assistant/guide`, `studio/{texture,material}-generator`, `reference/engine/classes/{GenerationService,AudioPlayer,AudioCompressor,AudioEmitter,AudioFader,AudioLimiter,SoundService,DataModelMesh}`, `audio/{assets,objects,effects}`, `resources/beyond-the-dark/sound-design`, `marketplace/validation-system`.

Внешние: devforum.roblox.com/t/3050119 (vertex colors), /t/4734973 (black meshes, 07.2026), /t/3127146 (оптимизация), /t/3974730 (шеринг аудио, окт 2025), /t/4734119 (SFX vs music, июль 2026), /t/4089305 (удаление песен), /t/1701697 (приватность 2022); en.help.roblox.com Audio Upload License Agreement; meshy.ai/pricing; tripo3d.ai (блог про private commercial use); hyper3d.ai/pricing; suno.com/terms; dupple.com (Suno/ElevenLabs, 10.10.2026); blog.dubspot.com (ИИ-музыка, 12.06.2026); app.cinevva.com (бесплатные звуки); audiokinetic.com; audiomediainternational.com; violetrecording.com.
