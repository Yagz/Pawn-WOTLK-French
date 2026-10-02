-- Imports real tooltip lines into the test corpus.  Run from the addon root:
--   luajit tests/import.lua logs                       tests/data/pawndebuglogs.frFR.txt -> tests/corpus/logs.txt (todo)
--   luajit tests/import.lua unknown <SavedVariables>   PawnScanResults.unknown -> tests/corpus/scan.txt (todo)
--   luajit tests/import.lua parsed <SavedVariables>    PawnScanResults.parsed  -> tests/corpus/regression.txt
package.path = "./tests/?.lua;" .. package.path
local Corpus = require("corpus")

local function Usable(Line)
	return type(Line) == "string" and Line ~= "" and not Line:find("\n", 1, true) and not Line:find(" => ", 1, true)
end

local function LoadSavedVariables(Path)
	local Chunk = assert(loadfile(Path))
	local Env = {}
	setfenv(Chunk, Env)
	Chunk()
	return Env
end

local Mode, Path = arg[1], arg[2]

if Mode == "logs" then
	local Entries = {}
	for Line in io.lines("tests/data/pawndebuglogs.frFR.txt") do
		if Usable(Line) then table.insert(Entries, { Text = Line, Expect = "todo" }) end
	end
	local Added = Corpus.Append("tests/corpus/logs.txt", Entries,
		"# Lignes réelles relevées en jeu par l'ancien PawnDebugLogs (comptes YAGZ et REROLL1).")
	print(Added .. " lignes ajoutées à tests/corpus/logs.txt")

elseif (Mode == "unknown" or Mode == "parsed") and Path then
	local Results = LoadSavedVariables(Path).PawnScanResults
	if not Results then error("pas de PawnScanResults dans " .. Path) end
	local Entries = {}
	if Mode == "unknown" then
		local Sorted = {}
		for _, Entry in pairs(Results.unknown or {}) do table.insert(Sorted, Entry) end
		table.sort(Sorted, function(A, B) return A.count > B.count end)
		for _, Entry in ipairs(Sorted) do
			if Usable(Entry.line) then table.insert(Entries, { Text = Entry.line, Expect = "todo" }) end
		end
		local Added = Corpus.Append("tests/corpus/scan.txt", Entries,
			"# Lignes non comprises relevées par /pawnscan (un exemple réel par modèle, les plus fréquentes d'abord).")
		print(Added .. " lignes ajoutées à tests/corpus/scan.txt")
		for Key, Text in pairs(Results.mismatch or {}) do print("ÉCART  " .. Key .. " : " .. Text) end
		for Key, Text in pairs(Results.errors or {}) do print("ERREUR " .. tostring(Key) .. " : " .. Text) end
	else
		for _, Entry in pairs(Results.parsed or {}) do
			if Usable(Entry.line) then table.insert(Entries, { Text = Entry.line, Expect = Entry.stats }) end
		end
		table.sort(Entries, function(A, B) return A.Text < B.Text end)
		local Added = Corpus.Append("tests/corpus/regression.txt", Entries,
			"# Lignes comprises relevées par /pawnscan, avec la lecture de Pawn au moment du scan (relue avant import).")
		print(Added .. " lignes ajoutées à tests/corpus/regression.txt")
	end

else
	print("usage : luajit tests/import.lua logs | unknown <SavedVariables/Pawn.lua> | parsed <SavedVariables/Pawn.lua>")
	os.exit(1)
end
