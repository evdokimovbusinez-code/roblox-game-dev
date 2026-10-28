-- Runs inside an Open Cloud Luau Execution task against the TEST place version built from test.project.json.
local ReplicatedStorage = game:GetService("ReplicatedStorage")
local Jest = require(ReplicatedStorage.DevPackages.Jest)

local root = ReplicatedStorage.Tests -- folder that contains jest.config.luau and __tests__/*.spec.luau
local status, result = Jest.runCLI(root, { ci = true, verbose = false }, { root }):awaitStatus()

if status == "Rejected" then
	error(tostring(result))
end
local r = result.results
print(("Jest: %d passed, %d failed, %d suites failed"):format(r.numPassedTests, r.numFailedTests, r.numFailedTestSuites))
if not r.success then
	error("Tests failed")
end
return { passed = r.numPassedTests, failed = r.numFailedTests }
