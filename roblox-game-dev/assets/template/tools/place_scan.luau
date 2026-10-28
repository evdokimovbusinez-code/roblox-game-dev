--!strict
--[[ place_scan.luau: READ-ONLY скан плейса для визуального аудита (references/builder/visual-audit.md, §6).
Запуск: Studio Command Bar (вставить целиком, многострочная вставка работает) или MCP execute_luau, datamodel_type = Edit.
Ничего не меняет и не выполняет чужой код: скрипты только читаются как текст (Source). Свойства через pcall.
Вывод: ОДИН print на секцию (<= 12 строк), длинные секции режутся на куски; весь текст ещё и возвращается через return (для MCP).
Studio: Output узкий, расширить или отстыковать панель. Одним print() весь отчёт НЕ печатать: Output показывает его одним
несворачиваемым сообщением, верх не прочитать (проверено на реальном плейсе, 27.10.2026).
Камера: в Studio присвоение workspace.CurrentCamera из Command Bar вызывает диалог "Dangerous Command Detected" (только про
камеру, можно продолжить). Скан камеру НЕ трогает: ни чтения, ни записи CurrentCamera; Camera из подсчётов исключена.
Чистые функции между PURE:BEGIN и PURE:END не используют Roblox API: их можно проверять обычным luau вне Studio. ]]

-- PURE:BEGIN (без Roblox API: можно гонять обычным luau)
local WALK, LEVELS, TOP, CHUNK = 16, 8, 12, 11 -- studs/с; уровней на канал (8^3 = 512 бакетов); размер топа цветов; строк тела на print
local FAR, SLOW = 1500, 15 -- дальше FAR studs от спавна = "далеко от карты"; дольше SLOW секунд пешком до зоны core loop = медленно
local OUT_FACTOR, OUT_MIN_DELTA, OUT_MIN_MODELS = 3, 20, 5 -- выброс: > 3x медианы соседей по папке и минимум +20; папки от 5 моделей
local DEAD = {archive = true, archives = true, archived = true, old = true, backup = true, backups = true, unused = true, test = true, tests = true}
local CORE = {plot = true, plots = true, base = true, bases = true, slot = true, slots = true, junk = true, junkyard = true, scrap = true, yard = true,
	shop = true, store = true, sell = true, craft = true, forge = true, build = true, launch = true, launchpad = true, rocket = true,
	garage = true, hub = true, lab = true, factory = true, spawn = true} -- токены имён зон core loop (правьте под игру)
local function pct(n: number, total: number): string return string.format("%.1f%%", total > 0 and 100 * n / total or 0) end
local function bump(t: {[string]: number}, k: string, n: number?) t[k] = (t[k] or 0) + (n or 1) end
local function topN(t: {[string]: number}, n: number): {{k: string, n: number}}
	local a: {{k: string, n: number}} = {}
	for k, v in t do table.insert(a, {k = k, n = v}) end
	table.sort(a, function(x, y) return x.n > y.n or (x.n == y.n and x.k < y.k) end)
	while #a > n do table.remove(a) end
	return a
end
local function median(xs: {number}): number
	local s = table.clone(xs); table.sort(s)
	local n = #s
	if n == 0 then return 0 end
	return n % 2 == 1 and s[(n + 1) // 2] or (s[n // 2] + s[n // 2 + 1]) / 2
end
local function bucket(c: Color3): string -- центр бакета в hex
	local function q(v: number): number return math.floor((math.min(LEVELS - 1, math.floor(v * LEVELS)) + 0.5) / LEVELS * 255) end
	return string.format("#%02X%02X%02X", q(c.R), q(c.G), q(c.B))
end
local function chunk(lines: {string}, n: number): {{string}} -- режет список строк на куски по n
	local r: {{string}} = {}
	local i = 1
	while i <= #lines do
		local c: {string} = {}
		for j = i, math.min(i + n - 1, #lines) do table.insert(c, lines[j]) end
		table.insert(r, c); i += n
	end
	return r
end
local function tokens(name: string): {string} -- "StageImportedV3" -> stage, imported, v; "_Archive" -> archive
	local spaced = name:gsub("(%l)(%u)", "%1 %2")
	local t: {string} = {}
	for w in spaced:lower():gmatch("%a+") do table.insert(t, w) end
	return t
end
local function hasToken(name: string, set: {[string]: boolean}): boolean
	for _, w in tokens(name) do if set[w] then return true end end
	return false
end
local function isDeadName(name: string): boolean return hasToken(name, DEAD) end -- не ловит gold/contest/latest
local function isCoreName(name: string): boolean return hasToken(name, CORE) end
local function outlierFlags(xs: {number}, factor: number, minDelta: number): ({boolean}, number)
	local med = median(xs) -- медиана СОСЕДЕЙ одной папки, не всего плейса
	local fl: {boolean} = {}
	for i, x in xs do fl[i] = med > 0 and x > factor * med and x - med >= minDelta end
	return fl, med
end
local function riskTokens(src: string): {string} -- только настоящие токены; длинная строка отдельно (hasLongLine)
	local f: {string} = {}
	if src:find("require%s*%(%s*%d+%s*%)") then table.insert(f, "require(id)") end
	if src:find("getfenv") or src:find("setfenv") then table.insert(f, "get/setfenv") end
	if src:find("loadstring") then table.insert(f, "loadstring") end
	local _, nChar = src:gsub("string%.char", "")
	if nChar >= 3 or src:find("\\%d+\\%d+\\%d+\\%d+") then table.insert(f, "string.char/escape-цепочка") end
	if src:find("HttpService") and (src:find("PostAsync") or src:find("RequestAsync")) then table.insert(f, "HTTP наружу") end
	if src:find("LoadAsset") then table.insert(f, "LoadAsset") end
	return f
end
local function hasLongLine(src: string): boolean -- генерируемые data-модули часто имеют строки >500: сама по себе не риск
	for line in src:gmatch("[^\n]+") do if #line > 500 then return true end end
	return false
end
-- PURE:END

local Lighting = game:GetService("Lighting")
local full: {string} = {}
local function section(title: string, lines: {string}) -- один print на кусок секции
	local parts = chunk(lines, CHUNK)
	if #parts == 0 then parts = {{}} end
	for i, c in parts do
		local text = (i == 1 and title or (title .. " (продолжение " .. i .. "/" .. #parts .. ")")) .. (#c > 0 and ("\n" .. table.concat(c, "\n")) or "")
		print(text); table.insert(full, text)
	end
end
local function fmt(v: any): string
	if typeof(v) == "Color3" then return string.format("%d,%d,%d", v.R * 255, v.G * 255, v.B * 255) end
	if typeof(v) == "number" then return string.format("%.3g", v) end
	if typeof(v) == "EnumItem" then return v.Name end
	return tostring(v)
end
local function prop(i: Instance, name: string): any
	local ok, v = pcall(function() return (i :: any)[name] end)
	return if ok then v else nil
end
local function path(i: Instance): string return (i:GetFullName():gsub("^Workspace%.", "")) end

-- 1. Группы: каждая верхнеуровневая Folder / Model в Workspace; единицы = Model (папки внутри раскрываем)
type Unit = {name: string, root: Model, items: {Instance}, char: boolean}
type Group = {name: string, isFolder: boolean, tracked: boolean, units: {Unit}, loose: {Instance}, parts: number, meshes: number, scripts: number,
	mats: {[string]: number}, sx: number, sz: number, n: number}
local groups: {Group} = {}
local function newGroup(name: string, isFolder: boolean, tracked: boolean): Group
	local g: Group = {name = name, isFolder = isFolder, tracked = tracked, units = {}, loose = {}, parts = 0, meshes = 0, scripts = 0, mats = {}, sx = 0, sz = 0, n = 0}
	table.insert(groups, g)
	return g
end
local function addUnit(g: Group, m: Model)
	local items = m:GetDescendants(); table.insert(items, m)
	table.insert(g.units, {name = path(m), root = m, items = items, char = m:FindFirstChildOfClass("Humanoid") ~= nil})
end
local function addLoose(g: Group, i: Instance)
	table.insert(g.loose, i); for _, d in i:GetDescendants() do table.insert(g.loose, d) end
end
local function collect(parent: Instance, g: Group)
	for _, ch in parent:GetChildren() do
		if ch:IsA("Terrain") or ch:IsA("Camera") then continue end
		if ch:IsA("Model") then addUnit(g, ch)
		elseif ch:IsA("Folder") then collect(ch, g)
		else addLoose(g, ch) end
	end
end
local rootLoose = newGroup("(детали вне папок)", false, false)
for _, ch in workspace:GetChildren() do
	if ch:IsA("Terrain") or ch:IsA("Camera") then continue end
	if ch:IsA("Folder") then collect(ch, newGroup(ch.Name, true, true))
	elseif ch:IsA("Model") then addUnit(newGroup(ch.Name, false, true), ch)
	else addLoose(rootLoose, ch) end
end

local C: {[string]: number} = {}
local mats: {[string]: number}, cols: {[string]: number} = {}, {}
local meshIds: {[string]: number}, texIds: {[string]: number}, saIds: {[string]: number} = {}, {}, {}
local unanch: {string} = {}
local spawns: {SpawnLocation} = {}
local nParts, sumS, sumV, hiS, minV, maxV = 0, 0, 0, 0, Vector3.zero, Vector3.zero
local first = true
type UnitStat = {u: Unit, g: Group, parts: number, meshes: number, proxy: number, cx: number, cz: number, n: number}
local unitStat: {UnitStat} = {}
local function scan(items: {Instance}, u: Unit?, g: Group)
	local parts, meshes, usx, usz = 0, 0, 0, 0
	for _, d in items do
		if d:IsA("BasePart") then
			parts += 1; nParts += 1
			bump(C, d.ClassName); bump(mats, d.Material.Name); bump(g.mats, d.Material.Name)
			local _, s, v = d.Color:ToHSV()
			sumS += s; sumV += v; if s > 0.85 then hiS += 1 end
			bump(cols, bucket(d.Color))
			if not d.Anchored and not (u and u.char) and #unanch < 6 then table.insert(unanch, path(d)) end
			if not d.Anchored and not (u and u.char) then bump(C, "unanchored") end
			if d:IsA("SpawnLocation") then table.insert(spawns, d) end
			if d:IsA("MeshPart") then
				meshes += 1
				if d.MeshId ~= "" then bump(meshIds, d.MeshId) end
				if d.TextureID ~= "" then bump(texIds, d.TextureID) end
			end
			local pos = d.Position
			usx += pos.X; usz += pos.Z
			if first then minV, maxV, first = pos, pos, false else minV, maxV = minV:Min(pos), maxV:Max(pos) end
		elseif d:IsA("SpecialMesh") then
			bump(C, "SpecialMesh"); meshes += 1
			if d.MeshId ~= "" then bump(meshIds, d.MeshId) end
			if d.TextureId ~= "" then bump(texIds, d.TextureId) end
		elseif d:IsA("SurfaceAppearance") then bump(C, "SurfaceAppearance"); bump(saIds, d.ColorMap ~= "" and d.ColorMap or "(без ColorMap)")
		elseif d:IsA("Texture") then bump(C, "Texture")
		elseif d:IsA("Decal") then bump(C, "Decal")
		elseif d:IsA("Light") then bump(C, "Light")
		elseif d:IsA("ParticleEmitter") then bump(C, "ParticleEmitter")
		elseif d:IsA("LuaSourceContainer") then g.scripts += 1
		elseif d:IsA("Model") then bump(C, "Model") end
	end
	g.parts += parts; g.meshes += meshes; g.sx += usx; g.sz += usz; g.n += parts
	if u then table.insert(unitStat, {u = u, g = g, parts = parts, meshes = meshes, proxy = parts + meshes, cx = parts > 0 and usx / parts or 0, cz = parts > 0 and usz / parts or 0, n = parts}) end
end
for _, g in groups do
	for _, u in g.units do scan(u.items, u, g) end
	scan(g.loose, nil, g)
end
local nUnits, nFolders = 0, 0
for _, g in groups do nUnits += #g.units; if g.isFolder then nFolders += 1 end end

section("== ИТОГО (Workspace) ==", {
	string.format("BasePart %d | MeshPart %d | Union %d | SpecialMesh %d | Model %d | моделей верхнего уровня %d | папок %d", nParts,
		C.MeshPart or 0, C.UnionOperation or 0, C.SpecialMesh or 0, C.Model or 0, nUnits, nFolders),
	string.format("Decal %d | Texture %d | SurfaceAppearance %d | Light %d | ParticleEmitter %d", C.Decal or 0, C.Texture or 0,
		C.SurfaceAppearance or 0, C.Light or 0, C.ParticleEmitter or 0),
	string.format("Unanchored вне персонажей: %d%s", C.unanchored or 0, #unanch > 0 and (" напр. " .. table.concat(unanch, "; ")) or ""),
})

local ml: {string} = {}
for _, e in topN(mats, 8) do table.insert(ml, e.k .. " " .. pct(e.n, nParts)) end
section("== МАТЕРИАЛЫ ==", {table.concat(ml, " | ")})

local colLines: {string} = {}
local cl: {string}, top6, nb = {}, 0, 0
for _ in cols do nb += 1 end
for i, e in topN(cols, TOP) do
	table.insert(cl, e.k .. " " .. pct(e.n, nParts)); if i <= 6 then top6 += e.n end
	if i % 4 == 0 or i == TOP then table.insert(colLines, table.concat(cl, "  ")); cl = {} end
end
if #cl > 0 then table.insert(colLines, table.concat(cl, "  ")) end
table.insert(colLines, string.format("бакетов %d | топ-6 покрывают %s | средняя S %.2f, V %.2f | S>0.85: %s (S>0.85 у >35%% = пересыщено; V<0.45 и S<0.25 = блёкло)",
	nb, pct(top6, nParts), nParts > 0 and sumS / nParts or 0, nParts > 0 and sumV / nParts or 0, pct(hiS, nParts)))
section("== ЦВЕТА: топ-" .. TOP .. " бакетов (шаг " .. 256 // LEVELS .. "/канал) ==", colLines)

local nm, nt, ns = 0, 0, 0
for _ in meshIds do nm += 1 end
for _ in texIds do nt += 1 end
for _ in saIds do ns += 1 end
local reuse: {string} = {}
for _, e in topN(meshIds, 3) do table.insert(reuse, e.k:sub(-14) .. " x" .. e.n) end
section("== МЕШИ И ТЕКСТУРЫ ==", {string.format("уникальных MeshId %d | TextureID %d | SurfaceAppearance.ColorMap %d | самые частые меши: %s", nm, nt, ns, table.concat(reuse, ", "))})

-- 1b. Таблица по папкам Workspace (+ одна строка для моделей и деталей вне папок)
local rows: {{name: string, models: number, parts: number, meshes: number, scripts: number, mats: {[string]: number}}} = {}
local other = {name = "(модели и детали вне папок)", models = 0, parts = 0, meshes = 0, scripts = 0, mats = {} :: {[string]: number}}
for _, g in groups do
	if g.isFolder then table.insert(rows, {name = g.name, models = #g.units, parts = g.parts, meshes = g.meshes, scripts = g.scripts, mats = g.mats})
	else
		other.models += #g.units; other.parts += g.parts; other.meshes += g.meshes; other.scripts += g.scripts
		for k, v in g.mats do bump(other.mats, k, v) end
	end
end
if other.parts > 0 then table.insert(rows, other) end
table.sort(rows, function(a, b) return a.parts > b.parts end)
local rowLines: {string} = {}
for _, r in rows do
	local dom = topN(r.mats, 1)[1]
	table.insert(rowLines, string.format("%s: models %d, parts %d, meshes %d, scripts %d, %s", r.name, r.models, r.parts, r.meshes, r.scripts,
		dom and (dom.k .. " " .. pct(dom.n, r.parts)) or "-"))
end
section("== ПАПКИ WORKSPACE: models, parts, meshes, scripts, доминирующий материал ==", rowLines)

-- 1c. Выбросы внутри папки: модель против медианы соседей той же папки (только папки с >= OUT_MIN_MODELS моделей)
local outLines: {string} = {}
local checked, flagged = 0, 0
local found: {{line: string, proxy: number}} = {}
for _, g in groups do
	if g.isFolder then
		local sts: {UnitStat} = {}
		for _, s in unitStat do if s.g == g and s.parts > 0 and not s.u.char then table.insert(sts, s) end end
		if #sts >= OUT_MIN_MODELS then
			checked += 1
			local xs: {number} = {}
			for _, s in sts do table.insert(xs, s.proxy) end
			local fl, med = outlierFlags(xs, OUT_FACTOR, OUT_MIN_DELTA)
			for i, s in sts do
				if fl[i] then
					flagged += 1
					table.insert(found, {proxy = s.proxy, line = string.format("[ВЫБРОС] %s: parts %d, meshes %d, прокси %d vs медиана %.0f (%d моделей в папке %s)", s.u.name, s.parts, s.meshes, s.proxy, med, #sts, g.name)})
				end
			end
		end
	end
end
table.sort(found, function(a, b) return a.proxy > b.proxy end)
table.insert(outLines, string.format("проверено папок: %d (>= %d моделей); выбросов: %d", checked, OUT_MIN_MODELS, flagged))
for i = 1, math.min(8, #found) do table.insert(outLines, found[i].line) end
if #found > 8 then table.insert(outLines, string.format("... ещё %d", #found - 8)) end
section(string.format("== МОДЕЛИ: выбросы внутри папок (прокси = BasePart + меши; > %dx медианы соседей и +%d) ==", OUT_FACTOR, OUT_MIN_DELTA), outLines)

-- 2. Риск free-моделей: скрипты читаем как текст, не исполняем
local sc: {[string]: number} = {}
local risky: {string} = {}
local longOnly: {string} = {}
local nLongOnly = 0
local dead: {Instance} = {}
local nDead = 0
for _, svc in game:GetChildren() do
	local ok, ds = pcall(function() return svc:GetDescendants() end)
	if not ok then continue end
	for _, d in ds do
		if isDeadName(d.Name) and not d:IsA("Camera") and not d:IsA("Terrain") then -- только верхний предок мёртвой ветки
			local under = false
			for _, r in dead do if d:IsDescendantOf(r) then under = true; break end end
			if not under then nDead += 1; if #dead < 40 then table.insert(dead, d) end end
		end
		if d:IsA("LuaSourceContainer") then
			bump(sc, svc.Name .. ":" .. d.ClassName)
			local okS, src = pcall(function() return (d :: any).Source :: string end)
			if not okS then bump(sc, "Source недоступен"); continue end
			local f = riskTokens(src)
			local long = hasLongLine(src)
			if long and #f > 0 then table.insert(f, "строка >500 символов") end
			local isLongOnly = long and #f == 0
			local inWorld = svc == workspace
			if inWorld and (src:find("PromptPurchase") or src:find("PromptProductPurchase") or src:find("PromptGamePassPurchase")) then table.insert(f, "Prompt*Purchase в мире") end
			if inWorld and not d:IsA("ModuleScript") and #f == 0 then table.insert(f, "скрипт внутри модели мира") end
			if #f > 0 and #risky < 15 then table.insert(risky, path(d) .. " [" .. table.concat(f, ", ") .. "]") end
			if isLongOnly then nLongOnly += 1; if #longOnly < 5 then table.insert(longOnly, path(d)) end end
		end
	end
end
local sl: {string} = {}
for _, e in topN(sc, 10) do table.insert(sl, e.k .. " " .. e.n) end
local riskLines: {string} = {#sl > 0 and table.concat(sl, " | ") or "скриптов нет"}
for _, r in risky do table.insert(riskLines, "  ! " .. r) end
if #risky == 0 then table.insert(riskLines, "  подозрительных токенов нет (не гарантия: читать скрипты глазами, art-ui-audio §14)") end
if nLongOnly > 0 then
	table.insert(riskLines, string.format("  info: строки >500 символов без других токенов: %d скр. (обычно генерируемые data-модули, не риск): %s%s", nLongOnly, table.concat(longOnly, "; "), nLongOnly > #longOnly and " ..." or ""))
end
section("== СКРИПТЫ И РИСК ==", riskLines)

local deadLines: {string} = {}
for i, d in dead do
	if i > 10 then break end
	local nd, ns2 = 0, 0
	for _, x in d:GetDescendants() do nd += 1; if x:IsA("LuaSourceContainer") then ns2 += 1 end end
	table.insert(deadLines, string.format("  ! %s (%s): потомков %d, скриптов %d%s", path(d), d.ClassName, nd, ns2, d:IsA("LuaSourceContainer") and " [сам скрипт]" or ""))
end
if nDead == 0 then table.insert(deadLines, "  нет") elseif nDead > 10 then table.insert(deadLines, string.format("  ... ещё %d", nDead - 10)) end
section("== МЁРТВЫЙ КОД В ПЛЕЙСЕ (имя: archive/old/backup/unused/test; удалить или вынести из плейса) ==", deadLines)

-- 3. Свет
local lightLines: {string} = {}
local lp: {string} = {}
for _, n in {"Brightness", "Ambient", "OutdoorAmbient", "ClockTime", "GlobalShadows", "ExposureCompensation", "EnvironmentDiffuseScale", "EnvironmentSpecularScale", "LightingStyle", "PrioritizeLightingQuality", "ShadowSoftness"} do
	local v = prop(Lighting, n)
	table.insert(lp, n .. "=" .. (v == nil and "н/д" or fmt(v)))
end
for i = 1, #lp, 6 do table.insert(lightLines, table.concat(lp, " ", i, math.min(i + 5, #lp))) end
local fx: {[string]: {string}} = {Atmosphere = {"Density", "Offset", "Haze", "Glare", "Color", "Decay"}, Sky = {"CelestialBodiesShown", "StarCount", "SkyboxFt"},
	BloomEffect = {"Intensity", "Size", "Threshold"}, ColorCorrectionEffect = {"Brightness", "Contrast", "Saturation", "TintColor"},
	SunRaysEffect = {"Intensity", "Spread"}, DepthOfFieldEffect = {"FarIntensity", "FocusDistance"}, ColorGradingEffect = {"TonemapperPreset"}}
local seen: {[string]: number} = {}
for _, ch in Lighting:GetChildren() do
	local keys = fx[ch.ClassName]
	if keys then
		bump(seen, ch.ClassName)
		if ch.ClassName ~= "Sky" then
			local kv: {string} = {}
			for _, k in keys do local v = prop(ch, k); if v ~= nil then table.insert(kv, k .. "=" .. fmt(v)) end end
			table.insert(lightLines, string.format("%s%s: %s", ch.ClassName, prop(ch, "Enabled") == false and " (выкл)" or "", table.concat(kv, " ")))
		end
	end
end
local miss: {string} = {}
for _, k in {"Atmosphere", "BloomEffect", "ColorCorrectionEffect", "SunRaysEffect"} do if not seen[k] then table.insert(miss, k) end end
table.insert(lightLines, "нет: " .. (#miss > 0 and table.concat(miss, ", ") or "-"))
section("== СВЕТ ==", lightLines)

-- 3b. Небо: Sky + Terrain.Clouds + 3D-облака вместе = два стиля неба
local clouds = workspace.Terrain:FindFirstChildOfClass("Clouds")
local cloudParts, cloudFolders = 0, {} :: {string}
for _, d in workspace:GetDescendants() do
	local par = d.Parent -- не считать детали внутри модели с cloud в имени дважды (папки считаются отдельно)
	local inCloudModel = par ~= nil and (par:IsA("Model") or par:IsA("BasePart")) and par.Name:lower():find("cloud") ~= nil
	if d.Name:lower():find("cloud") and not inCloudModel then
		if d:IsA("BasePart") or d:IsA("Model") then cloudParts += 1
		elseif d:IsA("Folder") then
			local np = 0
			for _, x in d:GetDescendants() do if x:IsA("BasePart") then np += 1 end end
			table.insert(cloudFolders, string.format("%s (%d деталей)", d.Name, np))
		end
	end
end
local skyN = seen.Sky or 0
section("== НЕБО ==", {
	string.format("Sky: %s (%d) | Terrain.Clouds: %s | деталей/моделей с 'cloud' в имени: %d | папки: %s", skyN > 0 and "есть" or "нет", skyN, clouds and "есть" or "нет", cloudParts,
		#cloudFolders > 0 and table.concat(cloudFolders, ", ") or "-"),
	(skyN > 0 or clouds ~= nil) and cloudParts > 0 and "  ! два стиля неба (Sky/Clouds + 3D-облака): выбрать один" or "  стиль неба один",
})

-- 4. Раскладка и дальность от спавна
local layout: {string} = {}
if nParts > 0 then
	local sz = maxV - minV
	table.insert(layout, string.format("bbox центров частей: %.0f x %.0f x %.0f studs (X x Y x Z)", sz.X, sz.Y, sz.Z))
end
if #spawns == 0 then table.insert(layout, "SpawnLocation: нет (дефолтный спавн), дальность не считаем") else
	local sp: {string} = {}
	for i = 1, math.min(4, #spawns) do table.insert(sp, string.format("(%.0f,%.0f,%.0f)", spawns[i].Position.X, spawns[i].Position.Y, spawns[i].Position.Z)) end
	table.insert(layout, string.format("SpawnLocation %d: %s (дальше считаем от первого)", #spawns, table.concat(sp, " ")))
end
section("== РАСКЛАДКА ==", layout)
if #spawns > 0 then
	local o = spawns[1].Position
	type Dist = {name: string, d: number, line: string, bad: boolean}
	local dl: {Dist} = {}
	local nFar = 0
	for _, g in groups do
		if g.tracked and g.n > 0 then
			local d = Vector3.new(g.sx / g.n - o.X, 0, g.sz / g.n - o.Z).Magnitude
			local line = string.format("  %s: %.0f studs = %.0f с", g.name, d, d / WALK)
			local bad = false
			if d > FAR then
				nFar += 1; bad = true
				line ..= " | далеко от карты: staging/скайбокс? убрать из Workspace или в ServerStorage"
			elseif isCoreName(g.name) then
				local worst, worstName = d, ""
				for _, s in unitStat do
					if s.g == g and s.n > 0 then
						local du = Vector3.new(s.cx - o.X, 0, s.cz - o.Z).Magnitude
						if du > worst then worst, worstName = du, s.u.name end
					end
				end
				if worst / WALK > SLOW then
					bad = true
					line ..= string.format(" | зона core loop >%d с пешком%s", SLOW, worstName ~= "" and string.format(" (дальняя: %s %.0f с)", worstName, worst / WALK) or "")
				end
			end
			table.insert(dl, {name = g.name, d = d, line = line, bad = bad})
		end
	end
	table.sort(dl, function(a, b) return a.d > b.d end)
	local dlines: {string} = {}
	local hidden = 0
	for i, e in dl do
		if e.bad or i <= 16 then table.insert(dlines, e.line) else hidden += 1 end
	end
	if hidden > 0 then table.insert(dlines, string.format("  ... ещё %d групп ближе и без флагов", hidden)) end
	if nFar > 0 then table.insert(dlines, string.format("  (>%d studs: Луна/небо/горы бывают намеренными; _Gallery и подобное = забытый staging)", FAR)) end
	section(string.format("== ДАЛЬНОСТЬ ОТ СПАВНА: центроид по деталям папки/модели, %d studs/с, дальние первыми ==", WALK), dlines)
end

local res = table.concat(full, "\n\n")
return res
