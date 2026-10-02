-- Loads Pawn 2.8.11's real localization and parsing code under LuaJIT and runs tooltip lines through it.
local Harness = {}

-- Same order as Pawn.toc; UI files and scale providers are left out (not needed to parse tooltips).
Harness.Files = {
	"VgerCore/VgerCore.lua",
	"Core.lua",
	"Localization.lua",
	"Localization.frFR.lua",
	"UIStrings.lua",
	"TooltipParsing.lua",
	"TooltipParsing.frFR.lua",
	"Gems.lua",
	"GemsClassic.lua",
	"GemsBurningCrusade.lua",
	"GemsWrath.lua",
	"ScaleTemplates.lua",
	"ItemIDs.lua",
	"Pawn.lua",
}

-- Loads the client constants line by line: a few lines of the real file use escapes LuaJIT rejects.
local function LoadGlobalStrings(Path)
	for Line in io.lines(Path) do
		local Chunk = loadstring(Line)
		if Chunk then pcall(Chunk) end
	end
end

function Harness.Load()
	dofile("tests/wowapi.lua")
	LoadGlobalStrings("tests/data/GlobalStrings.frFR.lua")
	for _, Path in ipairs(Harness.Files) do dofile(Path) end
	WowApiSetTooltip(PawnPrivateTooltipName, {}) -- normally created by PawnUI.xml
	PawnCommon = PawnCommon or {}
end

-- Runs one tooltip line (left text, optional right text) through PawnGetStatsFromTooltip.
-- Returns Raw (stats found by PawnLookForSingleStat, before Pawn's post-processing), Understood, Errors.
function Harness.ParseLine(Left, Right)
	local Raw = {}
	local Original = PawnLookForSingleStat
	PawnLookForSingleStat = function(RegexTable, Stats, Text, DebugMessages)
		local Found = {}
		local Understood = Original(RegexTable, Found, Text, DebugMessages)
		PawnAddStatsToTable(Stats, Found)
		PawnAddStatsToTable(Raw, Found)
		return Understood
	end
	WowApiMessages = {}
	WowApiSetTooltip("PawnTestTooltip", { "Objet de test", { Left, Right } })
	local Ok, Result, _, UnknownLines = pcall(PawnGetStatsFromTooltip, "PawnTestTooltip", false)
	PawnLookForSingleStat = Original
	local Errors = {}
	if not Ok then table.insert(Errors, tostring(Result)) end
	for _, Message in ipairs(WowApiMessages) do
		if Message:find("ERROR:", 1, true) then table.insert(Errors, Message) end
	end
	return Raw, UnknownLines == nil, Errors
end

return Harness
