--!strict
-- Reward fly-to-counter (animation.md R17, R31): N small 2D sprites burst out of an origin, then fly ONE BY ONE (staggered, not a
-- volley) into the currency icon; the counter bumps on arrival. Sprites are pooled ImageLabels in screen.Overlay, driven by ONE
-- RenderStepped connection that exists only while something flies.
--
--   local fly = RewardFlyToCounter.new(screen)
--   local handle = fly:play({
--       count = 12, icon = "coin",
--       from = Vector2.new(640, 360),          -- design units (screen.Size space) or a GuiObject (its center is used)
--       target = counter.Icon,                 -- a GuiObject: followed every frame, so a moving HUD does not break it
--       onBump = function() counter:bump() end,   -- first, every 4th and last arrival
--       onDone = function() ... end,
--   })
--   handle.cancel()                            -- stops silently, returns the sprites to the pool
--
-- The component never grants anything: call it AFTER the server confirmed the reward. Start counter:countTo(...) right when play()
-- starts: its first quarter is a slow creep that matches the first sprites still in the air (R16 / R31).
-- Limits: at most Motion.FlyMaxAlive sprites alive at once (phone), one flight >= 0.15 s, whole spawn <= ~0.7 s.

local RunService = game:GetService("RunService")

local Curves = require(script.Parent.Curves)
local Icons = require(script.Parent.Icons)
local Motion = require(script.Parent.Motion)
local Screen = require(script.Parent.Screen)
local Util = require(script.Parent.Util)

local RewardFlyToCounter = {}

export type PlayOptions = {
	count: number, -- sprites to launch (clamped to 1..Motion.FlyMaxAlive)
	icon: string, -- Icons key
	from: Vector2 | GuiObject, -- origin
	target: GuiObject, -- usually CurrencyCounter.Icon
	duration: number?, -- one flight, seconds (default Motion.FlyDuration, minimum 0.15)
	spread: number?, -- burst radius in design units (default 56)
	onArrive: ((index: number, total: number) -> ())?, -- every sprite
	onBump: (() -> ())?, -- throttled for the counter pop: first, every 4th and the last arrival
	onDone: (() -> ())?, -- after the last sprite arrived (not called after cancel)
}

export type Handle = {
	cancel: () -> (),
	isActive: () -> boolean,
}

export type RewardFlyToCounter = {
	play: (self: RewardFlyToCounter, options: PlayOptions) -> Handle,
	alive: (self: RewardFlyToCounter) -> number,
	destroy: (self: RewardFlyToCounter) -> (),
}

type Job = {
	delay: number,
	startedAt: number?,
	finished: boolean,
	sprite: ImageLabel?,
	scale: UIScale?,
	burst: Vector2, -- offset of the burst point from the origin
	rotation: number,
}

type Play = {
	options: PlayOptions,
	origin: Vector2,
	startedAt: number,
	duration: number,
	jobs: { Job },
	arrived: number,
	cancelled: boolean,
}

local BURST_SHARE = 0.3 -- first 30% of a flight: pop out of the origin (ease-out); the rest: accelerate into the counter
local MAX_SPAWN_TIME = 0.7 -- the whole staggered launch fits into this (many sprites -> smaller step)
local MIN_FLIGHT = 0.15

function RewardFlyToCounter.new(screen: Screen.Screen): RewardFlyToCounter
	local cleaner = Util.newCleaner()
	local plays: { Play } = {}
	local pool: { ImageLabel } = {}
	local aliveSprites = 0
	local connection: RBXScriptConnection? = nil
	local rng = Random.new()

	local function acquire(icon: string): (ImageLabel, UIScale)
		local sprite = table.remove(pool)
		local size = screen.Sizes.flySprite
		if sprite == nil then
			local created = Icons.new(screen.Overlay, icon, UDim2.fromOffset(size, size))
			created.Name = "FlySprite"
			created.SizeConstraint = Enum.SizeConstraint.RelativeXY
			created.AnchorPoint = Vector2.new(0.5, 0.5)
			created.ZIndex = 1
			Util.scale(created)
			sprite = created
		else
			Icons.apply(sprite, icon)
			sprite.Size = UDim2.fromOffset(size, size)
		end
		local live = sprite :: ImageLabel
		live.Visible = true
		aliveSprites += 1
		return live, live:FindFirstChildOfClass("UIScale") :: UIScale
	end

	local function release(sprite: ImageLabel)
		sprite.Visible = false
		aliveSprites = math.max(0, aliveSprites - 1)
		table.insert(pool, sprite)
	end

	local function stopLoop()
		if connection then
			connection:Disconnect()
			connection = nil
		end
	end
	cleaner:add(stopLoop)

	local function finishPlay(play: Play)
		local index = table.find(plays, play)
		if index then
			table.remove(plays, index)
		end
		for _, job in play.jobs do
			local sprite = job.sprite
			if sprite then
				release(sprite)
				job.sprite = nil
			end
		end
	end

	local function arrive(play: Play, index: number)
		play.arrived += 1
		local total = #play.jobs
		local options = play.options
		if options.onArrive then
			options.onArrive(index, total)
		end
		if options.onBump and (play.arrived == 1 or play.arrived % 4 == 0 or play.arrived == total) then
			options.onBump()
		end
	end

	local function step()
		local now = os.clock()
		-- iterate over a copy: callbacks may start a new play
		for _, play in table.clone(plays) do
			if play.cancelled then
				continue
			end
			local targetObject = play.options.target
			local target = if targetObject.Parent ~= nil then screen:centerOf(targetObject) else play.origin
			local allDone = true
			for index, job in play.jobs do
				if job.finished then
					continue
				end
				allDone = false
				local startedAt = job.startedAt
				if startedAt == nil then
					if now - play.startedAt >= job.delay and aliveSprites < Motion.FlyMaxAlive then
						local sprite, scale = acquire(play.options.icon)
						sprite.Rotation = job.rotation
						sprite.Position = UDim2.fromOffset(play.origin.X, play.origin.Y)
						scale.Scale = 0.4
						job.sprite = sprite
						job.scale = scale
						job.startedAt = now
					end
					continue
				end
				local t = (now - startedAt) / play.duration
				local sprite = job.sprite
				if t >= 1 or sprite == nil then
					job.finished = true
					if sprite then
						release(sprite)
						job.sprite = nil
					end
					arrive(play, index)
				else
					local position: Vector2
					local size: number
					if t < BURST_SHARE then
						local u = Curves.easeOut(t / BURST_SHARE)
						position = play.origin + job.burst * u
						size = Curves.lerp(0.4, 1, u)
					else
						local u = Curves.easeIn((t - BURST_SHARE) / (1 - BURST_SHARE))
						position = (play.origin + job.burst):Lerp(target, u)
						size = Curves.lerp(1, 0.7, u)
					end
					sprite.Position = UDim2.fromOffset(position.X, position.Y)
					if job.scale then
						job.scale.Scale = size
					end
				end
			end
			if allDone and not play.cancelled then
				finishPlay(play)
				if play.options.onDone then
					play.options.onDone()
				end
			end
		end
		if #plays == 0 then
			stopLoop()
		end
	end

	local function ensureLoop()
		if connection == nil then
			connection = RunService.RenderStepped:Connect(step)
		end
	end

	local api: RewardFlyToCounter
	api = {
		play = function(_self: RewardFlyToCounter, options: PlayOptions): Handle
			local origin: Vector2 = if typeof(options.from) == "Vector2"
				then options.from :: Vector2
				else screen:centerOf(options.from :: GuiObject)
			local total = math.clamp(math.floor(options.count), 1, Motion.FlyMaxAlive)

			-- reduced motion: no flight at all, the counter just receives the result
			if Util.reducedMotion() then
				task.defer(function()
					if options.onArrive then
						options.onArrive(total, total)
					end
					if options.onBump then
						options.onBump()
					end
					if options.onDone then
						options.onDone()
					end
				end)
				return {
					cancel = function() end,
					isActive = function(): boolean
						return false
					end,
				}
			end

			local duration = math.max(options.duration or Motion.FlyDuration, MIN_FLIGHT)
			local stagger = math.min(Motion.FlyStep, MAX_SPAWN_TIME / total)
			local spread = options.spread or 56
			local jobs: { Job } = {}
			for index = 1, total do
				local angle = rng:NextNumber(0, math.pi * 2)
				local radius = spread * rng:NextNumber(0.45, 1)
				table.insert(jobs, {
					delay = (index - 1) * stagger,
					startedAt = nil,
					finished = false,
					sprite = nil,
					scale = nil,
					burst = Vector2.new(math.cos(angle), math.sin(angle)) * radius,
					rotation = rng:NextNumber(-25, 25),
				})
			end
			local play: Play = {
				options = options,
				origin = origin,
				startedAt = os.clock(),
				duration = duration,
				jobs = jobs,
				arrived = 0,
				cancelled = false,
			}
			table.insert(plays, play)
			ensureLoop()
			return {
				cancel = function()
					if not play.cancelled then
						play.cancelled = true
						finishPlay(play)
						if #plays == 0 then
							stopLoop()
						end
					end
				end,
				isActive = function(): boolean
					return not play.cancelled and table.find(plays, play) ~= nil
				end,
			}
		end,
		alive = function(_self: RewardFlyToCounter): number
			return aliveSprites
		end,
		destroy = function(_self: RewardFlyToCounter)
			for _, play in table.clone(plays) do
				play.cancelled = true
				finishPlay(play)
			end
			cleaner:clean()
			for _, sprite in pool do
				sprite:Destroy()
			end
			table.clear(pool)
		end,
	}
	return api
end

return RewardFlyToCounter
