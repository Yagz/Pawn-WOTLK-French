-- Runs the offline tests: unit tests (tests/unit.lua), then the corpus files.
-- Usage, from the addon root:
--   luajit tests/run.lua                      all unit tests and all tests/corpus/*.txt
--   luajit tests/run.lua FILE...              unit tests and the given corpus files
--   luajit tests/run.lua --propose FILE...    print "text => current reading" for every todo case
package.path = "./tests/?.lua;" .. package.path
local Harness = require("harness")
local Corpus = require("corpus")
Harness.Load()

local Propose = arg[1] == "--propose"
local Files = {}
for i = Propose and 2 or 1, #arg do table.insert(Files, arg[i]) end
if #Files == 0 then Files = Corpus.Files() end

local function Reading(Raw, Understood)
	if not Understood then return "unhandled" end
	if next(Raw) == nil then return "ignored" end
	return Corpus.FormatStats(Raw)
end

if Propose then
	for _, Path in ipairs(Files) do
		for _, Case in ipairs((Corpus.ReadFile(Path))) do
			if Case.Kind == "todo" then
				local Raw, Understood = Harness.ParseLine(Case.Left, Case.Right)
				print(Case.Text .. " => " .. Reading(Raw, Understood))
			end
		end
	end
	os.exit(0)
end

local Failures, Passed, Todo = 0, 0, 0

for _, Test in ipairs(require("unit")) do
	local Ok, Err = pcall(Test.Run)
	if Ok then Passed = Passed + 1 else Failures = Failures + 1 print("UNIT  " .. Test.Name .. " : " .. tostring(Err)) end
end

local function SameStats(A, B)
	for Key, Value in pairs(A) do
		if not B[Key] or math.abs(B[Key] - Value) > 1e-6 then return false end
	end
	for Key in pairs(B) do if not A[Key] then return false end end
	return true
end

local function Check(Case)
	local Raw, Understood, Errors = Harness.ParseLine(Case.Left, Case.Right)
	if #Errors > 0 then return false, "erreur : " .. table.concat(Errors, " | ") end
	if Case.Kind == "todo" then return "todo" end
	if Case.Kind == "unhandled" then
		if not Understood then return true end
		return false, "devrait rester non comprise, lue comme [" .. Corpus.FormatStats(Raw) .. "]"
	end
	if not Understood then return false, "non comprise" end
	local Expected = Case.Stats or {}
	if SameStats(Raw, Expected) then return true end
	return false, "attendu [" .. Corpus.FormatStats(Expected) .. "], obtenu [" .. Corpus.FormatStats(Raw) .. "]"
end

for _, Path in ipairs(Files) do
	local Cases, Errors = Corpus.ReadFile(Path)
	for _, Err in ipairs(Errors) do Failures = Failures + 1 print("FORMAT " .. Err) end
	for _, Case in ipairs(Cases) do
		local Result, Reason = Check(Case)
		if Result == "todo" then
			Todo = Todo + 1
		elseif Result then
			Passed = Passed + 1
		else
			Failures = Failures + 1
			print(string.format("ECHEC %s:%d  %s  -> %s", Path, Case.Line, Case.Text, Reason))
		end
	end
end

print(string.format("%d réussis, %d échecs, %d à classer (todo)", Passed, Failures, Todo))
os.exit(Failures == 0 and 0 or 1)
