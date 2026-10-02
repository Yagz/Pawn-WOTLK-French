-- Pawn by Vger-Azjol-Nerub
-- www.vgermods.com
-- © 2006-2024 Travis Spomer.  This mod is released under the Creative Commons Attribution-NonCommercial-NoDerivs 3.0 license.
-- See Readme.htm for more information.
--
-- French (frFR) tooltip parsing for the WoW 3.3.5a client.
-- Pawn's own frFR patterns come from Wrath Classic and don't match the 3.3.5a client text, so on frFR clients this file
-- replaces the parsing tables built by TooltipParsing.lua.  Every pattern comes from real client data (GlobalStrings.lua,
-- Spell.dbc, SpellItemEnchantment.dbc, ItemSubClass.dbc) or from lines seen in game, and names its source.
------------------------------------------------------------

if GetLocale() ~= "frFR" then return end

-- The client writes a no-break space before ":"; Pawn turns those into plain spaces before parsing (LookForNBSP).
-- This is the single normalization rule for every client string used below.
local function PawnFrNoNbsp(Text)
	return (gsub(Text, "\194\160", " "))
end

-- Turns a GlobalStrings.lua format into a Lua pattern (not anchored).
-- %d and %c%d capture a number, %.1f captures a decimal number (dot or comma), %% is a literal percent sign,
-- %s and |4singular:plural; match any text without capturing.  Positional forms such as %1$d are accepted.
function PawnFrFormatToPattern(Format)
	local Pattern = PawnFrNoNbsp(Format)
	Pattern = gsub(Pattern, "%%%%", "\005")
	Pattern = gsub(Pattern, "%%%d%$", "%%")
	Pattern = gsub(Pattern, "|4[^;]*;", "\001")
	Pattern = gsub(Pattern, "%%c%%d", "\002")
	Pattern = gsub(Pattern, "%%%.%df", "\003")
	Pattern = gsub(Pattern, "%%d", "\004")
	Pattern = gsub(Pattern, "%%s", "\001")
	Pattern = gsub(Pattern, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")
	Pattern = gsub(Pattern, "\001", ".-")
	Pattern = gsub(Pattern, "\002", "%%+?(%%-?%%d+)")
	Pattern = gsub(Pattern, "\003", "([%%d%%.,]+)")
	Pattern = gsub(Pattern, "\004", "(%%d+)")
	Pattern = gsub(Pattern, "\005", "%%%%")
	return Pattern
end

-- "^...$" pattern for the client constant called Name.
function PawnFrPattern(Name)
	local Format = _G[Name]
	if type(Format) ~= "string" then error("Pawn frFR: missing client constant " .. Name, 2) end
	return "^" .. PawnFrFormatToPattern(Format) .. "$"
end

-- The same, shown as an equip effect: "Équipé : <format>".
function PawnFrEquipPattern(Name)
	local Format = _G[Name]
	if type(Format) ~= "string" then error("Pawn frFR: missing client constant " .. Name, 2) end
	return "^" .. PawnFrFormatToPattern(ITEM_SPELL_TRIGGER_ONEQUIP .. " " .. Format) .. "$"
end

-- "Équipé : <Spell.dbc description>", where # stands for the value.
function PawnFrSpellPattern(Template)
	return "^" .. PawnFrFormatToPattern(ITEM_SPELL_TRIGGER_ONEQUIP .. " " .. gsub(Template, "#", "%%d")) .. "$"
end

-- These strings indicate that a given line might contain multiple stats.  Sorted in priority order.
PawnSeparators =
{
	", ",
	"/",
	" & ",
	" et ", -- SpellItemEnchantment.dbc: "+6 à l'Agilité et +9 à l'Endurance"; logs: "+12 Intelligence et une chance de ..."
}

-- Lines that begin with any of the following strings will not be searched for separator strings.
PawnSeparatorIgnorePrefixes =
{
	'"', -- flavor text
	PawnFrNoNbsp(ITEM_SPELL_TRIGGER_ONEQUIP), -- GlobalStrings: "Équipé :"
	PawnFrNoNbsp(ITEM_SPELL_TRIGGER_ONUSE), -- GlobalStrings: "Utiliser :"
	PawnFrNoNbsp(ITEM_SPELL_TRIGGER_ONPROC), -- GlobalStrings: "Chances quand vous touchez :"
}

-- Normalizations applied before the regexes.
PawnNormalizationRegexes =
{
	{"^|c........(.+)$", "%1"}, -- color codes (same as TooltipParsing.lua)
	{"^([^%+%-%d][^%+]-) %+(%d+)$", "+%2 %1"}, -- SpellItemEnchantment.dbc: "Agilité +10" --> "+10 Agilité"
}

-- GlobalStrings: ITEM_SOCKET_BONUS = "Bonus de sertissage : %s"
PawnLocal.TooltipParsing.SocketBonusPrefix = gsub(PawnFrNoNbsp(ITEM_SOCKET_BONUS), "%%s", "")

-- No thousands separator; decimals may use a comma or a point (Pawn turns "," into "." before tonumber).
PawnLocal.ThousandsSeparator = ""
PawnLocal.DecimalSeparator = ","
