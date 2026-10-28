--!strict
-- Compliance gates evaluated on the SERVER, per player: PolicyService flags, age/verification, text filtering.
-- PolicyService integration is mandatory for games with paid random items, paid item trading, ads or subscriptions.
-- Fail CLOSED: until (or unless) the policy loads, the most restrictive answer is returned.

local Players = game:GetService("Players")
local TextService = game:GetService("TextService")
local PolicyService = game:GetService("PolicyService")

export type Info = {
	arePaidRandomItemsRestricted: boolean,
	isPaidItemTradingAllowed: boolean,
	areAdsAllowed: boolean,
	isEligibleToPurchaseSubscription: boolean,
	isContentSharingAllowed: boolean,
}

local RESTRICTIVE: Info = {
	arePaidRandomItemsRestricted = true,
	isPaidItemTradingAllowed = false,
	areAdsAllowed = false,
	isEligibleToPurchaseSubscription = false,
	isContentSharingAllowed = false,
}

local cache: { [Player]: Info } = {}

local Policy = {}

local function load(player: Player)
	for attempt = 1, 3 do
		local ok, raw = pcall(function()
			return PolicyService:GetPolicyInfoForPlayerAsync(player)
		end)
		if ok then
			cache[player] = {
				arePaidRandomItemsRestricted = raw.ArePaidRandomItemsRestricted ~= false,
				isPaidItemTradingAllowed = raw.IsPaidItemTradingAllowed == true,
				areAdsAllowed = raw.AreAdsAllowed == true,
				isEligibleToPurchaseSubscription = raw.IsEligibleToPurchaseSubscription == true,
				isContentSharingAllowed = raw.IsContentSharingAllowed == true,
			}
			return
		end
		task.wait(attempt * 2)
	end
	warn(`[Policy] could not load policy for {player.Name}; staying restrictive`)
end

function Policy.get(player: Player): Info
	return cache[player] or RESTRICTIVE
end

-- Loot boxes, gacha, random-reward packs paid with Robux (or currency bought with Robux): hide AND reject server-side.
function Policy.canUsePaidRandomItems(player: Player): boolean
	return not Policy.get(player).arePaidRandomItemsRestricted
end

-- Trading of items bought with Robux. Also gate trading on MarketplaceService:GetUsersPriceLevelsAsync (regional arbitrage).
function Policy.canTradePaidItems(player: Player): boolean
	return Policy.get(player).isPaidItemTradingAllowed
end

function Policy.canShowAds(player: Player): boolean
	return Policy.get(player).areAdsAllowed
end

function Policy.canBuySubscription(player: Player): boolean
	return Policy.get(player).isEligibleToPurchaseSubscription
end

-- Player.AgeChecked is an Enum.AgeCheckStatus. Use for features that should only exist for age-checked users.
function Policy.isAgeChecked(player: Player): boolean
	return player.AgeChecked == Enum.AgeCheckStatus.Checked
end

-- Server-only, always false in Studio. Use to protect ranking and trading integrity (never as the only defense).
function Policy.isVerified(player: Player): boolean
	local ok, result = pcall(function()
		return player:IsVerified()
	end)
	return ok and result == true
end

-- Mandatory for ANY player-written text that other players can see (pet names, signs, bios, custom chat).
-- Returns nil if the text must not be shown. Submit on FocusLost, never per keystroke. Filter again on every
-- display if you store the raw text: the filtered result is per viewer / per moment.
function Policy.filterForBroadcast(fromPlayer: Player, text: string): string?
	if utf8.len(text) == nil or #text > 200 then
		return nil
	end
	local ok, result = pcall(function()
		local filtered = TextService:FilterStringAsync(text, fromPlayer.UserId)
		return filtered:GetNonChatStringForBroadcastAsync()
	end)
	if ok then
		return result
	end
	return nil
end

function Policy.start()
	Players.PlayerAdded:Connect(function(player)
		task.spawn(load, player)
	end)
	for _, player in Players:GetPlayers() do
		task.spawn(load, player)
	end
	Players.PlayerRemoving:Connect(function(player)
		cache[player] = nil
	end)
end

return Policy
