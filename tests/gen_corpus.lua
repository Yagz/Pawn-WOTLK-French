-- Generates corpus files from the extracted client data, rendered exactly as the client displays them.
-- Only adds texts that are not in the corpus yet, so it never overwrites classifications.  Run from the addon root.
package.path = "./tests/?.lua;" .. package.path
dofile("tests/wowapi.lua")
for Line in io.lines("tests/data/GlobalStrings.frFR.lua") do
	local Chunk = loadstring(Line)
	if Chunk then pcall(Chunk) end
end
local Corpus = require("corpus")

-- Renders a GlobalStrings format like the client: %c is the sign, |4singular:plural; takes the plural.
-- Arguments are given in display order.
local function Render(Format, ...)
	assert(Format, "missing client constant")
	local Text = gsub(Format, "|4[^:;]*:([^;]*);", "%1")
	Text = gsub(Text, "%%(%d)%$", "%%")
	Text = gsub(Text, "%%c", "%%s")
	return format(Text, ...)
end

local Equip = ITEM_SPELL_TRIGGER_ONEQUIP .. " "

-- 1. GlobalStrings formats.  Each entry: { tooltip text, expectation }.
local GlobalCases = {
	{ Render(ITEM_MOD_STRENGTH, "+", 15), "Strength=15" },
	{ Render(ITEM_MOD_AGILITY, "+", 15), "Agility=15" },
	{ Render(ITEM_MOD_STAMINA, "+", 15), "Stamina=15" },
	{ Render(ITEM_MOD_STAMINA, "-", 5), "Stamina=-5" },
	{ Render(ITEM_MOD_INTELLECT, "+", 15), "Intellect=15" },
	{ Render(ITEM_MOD_SPIRIT, "+", 15), "Spirit=15" },
	{ Render(ITEM_MOD_HEALTH, "+", 150), "Health=150" },
	{ Render(ITEM_MOD_MANA, "+", 150), "Mana=150" },
	{ Equip .. Render(ITEM_MOD_ATTACK_POWER, 40), "Ap=40" },
	{ Equip .. Render(ITEM_MOD_RANGED_ATTACK_POWER, 40), "Rap=40" },
	{ Equip .. Render(ITEM_MOD_CRIT_RATING, 20), "CritRating=20" },
	{ Equip .. Render(ITEM_MOD_CRIT_MELEE_RATING, 20), "MeleeCritRating=20" },
	{ Equip .. Render(ITEM_MOD_CRIT_RANGED_RATING, 20), "RangedCritRating=20" },
	{ Equip .. Render(ITEM_MOD_CRIT_SPELL_RATING, 20), "SpellCritRating=20" },
	{ Equip .. Render(ITEM_MOD_HIT_RATING, 20), "HitRating=20" },
	{ Equip .. Render(ITEM_MOD_HIT_MELEE_RATING, 20), "MeleeHitRating=20" },
	{ Equip .. Render(ITEM_MOD_HIT_RANGED_RATING, 20), "RangedHitRating=20" },
	{ Equip .. Render(ITEM_MOD_HIT_SPELL_RATING, 20), "SpellHitRating=20" },
	{ Equip .. Render(ITEM_MOD_HASTE_RATING, 20), "HasteRating=20" },
	{ Equip .. Render(ITEM_MOD_HASTE_MELEE_RATING, 20), "MeleeHasteRating=20" },
	{ Equip .. Render(ITEM_MOD_HASTE_RANGED_RATING, 20), "RangedHasteRating=20" },
	{ Equip .. Render(ITEM_MOD_HASTE_SPELL_RATING, 20), "SpellHasteRating=20" },
	{ Equip .. Render(ITEM_MOD_EXPERTISE_RATING, 20), "ExpertiseRating=20" },
	{ Equip .. Render(ITEM_MOD_ARMOR_PENETRATION_RATING, 20), "ArmorPenetration=20" },
	{ Equip .. Render(ITEM_MOD_SPELL_POWER, 30), "SpellPower=30" },
	{ Equip .. Render(ITEM_MOD_SPELL_PENETRATION, 20), "SpellPenetration=20" },
	{ Equip .. Render(ITEM_MOD_DEFENSE_SKILL_RATING, 20), "DefenseRating=20" },
	{ Equip .. Render(ITEM_MOD_DODGE_RATING, 20), "DodgeRating=20" },
	{ Equip .. Render(ITEM_MOD_PARRY_RATING, 20), "ParryRating=20" },
	{ Equip .. Render(ITEM_MOD_BLOCK_RATING, 20), "BlockRating=20" },
	{ Equip .. Render(ITEM_MOD_BLOCK_VALUE, 20), "BlockValue=20" },
	{ Equip .. Render(ITEM_MOD_RESILIENCE_RATING, 20), "ResilienceRating=20" },
	{ Equip .. Render(ITEM_MOD_MANA_REGENERATION, 8), "Mp5=8" },
	{ Equip .. Render(ITEM_MOD_HEALTH_REGEN, 8), "Hp5=8" },
	{ Equip .. Render(ITEM_MOD_FERAL_ATTACK_POWER, 300), "ignored" }, -- Pawn computes feral AP from DPS
	{ Render(ITEM_MOD_FERAL_ATTACK_POWER, 300), "ignored" },
	{ Render(ITEM_RESIST_ALL, "+", 10), "AllResist=10" },
	{ Render(DAMAGE_TEMPLATE, 100, 200), "MinDamage=100; MaxDamage=200" },
	{ Render(DAMAGE_TEMPLATE_WITH_SCHOOL, 83, 156, "Arcanes"), "MinDamage=83; MaxDamage=156" }, -- in game: Récolteur d'essence
	{ Render(PLUS_DAMAGE_TEMPLATE_WITH_SCHOOL, 10, 20, DAMAGE_SCHOOL3), "MinDamage=10; MaxDamage=20" },
	{ Render(PLUS_DAMAGE_TEMPLATE, 10, 20), "MinDamage=10; MaxDamage=20" },
	{ Render(SINGLE_DAMAGE_TEMPLATE, 50), "MinDamage=50; MaxDamage=50" },
	{ Render(SINGLE_DAMAGE_TEMPLATE_WITH_SCHOOL, 50, DAMAGE_SCHOOL6), "MinDamage=50; MaxDamage=50" },
	{ Render(DPS_TEMPLATE, 45.5), "ignored" },
	{ gsub(Render(DPS_TEMPLATE, 45.5), "%.", ",", 1), "ignored" }, -- decimal comma
	{ "|| " .. SPEED .. " 2,60", "Speed=2.6" },
	{ "|| " .. SPEED .. " 2.60", "Speed=2.6" },
	{ Render(ARMOR_TEMPLATE, 1200), "Armor=1200" },
	{ Render(SHIELD_BLOCK_TEMPLATE, 40), "BlockValue=40" },
	{ Render(ITEM_SOCKET_BONUS, Render(ITEM_MOD_STAMINA, "+", 6)), "Stamina=6" },
	{ EMPTY_SOCKET_RED, "RedSocket=1" },
	{ EMPTY_SOCKET_YELLOW, "YellowSocket=1" },
	{ EMPTY_SOCKET_BLUE, "BlueSocket=1" },
	{ EMPTY_SOCKET_META, "MetaSocket=1" },
	{ EMPTY_SOCKET_NO_COLOR, "PrismaticSocket=1" },
	{ INVTYPE_WEAPON, "IsOneHand=1" },
	{ INVTYPE_2HWEAPON, "IsTwoHand=1" },
	{ INVTYPE_WEAPONMAINHAND, "IsMainHand=1" },
	{ INVTYPE_WEAPONOFFHAND, "IsOffHand=1" },
	{ INVTYPE_HOLDABLE, "IsFrill=1" },
	{ INVTYPE_RANGED, "IsRanged=1" },
	{ INVTYPE_RANGEDRIGHT, "IsRanged=1" },
	{ INVTYPE_THROWN, "IsRanged=1" },
}
for _, Name in ipairs({ "INVTYPE_HEAD", "INVTYPE_NECK", "INVTYPE_SHOULDER", "INVTYPE_CLOAK", "INVTYPE_ROBE", "INVTYPE_BODY",
	"INVTYPE_TABARD", "INVTYPE_WRIST", "INVTYPE_HAND", "INVTYPE_WAIST", "INVTYPE_FEET", "INVTYPE_LEGS",
	"INVTYPE_FINGER", "INVTYPE_TRINKET", "INVTYPE_RELIC", "INVTYPE_AMMO", "ITEM_SOULBOUND", "ITEM_BIND_ON_EQUIP",
	"ITEM_BIND_ON_PICKUP", "ITEM_BIND_ON_USE", "ITEM_BIND_TO_ACCOUNT", "ITEM_UNIQUE", "ITEM_UNIQUE_EQUIPPABLE",
	"ITEM_BIND_QUEST", "ITEM_STARTS_QUEST", "ITEM_CONJURED", "ITEM_PROSPECTABLE", "ITEM_MILLABLE",
	"ITEM_DISENCHANT_NOT_DISENCHANTABLE", "ITEM_ENCHANT_DISCLAIMER", "LOCKED", "ENCRYPTED", "ITEM_SPELL_KNOWN",
	"ITEM_HEROIC", "ITEM_HEROIC_EPIC", "ITEM_QUALITY0_DESC", "ITEM_QUALITY1_DESC", "ITEM_QUALITY2_DESC",
	"ITEM_QUALITY3_DESC", "ITEM_QUALITY4_DESC", "ITEM_QUALITY5_DESC", "ITEM_QUALITY7_DESC", "RETRIEVING_ITEM_INFO",
	"ITEM_OPENABLE", "ITEM_READABLE", "ITEM_SOCKETABLE", "ITEM_RANDOM_ENCHANT", "MAJOR_GLYPH", "MINOR_GLYPH",
	"ITEM_SPELL_CHARGES_NONE" }) do
	table.insert(GlobalCases, { assert(_G[Name], Name), "ignored" })
end
for _, Case in ipairs({
	{ DURABILITY_TEMPLATE, 100, 100 }, { ITEM_LEVEL, 200 }, { ITEM_MIN_LEVEL, 80 }, { ITEM_MIN_SKILL, "Forge", 300 },
	{ ITEM_REQ_SKILL, "Forge" }, { ITEM_REQ_REPUTATION, "Aube d'argent", "Révéré" }, { ITEM_LEVEL_RANGE, 1, 80 },
	{ ITEM_LEVEL_RANGE_CURRENT, 1, 80, 60 }, { ITEM_REQ_ARENA_RATING, 1800 }, { ITEM_CLASSES_ALLOWED, "Prêtre" },
	{ ITEM_RACES_ALLOWED, "Humain" }, { ITEM_DISENCHANT_MIN_SKILL, "Enchantement", 300 }, { ITEM_DURATION_MIN, 30 },
	{ ITEM_DURATION_SEC, 30 }, { ITEM_DURATION_HOURS, 2 }, { ITEM_DURATION_DAYS, 2 }, { ITEM_COOLDOWN_TIME, "5 min" },
	{ ITEM_COOLDOWN_TIME_MIN, 5 }, { ITEM_COOLDOWN_TIME_SEC, 30 }, { ITEM_COOLDOWN_TIME_HOURS, 2 },
	{ ITEM_COOLDOWN_TIME_DAYS, 2 }, { ITEM_WRITTEN_BY, "Vger" }, { ITEM_CREATED_BY, "Vger" },
	{ ITEM_SPELL_CHARGES, 5 }, { ITEM_UNIQUE_MULTIPLE, 3 }, { ITEM_LIMIT_CATEGORY_MULTIPLE, "Gemme", 3 },
	{ ITEM_ENCHANT_TIME_LEFT_MIN, "Huile", 30 }, { ITEM_ENCHANT_TIME_LEFT_SEC, "Huile", 30 },
	{ ITEM_ENCHANT_TIME_LEFT_HOURS, "Huile", 2 }, { ITEM_ENCHANT_TIME_LEFT_DAYS, "Huile", 2 },
	{ ENCHANT_ITEM_REQ_SKILL, "Enchantement" }, { ENCHANT_ITEM_MIN_SKILL, "Enchantement", 375 }, { ENCHANT_ITEM_REQ_LEVEL, 60 },
}) do
	table.insert(GlobalCases, { Render(unpack(Case)), "ignored" })
end
local Entries = {}
for _, Case in ipairs(GlobalCases) do table.insert(Entries, { Text = Case[1], Expect = Case[2] }) end
print(Corpus.Append("tests/corpus/globalstrings.txt", Entries,
	"# Généré par tests/gen_corpus.lua depuis GlobalStrings.lua (frFR 3.3.5a).") .. " cas ajoutés à globalstrings.txt")

-- 2. ItemSubClass.dbc: right-hand text.  Pawn stat per class:subclass (stats of PawnRightHandRegexes in 2.8.11);
--    subclasses with no Pawn stat must produce no stat ("ignored").
local SubClassStat = {
	["2:0"] = "IsAxe", ["2:1"] = "IsAxe", ["2:2"] = "IsBow", ["2:3"] = "IsGun", ["2:4"] = "IsMace", ["2:5"] = "IsMace",
	["2:6"] = "IsPolearm", ["2:7"] = "IsSword", ["2:8"] = "IsSword", ["2:10"] = "IsStaff", ["2:13"] = "IsFist",
	["2:15"] = "IsDagger", ["2:16"] = "IsThrown", ["2:18"] = "IsCrossbow", ["2:19"] = "IsWand",
	["4:1"] = "IsCloth", ["4:2"] = "IsLeather", ["4:3"] = "IsMail", ["4:4"] = "IsPlate", ["4:6"] = "IsShield",
}
Entries = {}
for Line in io.lines("tests/data/itemsubclass.frFR.txt") do
	local Class, SubClass, Name = Line:match("^(%d+)\t(%d+)\t(.+)$")
	if Class then
		local Stat = SubClassStat[Class .. ":" .. SubClass]
		table.insert(Entries, { Text = "|| " .. Name, Expect = Stat and (Stat .. "=1") or "ignored" })
	end
end
print(Corpus.Append("tests/corpus/itemsubclass.txt", Entries,
	"# Généré par tests/gen_corpus.lua depuis ItemSubClass.dbc (frFR 3.3.5a) : texte de droite de l'infobulle.") .. " cas ajoutés à itemsubclass.txt")

-- 3. Spell.dbc templates, shown on items as "Équipé : <description>".  Value 12.  Classified by hand afterwards.
Entries = {}
for Line in io.lines("tests/data/spell_templates.frFR.txt") do
	local Count, Template = Line:match("^(%d+)\t(.+)$")
	if Count then table.insert(Entries, { Text = Equip .. gsub(Template, "#", "12"), Expect = "todo" }) end
end
print(Corpus.Append("tests/corpus/spells.txt", Entries,
	"# Généré par tests/gen_corpus.lua depuis Spell.dbc (frFR 3.3.5a), du plus fréquent au plus rare. À classer.") .. " cas ajoutés à spells.txt")

-- 4. SpellItemEnchantment.dbc: one real example per template.  Classified by hand afterwards.
Entries = {}
for Line in io.lines("tests/data/enchant_texts.frFR.txt") do
	local Count, Template, Example = Line:match("^(%d+)\t(.-)\t(.+)$")
	if Count then table.insert(Entries, { Text = Example, Expect = "todo" }) end
end
print(Corpus.Append("tests/corpus/enchants.txt", Entries,
	"# Généré par tests/gen_corpus.lua depuis SpellItemEnchantment.dbc (frFR 3.3.5a), du plus fréquent au plus rare. À classer.") .. " cas ajoutés à enchants.txt")
