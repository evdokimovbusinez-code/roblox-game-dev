--!strict
-- Thin, crash-proof wrapper over AnalyticsService (server only, published games only; calls are silent no-ops in Studio).
-- Rules: log AFTER the action succeeded; use the Enum.*.Name strings for standard dashboard grouping; keep event names
-- few (limits: 100 custom event names, 10 funnels x 100 steps, 10 economy currencies, 120 + 20 x CCU requests/min).
-- Never let analytics errors break gameplay: every call is pcall-protected.

local AnalyticsService = game:GetService("AnalyticsService")

local Analytics = {}

local function safe(label: string, fn: () -> ())
	local ok: boolean, err: any = pcall(fn)
	if not ok then
		warn(`[Analytics] {label} failed: {err}`)
	end
end

-- Economy: every currency gain is a Source, every spend is a Sink. endingBalance is the balance AFTER the change.
function Analytics.economy(
	player: Player,
	flow: Enum.AnalyticsEconomyFlowType,
	currency: string,
	amount: number,
	endingBalance: number,
	transactionType: Enum.AnalyticsEconomyTransactionType,
	itemSku: string?
)
	if not math.isfinite(amount) or amount <= 0 then
		return
	end
	safe("economy", function()
		AnalyticsService:LogEconomyEvent(player, flow, currency, amount, endingBalance, transactionType.Name, itemSku)
	end)
end

-- Onboarding funnel (first-session steps). Call each step once, in order, with a stable number.
function Analytics.onboarding(player: Player, step: number, stepName: string)
	safe("onboarding", function()
		AnalyticsService:LogOnboardingFunnelStepEvent(player, step, stepName)
	end)
end

-- Custom funnel (shop visit -> click -> purchase). funnelSessionId: a GUID per attempt.
function Analytics.funnel(player: Player, funnelName: string, sessionId: string, step: number, stepName: string)
	safe("funnel", function()
		AnalyticsService:LogFunnelStepEvent(player, funnelName, sessionId, step, stepName)
	end)
end

-- Progression (levels / stages / chapters).
function Analytics.progressionStart(player: Player, path: string, level: number, levelName: string?)
	safe("progressionStart", function()
		AnalyticsService:LogProgressionStartEvent(player, path, level, levelName)
	end)
end

function Analytics.progressionComplete(player: Player, path: string, level: number, levelName: string?)
	safe("progressionComplete", function()
		AnalyticsService:LogProgressionCompleteEvent(player, path, level, levelName)
	end)
end

function Analytics.progressionFail(player: Player, path: string, level: number, levelName: string?)
	safe("progressionFail", function()
		AnalyticsService:LogProgressionFailEvent(player, path, level, levelName)
	end)
end

-- Anything else (max 3 custom fields; put variants into fields, not into the event name).
function Analytics.custom(player: Player, eventName: string, value: number?, fields: { [string]: any }?)
	safe("custom", function()
		AnalyticsService:LogCustomEvent(player, eventName, value, fields)
	end)
end

return Analytics
