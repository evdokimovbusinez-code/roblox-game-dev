-- Example Jest Roblox spec (runs in CI via tasks/runTests.luau). Pure-logic modules are the best first targets:
-- economy math, migrations, trade validation. NOT executed against a live Jest in this repo: run it once in your test place.
local ReplicatedStorage = game:GetService("ReplicatedStorage")

local JestGlobals = require(ReplicatedStorage.DevPackages.JestGlobals)
local NumberFormat = require(ReplicatedStorage.Shared.NumberFormat)

local describe = JestGlobals.describe
local expect = JestGlobals.expect
local it = JestGlobals.it

describe("NumberFormat.abbreviate", function()
	it("keeps small numbers whole", function()
		expect(NumberFormat.abbreviate(950)).toBe("950")
	end)

	it("truncates instead of rounding", function()
		expect(NumberFormat.abbreviate(1999)).toBe("1.9K")
		expect(NumberFormat.abbreviate(999999)).toBe("999.9K")
	end)

	it("handles billions and negatives", function()
		expect(NumberFormat.abbreviate(1e9)).toBe("1B")
		expect(NumberFormat.abbreviate(-2500)).toBe("-2.5K")
	end)

	it("never prints garbage for non-finite input", function()
		expect(NumberFormat.abbreviate(0 / 0)).toBe("0")
		expect(NumberFormat.abbreviate(math.huge)).toBe("0")
	end)
end)
