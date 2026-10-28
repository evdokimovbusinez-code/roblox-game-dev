# Анимация и моушн-канон Roblox: пайплайн производства и тайминги топ-игр

**Зачем этот файл.** Две части для Builder- и Advisor-ролей. **Часть A (пайплайн):** чем и как делать анимации для Roblox-игры, какой риг, какие инструменты (Animation Editor, Moon Animator, Blender, мокап), как их публиковать (владелец, права, Animation Packs), как они проигрываются и где ломаются (Animator, приоритеты, троттлинг, репликация), и как делать моушн кодом (TweenService, SmoothDamp, процедурные питомцы). **Часть B (моушн-канон):** измеренные по видео топ-игр тайминги и последовательности (вылупление, карточки открытия, роллы, полёт монет к счётчику, офлайн-попап, колесо эмоутов, телепорты, удары, поп-апы) с готовыми подсказками реализации на Roblox (TweenInfo, easing, длительности). Что уже есть в других файлах, здесь не повторяется: AnimationPriority, ловушка владения, Animation Graph, Adaptive Animation, официальные туториальные твины, пресеты тряски камеры → `builder/art-ui-audio.md` §10-11; 3D-ассеты, на которых играют анимации → `builder/3d-asset-canon.md`; иконки и расположение UI → `builder/ui-canon.md`.

**Актуально на: октябрь 2026.** Перепроверять (самое волатильное):
- статус «Prompt-to-Animation» (в весенней дорожной карте Roblox «Late 2026», в осенней не найдена; сейчас считать недоступной);
- Animation Packs: порог цены 300 R$ динамический, плата за загрузку 80 R$, прогрессивная доля с продаж, requirements для продавца;
- статус бета-функций: Animation Graph Editor, Animation Capture (body/face), Share custom animations;
- цены и лицензии мокап-инструментов (DeepMotion, Move.ai, Rokoko, Plask, NoCapMocap, Mixamo);
- троттлинг аниматоров: перманентный с 29.04.2026, переключателя в Workspace больше нет;
- тайминги Части B измерены по пережатому YouTube-видео (30/60 fps, ошибка ±0.05-0.25 с, большая часть правил n=1-3 игры). Это ориентиры для старта, а не спецификация Roblox.

**Метки.** «док» = официальная документация (creator-docs, октябрь 2026); «DevForum» = форум, надёжность средняя; «вендор» = заявление продавца инструмента; «вывод» = мой вывод; «[prior]» = не наблюдалось в видео, из общей практики. Уверенность в Части B: **canon** ≥5 клипов, **common** 3-4, **seen** 1-2 (на малой выборке слово «canon» не равно закону).

## Оглавление

**Часть A. Пайплайн**
1. [Главные решения (кратко)](#1-главные-решения-кратко)
2. [Риг: R15, R6, кастомный, не-гуманоид](#2-риг-r15-r6-кастомный-не-гуманоид)
3. [Инструменты Roblox и статус дорожной карты](#3-инструменты-roblox-и-статус-дорожной-карты)
4. [Внешние инструменты и ИИ-мокап](#4-внешние-инструменты-и-ии-мокап)
5. [Рецепт: клип из Mixamo / мокапа в R15 и в игру](#5-рецепт-клип-из-mixamo--мокапа-в-r15-и-в-игру)
6. [Проигрывание: Animator, треки, приоритеты, троттлинг, репликация](#6-проигрывание-animator-треки-приоритеты-троттлинг-репликация)
7. [Загрузка, владелец, права](#7-загрузка-владелец-права)
8. [Animation Packs и эмоуты как продукт](#8-animation-packs-и-эмоуты-как-продукт)
9. [Какие анимации нужны жанру](#9-какие-анимации-нужны-жанру)
10. [Моушн кодом: твины, пружины, питомцы, UI и пропсы](#10-моушн-кодом-твины-пружины-питомцы-ui-и-пропсы)
11. [Ловушки и чек-лист отладки](#11-ловушки-и-чек-лист-отладки)

**Часть B. Моушн-канон топ-игр**
12. [Метод, ограничения и обозначения](#12-метод-ограничения-и-обозначения)
13. [Вылупление, гача, ролл: последовательности и тайминги](#13-вылупление-гача-ролл-последовательности-и-тайминги)
14. [Окна, кнопки, счётчики, тосты, ребёрс, телепорт](#14-окна-кнопки-счётчики-тосты-ребёрс-телепорт)
15. [Награды, монеты, офлайн-доход](#15-награды-монеты-офлайн-доход)
16. [Бой: числа урона, hit freeze, M1, тяжёлые приёмы](#16-бой-числа-урона-hit-freeze-m1-тяжёлые-приёмы)
17. [Тинт мира, хоррор-погоня, питомцы, рыбалка](#17-тинт-мира-хоррор-погоня-питомцы-рыбалка)
18. [Что НЕ измерено и конфликты источников](#18-что-не-измерено-и-конфликты-источников)
19. [Источники](#19-источники)

---

# ЧАСТЬ A. ПАЙПЛАЙН

## 1. Главные решения (кратко)

1. **Первым делом спросите, нужна ли вообще авторская анимация.** Большинство топ-симуляторов живёт на стоковой локомоции Roblox и процедурном «juice» (твин, покачивание, squash-stretch): в трёх из трёх казуальных клипов (Grow a Garden, Kick a Lucky Block, Steal a Brainrot) аватар ходит по умолчанию. Авторские клипы нужны PvP-боевкам, хоррору, ивентовым эмоутам. (H)
2. **Первоклассного text-to-animation у Roblox нет** (на 27.10.2026): `GenerationService` не имеет метода анимации; «Prompt-to-Animation» стоял в весенней карте на «Late 2026» и в осенней не найден. Никогда не обещайте его в плане. Рабочие пути: клипы вручную в Animation Editor, мокап → R15 через Blender, библиотеки (Mixamo, каталог), процедурный код. (H)
3. **Всё делайте под R15** и никогда не смешивайте R6/R15: «R15 Only» нужен для ставки 18+ DevEx (`art-ui-audio.md` §8). NPC и монстры могут быть на любом риге. (H)
4. **Анимации публикуются от группы-владельца** игры (иначе ошибка владения → `art-ui-audio.md` §11.4). Это первое, что проверять при «анимация не играет». (H)
5. **Визуальные твины, питомцы, пикапы и UI анимируются на клиенте**, сервер держит только логическое состояние. Серверный твин реплицирует свойство каждому клиенту каждый кадр (дрожание под нагрузкой). (H док)
6. **Кэшируйте `AnimationTrack`**: `Animator:LoadAnimation` каждый раз создаёт новый трек; лимит 256 треков на один Animator; утечка анимаций это одна из самых частых утечек памяти в продакшене (Scene Analysis). (H)
7. **Троттлинг аниматоров постоянный** с 29.04.2026 (снижает частоту обновления далёких/невидимых персонажей, по заявлению Roblox −25-30% CPU анимации в людных сценах). Процедурные оффсеты пишите в `PreSimulation` и пропускайте кадр, если `Animator.EvaluationThrottled`. (M-H)
8. **Тайминги Части B берите как стартовые значения и прогоняйте на телефоне**; «skip/auto/quick» тоглы для вылупления и роллов это часть дизайна, не опция (§13). (M)

---

## 2. Риг: R15, R6, кастомный, не-гуманоид

| Ситуация | Риг | Анимации | Почему |
|---|---|---|---|
| Аватар игрока (по умолчанию) | **R15 Only** (Avatar Settings) | стоковые + свои клипы под R15 | условие повышенной ставки 18+ DevEx; SLIM-LOD толпы только для R15-аватаров |
| Игра, где риг и есть продукт (Dandy's World, Animal Hospital) | кастомный риг | Adaptive Animation: ≥15 суставов сопоставлены, T-pose → проигрывает любую R15-анимацию | официальный путь для небоксовых персонажей (`art-ui-audio.md` §11.1) |
| NPC / юниты в боевых играх (TSB, TTD, Sailor Piece) | стоковые R15 с аксессуарами | стоковые + кастом | дёшево; 27+ игр так |
| Питомец/существо с костями | `AnimationController` + `Animator` + Motor6D (или Bone) | авторские клипы или процедурно | Humanoid не нужен; имена Motor6D не менять |
| Питомцы роя (PS99, BGSI) | статические меши | **процедурный bob/hop на клиенте** | десятки штук; клипы не масштабируются |
| Нужны рагдолл и «powered limbs» | `StarterPlayer.AvatarJointUpgrade` (по умолчанию для новых игр) | `AnimationConstraint` вместо Motor6D | встроенный ragdoll на смерти |
| Кат-сцены (камера + несколько ригов) | любой | Moon Animator 2 или Blender; встроенный Clip Editor слабее для катсцен | DevForum, август 2026 |

Правила:
- **Не пишите `C0/C1` у аватаров и не меняйте `RigAttachment.CFrame`** (ломает ретаргетинг, бьёт по производительности); процедурный оффсет это `Transform` у `AnimationConstraint`/`Motor6D`. (док)
- `Workspace.Retargeting` (`AnimatorRetargetingMode`: Default / Disabled / Enabled) подгоняет клипы под пропорции тела. Default «пока opt-in, может измениться». При выключенном ретаргетинге клипы играют как нарисованы (скольжение ног на масштабированных персонажах: вывод). (док)
- Игра с собственным видом ходьбы/idle должна выставить `Avatar Settings > Animation Packs = Standard R15` (или подменять набор скриптом): по умолчанию стоит **Player Choice**, и купленный игроком пак заменит ваши стоковые анимации. (док)

---

## 3. Инструменты Roblox и статус дорожной карты

| Инструмент | Что делает | Статус (окт 2026) |
|---|---|---|
| **Animation (Clip) Editor** | ключи, кривые (Curve Editor), easing, events, IK | основной; вкладка Avatar |
| **Curve Editor** | конвертирует `KeyframeSequence` → `CurveAnimation`; перевод кватернионов в Эйлеры необратим; bounce/elastic не стандарт для кривых, Studio имитирует генерацией кривых | нужен для паков и эмоутов |
| **Animation Graph Editor** | блендинг-деревья, state machines; Studio Beta; репликация по `Workspace.AuthorityMode` | Beta (подробности → `art-ui-audio.md` §11.1) |
| **Adaptive Animation** | кастомный гуманоид играет любую R15-анимацию | full release |
| **IKControl** | look-at, постановка ног, удержание оружия; нужны Type, EndEffector, Target, ChainRoot; работает под Humanoid/AnimationController с Animator; свойства Weight, SmoothTime, Pole, Offset, Priority | доступен |
| **Animation Capture** | тело из видео (`.mp4`/`.mov`, один человек, один дубль, **<15 с**, стабильная камера, только R15, бета «Live Animation Creator»; ключи через ~минуту); лицо с веб-камеры до 60 с, нужна Dynamic Head | бета (graduation не подтверждена) |
| **`AssetService:PromptImportAnimationClipFromVideoAsync`** | из серверного Script просит игрока загрузить видео и возвращает `AnimationClip`; нужно согласие игрока | API есть |
| **FBX/glTF-импорт анимации** | Clip Editor «...» > Import > From File; Studio Importer принимает `.fbx`/`.gltf` с ригом и скиннингом | см. §5 |
| **Moon Animator 2** | платный плагин; сильнее для мульти-ригов, камеры, зеркалирования | **поддерживается**: обновлён 21.10.2026, на распродаже −33% (около $19.99, список около $29.99: вывод), 93% положительных из 30K голосов; Roblox упоминает его как допустимый внешний инструмент для эмоутов. Тема DevForum «альтернативы MA2» (авг 2026) была про катсцены, не про брошенность. Недоступен для покупки в некоторых странах |
| **Blender** | для катсцен (рекомендация DevForum, камеры + риги) и для ретаргетинга мокапа; есть официальный Roblox Blender plugin | де-факто стандарт внешнего инструмента |

**Дорожная карта (весна 2026, осень от 18.09.2026):**
- Поставлено (весна): Adaptive Animation (full), Animation Graphs (Beta), Character Controller library, R15 full-body rigs (пальцы, ключицы), Avatar joint upgrade (ragdoll), Animation Clip Editor importer (glTF).
- Осенняя карта добавляет: motion matching в Animation Graph (раннее 2027), state-machine nodes и Luau Expressions (середина 2027), root motion (середина 2027), procedural bones (раннее 2027), прямой импорт sprite sheet (поздний 2026, 2D). Сдвиги: переимпорт анимаций на Late 2026; **Share custom animations through Creator Store** на Early 2027. RDC26 (11.09.2026): NPC Dynamic Behavior (поздний 2026), New Default Movement на motion matching (раннее 2027).
- **Prompt-to-Animation** (весна: Late 2026, планировалось) в осенней карте и RDC26 не найдена. Молчание карты может означать «сдвинули», «убрали» или «не вошло в суммаризацию». Для плана: **недоступно, без даты**.
- Cube 4D (бета с февраля 2026) делает функциональные объекты (Car-5, Body-1), не анимацию персонажей. Анимации сцены «в перспективе» без даты.
- Studio Assistant не создаёт анимации (в локальных доках способности не найдено).
- Для AI-features внутри игры: Roblox-served ИИ инструктирован выдавать результат, совместимый с All Ages, и избегать вывода, требующего дескриптор (например Horror) — важно, если ИИ-фичи в хорроре.

Источники: devforum.roblox.com/t/creator-roadmap-2026-spring-update/4625473; /creator-roadmap-2026-fall-update/4880208; /rdc26-what-we-announced/4865880; create.roblox.com/docs/animation/editor, /curve-editor, /graph-editor, /capture, /inverse-kinematics; create.roblox.com/store/asset/4725618216.

---

## 4. Внешние инструменты и ИИ-мокап

### 4.1 Таблица (цены и лицензии: вендорские, сняты 27.10.2026; не юридическая консультация)

| Инструмент | Что | Цена / лимиты | Коммерческая лицензия |
|---|---|---|---|
| **Mixamo** | библиотека + авторигг гуманоидов | бесплатно с Adobe ID; сайт жив в октябре 2026 | «Create video games» разрешено, royalty free; **нельзя** раздавать сырые файлы персонажей/анимаций и обучать ML (FAQ 2022; в FAQ 2021 этих оговорок нет); 2026-текст Adobe ToS не читался |
| **DeepMotion Animate 3D** | видео → мокап | Free 25 кредитов/мес (1 кредит = 1 с анимации), клипы ≤20 с; Starter $9/мес (годовой тариф) 180 кредитов, 20 с; Innovator $17 / 480 / 30 с; Pro $39 / 1500 / 120 с; Studio $83 безлимит / 360 с. Выход FBX/BVH/GLB; «Root Joint at Origin», Foot Locking | **Free нет**, платные да. Прежняя цифра «60 с бесплатно» устарела |
| **Move.ai** | видео → мокап (одна камера) | Personal $15/мес (годовой $10.50), 2250 кредитов; Standard $50/мес (годовой $35), 7500 кредитов ≈1250 с на s1 (6 кредитов/с, s2 12 кредитов/с); FBX/BVH/USD/BLEND | Personal **некоммерческий**, Standard коммерческий (докс без даты) |
| **Plask** | видео → мокап | Free 15 с/день, Standard $18/мес, Pro $50/мес (годовые); FBX/GLB/BVH | ToS (2023): личное некоммерческое; «Commercial plan» упомянут, но тариф не назван → **не полагаться** без письменного ответа поддержки |
| **Rokoko** (Vision, Studio, Create) | видео и text-to-motion | Vision Starter $0: 30 с/мес; Basic $10/мес (годовой): 600 с; text-to-motion в Studio Preview для Plus и Pro, клипы 1-5 с, «experimental», экспорт на скелет Newton (не R15) | ToS v2.0.1 (16.07.2026): права на сгенерированное у вас; явной коммерческой клаузулы нет; стоковые Assets Rokoko привязаны к аккаунту, не для раздачи, без ML-обучения |
| **NoCapMocap** (Studio-плагин Motion Lab) | text-to-motion R15, 4 варианта за 1-3 мин, видео в бете | кредитная система, пакеты от $7; нужны HTTP Requests в Studio | ToS (28.09.2026): коммерческое использование разрешено, соблюдать правила Roblox, нельзя обучать посторонние ИИ. Доступ для агента (API/MCP): не подтверждён |
| **Meshy** | авторигг/библиотека | Free: 100 кредитов/мес, 20 анимаций, **CC BY 4.0** (атрибуция) | платные: приватные ассеты |
| **Cascadeur** 2026.2 | физичная анимация, десктоп | Free: только `.casc`, без FBX; Indie $19/мес ($96/год, доход <$100k) | на странице противоречие |

### 4.2 Что для чего (вывод)

| Тип клипа | Источник | Почему |
|---|---|---|
| Idle / walk / run / jump / fall / climb | библиотека (каталог Roblox, Mixamo «In Place») или ручные ключи | text-to-motion плохо замыкает петли; самый частый дефект ИИ-мокапа это скольжение ног, плавание и пенетрация |
| Эмоуты, одиночные приёмы, кастпоза, финишер | text-to-motion (1-5 с) + чистка, либо мокап по своему видео | подходит для коротких уникальных движений |
| Боёвка (M1, блок, уклон) | ручные ключи или мокап + чистка, маркеры событий | нужны точные фреймы попадания |
| Камера и катсцена | Blender или Moon Animator 2 | камеры + несколько ригов |
| Питомцы роя | процедурно (§10) | клипы не нужны |

Всегда план на чистку: ключи, замыкание петли (первый ключ = последний), дрейф корня, скольжение стоп, «Optimize keyframes» в редакторе. Мокап обычно слишком шумный для 60-fps «мультяшного» вида. Freelance-ставки на анимацию и UI → `art-ui-audio.md` §16.3.

Не найдено: проверенный статус Move.ai/Plask за пределами их страниц; практическое качество text-to-motion на R15; Rokoko Create против Studio по тарифам.

Источники: deepmotion.com/pricing-animate3d; docs.move.ai/knowledge/move-ai-pricing-plans-credits; plask.ai/pricing; rokoko.com/studio-term-of-use; support.rokoko.com (Text-to-Motion in Studio Preview); nocapmocap.com/terms; mixamo.com; helpx.adobe.com/creative-cloud/faq/mixamo-faq.html; cascadeur.com/plans.

---

## 5. Рецепт: клип из Mixamo / мокапа в R15 и в игру

Собрано из официальных правил и DevForum. **Сквозной прогон не выполнялся** (нет Studio+Blender в исследовании); считайте это отправной точкой и проверяйте на первом клипе.

**Требования Roblox к импорту (док):** суставы названы точно и в иерархии `Root > HumanoidRootPart > LowerTorso > UpperTorso > Head`, `Left/Right UpperArm > LowerArm > Hand`, `Left/Right UpperLeg > LowerLeg > Foot`; анимации аватаров не двигают персонажа по миру, поэтому **трансляция корня заглушается** (анимация на месте у начала координат); bake, step 1, FBX Binary (FBX 2020 при необходимости).

**Шаги:**
1. **Источник.** Mixamo («X Bot», «Without Skin», FBX, 30 fps, «In Place» для локомоции) или экспорт DeepMotion/Rokoko/NoCapMocap (у DeepMotion «Root Joint at Origin»).
2. **Blender.** Импортируйте R15-арматуру (T-pose; есть официальный Roblox Blender plugin и R15-риг на GitHub Roblox) и клип. Ретаргетинг через bone-map аддон (HEAT или любой bone-map ретаргетер; ни один не валидирован). Сопоставьте 15 суставов R15; **уберите маппинг Root** (иначе персонаж «улетает»), вручную проверьте UpperArm/LowerArm/UpperLeg/LowerLeg: автосписок их пропускал. Обнулите корневой/hip-трансляцию, нормализуйте масштаб (1 stud = 0.28 м) и корень (иначе «скачки»), одинаковые Forward/Up у модели и анимации.
3. **Экспорт FBX.** Selected Objects, типы только Armature, **Add Leaf Bones выкл**, bake анимации, NLA Strips и All Actions выкл.
4. **Studio.** Rig Builder R15 → Clip Editor → «...» > Import > From File; в настройках импорта Rig Type = R15, Rest Pose Source = «Imported Rig» (или «Imported Rig (Zeroed Rotations)», если руки скручиваются), Rig Scale по stud, Animation Track Selection. Импортёр (обновление 04.08.2026) также автосохраняет анимации моделей, импортированных Universal Importer, в `ServerStorage.AnimSaves`.
5. **Доводка.** Обрезка, первая поза = последняя, конвертация в `CurveAnimation` (необратимо), Loop в `ServerStorage.RBX_ANIMSAVES`, имя последнего ключа `End` (регистр!) если клип заменяет стоковый.
6. **Публикация** с Creator = группа (§7); для паков и эмоутов пройти валидацию (§8).

**Типичные отказы:** руки схлопываются (несовпадение rest-поз, I-pose импортёра против T-pose ретаргета); дрейф и скачки корня (корень не обнулён); «плавание над землёй» (высота таза/масштаб); кость с именем меши в арматуре превращается в физический `Motor6D` (давайте костям уникальные имена); несовместимость версий FBX с аддонами Blender. Актуального сквозного гайда Mixamo→R15 нет даже на DevForum 2025 («три дня, гайдов нет»): ожидайте метод проб и ошибок на каждый файл. Рипнутые AAA-анимации (пример: TLOU2-тест на DevForum, частичный успех, двойной ретаргетинг) не публиковать: авторские права.

Вывод: узкое место ретаргет, не генерация. Roblox-родной Live Animation Creator (§3) обходит этот шаг (целится прямо в R15), но с ограничением 15 с и одного человека.

Источники: create.roblox.com/docs/art/characters/export-avatar-animations-from-maya; devforum.roblox.com/t/animation-import-improvements/4775593; /motion-capture-animation-into-roblox-with-heat-tutorial/3127168; /aaa-animation-retarget-to-roblox-tlou2-test/3937995; /need-a-guide-on-how-to-import-an-animation-from-mixamo-2025/3540028.

---

## 6. Проигрывание: Animator, треки, приоритеты, троттлинг, репликация

### 6.1 Правила `Animator` / `AnimationTrack` (док)

| Правило | Деталь |
|---|---|
| Создавать трек | `Animator:LoadAnimation(anim)`; `Humanoid:LoadAnimation` deprecated; Animator должен быть в Workspace к моменту загрузки (иначе ошибка) |
| Кэш | каждый `LoadAnimation` создаёт новый трек; хранить трек, брать существующий через `Animator:GetTrackByAnimationId()`; лимит **256 треков на Animator** («new animations will not be played») |
| Play | `AnimationTrack:Play(fadeTime = 0.1, weight = 1, speed = 1)`; `TimePosition` выставлять **после** Play |
| События | маркеры в редакторе + `GetMarkerReachedSignal(name)` (для хитбокса, VFX, SFX); `KeyframeReached` устарел |
| Скорость | `AdjustSpeed` под WalkSpeed, против скольжения ног |
| Приоритеты | Action4 > Action3 > Action2 > Action > Movement > Idle > Core; одинаковые блендятся по весу → `art-ui-audio.md` §11.2 |
| Верхняя часть тела | идут на Action поверх Movement; чисто «частичные» клипы делайте ключами только нужных суставов (вывод) |
| Замена стоковых | остановить текущие треки, последний ключ `End`, подмена по ID при `CharacterAppearanceLoaded`; Animate-скрипт: run, walk, jump, idle (два варианта с весами), fall, swim, swimidle, climb |
| Эмоуты | до 8 в колесе: `HumanoidDescription:SetEquippedEmotes()`, `SetEmotes(table)`, `Humanoid:PlayEmoteAsync(name)`; по умолчанию dance, point, cheer; отключить меню: `StarterGui:SetCoreGuiEnabled(Enum.CoreGuiType.EmotesMenu, false)` |

### 6.2 Репликация

- Для персонажа игрока: треки, запущенные на клиенте владельца, реплицируются на сервер и другим клиентам. Для NPC и пропсов треки нужно загружать и запускать **на сервере**, иначе другие их не увидят; Animator для них изначально создаётся на сервере (локально созданный Animator не реплицируется никогда).
- Для толп NPC серверная анимация дорога: создавайте Animator на клиенте, используйте `AnimationController` вместо Humanoid для статичных NPC, отключайте неиспользуемые состояния Humanoid, пулите NPC.
- Остатки данных анимации от плагинов в ригах реплицируются при клонировании в рантайме; чистить до публикации.
- Анимации игрока играйте у клиента (отклик), сервер остаётся авторитетом по исходу (урон).
- Animation Graph: параметры реплицируются; `SetParameter` вызывается для NPC с серверного скрипта, для игроков в Automatic с клиента, в Server-authority с обеих сторон; незаписанный граф в плейтесте грузится локально, в Server authority не поддерживается (→ `art-ui-audio.md` §11.1).

### 6.3 Троттлинг и производительность (с 29.04.2026)

- Троттлинг аниматоров **постоянный** и «больше не переключается в Workspace»; снижает частоту обновления далёких и невидимых персонажей (локально созданные нереплицируемые персонажи подчиняются тем же правилам). Заявление Roblox: −25-30% CPU анимации в людных сценах; пороги по дистанции не публиковались; мобильные устройства в посте не выделены.
- Свойство `Workspace.ClientAnimatorThrottling` и enum (Default/Disabled/Enabled) всё ещё видны в API-снимке, но эффективным выключателем **не являются**. Единственный opt-out это подсказка `Animator.PreferLodEnabled = false` для важных NPC.
- Процедурные оффсеты (`Transform`, C0/C1) при троттлинге могут накапливаться: пишите их в `RunService.PreSimulation` (Animator перезаписывает Transform между PreAnimation и PreSimulation) и пропускайте кадр, если `Animator.EvaluationThrottled == true`.
- SLIM: `Workspace.EnableSLIMAvatars` для платформенных R15-аватаров (не для R6/NPC/Humanoid-кастомов).
- Числа «сколько анимированных ригов тянет телефон» не публикуются. Измеряйте на baseline-устройстве (MicroProfiler, Scene Analysis; `GetAnimationMemoryAsync`). Эвристика (вывод): рядом с камерой на мобильных несколько десятков анимированных гуманоидов максимум, дальних NPC не анимировать, процедурное движение Parts через один `RunService`-цикл вместо твина на каждую часть.

Источники: create.roblox.com/docs/reference/engine/classes/Animator, /AnimationTrack, /Workspace, /AnimationConstraint; create.roblox.com/docs/performance-optimization/improve, /scene-analysis; devforum.roblox.com/t/4568218 (Phase 3 троттлинга); devforum.roblox.com/t/2577096 (лимит 256).

---

## 7. Загрузка, владелец, права

| Вопрос | Правило |
|---|---|
| Кто владеет | для игры в группе публикуйте анимации **с Creator = группа** (окно Asset Configuration при экспорте); при переносе плейса в группу личные анимации перепубликовать. Точный текст ошибки «You do not have ownership of animation with the selected ID» в доках не найден (в скилле цитируется) |
| Asset Privacy | к Animations **не применяется** (только Images, Decals, Meshes); доступ даётся грантами друзьям/группам/играм в Creator Dashboard; грант игры постоянный; «поделиться без перезагрузки» через гранты |
| Share via Creator Store | перенесено на Early 2027 (осенняя карта); не планируйте |
| Экспорт-перенос между ригами | сохранить анимацию (`AnimSaves`) в `.rbxm` и импортировать на другом риге |
| Headless-публикация | Open Cloud Assets API (бета) принимает Animation как `.rbxm`/`.rbxmx` до 20 МБ; файлы, отредактированные вне Studio, «могут не загрузиться или не работать». Безопасная цепочка (вывод, **не проверена**): Studio (через плагин/MCP) сохраняет анимацию в файл → Open Cloud загружает с группой-владельцем. Plugin-API `AssetService:CreateAssetAsync` анимацию не поддерживает |
| Модерация | паки и эмоуты проходят валидацию (§8); обычные анимации: сроки модерации не документированы |
| Что делает человек | загрузка из Studio (кнопка Publish to Roblox) и выбор группы, если не настроен Open Cloud-ключ |

Открыто: сквозной прогон «мокап → R15 → группа → ID», загрузка `.rbxm` с `KeyframeSequence`/`CurveAnimation` через Open Cloud (нужен API-ключ и Studio).

---

## 8. Animation Packs и эмоуты как продукт

**Для кого это.** Это товар для Marketplace (аватар-креатор), а не способ анимировать вашу игру. Для игрового разработчика обычно низкий приоритет (вывод), стоит рассматривать только как побочный доход или ивентовую фишку.

| Параметр | Значение (док) |
|---|---|
| Состав пака | 8-9 клипов: Idle (1 или 2), Walk, Run, Jump, Fall, Climb, Swim, SwimIdle; все петлёвые кроме Jump; ≤10 с каждый |
| Источник клипа | стандартный R15, оригинальная работа (стоковые Roblox отклоняются), **только `CurveAnimation`** (KeyframeSequence не принимается); собрать и загрузить надо в Studio, автор может работать во внешнем инструменте |
| Лимит | один пак в день на креатора; группы и Limited поддерживаются |
| Плата за загрузку | **80 R$**, невозвратная при отказе |
| Порог цены (price floor) | **300 R$** — минимальная цена продажи, не дополнительный сбор; динамический (по спросу), живой диапазон в Creator Dashboard; контролы «Amount Above Price Floor», «Do Not Price Below» |
| Публикационный аванс для паков | **не указан** (в таблице есть эмоуты: 1 500 / 10 000 R$); реальная сумма видна в окне Pay & Submit в Studio |
| Валидация | позиционные треки допустимы только у `LowerTorso`, остальные части только вращение; ни одна часть не дальше 1.5 stud от начальной позиции ни в одном кадре; ограничены дрейф корня и скорость между кадрами; один корневой Folder (`HumanoidRootPart` или часть тела); разрешённые типы в дереве: MarkerCurve, AnimationRigData, Folder, Vector3Curve, EulerRotationCurve, FloatCurve, ObjectValue; костные подпапки (HRD/DRD advanced-rig) только доверенным креаторам |
| Продавец | верификация личности (свой ID или привязанный родительский), 2-step verification, публикационный аванс, и владелец (человек или группа) должен иметь **Roblox Plus или Premium 1000/2200**; то же нужно, чтобы вещи оставались в продаже |

**Доля с продаж (Marketplace fees and commissions).** В Marketplace база 30%, и действует **прогрессивная доля** от отношения цены к порогу: ×1 = 30%, ×1.3 = 37%, ×1.5 = 41%, ×2 = 50%, ×2.5 = 57%, ×3 = 62%, ×4 = 67%, ×5 = 69%, ×6 и выше = 70% (потолок). При пороге 300 R$: цена 300 → креатору 90; 600 → 300; 900 → 558; 1200 → 804; 1800 (×6) → 1260. **Покупки внутри игр** (Avatar Inspect Menu, AvatarEditorService, MarketplaceService): креатору 30%, владельцу игры 40% (affiliate), Roblox 30%; прогрессивная доля не применяется; региональные цены процент не меняют; 30-дневный эскроу на каждую продажу. Арифметика (вывод): пак за 300 R$ даёт 90 R$ креатору с продажи в Marketplace, то есть одной продажи хватает, чтобы вернуть 80 R$ платы; если вы одновременно креатор и владелец игры, через свою игру получаете 70%.

**Эмоуты:** <10 с, корень не уходит далеко (анти-телепорт), стандартный R15, источник `CurveAnimation`, плата 80 R$; эмоуты на advanced R15 в закрытой бете.

Источники: create.roblox.com/docs/avatar/animation-packs, /avatar/emotes/specifications, /avatar/emotes/import, /marketplace/marketplace-fees-and-commissions, /marketplace/marketplace-policy, /marketplace/validation-system, /marketplace/publish-to-marketplace; devforum.roblox.com/t/upcoming-launches-for-avatar-creators/4263106 (анонс январь 2026; запуска отдельным постом не найдено, док живая и без бета-баннера).

---

## 9. Какие анимации нужны жанру

Всё ниже это планировочные эвристики на основе документированных ограничений (набор Animate, спецификация пака, лимиты эмоутов), **не** данные о топ-играх: измерений числа клипов в реальных играх нет. P0 обязательно, P1 важно, P2 полировка; петля Y/N; приоритет трека.

**Общее (все жанры).** P0: idle (Y, Idle), walk и run (Y, Movement), jump (N), fall (Y), climb (Y); swim и swimidle только если есть вода. P1: 2-3 idle с весами, смерть (N, Action4) или рагдолл, спавн (N, Action2), interact/pickup (N, Action). P2: sit, look-around.

| Жанр | P0 | P1 |
|---|---|---|
| Симулятор / тайкун / кликер (≈<10 кастомных клипов) | взмах инструментом/сбор (N, Action, 0.3-0.6 с, маркер на кадр попадания), carry idle/walk (Y), празднование покупки/уровня (N, Action2) | idle/hop питомца (иначе процедурно), поза ребёрса, sell/deposit |
| Баттлграунд / PvP (≈25-40) | 4-5 ударов комбо (N, Action), блок (Y пока зажат, Action2), дэш/уклон (N, Action3), hit-react спереди/сзади (N, Action3), нокдаун/подъём и смерть (N, Action4), каст и финишер навыков (N, Action3, маркеры для хитбокса) | воздушные атаки, grab/throw (синхронизация двух ригов, сложнее), equip/unequip, run-attack |
| Хоррор (≈15) | выжившие: crouch idle/walk (Y), hide/locker (N, Action2), фонарь (Y, Action или IKControl), испуганный спринт (Y), caught и смерть (N, Action4); монстр: idle, patrol, chase run (Y), lunge (N, Action), stun (N, Action3), scream (N, Action2) | look-at головой через IKControl, jumpscare-клип (камера + риг) |

Флаги петли: Y для idle, walk, run, fall, climb, swim, block-hold, carry; N для jump (по спецификации пака), атак, hit-react, завершаемых эмоутов; смерть можно держать последним кадром (деталь не проверена). Не-гуманоидные монстры: `AnimationController` + `Animator` + Motor6D или Bone; кастомные гуманоиды играют R15-анимации через Adaptive Animation. Каталожные бандлы (Ninja, Zombie, Robot, Knight, Vampire, Werewolf, Rthro) имеют задокументированные ID по состояниям: подмена даёт разнообразие локомоции без авторской работы.

---

## 10. Моушн кодом: твины, пружины, питомцы, UI и пропсы

Процедурное движение это единственный по-настоящему «под ключ» путь анимации для агента (вывод): всё пишется кодом, проверяется в плейтесте.

### 10.1 Правила

1. **Твины и визуал на клиенте.** Сервер: состояние (атрибут `Open`, цель следования). Клиент слушает `GetAttributeChangedSignal` и твинит. Поздно зашедшие игроки должны «снэпнуться» в текущее состояние.
2. `TweenService` твинит number, boolean, CFrame, Rect, Color3, UDim, UDim2, Vector2, Vector2int16, Vector3, EnumItem. **Второй твин того же свойства отменяет первый.** `TweenInfo` не принимает `EasingStyle.Spring`/`Bezier` (ошибка).
3. EasingStyle (по справочнику): Linear, Sine, Back, Quad, Quart, Quint, Bounce, Elastic, Exponential, Circular, Cubic. Выбор: Quad/Quint/Exponential Out для входа и подтверждений; Back Out для «поп-ин»; Bounce/Elastic только для игривых мест; закрытие быстрее открытия. Официальные туториальные значения → `art-ui-audio.md` §10.1.
4. `TweenService:SmoothDamp(current, target, velocity, smoothTime, maxSpeed?, dt?)` возвращает `(newValue, newVelocity)` для number, Vector2, Vector3, CFrame; скорость хранится снаружи и передаётся каждый вызов. Подходит для следования (питомец, камера, элемент за курсором). Овершутящая «пружина» для бодрого UI всё ещё требует модуля или ручной пружины (без источника).
5. Процедурный оффсет на риге: `Transform` у `AnimationConstraint`/`Motor6D` умножением в `RunService.PreSimulation` (стакается с активными треками и не ломает ретаргетинг), пропуск при `Animator.EvaluationThrottled`.
6. Камера: `CameraType = Scriptable`, ведите `Camera.CFrame` и **обновляйте `Camera.Focus` каждый кадр** (часть визуала зависит от фокуса). Тряска: `BindToRenderStep` с приоритетом `Enum.RenderPriority.Camera.Value + 1`; пресеты EZ Camera Shake → `art-ui-audio.md` §10.2.
7. **ReducedMotion:** для каждого твина путь нулевой длительности или fade-only при `GuiService.ReducedMotionEnabled`.
8. **Стоимость:** `CanvasGroup` (групповой фейд) тратит дополнительную текстурную память и на слабом устройстве может отрисоваться пустой текстурой; в окнах UI на мобильных предпочитайте `UIScale` + фейд отдельных элементов или тяжёлые окна заранее с `Visible=false` (→ `art-ui-audio.md` §6.1). `ViewportFrame` не рисует частицы и пост-обработку.
9. Массовое движение пикапов/монет: один цикл `RunService.PreRender` и `workspace:BulkMoveTo` вместо твина на каждую часть.

### 10.2 Питомец: следование и покачивание (клиентский LocalScript)

API-имена сверены с доками, **в Studio не запускалось**. Питомец = клиентская Model, все части Anchored, CanCollide=false, PrimaryPart задан; сервер хранит только атрибут «какой питомец надет».

```lua
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local TweenService = game:GetService("TweenService")

local player = Players.LocalPlayer
local OFFSET = Vector3.new(3, 1.5, 3)   -- в системе координат персонажа
local SMOOTH_TIME = 0.25
local BOB_AMP, BOB_HZ = 0.35, 1.2        -- амплитуда/частота покачивания: стартовые значения, не измерены в топ-играх

local function followPet(pet: Model)
	local pos = pet:GetPivot().Position
	local vel = Vector3.zero
	local conn
	conn = RunService.PreRender:Connect(function(dt)
		if not pet.Parent then conn:Disconnect() return end
		local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
		if not root then return end
		local target = root.CFrame:PointToWorldSpace(OFFSET)
		if (target - pos).Magnitude > 60 then pos, vel = target, Vector3.zero end -- телепорт
		pos, vel = TweenService:SmoothDamp(pos, target, vel, SMOOTH_TIME, nil, dt)
		local p = pos + Vector3.new(0, math.sin(os.clock() * BOB_HZ * math.pi * 2) * BOB_AMP, 0)
		local look = Vector3.new(root.Position.X, p.Y, root.Position.Z)
		pet:PivotTo((look - p).Magnitude > 0.05 and CFrame.lookAt(p, look) or CFrame.new(p))
	end)
end
```

По наблюдениям (PS99, один клип, грубо): наземные питомцы низкого тира следуют на 1.5-2.5 высоты аватара позади со смещением влево; крылатые парят рядом на расстоянии около ширины тела. Амплитуда и период покачивания в топ-играх **не измерены**; синус 0.4 stud с периодом 1.5 с это [prior].

### 10.3 Магнит монет (клиент: визуал; сервер: проверка)

```lua
local CollectionService = game:GetService("CollectionService")
local Players = game:GetService("Players")
local RunService = game:GetService("RunService")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local collectRemote = ReplicatedStorage:WaitForChild("CoinCollect") :: RemoteEvent
local player = Players.LocalPlayer
local MAGNET_RADIUS, COLLECT_DIST = 18, 2.5
local ACCEL, MAX_SPEED = 60, 90

local coins: {[BasePart]: number} = {}
local function track(part: Instance) if part:IsA("BasePart") then coins[part] = 0 end end
for _, p in CollectionService:GetTagged("Coin") do track(p) end
CollectionService:GetInstanceAddedSignal("Coin"):Connect(track)
CollectionService:GetInstanceRemovedSignal("Coin"):Connect(function(p) coins[p :: BasePart] = nil end)

RunService.PreRender:Connect(function(dt)
	local root = player.Character and player.Character:FindFirstChild("HumanoidRootPart") :: BasePart?
	if not root then return end
	for coin, speed in coins do
		local to = root.Position - coin.Position
		local dist = to.Magnitude
		if dist <= COLLECT_DIST then
			coins[coin] = nil
			collectRemote:FireServer(coin)   -- сервер перепроверяет расстояние и владение
			coin.Transparency = 1
		elseif dist <= MAGNET_RADIUS or speed > 0 then
			speed = math.min(speed + ACCEL * dt, MAX_SPEED)
			coins[coin] = speed
			coin.CFrame += to.Unit * math.min(speed * dt, dist)
		end
	end
end)
```

Сервер при `CoinCollect`: расстояние `<= COLLECT_DIST + 10`, монета существует и не собрана, лимит частоты на игрока, затем награда и `coin:Destroy()` (→ `code-architecture.md`, валидация ремоутов). Монеты Anchored, CanCollide=false. В топ-играх магнит не наблюдался как полёт монеты в 3D (§15); этот код это общий приём, не канон.

### 10.4 Дверь / сундук

Сервер: `ProximityPrompt.Triggered` переключает атрибут `Open` и `CanCollide` (истина гейм-плея на сервере). Клиент: на каждую модель с тегом слушает `GetAttributeChangedSignal("Open")` и твинит `CFrame` двери с `TweenInfo.new(0.35, Back, Out)`; поздно зашедшие игроки применяют состояние сразу. Вращать нужно **вокруг петли**, а не центра части: `hingeCF * CFrame.Angles(...) * hingeCF:Inverse() * closed`. Серверный твин допустим для редкой одноразовой двери, но реплицирует свойство каждый кадр.

Источники: create.roblox.com/docs/reference/engine/classes/TweenService, /RunService, /Animator, /AnimationConstraint, /Camera; create.roblox.com/docs/performance-optimization/improve.

---

## 11. Ловушки и чек-лист отладки

Почти все случаи «анимация ничего не делает» сводятся к пяти причинам: неверный владелец (пользователь против группы), Animator не создан на сервере для не-игрового рига, конфликт приоритета/веса со стоковым Animate, несовпадение рига (R6-клип на R15, переименованные суставы), загрузка трека до того, как Animator оказался в Workspace.

**Чек-лист (можно автоматизировать в плейтесте):**
1. `track.Length > 0` и `IsPlaying`;
2. нет ошибок разрешений в Output;
3. логируйте `track.Priority` и `WeightCurrent`;
4. `rig:FindFirstChildOfClass("Animator")` существует на сервере;
5. владелец анимации совпадает с владельцем игры (группа);
6. `Humanoid.RigType` соответствует клипу (R15);
7. не превышен лимит 256 треков (кэшировать);
8. приоритет: кастомный Idle перекрывается стоковым Movement; атаки ставить на Action;
9. петля: между последним и первым ключами интерполяции нет, продублируйте первые ключи в конец; `TimePosition` после Play;
10. StreamingEnabled: стримящийся NPC/проп может ещё не иметь Animator на клиенте при старте скрипта: ждите `WaitForChild` или грузите по `GetInstanceAddedSignal` (вывод, не цитата из доков);
11. R6/R15: клип R6 не поведёт R15-риг и наоборот.

Источники: create.roblox.com/docs/animation/using; create.roblox.com/docs/reference/engine/classes/Animator.

---

# ЧАСТЬ B. МОУШН-КАНОН ТОП-ИГР

## 12. Метод, ограничения и обозначения

- **Источники:** ~30 клипов из ~35 видео YouTube (PS99, BGSI, Adopt Me, Steal an Egg, Steal a Brainrot, Grow a Garden, Kick a Lucky Block, Fisch, Anime Vanguards, Sol's RNG, TSB, Jujutsu Shenanigans, Blox Fruits, Sailor Piece, DOORS, Pressure, Forsaken), снятые 27.10.2026 покадровой выборкой (пауза `<video>`, шаг 0.033-0.6 с). Видео 2025-середины 2026 (не все свежие; часть правок монтажёров).
- **Погрешность:** каждый тайминг это метка поиска, ±половина шага листа + 1 кадр источника (1/30 или 1/60 с); для 30-fps пережатия hitstop <0.1 с не измерим.
- **Выборка малая:** N из M считается по клипам, где явление видно и измеримо; M обычно 2-8. Теги canon/common/seen пересчитаны по строгому правилу (canon ≥5 клипов); прежние «canon (n=2)» понижены.
- **Не наблюдалось** (см. §18): звук, нажатие кнопки с масштабом, красные точки, магнит монет, блок/парирование, ульта в бою, амплитуда покачивания питомца, тайминг открытия попапа офлайн-дохода, современный обычный ролл Sol's, easing одиночного спрайта к счётчику. Эти пункты в скилле считаются **дизайн-решением, а не каноном**.
- Номера правил `R1…R35` взяты из итоговых сводок раундов 3 и 4 моушн-серии (раунд 4 изменил R13, R16, R23, R29 и добавил R31-R35; моушн-канон считается сошедшимся: сырая полнота ≈62%, от достижимого ≈86%). Они ссылаются на строки таблиц ниже.

**Обозначение:** `TI(t, Style, Dir)` = `TweenInfo.new(t, Enum.EasingStyle.Style, Enum.EasingDirection.Dir)`. Все визуальные твины на клиенте. Пути без «нулевой длительности» для ReducedMotion недопустимы (§10.1).

---

## 13. Вылупление, гача, ролл: последовательности и тайминги

### 13.1 Измеренные сценарии

| Сценарий | Фазы и длительности | Итого | Источник |
|---|---|---|---|
| **PS99, ручной/медленный цикл** | выброс яиц дугой/кольцом ≈1.5 с → зависание и дрожание ≈2.5 с → взрыв: белое облако + искры ≈0.5 с → наклон/подтяжка камеры ≈1.5 с → reveal, удержание ≥1.5 с | **≈6.5 с** (±0.5) | 3 цикла PS99 |
| **PS99, быстрый цикл** | яйца подаются к камере 0.5-1 с → дрожание 2.5 с → взрыв 0.5 с → reveal | **≈4 с** | PS99 цикл 2 |
| **PS99 Huge** | облако с лучами ≈2 с → пик белой вспышки ≤0.5 с → питомец крупно (35-40% ширины экрана) 1.5 с с hue-циклом и 4-точечными искрами → имя ≈1.0 с → уход питомца ≈0.5 с + вторая вспышка | **≈5 с** | PS99 e-S0rJ7VoBE |
| **PS99 Gargantuan** | питомец удержан 2.5-2.75 с, конфетти/стримеры, вспышка + разлёт искр ≈0.25 с | | PS99 multi |
| **BGSI авто-хэтч** | яйцо ≈1.0-1.25 с → белый силуэт ≈0.25 с → tint цветом тира + reveal ≈0.75-1.0 с → удержание ≈1.0 с; **без зависания** | **3.0 с** (±0.25), 2 цикла подряд | BGSI J3FMWcgqyhk |
| **BGSI Mythic** | экран розовый → магентовый tint ≈0.4-0.6 с → питомец с hue-циклом, плашка «Mythic» + «1 in 10M»; удержание ≥3.5 с | | BGSI-A |
| **Adopt Me** | яйцо в мире → **белый экран с радиальными лучами ≈1.75 с** → питомец с яркой каймой, затухание ≈1.75 с; имя + «Newborn» с ≈0.5 с после | **≈4 с** от яйца до питомца | Adopt-1 |
| **Adopt Me, первое открытие** | через ≈2.6 с после взрыва карточка «New Pet Discovered!» (рамка-портрет, имя крупно, кнопки DONE красная / NEXT зелёная, мир размыт и тёплый tint), **закрывает игрок**; затем панель «Journal Updated!» (≥1.8 с) и страница индекса «x/11» (≈3 с) | от взрыва до возврата в мир ≈15 с, из них ≈12 с UI в темпе игрока | AdoptMe-Fairy |
| **Adopt Me, повтор** | карточки нет (питомец уже в индексе) | | 3 хэтча без карточки |
| **Anime Vanguards, редкий призыв** | чёрный экран ≈0.8 с → частицы → имя + шансы в нижней трети ≈1.6 с → небо и искры ≈1 с → персонаж слайдом слева ≈1.2 с → вставка атаки | **≈5.5 с** | AV |
| **Sol's RNG, обычный ролл (старая сборка v1885, quick roll)** | баннер «You've found…» сверху по центру ≈1.3 с (±0.25), без блэкаута | ≈1.3 с | Sol-100d |
| **Sol's RNG, 1 из 72M** | чёрный/тёмно-синий звёздный экран с пульсирующей звездой ≈6.4 с → горизонт ≈0.2 с → бурст ауры, кольца, световой столб | **≈6.6 с** | aZ-mk2y-TAE |
| **Sol's RNG, редкий Monarch** | рост кольца ≥5 с → чёрный экран ≥3 с → текст-кинематограф ≥4 с | **≥12 с** до ауры | Sol-Monarch |
| **Sol's RNG, глобальный (Breakthrough)** | letterbox, серифные титры каждые 2.5-5 с, белая вспышка | 38 с | Sol-cut |

### 13.2 Правила (R1-R11, R30)

| # | Правило | n / уверенность | Реализация на Roblox |
|---|---|---|---|
| R1 | Hatch = дрожание ≈2.5 с → взрыв ≈0.5 с → удержание 1.5-3.5 с; ≈4 с быстро, ≈6.5 с медленно. Зависание/дрожание **только для ручного/медленного** хэтча | 3 цикла PS99 / common | бросок яйца по `CFrame` `TI(0.8, Back, Out)`; дрожание: синус по крену ±6° с амплитудой 0→1 за 2.5 с; взрыв `ParticleEmitter:Emit(40)` белое облако |
| R2 | Быстрый/авто хэтч сжимается до ≈3.0 с на яйцо, без зависания | 2 цикла BGSI / seen | один множитель `speed` на все длительности; тоглы «Open 1/3/8» и Auto; монетизируемый рычаг (pass ускоряет вдвое: см. `monetization.md`) |
| R3 | Белое затемнение: вход ≈0.15 с, удержание лучей ≈1.75 с, затухание каймы ≈1.75 с (Adopt Me) | 3 хэтча / seen | полноэкранный `Frame` `BackgroundTransparency` `TI(0.15, Quad, In)` 1→0, пауза, `TI(0.6, Quad, Out)`; или `ColorCorrectionEffect.Brightness` 0→1→0 + `BloomEffect` |
| R4 | Tint экрана цветом тира на reveal ≈0.75-1.0 с (BGSI: магентовый для Mythic) | 3 из 8 / common | `ColorCorrectionEffect.TintColor` + `Saturation` `TI(0.2, Quad, Out)` вход, `TI(0.6, Sine, In)` выход |
| R5 | Имя + слово тира + шансы под питомцем, толстый контур, без панели (5 из 8); AV: нижняя треть | canon | `BillboardGui` + `TextLabel` + `UIStroke` Thickness 2-3 чёрный; цвет тира через `UIGradient.Color` (→ `3d-asset-canon.md` §8.3) |
| R6 | Время удержания растёт с редкостью: ≈1.0 с быстрый, 1.5 Huge, 2.5 Gargantuan, ≥3.5 Mythic | 3 / common | `holdTime = {Common=1, Rare=1.5, Epic=2, Legendary=2.5, Mythic=3.5}` (вывод по точкам) |
| R7 | Длина и темнота кинематографа растут с редкостью: ≈1.3 с обычный, ≈5.5 с AV, ≈6.6 с 72M, ≥12 с Monarch, 38 с глобальный | 5 клипов / common | таблица редкости задаёт альфу блэкаута, `Camera.FieldOfView` удар, letterbox, длительность; глобальный через `MessagingService` |
| R8 | **Пропуск по порогу у игрока:** «Cutscene Skip Rarity» (порог), «Play New Aura Cutscene», «Warning Rarity», «Auto Equip Rarity», «Aura Filter» в Settings > Roll Settings | Sol's RNG (1 игра, проверено) / seen | настройки в DataStore; `if rarity < skipThreshold then skipTimeline()`; отдельный тогл «первое открытие» |
| R9 | Карточка первого открытия: появляется ≈2.6 с после взрыва, закрывает игрок; белый силуэт портрета заполняется ≈0.6 с (на самом деле асинхронная загрузка 3D/viewport, ≈3 с на полную подгрузку); затем «Journal Updated» и индекс | 2 карточки / seen | `ViewportFrame` с моделью; `BlurEffect.Size` 0→20 `TI(0.25, Quad, Out)`; силуэт = белый `Ambient/LightColor` во ViewportFrame, затем твин к норме; показывать только `if not Index[petId]`; **никогда не авто-продвигать** |
| R10 | Мульти-хэтч: кольцо/дуга 3-8 яиц, один и тот же таймлайн параллельно, яйцо это 3D-объект мира (4 из 4 egg-игр) | canon | дуга вокруг `HumanoidRootPart`; корутина на яйцо с общим «временем» |
| R11 | Rainbow = hue-цикл цвета на премиальных питомцах | 3 / common | `UIGradient.Offset` `TI(1, Linear, InOut)` в цикле или `Color3.fromHSV((t*0.6)%1, 0.7, 1)` по кадру |
| R30 | Меню автоматически скрываются при начале хэтча/ролла; тоглы «Auto roll», «Quick roll» внизу по центру | 3 / common | `ScreenGui.Enabled=false` на старте; тоглы это BoolValue, укорачивающие таймлайн (R2) |
| R34 (НОВОЕ, дополняет R30) | Современный гача-HUD (Sol's RNG, окт 2026): внизу по центру [Auto roll : ON] [Roll] [Quick roll : ON] с подписью «Player will automatically roll again» над Roll; **внизу справа уведомления-тосты ≥1 с каждое** («Item Collected» ≥1.05 с, «Coin Notification» ≥0.85 с), стеком в одном слоте, разных типов; для предметных событий жёлтая полноэкранная вспышка ≈0.6 с и синяя молния. Обычный ролл современной сборки не пойман (v1885: ≈1.3 с) | 1 игра / seen | `Frame` внизу справа + `UIListLayout`; жизнь тоста 1.0-1.5 с, очередь вместо наложения |

**Общая спецификация (вывод, собрано из измеренного):** 0-0.8 с яйца выбрасываются к кольцу/дуге перед игроком (бросок + scale-in) → до ≈3.3 с зависание и дрожание (только в медленном режиме; в быстром пропуск) → ≈3.3-3.8 с взрыв: белое облако 0.5 с, для редких тиров добавляйте полноэкранный белый (или цвета тира) пик 0.3-0.5 с → ≈3.8-5.5 с reveal: питомец по центру (для Huge 35-40% ширины экрана; обычные 15-25%: оценка), hue-цикл у Rainbow, 4-точечные искры, имя + тир + «1 in N» → ≈0.5 с уход питомца к игроку/инвентарю, вторая вспышка по желанию. Итого ≈6.5 / 4 / 5 с (медленный / быстрый / Huge).

**Реализация (подсказки):** питомцы и яйца это клиентские 3D-модели, позиционируемые каждый кадр в пространстве камеры; `ViewportFrame` не рисует частицы и пост-обработку (→ `art-ui-audio.md` §6.1, §10.5). Эталон community-скрипта (все длительности делятся на `hatchSpeed` 2 → 4 с game pass): базовые ≈10.6 с, около 5.3 с по умолчанию и ≈2.7 с быстрый; он близок к измеренным 6.5 / 4 / 3.0 с. **Ограничения мобильных:** до 100 частиц/с на эмиттер; для массового мульти-хэтча уменьшайте частицы и число одновременных эмиттеров.

**Звук** (не наблюдался): нарастающий `Sound.PlaybackSpeed` 0.8→1.2 на зависании, одноразовый удар на взрыве [prior]; ±10% питч у повторяющихся SFX → `art-ui-audio.md` §10.4.

Источники: видео из `05_motion_canon.md` и `05_round2/3` (PS99 7V8L1oCRxHU, e-S0rJ7VoBE, eCv4iXr1oSE; BGSI J3FMWcgqyhk, tPs67FQavb4; Adopt Me XRCTv-DKxWA, 1ydhqinqJYE, H5-uByqXCgY; AV 4pxt5-8xTKw; Sol's mIgcPe2RNtw, aZ-mk2y-TAE, a4EAJZ3hWiM, fcuo8hdPjbE, aBqNQF9MXIQ); devforum.roblox.com/t/help-with-egg-open-animation/2876100.

---

## 14. Окна, кнопки, счётчики, тосты, ребёрс, телепорт

| # | Правило | Тайминг | n / уверенность | Реализация |
|---|---|---|---|---|
| R12 | **Открытие окна:** масштаб ≈0.6 → 1 за ≈0.3 с с лёгким овершутом, контент проявляется; затемнение/размытие фона появляется в первом же кадре; магазины часто размывают мир (GaG, Steal a Brainrot, BGSI). Прежнее «открытие мгновенное» опровергнуто (было склейкой монтажа) | 0.25-0.35 с; 4 чистых замера + GaG / common | `UIScale.Scale` `TI(0.3, Back, Out)` от 0.6; фейд контента `TI(0.15, Quad, Out)` (с осторожностью с `CanvasGroup`, §10.1 п.8); затемняющий `Frame` чёрный `BackgroundTransparency` 0.55 (около 40-50% затемнения) или `BlurEffect.Size` 0→12 `TI(0.2, Quad, Out)` |
| R13 (ИЗМЕНЕНО раундом 4; было «мгновенно») | **Закрытие окна ≤0.15 с:** короткое сжатие и скрытие (попап до ≈0.95 масштаба, исчез в следующие 0.1 с) | 4 из 4 / common | `UIScale.Scale` 1 → 0.95 `TI(0.1, Quad, In)`, затем `Visible=false` |
| R14 | **Нажатие кнопки:** смена цвета ≈0.1 с (фиолетовый → жёлтый), без изменения размера в 4K-кропах; hover/pressed ≥0.4 с в апгрейдах | 2 игры / seen | `MouseButton1Down`: поменять `BackgroundColor3`, вернуть на отпускание; сжатие 0.95 остаётся [prior]. Официальные значения туториалов (нажатие 0.15-0.2 с) → `art-ui-audio.md` §10.1 |
| R15 | **Успешная покупка:** мгновенная смена состояния в том же кадре (кнопка зелёная → красная если следующий уровень недоступен, цена обновилась, индикатор уровня зажёгся циановым 0.2 с); тоста, монетки и пульсации нет | 1 клип / seen | обновление по серверному ack; индикатор `BackgroundColor3` вспышка циан 0.2 с; звук `Sound:Play()` по желанию |
| R16 (ИЗМЕНЕНО раундом 4) | **Малые счётчики** меняются дискретно (≤0.1 с), без «накрутки» и пульса: $98.53M → $98.55M за один шаг; суффиксы K, M, B, T, Qa. Исключение: счётчик монет PS99 тикает непрерывно, пока прилетают 2D-спрайты. **Крупная награда (клейм офлайн-дохода) считается вверх ≈1.0-1.1 с:** «ползучая» фаза ≈0.25 с (≤10%, пока летят купюры), быстрый прогон (пик ≈2-3 доли/с), мягкий хвост ≈0.4 с; старт ≈0.4 с после клика; форма ease-in-out со смещением к Out (вывод по сэмплам; Quad/Expo Out после задержки подходит лучше Sine InOut) | 4 клипа (1 count-up) / seen | малые: задавать `Text` напрямую; крупные: `NumberValue` 0 → награда `TI(0.9, Quad, Out)` после `task.wait(0.25)`, формат той же функцией сокращений каждый кадр (→ `art-ui-audio.md` §10.6) |
| R18 | **Ребёрс:** без VFX. Телепорт игрока + сброс статов + зелёный тост «You successfully rebirthed!» ≥5 с внизу по центру; окно закрывается ≈1.2 с спустя. В BGSI вообще без эффекта: окно остаётся, счётчик сбрасывается, кнопка серая | 2 игры / seen; **свободное место для дизайна, не конвенция** | `PivotTo` на спавн, сброс leaderstats, тост `TI(0.25, Back, Out)`; VFX как необязательное отличие (не проверено) |
| R19 | **Тост:** обычный текст с контуром сверху по центру, без панели, появляется ≤0.2 с, держится ≥2.6 с; повтор тоже же сообщения не создаёт новый тост, а добавляет суффикс «[X2]», «[X3]» (по одному на нажатие, шаг ≈0.4 с) | 1 игра (GaG) / seen | один `TextLabel` + `UIStroke`; инкрементировать счётчик вместо дублей |
| R20 | **Баннер события** слайдом слева ≈0.3 с, удержание ≈1 с; **квест выполнен:** маленький текст + зелёное квадратное конфетти ≈0.4 с + полоса ранга слайдом сверху | 1 игра (PS99) / seen | позиция `TI(0.3, Back, Out)`; конфетти `Emit(40)`, `RotSpeed` случайно, `Acceleration (0,-30,0)`, `Lifetime` 1.2 |
| R32 (НОВОЕ) | **Колесо эмоутов — стандартный CoreGui:** открывается за ≤1 исходного кадра (≈0.03-0.07 с, без твина), 8 нумерованных секторов вокруг тёмного полупрозрачного диска по центру экрана (ниже середины), диаметр ≈20% высоты экрана, иконки поз на ободе; центр показывает название эмоута под курсором; подсвеченный сектор светло-серый, реакция ≤0.14 с; выбор закрывает колесо (≤0.14 с) и эмоут стартует сразу. Альтернативный вход — вертикальный список слева | 1 клип / seen (ядро Roblox, применимо ко всем играм с CoreGui-эмоутами) | не пересобирайте; для своего колеса: переключение `Visible`, подсветка сектора на `MouseEnter` мгновенно, смена `TextLabel.Text` в центре, `Humanoid:PlayEmoteAsync(name)` (`PlayEmote` устарел, §6.1); открывающий твин не нужен |
| R21 | **Телепорт в зону:** кнопка «Buy» растёт при приближении камеры → экран белеет (не чернеет) ≈0.5 с → удержание ≈0.25-0.5 с → новая зона проявляется ≈0.25-0.5 с; питомцы разбегаются вокруг игрока; всё ≈1.5-2.0 с | 1 игра (PS99) / seen | белый `Frame` `TI(0.5, Quad, In)`, `PivotTo` пока непрозрачно, `TI(0.4, Quad, Out)`; блокируйте ввод |

**Что общего:** окна открываются «живо», но закрываются мгновенно; подтверждения (покупка, ребёрс) показываются сменой состояния и коротким текстом, а не фейерверком. Это одновременно ограничение (не ждите от топ-игр эталонного «сока» на ребёрсе) и возможность отличиться, но проверяйте VFX на ретеншн, не считайте их конвенцией. Статичный UI (положение валют, левое меню, красный X) → `ui-canon.md`.

Источники: BGSI JO7g6QbaBVQ (4K), Steal a Brainrot jGQm_BX2Loo, PS99 eCv4iXr1oSE и gx7Lwqiw5eA, GaG (_b7jdplqqhU, 8O4ktjD5HtM), Adopt Me 1ydhqinqJYE.

---

## 15. Награды, монеты, офлайн-доход

| # | Правило | Тайминг | n / уверенность | Реализация |
|---|---|---|---|---|
| R17 | **Два слоя монет:** 3D-меши монет от сундука остаются лежать на земле как декор; к счётчику HUD летит **поток 2D-спрайтов монет** (≈1-1.5% высоты экрана), с шагом, не залпом; одиночный полёт ≥0.15 с; взрыв сундука ≈0.3 с с жёлтыми искрами; теги урона/монет над питомцами обновляются на месте. Полёт монеты в 3D (магнит) не наблюдался | 1 игра (PS99, 60 fps) / seen; время и easing одиночного спрайта не измерены | спрайт `ImageLabel` в точке `Camera:WorldToViewportPoint`, `TI(0.5-0.7, Quad, In)` к иконке счётчика, затем инкремент; спавн с шагом 0.03-0.05 с, 8-20 спрайтов на разрушение, **не больше ≈30 живых спрайтов** (мобильные); взрыв `ParticleEmitter` `Emit(25)` `Lifetime` 0.3 |
| R29 (ИЗМЕНЕНО раундом 4; было [prior]) | **Офлайн-доход = модальное окно «Welcome BACK!» при заходе:** тёмная панель с толстой зелёной пунктирной рамкой, строка «You were offline for 2h 19m 35s and earned…», крупное зелёное число + слово единицы («sextillion») на тёмной вставке; кнопки серая **[OKAY]** и зелёная **[DOUBLE IT!]** с тегом «x2» и ценой **25 R$**; закрывает игрок (≥7 с на экране); **без затемнения и размытия фона** (в отличие от магазинов и карточек Adopt Me, R12), HUD и таймеры идут позади. Также в Steal an Egg постоянная строка сверху «You earn $187T/Day offline!», в Steal a Brainrot статичное приглашение «Offline Cash $4.1T / Collect». Тайминг ОТКРЫТИЯ попапа не пойман | 2 клипа / seen | на входе `earned = rate * math.min(os.time() - lastSeen, cap)`; модальное окно; [OKAY] начисляет `earned`; [DOUBLE IT] = `MarketplaceService:PromptProductPurchase` (Developer Product ≈25 R$) и начисление ×2 в `ProcessReceipt`; **не начислять до нажатия**; открытие по R12 как дизайн-выбор; формула и кап ваши (→ `monetization.md`, `code-architecture.md`) |
| R31 (НОВОЕ) | **Цепочка обратной связи клейма:** клик → попап закрывается ≤0.15 с → спрайты купюр взрываются вокруг аватара ≈0.6 с (25-40 одновременно) → счётчик HUD считает вверх ≈1.0 с (R16) | 1 клип / seen | `ParticleEmitter` (Image = купюра) `Emit(30)`, `Lifetime` 0.6, разброс 360°; либо 2D `ImageLabel` с твином к счётчику (R17); не больше ≈30 живых спрайтов на мобильных |
| — | Hub-collect игры (Steal a Brainrot, Steal An Egg): без пикап-мешей, зелёная площадка «Collect» + плавающий «+$» | 2 из 2 | `Part` с `Touched`/ProximityPrompt и `BillboardGui`; валидация на сервере |

---

## 16. Бой: числа урона, hit freeze, M1, тяжёлые приёмы

| # | Правило | Тайминг | n / уверенность | Реализация |
|---|---|---|---|---|
| R22 | **Плавающий урон/прирост** над целью; накопительный счётчик тикает каждые 0.15-0.3 с (Blox Fruits: фиксированная позиция слева-по-центру, угасает 0.5-1 с после последнего удара) | 2 игры / seen | `BillboardGui`, подъём на 3 stud `TI(0.6, Quad, Out)`, фейд `TextTransparency`; объединяйте удары в окне 0.3 с. Официальный дефолт Weapons Kit: числа урона видит только атакующий |
| R23 (ИЗМЕНЕНО раундом 4; seen → common по 2 клипам TSB) | **Тяжёлый приём:** замах/удержание 0.2-0.35 с (фиолетово-розовый вихрь-дуга ≈0.35 с в одном клипе) → **однокадровая белая вспышка/колонна** (≈1-3 исходных кадра) → кольцо/взрыв (≥0.1 с) → белый дым 0.5-2 с, обломки и трещины → цель отброшена; в другом клипе вспышка → кольцо → вихрь → пыль → обломки ≈2 с. Сцена десатурируется, пока горит полоса «SERIOUS MODE». **Заморозка при тяжёлом ударе ≈0.2-0.3 с** перед нокаутом | 2 клипа TSB (4 сэмпла) + заморозка / **не подтверждено как движковый hitstop** (пережатие может дать то же); **это тяжёлая атака/ульта, не блок** | `AnimationTrack:AdjustSpeed(0)` на обоих ригах 0.06-0.15 с (настройте ниже наблюдённого), вернуть скорость; однокадровая колонна = `Transparency` 0 на один `Heartbeat`; кольцо = Neon-цилиндр `Size` `TI(0.35, Quad, Out)` + `Transparency` 0→1; дым `ParticleEmitter` `Lifetime` 2; камера `Humanoid.CameraOffset` дрожь 0.1 с |
| R24 | **M1:** 3 удара с шагом 0.25 с + апперкот-эндер; «consecutive punches» ≈1.3 с; полоса ульты показывает название приёма при 100%; слоты приёмов 1-4 (с пометкой «USE TWICE») | 3 клипа / common | `GetMarkerReachedSignal("Hit")` запускает VFX; полоса ульты `Frame` размер твином, смена подписи на 100% |
| R35 (НОВОЕ, дополняет R24) | **HUD тяжёлого приёма:** красная сегментированная полоса «SERIOUS MODE»/ульты над четырьмя нумерованными слотами приёмов (названия под каждым: Normal Punch / Consecutive Punches / Shove / Uppercut), подсказка клавиши «[C]» под полосой; оверлей Ping/FPS сверху справа | 2 клипа / seen | `Frame` полоса с `UIGradient`; кнопки слотов на клавиши 1-4; подсказка `TextLabel` |
| — | **Каденс навыков:** элементные слэш-тренды 0.2-0.4 с с паузой 0.2-0.6 с (Sailor Piece); удары Jujutsu 0.25-0.5 с; кольца удара на земле (3 из 3); запуск жертвы вверх (2 из 2) | common/canon | как R23; разброс по маркерам |
| — | Камера файтеров: высокий вид сзади-сверху (30-45° вниз), персонаж 10-15% высоты кадра | 3 из 3 / canon | `Camera.CFrame` в `Scriptable`/смещение стандартной |

Не измерено: M1-серии целиком, дэш и блок, ульта в бою, истинный hitstop на 60 fps. Не копируйте заморозку 0.2-0.3 с как факт; начните с 0.06-0.15 с и сравните на плейтесте.

---

## 17. Тинт мира, хоррор-погоня, питомцы, рыбалка

| # | Правило | Тайминг | n / уверенность | Реализация |
|---|---|---|---|---|
| R25 | **Тинт всего мира при редком событии:** Sol's RNG (красный/зелёный/магента по ауре), Kick a Lucky Block (розовая пульсация), BGSI (магента), DOORS (зелёный) | 4 из 4 / canon | `Lighting.ColorShift_Top`, `ExposureCompensation`, `ColorCorrectionEffect` `TI(0.2, Quad, Out)` вход, `TI(1, Sine, In)` выход |
| R26 | **Хоррор-погоня:** красный тинт полного экрана + темнота + радиальное размытие; проход сущности ≈1 с (DOORS Rush: свет гаснет ≈0.35 с до, сущность видна ≈1 с, второй проход через ≈2.5 с); HUD крошечный, маленький круглый индикатор здоровья слева внизу | 3 из 3 / canon | `ColorCorrectionEffect.TintColor` к красному; `BlurEffect.Size` пульс 0→10; `Camera.FieldOfView` 70→82 `TI(0.12, Quad, Out)`; ambient/тени не опирайте на тени ниже качества 4 (`art-ui-audio.md` §6) |
| R27 | **Лестница редкостей (цвет):** «серый/зелёный → синий → пурпурный → золото → красный/магента → радуга» (по 5 тирам, n=1-2 на тир) | seen. **Не универсальна** (§18, п.1) | один модуль `RarityColors` управляет подписью, тинтом, частицами |
| R28 | **Рыбалка (Fisch):** замах назад ≈0.25 с → бросок ≈1.5-1.75 с → пунктирная дуга удочка-поплавок → полоса вываживания появляется ≈0.25 с позже; поклёвка = красный «!» над головой; пойманная рыба держится ≈4 с с подписью «I caught a …!» и тонким красным столбом; босс-бой ≈65 с: цвет зоны на полосе белый → фиолетовый → оранжевый → магента, ноты-иконки каждые ≈5 с | 1 цепочка / seen | маркеры анимации; дуга `Beam` (`CurveSize0/1`, `Segments` 10) между attachment кончика удилища и поплавка |
| R33 (НОВОЕ) | **Idle питомца:** моргание ≈0.3 с (глаза закрыты ≈0.2 с, открыты к 0.3 с) раз в несколько секунд; аксессуары (шарики) покачиваются; пыль/искры под лапами при шаге | 1 клип (Adopt Me) / seen | подмена текстуры глаз (`Decal`/текстура меша) на 0.25 с по случайному таймеру 2-5 с; амплитуда и период покачивания [prior], не измерены |
| — | **Питомцы в мире:** наземные питомцы низкого тира следуют на 1.5-2.5 высоты аватара позади и слева; крылатые парят рядом; покачивание в синусоиде с периодом ≈1.5 с и амплитудой ≈0.4 stud это [prior] | 1 клип / seen | см. §10.2 (`SmoothDamp` + синус) |
| — | **Носимый brainrot (Steal a Brainrot):** носитель в голубом сферическом пузыре-щите, над brainrot красный тег «STOLEN» со значением; площадка «Collect $X» | 2 из 2 клипов / seen | `ForceField`-подобная сфера `Transparency` 0.6 + `BillboardGui` |
| — | **Шаблон частиц-похвалы:** 4-точечные звёзды как универсальный «хороший» партикл (6 из 8 reveal-клипов); хит-кольца на земле; жёлтое пламя на краже/кэше | canon/common | `ParticleEmitter` с текстурой звезды, `LightEmission` 1 |

---

## 18. Что НЕ измерено и конфликты источников

**Не наблюдалось (дизайн-решения, не канон; скилл помечает их так):**
- блок (F) / парирование / вспышка идеального блока (поиск в TSB нашёл только тяжёлую атаку);
- амплитуда и период покачивания питомцев (камера двигалась относительно питомцев; моргание измерено, покачивание нет);
- обычный ролл Sol's RNG в современной сборке (измерены только UI и тосты; v1885: ≈1.3 с);
- easing и время полёта **одиночного** спрайта к счётчику (известны только пакетные тайминги: купюры 0.6 с, count-up ≈1.0 с);
- твин **открытия** попапа офлайн-дохода (клип начинался с уже открытого окна): берите R12 как дизайн-выбор.

Также не измерено: звук (весь); сжатие кнопки при нажатии; красная точка на уведомлении и пульс; магнит монет и полёт 3D-монеты; ежедневная награда/колесо; ульта в бою и истинный hitstop на 60 fps; последовательность M1 целиком; дистанция следования питомцев в stud; Fisch-замах в чистом виде; «Level Up!» (Fisch: белый обведённый текст с числом, тайминг не мерился); ребёрс как эффект; истинные FOV и расстояния в stud; путь покупки Robux в попапе (кнопки не нажимались); формула и кап клейма (из видео не видны).

**Конфликты и как они разрешены:**
1. **Лестница цвета редкости.** Моушн-серия (R27) даёт порядок «серый/зелёный → синий → пурпурный → золото → красный → радуга», а серия 3D-ассетов (`3d-asset-canon.md` §8) по 8 играм показывает, что универсальной лестницы нет (Epic: золото в PS99, пурпур в Steal a Brainrot; Common: серый / зелёный / синий). Принято более позднее и более широкое: порядок это тенденция, **ваш ассортимент задаётся одной таблицей** игры; UI-канон → `ui-canon.md` §3.5.
2. **Открытие и закрытие окна.** Первая серия: «мгновенное (≤0.033 с)» — опровергнуто (было склейкой), измерено 0.25-0.35 с; закрытие в раунде 4 уточнено с «мгновенно» до «≤0.15 с, сжатие и скрытие» (R13). Попап офлайн-дохода без затемнения фона, магазины с ним (R29 против R12). Официальные туториалы Roblox: меню 0.5 с Bounce Out, закрытие 0 с (`art-ui-audio.md` §10.1). Принято: для топ-игр ≈0.3 с, Back Out, закрытие мгновенное; 0.5 с допустимо как верх диапазона.
3. **Универсальный «зависающий» хэтч 2.5 с.** Первая серия считала шаг универсальным; BGSI авто-цикл его не имеет (3.0 с на яйцо). Принято: условный шаг только для ручного режима.
4. **Hitstop 0.2-0.3 с.** Три клипа TSB показывают застывание, но пережатие 30/60 fps могло дать то же; метка «seen, unconfirmed»; в реализации берите меньше.
5. **Тайминги community-скрипта хэтча** (`art-ui-audio.md` §10.5; 5.3 / 2.7 с) отличаются от измеренных (6.5 / 4 / 3.0 с). Принято: измеренные как ориентиры топ-игр, скрипт как рабочая заготовка.
6. **Троттлинг:** первая версия заметок описывала `Workspace.ClientAnimatorThrottling` как рабочий переключатель; позднее подтверждено перманентное включение с 29.04.2026. Принято позднее.
7. **Цены инструментов:** DeepMotion «60 с бесплатно» (старая страница) → 25 кредитов в месяц (живая страница 27.10.2026, принято); Moon Animator 2 «статус неясен» → поддерживается (проверено на Creator Store).
8. **Text-to-motion у Rokoko:** первая заметка предполагала бесплатный Starter в Rokoko Create; вендорская справка говорит «Plus и Pro в Studio Preview». Разные продукты возможны; не проверено, принято консервативно (платный).
9. **Список EasingStyle:** серия моушна перечисляет 9 стилей, справочник 11 (+Circular, Cubic). Принят справочник.

**Открыто (Часть A):** сквозная проверка рецепта §5; Open Cloud загрузка анимации; качество text-to-motion на R15; Animation Capture GA; публикационный аванс паков (не в доках); мобильные бюджеты анимации (не публикуются); пороги LOD аниматора (не публикуются); данные «какие клипы реально использует топ-игра» (не публичны).

---

## 19. Источники

- Roblox docs: https://create.roblox.com/docs/animation/editor ; /animation/curve-editor ; /animation/graph-editor ; /animation/capture ; /animation/events ; /animation/inverse-kinematics ; /animation/using ; /characters/adaptive-animation ; /characters/emotes ; /avatar/animation-packs ; /avatar/emotes/specifications ; /studio/avatar-settings ; /art/characters/export-avatar-animations-from-maya ; /studio/importer ; /projects/assets/privacy ; /cloud/guides/usage-assets ; /marketplace/marketplace-fees-and-commissions ; /marketplace/marketplace-policy ; /marketplace/validation-system ; /performance-optimization/improve ; /performance-optimization/scene-analysis ; /production/monetization/18-plus-devex-rate ; справочник: /reference/engine/classes/{Animator, AnimationTrack, AnimationConstraint, TweenService, RunService, Camera, Workspace, GenerationService} и /reference/engine/enums/EasingStyle.
- DevForum: roadmap весна https://devforum.roblox.com/t/creator-roadmap-2026-spring-update/4625473 , осень /creator-roadmap-2026-fall-update/4880208 , RDC26 /rdc26-what-we-announced/4865880 ; троттлинг /4568218 ; импорт анимаций /animation-import-improvements/4775593 ; HEAT /motion-capture-animation-into-roblox-with-heat-tutorial/3127168 ; MA2 /any-alternatives-to-ma2-moon-animator-2/4770365 ; лимит 256 /2577096 ; хэтч /help-with-egg-open-animation/2876100.
- Creator Store, Moon Animator 2: https://create.roblox.com/store/asset/4725618216
- Вендоры: deepmotion.com/pricing-animate3d ; docs.move.ai/knowledge/move-ai-pricing-plans-credits ; plask.ai/pricing ; rokoko.com/studio-term-of-use ; nocapmocap.com/terms ; mixamo.com ; cascadeur.com/plans.
- Видео для Части B: список видео-ID в `research_notes/Level design/05_motion_canon.md`, `rounds/05_round2.md`, `rounds/05_round3.md`, `rounds/05_round4.md`, `critiques/critique_05_motion.md`; раунд 4: Lemon-Offline 2WVyyKQiOKo (офлайн-попап), Emote-2026 2Guc3Jrz9j8 (колесо эмоутов), TSB pxsLjax4bkw, Sol's SZec3MKUGtA, Adopt Me 5c95qGaO5a4.

