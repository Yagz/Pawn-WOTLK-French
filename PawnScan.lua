-- Pawn by Vger-Azjol-Nerub
-- www.vgermods.com
-- © 2006-2024 Travis Spomer.  This mod is released under the Creative Commons Attribution-NonCommercial-NoDerivs 3.0 license.
-- See Readme.htm for more information.
--
-- PawnScan: checks Pawn's tooltip parsing on the client's items, in game.
-- /pawnscan [first last] | gems [itemID] | enchants [itemID] | stop | status | clear | speed <n>
-- Results go to the PawnScanResults SavedVariable; tests/import.lua turns them into test corpus files.
------------------------------------------------------------

PawnScan = {}
PawnScan.DefaultFirstID = 1
PawnScan.DefaultLastID = 56000
PawnScan.MaxEnchantID = 4000
PawnScan.ItemsPerSecond = 10
PawnScan.MaxAttempts = 3
PawnScan.RetryDelay = 1

-- Keys returned by GetItemStats (when the client has it) and the Pawn stat each one feeds.
PawnScan.ItemModToStat =
{
	ITEM_MOD_STRENGTH_SHORT = "Strength",
	ITEM_MOD_AGILITY_SHORT = "Agility",
	ITEM_MOD_STAMINA_SHORT = "Stamina",
	ITEM_MOD_INTELLECT_SHORT = "Intellect",
	ITEM_MOD_SPIRIT_SHORT = "Spirit",
	ITEM_MOD_ATTACK_POWER_SHORT = "Ap",
	ITEM_MOD_RANGED_ATTACK_POWER_SHORT = "Rap",
	ITEM_MOD_CRIT_RATING_SHORT = "CritRating",
	ITEM_MOD_CRIT_MELEE_RATING_SHORT = "CritRating",
	ITEM_MOD_CRIT_RANGED_RATING_SHORT = "CritRating",
	ITEM_MOD_CRIT_SPELL_RATING_SHORT = "CritRating",
	ITEM_MOD_HIT_RATING_SHORT = "HitRating",
	ITEM_MOD_HIT_MELEE_RATING_SHORT = "HitRating",
	ITEM_MOD_HIT_RANGED_RATING_SHORT = "HitRating",
	ITEM_MOD_HIT_SPELL_RATING_SHORT = "HitRating",
	ITEM_MOD_HASTE_RATING_SHORT = "HasteRating",
	ITEM_MOD_HASTE_MELEE_RATING_SHORT = "HasteRating",
	ITEM_MOD_HASTE_RANGED_RATING_SHORT = "HasteRating",
	ITEM_MOD_HASTE_SPELL_RATING_SHORT = "HasteRating",
	ITEM_MOD_EXPERTISE_RATING_SHORT = "ExpertiseRating",
	ITEM_MOD_ARMOR_PENETRATION_RATING_SHORT = "ArmorPenetration",
	ITEM_MOD_SPELL_POWER_SHORT = "SpellPower",
	ITEM_MOD_SPELL_PENETRATION_SHORT = "SpellPenetration",
	ITEM_MOD_DEFENSE_SKILL_RATING_SHORT = "DefenseRating",
	ITEM_MOD_DODGE_RATING_SHORT = "DodgeRating",
	ITEM_MOD_PARRY_RATING_SHORT = "ParryRating",
	ITEM_MOD_BLOCK_RATING_SHORT = "BlockRating",
	ITEM_MOD_BLOCK_VALUE_SHORT = "BlockValue",
	ITEM_MOD_RESILIENCE_RATING_SHORT = "ResilienceRating",
	ITEM_MOD_MANA_REGENERATION_SHORT = "Mp5",
	ITEM_MOD_HEALTH_REGEN_SHORT = "Hp5",
	ITEM_MOD_HEALTH_SHORT = "Health",
	ITEM_MOD_MANA_SHORT = "Mana",
}

local Pending = {} -- entries waiting for the server: { Index, Tries, At }
local Elapsed = 0

local ScanFrame = CreateFrame("Frame")
ScanFrame:Hide()
ScanFrame:SetScript("OnUpdate", function(self, Delta) PawnScan.OnUpdate(Delta) end)

-- Hidden tooltip used to make the client ask the server for an item it doesn't have yet.
local PrimerTooltip = CreateFrame("GameTooltip", "PawnScanPrimerTooltip", nil, "GameTooltipTemplate")
PrimerTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")

-- Asks the server for an item.  The tooltip is re-owned and cleared each time: the client may unown it after an
-- uncached item, and later SetHyperlink calls would then do nothing.
local function PrimeItem(ItemID)
	PrimerTooltip:SetOwner(WorldFrame, "ANCHOR_NONE")
	PrimerTooltip:ClearLines()
	PrimerTooltip:SetHyperlink("item:" .. ItemID)
end

function PawnScan.Message(Text)
	VgerCore.Message(VgerCore.Color.Blue .. "PawnScan : " .. VgerCore.Color.Reset .. Text)
end

function PawnScan.GetResults()
	if not PawnScanResults then PawnScanResults = {} end
	local R = PawnScanResults
	R.unknown = R.unknown or {}
	R.parsed = R.parsed or {}
	R.mismatch = R.mismatch or {}
	R.errors = R.errors or {}
	R.summary = R.summary or { scanned = 0, ok = 0, nok = 0 }
	R.state = R.state or {}
	return R
end

-- "Augmente de 12 le score de toucher." --> "Augmente de # le score de toucher."
function PawnScan.Template(Line)
	return (gsub(Line, "%d+", "#"))
end

-- Same format as tests/corpus.lua: "Agility=12; Speed=2.6"
function PawnScan.FormatStats(Stats)
	local Keys = {}
	for Key in pairs(Stats) do tinsert(Keys, Key) end
	table.sort(Keys)
	local Parts = {}
	for _, Key in ipairs(Keys) do tinsert(Parts, Key .. "=" .. format("%.10g", Stats[Key])) end
	return table.concat(Parts, "; ")
end

function PawnScan.CompareWithItemStats(Link, Stats, Example)
	local R = PawnScan.GetResults()
	local Expected = {}
	for Key, Value in pairs(GetItemStats(Link) or {}) do
		local Stat = PawnScan.ItemModToStat[Key]
		if Stat then Expected[Stat] = (Expected[Stat] or 0) + Value end
	end
	for Stat, Value in pairs(Expected) do
		local Got = Stats[Stat] or 0
		if math.abs(Got - Value) > 0.001 then
			R.mismatch[tostring(Example) .. " " .. Stat] = format("jeu %s, Pawn %s", Value, Got)
		end
	end
end

-- Parses one item link with Pawn and records what was understood or not.  Example identifies the item.
-- Returns "ok", "nok", "skip" (Pawn returned nothing) or "error".
function PawnScan.RecordItem(Link, Example)
	local R = PawnScan.GetResults()
	local Seen = {}
	local Original = PawnLookForSingleStat
	PawnLookForSingleStat = function(RegexTable, Stats, Text, DebugMessages)
		local Found = {}
		local Understood = Original(RegexTable, Found, Text, DebugMessages)
		PawnAddStatsToTable(Stats, Found)
		if Understood and Text and next(Found) then
			local Key = strtrim(Text)
			if RegexTable == PawnRightHandRegexes then Key = "|| " .. Key end
			Seen[Key] = Found
		end
		return Understood
	end
	local Ok, Stats, _, UnknownLines = pcall(PawnGetStatsForItemLink, Link, false)
	PawnLookForSingleStat = Original

	if not Ok then
		R.errors[tostring(Example)] = tostring(Stats)
		return "error"
	end
	if not Stats then return "skip" end

	R.summary.scanned = R.summary.scanned + 1
	if UnknownLines then
		R.summary.nok = R.summary.nok + 1
		for Line in pairs(UnknownLines) do
			local Template = PawnScan.Template(Line)
			local Entry = R.unknown[Template]
			if not Entry then
				Entry = { count = 0, example = Example, line = Line }
				R.unknown[Template] = Entry
			end
			Entry.count = Entry.count + 1
		end
	else
		R.summary.ok = R.summary.ok + 1
	end
	for Line, Found in pairs(Seen) do
		local Template = PawnScan.Template(Line)
		if not R.parsed[Template] then R.parsed[Template] = { line = Line, stats = PawnScan.FormatStats(Found) } end
	end
	if GetItemStats then PawnScan.CompareWithItemStats(Link, Stats, Example) end
	if not R.socketedExample and type(Example) == "number" and (Stats.RedSocket or Stats.YellowSocket or Stats.BlueSocket) then
		R.socketedExample = Example
	end
	if UnknownLines then return "nok" end
	return "ok"
end

-- Every gem ID in Pawn's gem tables for this version of the game.
local function GemIDs()
	local IDs, Seen = {}, {}
	for _, Levels in ipairs({ PawnGemQualityLevels or {}, PawnMetaGemQualityLevels or {} }) do
		for _, Level in ipairs(Levels) do
			for _, Gem in ipairs(Level[2] or {}) do
				if type(Gem.ID) == "number" and not Seen[Gem.ID] then
					Seen[Gem.ID] = true
					tinsert(IDs, Gem.ID)
				end
			end
		end
	end
	table.sort(IDs)
	return IDs
end

-- Entry number Index of the current scan.  Require: item ID that must be in the client cache first.
function PawnScan.GetEntry(State, Index)
	if State.mode == "range" then
		return { Require = Index, Example = Index }
	elseif State.mode == "gems" then
		local Gem = State.gems[Index]
		return { Require = Gem, Link = format("item:%d:0:%d:0:0:0:0:0", State.base, Gem), Example = "gem " .. Gem }
	elseif State.mode == "enchants" then
		return { Link = format("item:%d:%d:0:0:0:0:0:0", State.base, Index), Example = "enchant " .. Index }
	end
end

-- Returns "pending" while the client is still waiting for item data, "skip" for items that can't be equipped,
-- otherwise the result of RecordItem.
function PawnScan.TryEntry(Entry, Tries)
	local Link = Entry.Link
	if Entry.Require then
		local Name, ItemLink, _, _, _, _, _, _, EquipLoc = GetItemInfo(Entry.Require)
		if not Name then
			if Tries == 0 then PrimeItem(Entry.Require) end
			return "pending"
		end
		if not Link then
			if not EquipLoc or EquipLoc == "" or EquipLoc == "INVTYPE_BAG" or EquipLoc == "INVTYPE_QUIVER" then return "skip" end
			Link = ItemLink
		end
	end
	return PawnScan.RecordItem(Link, Entry.Example)
end

-- Processes one entry.  Returns false when the scan is finished.
function PawnScan.Step(Now)
	local State = PawnScan.GetResults().state
	local Index, Tries
	for i, Waiting in ipairs(Pending) do
		if Waiting.At <= Now then
			Index, Tries = Waiting.Index, Waiting.Tries
			tremove(Pending, i)
			break
		end
	end
	if not Index then
		if not State.next or State.next > State.last then return #Pending > 0 end
		Index, Tries = State.next, 0
		State.next = State.next + 1
	end
	if PawnScan.TryEntry(PawnScan.GetEntry(State, Index), Tries) == "pending" and Tries + 1 < PawnScan.MaxAttempts then
		tinsert(Pending, { Index = Index, Tries = Tries + 1, At = Now + PawnScan.RetryDelay })
	end
	return true
end

function PawnScan.OnUpdate(Delta)
	Elapsed = math.min(Elapsed + Delta, 1) -- never catch up more than one second after a lag spike
	local Interval = 1 / PawnScan.ItemsPerSecond
	while Elapsed >= Interval do
		Elapsed = Elapsed - Interval
		if not PawnScan.Step(GetTime()) then
			PawnScan.Finish()
			return
		end
	end
end

function PawnScan.StatusText()
	local R = PawnScan.GetResults()
	local Unknown, Errors = 0, 0
	for _ in pairs(R.unknown) do Unknown = Unknown + 1 end
	for _ in pairs(R.errors) do Errors = Errors + 1 end
	local S = R.summary
	local Text = format("%d objets analysés, %d OK, %d avec des lignes inconnues, %d modèles de lignes inconnues, %d erreurs.", S.scanned, S.ok, S.nok, Unknown, Errors)
	local State = R.state
	if State.mode and State.next and State.next <= State.last then
		Text = Text .. format(" Position : %d / %d (%s).", State.next, State.last, State.mode)
	end
	return Text
end

function PawnScan.Start(Mode, First, Last, Base)
	local R = PawnScan.GetResults()
	local State = { mode = Mode, next = First, last = Last, base = Base, running = true }
	if Mode == "gems" then
		State.gems = GemIDs()
		State.last = #State.gems
	end
	R.state = State
	Pending = {}
	Elapsed = 0
	ScanFrame:Show()
	PawnScan.Message(format("scan « %s » lancé : %d entrées.", Mode, State.last - State.next + 1))
end

function PawnScan.Resume()
	local State = PawnScan.GetResults().state
	if not State.mode or not State.next or State.next > State.last then return false end
	if State.mode == "gems" then State.gems = State.gems or GemIDs() end
	State.running = true
	Pending = {}
	Elapsed = 0
	ScanFrame:Show()
	PawnScan.Message(format("reprise du scan « %s » à l'entrée %d sur %d.", State.mode, State.next, State.last))
	return true
end

function PawnScan.Stop()
	ScanFrame:Hide()
	PawnScan.GetResults().state.running = false
end

function PawnScan.Finish()
	PawnScan.Stop()
	PawnScan.Message("scan terminé. " .. PawnScan.StatusText())
end

function PawnScan.Command(Text)
	local Args = {}
	for Word in gmatch(Text or "", "%S+") do tinsert(Args, Word) end
	local Command = strlower(Args[1] or "")
	if Command == "" then
		if not PawnScan.Resume() then PawnScan.Start("range", PawnScan.DefaultFirstID, PawnScan.DefaultLastID) end
	elseif tonumber(Command) then
		local First = tonumber(Args[1])
		PawnScan.Start("range", First, tonumber(Args[2]) or First)
	elseif Command == "gems" or Command == "enchants" then
		local Base = tonumber(Args[2]) or PawnScan.GetResults().socketedExample
		if not Base then
			PawnScan.Message("aucun objet à châsses connu : lancez d'abord /pawnscan, ou indiquez un numéro d'objet.")
			return
		end
		if not GetItemInfo(Base) then
			PrimeItem(Base)
			PawnScan.Message("l'objet " .. Base .. " n'est pas encore en cache. Réessayez dans quelques secondes.")
			return
		end
		PawnScan.Start(Command, 1, Command == "enchants" and PawnScan.MaxEnchantID or 0, Base)
	elseif Command == "stop" then
		PawnScan.Stop()
		PawnScan.Message("scan arrêté. " .. PawnScan.StatusText())
	elseif Command == "status" then
		PawnScan.Message(PawnScan.StatusText())
	elseif Command == "clear" then
		PawnScan.Stop()
		PawnScanResults = nil
		PawnScan.GetResults()
		PawnScan.Message("résultats effacés.")
	elseif Command == "speed" and tonumber(Args[2]) then
		PawnScan.ItemsPerSecond = tonumber(Args[2])
		PawnScan.Message("débit : " .. Args[2] .. " entrées par seconde.")
	else
		PawnScan.Message("usage : /pawnscan [début fin] | gems [objet] | enchants [objet] | stop | status | clear | speed <n>")
	end
end

SLASH_PAWNSCAN1 = "/pawnscan"
SlashCmdList["PAWNSCAN"] = PawnScan.Command
