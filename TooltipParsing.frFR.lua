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

------------------------------------------------------------
-- Tooltip regexes (same row format as TooltipParsing.lua: first match wins)
------------------------------------------------------------

-- Every pattern built from a client constant goes through PawnFrFormatToPattern (NBSP and magic characters such as
-- the parentheses of "Tenu(e) en main gauche" are handled there); PawnGameConstant only escapes % and -.
local Fr, FrEquip, FrSpell = PawnFrPattern, PawnFrEquipPattern, PawnFrSpellPattern
local Fixed, Extract = PawnMultipleStatsFixed, PawnMultipleStatsExtract

PawnRegexes =
{
	-- ========================================
	-- Ignored lines
	-- ========================================
	{Fr("ITEM_QUALITY0_DESC")}, -- GlobalStrings
	{Fr("ITEM_QUALITY1_DESC")}, -- GlobalStrings
	{Fr("ITEM_QUALITY2_DESC")}, -- GlobalStrings
	{Fr("ITEM_QUALITY3_DESC")}, -- GlobalStrings
	{Fr("ITEM_QUALITY4_DESC")}, -- GlobalStrings
	{Fr("ITEM_QUALITY5_DESC")}, -- GlobalStrings
	{Fr("ITEM_QUALITY7_DESC")}, -- GlobalStrings
	{Fr("ITEM_HEROIC")}, -- GlobalStrings
	{Fr("ITEM_HEROIC_EPIC")}, -- GlobalStrings
	{Fr("ITEM_LEVEL")}, -- GlobalStrings
	{Fr("ITEM_UNSELLABLE")}, -- GlobalStrings
	{Fr("ITEM_SOULBOUND")}, -- GlobalStrings
	{Fr("ITEM_BIND_ON_EQUIP")}, -- GlobalStrings
	{Fr("ITEM_BIND_ON_PICKUP")}, -- GlobalStrings
	{Fr("ITEM_BIND_ON_USE")}, -- GlobalStrings
	{Fr("ITEM_BIND_TO_ACCOUNT")}, -- GlobalStrings (ITEM_ACCOUNTBOUND has the same text)
	{"^" .. PawnFrFormatToPattern(ITEM_UNIQUE)}, -- GlobalStrings: also ITEM_UNIQUE_MULTIPLE, ITEM_UNIQUE_EQUIPPABLE, ITEM_LIMIT_CATEGORY*
	{"^" .. PawnFrFormatToPattern(ITEM_BIND_QUEST)}, -- GlobalStrings
	{Fr("ITEM_STARTS_QUEST")}, -- GlobalStrings
	{Fr("ITEM_CONJURED")}, -- GlobalStrings
	{Fr("ITEM_PROSPECTABLE")}, -- GlobalStrings
	{Fr("ITEM_MILLABLE")}, -- GlobalStrings
	{Fr("ITEM_DISENCHANT_NOT_DISENCHANTABLE")}, -- GlobalStrings
	{Fr("ITEM_DISENCHANT_MIN_SKILL")}, -- GlobalStrings; logs: "Le désenchantement nécessite Enchantement (175)"
	{Fr("ITEM_ENCHANT_DISCLAIMER")}, -- GlobalStrings
	{Fr("LOCKED")}, -- GlobalStrings; logs: "Verrouillé(e)"
	{Fr("ENCRYPTED")}, -- GlobalStrings
	{Fr("ITEM_SPELL_KNOWN")}, -- GlobalStrings
	{Fr("RETRIEVING_ITEM_INFO")}, -- GlobalStrings; logs
	{"^%d+ charges?$"}, -- GlobalStrings: ITEM_SPELL_CHARGES "%d |4charge:charges;" (by hand: the generic form would match any "N ...")
	{Fr("ITEM_SPELL_CHARGES_NONE")}, -- GlobalStrings
	{Fr("INVTYPE_HEAD")}, -- GlobalStrings
	{Fr("INVTYPE_NECK")}, -- GlobalStrings
	{Fr("INVTYPE_SHOULDER")}, -- GlobalStrings
	{Fr("INVTYPE_CLOAK")}, -- GlobalStrings
	{Fr("INVTYPE_ROBE")}, -- GlobalStrings (INVTYPE_CHEST has the same text)
	{Fr("INVTYPE_BODY")}, -- GlobalStrings
	{Fr("INVTYPE_TABARD")}, -- GlobalStrings
	{Fr("INVTYPE_WRIST")}, -- GlobalStrings
	{Fr("INVTYPE_HAND")}, -- GlobalStrings
	{Fr("INVTYPE_WAIST")}, -- GlobalStrings
	{Fr("INVTYPE_FEET")}, -- GlobalStrings
	{Fr("INVTYPE_LEGS")}, -- GlobalStrings
	{Fr("INVTYPE_FINGER")}, -- GlobalStrings
	{Fr("INVTYPE_TRINKET")}, -- GlobalStrings
	{Fr("INVTYPE_RELIC")}, -- GlobalStrings
	{Fr("INVTYPE_AMMO")}, -- GlobalStrings
	{Fr("MAJOR_GLYPH")}, -- GlobalStrings
	{Fr("MINOR_GLYPH")}, -- GlobalStrings
	{"^Libram$"}, -- ItemSubClass.dbc 4:7; logs
	{"^Idole$"}, -- ItemSubClass.dbc 4:8; logs
	{"^Totem$"}, -- ItemSubClass.dbc 4:9; logs
	{"^Cachet$"}, -- ItemSubClass.dbc 4:10
	{Fr("ITEM_CLASSES_ALLOWED")}, -- GlobalStrings
	{Fr("ITEM_RACES_ALLOWED")}, -- GlobalStrings
	{Fr("ITEM_MIN_LEVEL")}, -- GlobalStrings
	{Fr("ITEM_MIN_SKILL")}, -- GlobalStrings; logs: "Forge (300) requis"
	{Fr("ITEM_LEVEL_RANGE_CURRENT")}, -- GlobalStrings; logs: "Niveau 1 à 80 (60) requis"
	{Fr("ITEM_LEVEL_RANGE")}, -- GlobalStrings
	{Fr("ITEM_REQ_SKILL")}, -- GlobalStrings (also covers ITEM_REQ_REPUTATION "Requiert %s - %s")
	{Fr("ITEM_REQ_ARENA_RATING")}, -- GlobalStrings
	{Fr("DURABILITY_TEMPLATE")}, -- GlobalStrings
	{Fr("ITEM_DURATION_DAYS")}, -- GlobalStrings
	{Fr("ITEM_DURATION_HOURS")}, -- GlobalStrings
	{Fr("ITEM_DURATION_MIN")}, -- GlobalStrings
	{Fr("ITEM_DURATION_SEC")}, -- GlobalStrings
	{Fr("ITEM_COOLDOWN_TIME")}, -- GlobalStrings
	{Fr("ITEM_COOLDOWN_TIME_DAYS")}, -- GlobalStrings
	{Fr("ITEM_COOLDOWN_TIME_HOURS")}, -- GlobalStrings
	{Fr("ITEM_COOLDOWN_TIME_MIN")}, -- GlobalStrings
	{Fr("ITEM_COOLDOWN_TIME_SEC")}, -- GlobalStrings
	{"<.+>"}, -- GlobalStrings: ITEM_CREATED_BY, ITEM_OPENABLE, ITEM_READABLE, ITEM_SOCKETABLE, ITEM_RANDOM_ENCHANT... (can be prefixed by a color)
	{Fr("ITEM_WRITTEN_BY")}, -- GlobalStrings
	{"|cff%x%x%x%x%x%x" .. PawnFrFormatToPattern(ENCHANT_CONDITION_REQUIRES)}, -- GlobalStrings: meta gem requirements ("Nécessite ...")
	{"^.+ %d+ emplacements?$"}, -- GlobalStrings: CONTAINER_SLOTS; logs: "Sac 14 emplacements", "Carquois 18 emplacements"
	{Fr("ITEM_ENCHANT_TIME_LEFT_DAYS")}, -- GlobalStrings: temporary item buff
	{Fr("ITEM_ENCHANT_TIME_LEFT_HOURS")}, -- GlobalStrings
	{Fr("ITEM_ENCHANT_TIME_LEFT_MIN")}, -- GlobalStrings
	{Fr("ITEM_ENCHANT_TIME_LEFT_SEC")}, -- GlobalStrings
	{Fr("ENCHANT_ITEM_REQ_SKILL")}, -- GlobalStrings
	{Fr("ENCHANT_ITEM_MIN_SKILL")}, -- GlobalStrings
	{Fr("ENCHANT_ITEM_REQ_LEVEL")}, -- GlobalStrings
	{Fr("ITEM_MOD_FERAL_ATTACK_POWER")}, -- GlobalStrings: Pawn computes feral AP from weapon DPS
	{FrEquip("ITEM_MOD_FERAL_ATTACK_POWER")}, -- GlobalStrings
	{Fr("DPS_TEMPLATE")}, -- GlobalStrings: Pawn computes DPS itself

	-- ========================================
	-- Stats
	-- ========================================
	{Fr("INVTYPE_RANGED"), "IsRanged", 1, Fixed}, -- GlobalStrings
	{Fr("INVTYPE_RANGEDRIGHT"), "IsRanged", 1, Fixed}, -- GlobalStrings
	{Fr("INVTYPE_THROWN"), "IsRanged", 1, Fixed}, -- GlobalStrings
	{Fr("INVTYPE_WEAPON"), "IsOneHand", 1, Fixed}, -- GlobalStrings
	{Fr("INVTYPE_2HWEAPON"), "IsTwoHand", 1, Fixed}, -- GlobalStrings
	{Fr("INVTYPE_WEAPONMAINHAND"), "IsMainHand", 1, Fixed}, -- GlobalStrings
	{Fr("INVTYPE_WEAPONOFFHAND"), "IsOffHand", 1, Fixed}, -- GlobalStrings (INVTYPE_SHIELD has the same text)
	{Fr("INVTYPE_HOLDABLE"), "IsFrill", 1, Fixed}, -- GlobalStrings
	{Fr("DAMAGE_TEMPLATE"), "MinDamage", 1, Extract, "MaxDamage", 2, Extract}, -- GlobalStrings
	{Fr("DAMAGE_TEMPLATE_WITH_SCHOOL"), "MinDamage", 1, Extract, "MaxDamage", 2, Extract}, -- GlobalStrings; in game: "83 - 156 points de dégâts (Arcanes)"
	{Fr("PLUS_DAMAGE_TEMPLATE_WITH_SCHOOL"), "MinDamage", 1, Extract, "MaxDamage", 2, Extract}, -- GlobalStrings
	{Fr("PLUS_DAMAGE_TEMPLATE"), "MinDamage", 1, Extract, "MaxDamage", 2, Extract}, -- GlobalStrings
	{Fr("SINGLE_DAMAGE_TEMPLATE_WITH_SCHOOL"), "MinDamage", 1, Extract, "MaxDamage", 1, Extract}, -- GlobalStrings
	{Fr("SINGLE_DAMAGE_TEMPLATE"), "MinDamage", 1, Extract, "MaxDamage", 1, Extract}, -- GlobalStrings
	{"^Équipé : %+(%d+) aux dégâts des armes%.$", "MinDamage", 1, Extract, "MaxDamage", 1, Extract}, -- logs
	{Fr("ITEM_MOD_STRENGTH"), "Strength"}, -- GlobalStrings
	{Fr("ITEM_MOD_AGILITY"), "Agility"}, -- GlobalStrings
	{Fr("ITEM_MOD_STAMINA"), "Stamina"}, -- GlobalStrings
	{Fr("ITEM_MOD_INTELLECT"), "Intellect"}, -- GlobalStrings
	{Fr("ITEM_MOD_SPIRIT"), "Spirit"}, -- GlobalStrings
	{Fr("ITEM_MOD_HEALTH"), "Health"}, -- GlobalStrings
	{Fr("ITEM_MOD_MANA"), "Mana"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_ATTACK_POWER"), "Ap"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_RANGED_ATTACK_POWER"), "Rap"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_CRIT_RATING"), "CritRating"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_CRIT_MELEE_RATING"), "CritRating"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_CRIT_RANGED_RATING"), "CritRating"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_CRIT_SPELL_RATING"), "CritRating"}, -- GlobalStrings (ratings are unified in 3.3.5)
	{FrEquip("ITEM_MOD_HIT_RATING"), "HitRating"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_HIT_MELEE_RATING"), "HitRating"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_HIT_RANGED_RATING"), "HitRating"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_HIT_SPELL_RATING"), "HitRating"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_HASTE_RATING"), "HasteRating"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_HASTE_MELEE_RATING"), "HasteRating"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_HASTE_RANGED_RATING"), "HasteRating"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_HASTE_SPELL_RATING"), "HasteRating"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_EXPERTISE_RATING"), "ExpertiseRating"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_ARMOR_PENETRATION_RATING"), "ArmorPenetration"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_SPELL_POWER"), "SpellPower"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_SPELL_PENETRATION"), "SpellPenetration"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_DEFENSE_SKILL_RATING"), "DefenseRating"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_DODGE_RATING"), "DodgeRating"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_PARRY_RATING"), "ParryRating"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_BLOCK_RATING"), "BlockRating"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_BLOCK_VALUE"), "BlockValue"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_RESILIENCE_RATING"), "ResilienceRating"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_MANA_REGENERATION"), "Mp5"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_HEALTH_REGEN"), "Hp5"}, -- GlobalStrings
	{Fr("SHIELD_BLOCK_TEMPLATE"), "BlockValue"}, -- GlobalStrings
	{Fr("ARMOR_TEMPLATE"), "Armor"}, -- GlobalStrings
	{Fr("ITEM_RESIST_ALL"), "AllResist"}, -- GlobalStrings
	{FrSpell("Augmente la puissance des sorts de Feu de #."), "FireSpellDamage"}, -- Spell.dbc
	{FrSpell("Augmente la puissance des sorts d'Ombre de #."), "ShadowSpellDamage"}, -- Spell.dbc; logs
	{FrSpell("Augmente la puissance des sorts de Nature de #."), "NatureSpellDamage"}, -- Spell.dbc
	{FrSpell("Augmente la puissance des sorts des Arcanes de #."), "ArcaneSpellDamage"}, -- Spell.dbc; logs
	{FrSpell("Augmente la puissance des sorts de Givre de #."), "FrostSpellDamage"}, -- Spell.dbc; logs
	{FrSpell("Augmente la puissance des sorts du Sacré de #."), "HolySpellDamage"}, -- Spell.dbc
	{FrSpell("Augmente de # la puissance d'attaque."), "Ap"}, -- Spell.dbc
	{FrSpell("Augmente la puissance des attaques à distance de #."), "Rap"}, -- Spell.dbc
	{FrSpell("Augmente votre score de coup critique de #."), "CritRating"}, -- Spell.dbc
	{FrSpell("Augmente votre score de toucher de #."), "HitRating"}, -- Spell.dbc
	{FrSpell("Augmente votre score de blocage de #."), "BlockRating"}, -- Spell.dbc
	{FrSpell("Augmente la pénétration de vos sorts de #."), "SpellPenetration"}, -- Spell.dbc
	{FrSpell("Augmente de # le score de pénétration d'armure."), "ArmorPenetration"}, -- Spell.dbc
	{FrSpell("Rend # points de mana toutes les 5 sec."), "Mp5"}, -- Spell.dbc
	{FrSpell("Rend # points de vie toutes les 5 sec."), "Hp5"}, -- Spell.dbc
	{FrSpell("+# à toutes les résistances."), "AllResist"}, -- Spell.dbc; logs
	{"^%+(%d+) à la puissance des sorts$", "SpellPower"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) à la puissance d'attaque$", "Ap"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) à la puissance des attaques à distance$", "Rap"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) au score de défense$", "DefenseRating"}, -- SpellItemEnchantment.dbc; logs
	{"^%+(%d+) au score de coup critique$", "CritRating"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) au score de coups critiques$", "CritRating"}, -- logs
	{"^%+(%d+) au score de critique$", "CritRating"}, -- logs
	{"^%+(%d+) au score de toucher$", "HitRating"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) au score de hâte$", "HasteRating"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) au score d'expertise$", "ExpertiseRating"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) au score de pénétration d'armure$", "ArmorPenetration"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) au score de résilience$", "ResilienceRating"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) au score d'esquive$", "DodgeRating"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) au score de parade$", "ParryRating"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) au score de blocage$", "BlockRating"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) à la pénétration des sorts$", "SpellPenetration"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) à l'Agilité$", "Agility"}, -- SpellItemEnchantment.dbc; logs
	{"^%+(%d+) à l'Endurance$", "Stamina"}, -- SpellItemEnchantment.dbc; logs
	{"^%+(%d+) points de vie$", "Health"}, -- logs
	{"^%+(%d+) points de mana$", "Mana"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) Armure$", "Armor"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) aux dégâts de l'arme$", "MinDamage", 1, Extract, "MaxDamage", 1, Extract}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) points de dégâts$", "MinDamage", 1, Extract, "MaxDamage", 1, Extract}, -- SpellItemEnchantment.dbc
	{"^%+?(%d+) points de mana toutes les 5 sec%.$", "Mp5"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) points de mana toutes les 5 secondes$", "Mp5"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) points de vie toutes les 5 sec%.$", "Hp5"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) aux dégâts des sorts de Feu$", "FireSpellDamage"}, -- SpellItemEnchantment.dbc; logs
	{"^%+(%d+) aux dégâts des sorts d'Ombre$", "ShadowSpellDamage"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) aux dégâts des sorts de Nature$", "NatureSpellDamage"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) aux dégâts des sorts des Arcanes$", "ArcaneSpellDamage"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) aux dégâts des sorts de Givre$", "FrostSpellDamage"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) aux dégâts des sorts du Sacré$", "HolySpellDamage"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) à la résistance au Feu$", "FireResist"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) à la résistance à l'Ombre$", "ShadowResist"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) à la résistance à la Nature$", "NatureResist"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) à la résistance aux Arcanes$", "ArcaneResist"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) à la résistance au Givre$", "FrostResist"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) à toutes les résistances$", "AllResist"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) à toutes les caractéristiques$", "Strength", 1, Extract, "Agility", 1, Extract, "Stamina", 1, Extract, "Intellect", 1, Extract, "Spirit", 1, Extract}, -- SpellItemEnchantment.dbc
	{Fr("EMPTY_SOCKET_RED"), "RedSocket", 1, Fixed}, -- GlobalStrings
	{Fr("EMPTY_SOCKET_YELLOW"), "YellowSocket", 1, Fixed}, -- GlobalStrings
	{Fr("EMPTY_SOCKET_BLUE"), "BlueSocket", 1, Fixed}, -- GlobalStrings
	{Fr("EMPTY_SOCKET_NO_COLOR"), "PrismaticSocket", 1, Fixed}, -- GlobalStrings
	{Fr("EMPTY_SOCKET_META"), "MetaSocket", 1, Fixed}, -- GlobalStrings

	-- ========================================
	-- Meta gem effects (pieces after " et "): valued through MetaSocketEffect, so ignored here
	-- ========================================
	{"^dégâts critiques augmentés de %d+%%$"}, -- SpellItemEnchantment.dbc; logs
	{"^dégâts des critiques augmentés de %d+%%$"}, -- logs
	{"^%+%d+%% à la valeur de blocage du bouclier$"}, -- logs
	{"^une chance de rendre des points de vie au toucher$"}, -- logs
	{"^une chance de restaurer des points de mana au lancement d'un sort$"}, -- logs
	{"^%d+%% de renvoi de sort$"}, -- logs
	{"^durée d'Étourdissement réduite de %d+%%%.$"}, -- logs

	{'^"'}, -- Flavor text
}

-- Right side of the tooltip (weapon speed and item subclass).  Unrecognized lines here are always ignored.
PawnRightHandRegexes =
{
	{"^" .. PawnFrFormatToPattern(SPEED) .. " ([%d%.,]+)$", "Speed"}, -- GlobalStrings: SPEED
	{"^Hache$", "IsAxe", 1, Fixed}, -- ItemSubClass.dbc 2:0, 2:1
	{"^Arc$", "IsBow", 1, Fixed}, -- ItemSubClass.dbc 2:2
	{"^Arme à feu$", "IsGun", 1, Fixed}, -- ItemSubClass.dbc 2:3
	{"^Masse$", "IsMace", 1, Fixed}, -- ItemSubClass.dbc 2:4, 2:5
	{"^Arme d'hast$", "IsPolearm", 1, Fixed}, -- ItemSubClass.dbc 2:6
	{"^Epée$", "IsSword", 1, Fixed}, -- ItemSubClass.dbc 2:7, 2:8 (no accent on the E in the client); logs
	{"^Bâton$", "IsStaff", 1, Fixed}, -- ItemSubClass.dbc 2:10
	{"^Arme de pugilat$", "IsFist", 1, Fixed}, -- ItemSubClass.dbc 2:13; logs
	{"^Dague$", "IsDagger", 1, Fixed}, -- ItemSubClass.dbc 2:15
	{"^Armes de jet$", "IsThrown", 1, Fixed}, -- ItemSubClass.dbc 2:16
	{"^Arbalète$", "IsCrossbow", 1, Fixed}, -- ItemSubClass.dbc 2:18
	{"^Baguette$", "IsWand", 1, Fixed}, -- ItemSubClass.dbc 2:19
	{"^Tissu$", "IsCloth", 1, Fixed}, -- ItemSubClass.dbc 4:1
	{"^Cuir$", "IsLeather", 1, Fixed}, -- ItemSubClass.dbc 4:2
	{"^Mailles$", "IsMail", 1, Fixed}, -- ItemSubClass.dbc 4:3
	{"^Plaques$", "IsPlate", 1, Fixed}, -- ItemSubClass.dbc 4:4
	{"^Bouclier$", "IsShield", 1, Fixed}, -- ItemSubClass.dbc 4:6
}
