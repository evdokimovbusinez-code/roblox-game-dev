--!strict
-- Minimal HUD built in code (no Studio-authored GUI needed): shows the coin balance with NumberFormat.
-- Replace with your UI library of choice (React Luau / Fusion / Vide); keep StateController as the single data source.

local Players = game:GetService("Players")
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)
local Remotes = require(ReplicatedStorage.Shared.Remotes)
local StateController = require(script.Parent.StateController)

local HudController = {}

-- Ask the server to buy a catalog item. The server validates, charges and replies through StateChanged.
function HudController.requestBuy(itemName: string)
	Remotes.get("BuyItem"):FireServer(itemName)
end

export type StartOptions = {
	coinLabel: boolean?, -- false when the ui/ library HUD (UiDemoController) shows the currency instead
}

function HudController.start(options: StartOptions?)
	if options and options.coinLabel == false then
		return
	end
	local player = Players.LocalPlayer
	local playerGui = player:WaitForChild("PlayerGui") :: PlayerGui

	local gui = Instance.new("ScreenGui")
	gui.Name = "Hud"
	gui.ResetOnSpawn = false
	gui.Parent = playerGui

	local coins = Instance.new("TextLabel")
	coins.Name = "Coins"
	coins.AnchorPoint = Vector2.new(1, 0)
	coins.Position = UDim2.new(1, -16, 0, 16) -- ScreenInsets keeps this clear of the top bar by default
	coins.Size = UDim2.fromOffset(160, 40)
	coins.BackgroundTransparency = 0.3
	coins.BackgroundColor3 = Color3.fromRGB(20, 20, 20)
	coins.TextColor3 = Color3.fromRGB(255, 221, 87)
	coins.TextScaled = true
	coins.Font = Enum.Font.BuilderSansBold
	coins.Text = "0"
	coins.Parent = gui

	StateController.observe("Coins", function(value)
		coins.Text = NumberFormat.abbreviate(if typeof(value) == "number" then value else 0)
	end)
end

return HudController
