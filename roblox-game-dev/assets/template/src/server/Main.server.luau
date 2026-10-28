--!strict
-- The ONLY server Script. Everything else is a ModuleScript with optional init() / start():
--   init()  create objects, read config; must not yield, must not depend on other services being started
--   start() connect events, begin loops (may spawn tasks)
-- Order matters only for the lines below: remotes must exist before anything listens, and the receipt handler must be
-- registered during boot, before the first player's pending receipts are delivered.

local services = script.Parent.services

local Policy = require(services.Policy)
local Remotes = require(services.Remotes)
local PlayerData = require(services.PlayerData)
local Purchases = require(services.Purchases)
local Shop = require(services.Shop)

-- init phase
Remotes.init()
PlayerData.init()

-- start phase
Remotes.start()
Policy.start()
PlayerData.start()
Purchases.start()
Shop.start()
