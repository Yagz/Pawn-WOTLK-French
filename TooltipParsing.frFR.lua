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

-- GlobalStrings: ITEM_RESIST_SINGLE "%1$c%2$d à la résistance %3$s", for one school name as the client shows it in game.
local function FrResist(School)
	return "^" .. PawnFrFormatToPattern((gsub(ITEM_RESIST_SINGLE, "%%3%$s", School))) .. "$"
end

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
	{"^Projectile$"}, -- scan: "Projectile" (item 31735), slot line of ammo
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
	-- GlobalStrings: temporary item buff.  ITEM_ENCHANT_TIME_LEFT_DAYS "%s (%d |4jour:jours;)" and _HOURS "%s (%d |4heure:heures;)"
	-- are written by hand: the generic |4 form would also swallow "Utiliser : ... (30 min de recharge)" (scan).
	{"^.- %(%d+ jours?%)$"}, -- GlobalStrings: ITEM_ENCHANT_TIME_LEFT_DAYS
	{"^.- %(%d+ heures?%)$"}, -- GlobalStrings: ITEM_ENCHANT_TIME_LEFT_HOURS
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
	{FrResist("Feu"), "FireResist"}, -- GlobalStrings: ITEM_RESIST_SINGLE; scan (PawnScanResults.parsed): "+110 à la résistance Feu", "-10 à la résistance Feu"
	{FrResist("Ombre"), "ShadowResist"}, -- GlobalStrings: ITEM_RESIST_SINGLE; scan (parsed): "+100 à la résistance Ombre"
	{FrResist("Nature"), "NatureResist"}, -- GlobalStrings: ITEM_RESIST_SINGLE; scan (parsed): "+100 à la résistance Nature"
	{FrResist("Arcanes"), "ArcaneResist"}, -- GlobalStrings: ITEM_RESIST_SINGLE; scan (parsed): "+5 à la résistance Arcanes"
	{FrResist("Givre"), "FrostResist"}, -- GlobalStrings: ITEM_RESIST_SINGLE; scan (parsed): "+100 à la résistance Givre"
	{FrSpell("Score de défense augmenté de #."), "DefenseRating"}, -- scan (PawnScanResults.parsed, no item number kept): "Équipé : Score de défense augmenté de 7."
	{FrSpell("Augmente de # la puissance d'attaque pour les formes de félin, d'ours, d'ours redoutable et de sélénien uniquement."), "FeralAp"}, -- Spell.dbc; scan (parsed): "... de 154 ..."
	{"^Ajoute ([%d%.,]+) dégâts par seconde$", "Dps"}, -- scan (PawnScanResults.parsed): "Ajoute 32 dégâts par seconde", "Ajoute 46.5 dégâts par seconde" (ammunition)
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
	{FrSpell("+# en Force."), "Strength"}, -- Spell.dbc
	{FrSpell("+# en Agilité."), "Agility"}, -- Spell.dbc
	{FrSpell("+# en Endurance."), "Stamina"}, -- Spell.dbc
	{FrSpell("+# en Intelligence."), "Intellect"}, -- Spell.dbc
	{FrSpell("+# en Esprit."), "Spirit"}, -- Spell.dbc
	{FrSpell("Augmente votre Esprit de #."), "Spirit"}, -- Spell.dbc
	{FrSpell("+# à l'Armure."), "Armor"}, -- Spell.dbc
	{FrSpell("Augmente l'Armure de #."), "Armor"}, -- Spell.dbc
	{FrSpell("+# à la résistance au Feu."), "FireResist"}, -- Spell.dbc
	{FrSpell("+# à la résistance à l'Ombre."), "ShadowResist"}, -- Spell.dbc
	{FrSpell("+# à la résistance à la Nature."), "NatureResist"}, -- Spell.dbc
	{FrSpell("+# à la résistance aux Arcanes."), "ArcaneResist"}, -- Spell.dbc
	{FrSpell("+# à la résistance au Givre."), "FrostResist"}, -- Spell.dbc
	{FrSpell("Augmente la résistance au Feu de #."), "FireResist"}, -- Spell.dbc
	{FrSpell("Augmente la résistance à l'Ombre de #."), "ShadowResist"}, -- Spell.dbc
	{FrSpell("Augmente la résistance à la Nature de #."), "NatureResist"}, -- Spell.dbc
	{FrSpell("Augmente la résistance aux Arcanes de #."), "ArcaneResist"}, -- Spell.dbc
	{FrSpell("Augmente la résistance au Givre de #."), "FrostResist"}, -- Spell.dbc
	{FrSpell("Augmente la puissance de vos sorts de #."), "SpellPower"}, -- Spell.dbc
	{FrSpell("Augmente le score de coup critique de #."), "CritRating"}, -- Spell.dbc
	{FrSpell("Augmente le score de coup critique des sorts de #."), "CritRating"}, -- Spell.dbc
	{FrSpell("Augmente votre score de coup critique à distance de #."), "CritRating"}, -- scan: "Équipé : Augmente votre score de coup critique à distance de 14." (item 7348)
	{FrSpell("Augmente le score de hâte de #."), "HasteRating"}, -- Spell.dbc
	{FrSpell("Augmente le score d'expertise de #."), "ExpertiseRating"}, -- Spell.dbc
	{FrSpell("Augmente votre score d'esquive de #."), "DodgeRating"}, -- Spell.dbc
	{FrSpell("Augmente votre score de parade de #."), "ParryRating"}, -- Spell.dbc
	{FrSpell("+# au score de résilience."), "ResilienceRating"}, -- Spell.dbc
	{"^%+(%d+) à la puissance des sorts$", "SpellPower"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) à la puissance d'attaque$", "Ap"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) à la puissance des attaques à distance$", "Rap"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) au score de défense$", "DefenseRating"}, -- SpellItemEnchantment.dbc; logs
	{"^%+?(%d+) au score de coup critique$", "CritRating"}, -- SpellItemEnchantment.dbc (also "+30 à la puissance des sorts et 20 au score de coup critique")
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
	{"^%+?(%d+) points de mana toutes les 5 secondes$", "Mp5"}, -- SpellItemEnchantment.dbc (also "+12 à la puissance des sorts et 8 points de mana toutes les 5 secondes")
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
	-- Other SpellItemEnchantment.dbc wordings (one row per real text form)
	{"^%+ (%d+) Force$", "Strength"}, -- SpellItemEnchantment.dbc: "+ 7 Force"
	{"^%+(%d+) à la Force$", "Strength"}, -- SpellItemEnchantment.dbc: "+5 à la Force et +4 au score de défense"
	{"^%+(%d+) à l'Intelligence$", "Intellect"}, -- SpellItemEnchantment.dbc: "+7 à la puissance des sorts et +6 à l'Intelligence"
	{"^%+(%d+) à l'Esprit$", "Spirit"}, -- SpellItemEnchantment.dbc: "+6 à la puissance des sorts et +5 à l'Esprit"
	{"^%+(%d+) à toutes les statistiques$", "Strength", 1, Extract, "Agility", 1, Extract, "Stamina", 1, Extract, "Intellect", 1, Extract, "Spirit", 1, Extract}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) aux points de vie$", "Health"}, -- SpellItemEnchantment.dbc: "+15 aux points de vie"
	{"^%+(%d+) aux points de mana$", "Mana"}, -- SpellItemEnchantment.dbc: "+5 aux points de mana"
	{"^%+(%d+) Défense$", "DefenseRating"}, -- SpellItemEnchantment.dbc: "+20 Défense et +15 au score d'esquive"
	{"^%+(%d+) score de coup critique$", "CritRating"}, -- SpellItemEnchantment.dbc: "+5 Force et +4 score de coup critique"
	{"^%+(%d+) au score de critique en mêlée$", "CritRating"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) au score de coup critique à distance$", "CritRating"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) aux score de toucher$", "HitRating"}, -- SpellItemEnchantment.dbc: "+11 aux score de toucher"
	{"^%+(%d+) au score de toucher à distance$", "HitRating"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) au score de hâte à distance$", "HasteRating"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) score de résilience$", "ResilienceRating"}, -- SpellItemEnchantment.dbc: "+6 Endurance et +5 score de résilience"
	{"^%+(%d+) à la résilience$", "ResilienceRating"}, -- SpellItemEnchantment.dbc: "+9 à la résilience"
	{"^%+(%d+) à la valeur de blocage$", "BlockValue"}, -- SpellItemEnchantment.dbc: "+36 à la valeur de blocage"
	{"^%+(%d+) à la puissance d'attaque à distance$", "Rap"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) à la puissance des sorts de Feu$", "FireSpellDamage"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) à la puissance des sorts d'Ombre$", "ShadowSpellDamage"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) à la puissance des sorts de Givre$", "FrostSpellDamage"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) à la puissance des sorts de Feu et des Arcanes$", "FireSpellDamage", 1, Extract, "ArcaneSpellDamage", 1, Extract}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) à la puissance des sorts d'Ombre et de Givre$", "ShadowSpellDamage", 1, Extract, "FrostSpellDamage", 1, Extract}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) à la résistance aux arcanes$", "ArcaneResist"}, -- SpellItemEnchantment.dbc: "+31 à la résistance aux arcanes"
	{"^%+(%d+) de résistance à la Nature$", "NatureResist"}, -- SpellItemEnchantment.dbc: "+70 de résistance à la Nature"
	{"^%+(%d+) point de vie toutes les 5 sec%.$", "Hp5"}, -- SpellItemEnchantment.dbc: "+1 point de vie toutes les 5 sec."
	{"^%+?(%d+) point de mana toutes les 5 sec%.$", "Mp5"}, -- SpellItemEnchantment.dbc: "+1 point de mana ...", "3 point de mana ..."
	{"^%+(%d+) point de mana toutes les 5 secondes$", "Mp5"}, -- SpellItemEnchantment.dbc: "+2 point de mana toutes les 5 secondes"
	{"^%+(%d+) points de mana rendus toutes les 5 secondes$", "Mp5"}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) points de mana par tranche de 5 secondes$", "Mp5"}, -- SpellItemEnchantment.dbc
	{"^(%d+) à la régén%. mana toutes les 5 sec%.$", "Mp5"}, -- SpellItemEnchantment.dbc: "5 à la régén. mana toutes les 5 sec."
	{"^%+(%d+) points de vie et de mana toutes les 5 sec%.$", "Hp5", 1, Extract, "Mp5", 1, Extract}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) points de mana et de vie toutes les 5 sec%.$", "Mp5", 1, Extract, "Hp5", 1, Extract}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) point de dégâts$", "MinDamage", 1, Extract, "MaxDamage", 1, Extract}, -- SpellItemEnchantment.dbc: "+1 point de dégâts"
	{"^%+(%d+) Dégâts de l'arme$", "MinDamage", 1, Extract, "MaxDamage", 1, Extract}, -- SpellItemEnchantment.dbc: "+1 Dégâts de l'arme"
	{"^Lunette %(%+(%d+) points? de dégâts%)$", "MinDamage", 1, Extract, "MaxDamage", 1, Extract}, -- SpellItemEnchantment.dbc: ranged weapon scope
	{"^Lunette %(%+(%d+) au score de coup critique%)$", "CritRating"}, -- SpellItemEnchantment.dbc
	{"^Renforcé %(%+(%d+) Armure%)$", "Armor"}, -- SpellItemEnchantment.dbc: armor kit
	{"^Contrepoids %(%+(%d+) au score de hâte%)$", "HasteRating"}, -- SpellItemEnchantment.dbc
	-- Whole lines whose stats are not separated by ", ", "/", " & " or " et ", or whose "/" would split a stat in two
	{"^%+(%d+) Score de défense %+(%d+) Endurance %+(%d+) Valeur de blocage$", "DefenseRating", 1, Extract, "Stamina", 2, Extract, "BlockValue", 3, Extract}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) à la puissance d'attaque %+(%d+) Endurance %+(%d+) au score de toucher$", "Ap", 1, Extract, "Stamina", 2, Extract, "HitRating", 3, Extract}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) à la puissance d'attaque %+(%d+) au score d'esquive$", "Ap", 1, Extract, "DodgeRating", 2, Extract}, -- SpellItemEnchantment.dbc
	{"^%+(%d+) à la puissance des sorts et %+(%d+) points de mana/5 secondes$", "SpellPower", 1, Extract, "Mp5", 2, Extract}, -- SpellItemEnchantment.dbc
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
	{"^légère augmentation de la vitesse de course$"}, -- SpellItemEnchantment.dbc: "+24 à la puissance d'attaque et légère augmentation de la vitesse de course"
	{"^augmentation de la Vitesse de course mineure$"}, -- SpellItemEnchantment.dbc: "+25 à la puissance des sorts et augmentation de la Vitesse de course mineure"
	{"^durée de Silence réduite de %d+%%$"}, -- SpellItemEnchantment.dbc: "+25 à la puissance des sorts et durée de Silence réduite de 10%"
	{"^durée de Peur réduite de %d+%%$"}, -- SpellItemEnchantment.dbc: "+21 au score de coup critique et durée de Peur réduite de 10%"
	{"^durée de Etourdir réduite de %d+%%$"}, -- SpellItemEnchantment.dbc: "+32 Endurance et durée de Etourdir réduite de 10%"
	{"^durée d'Etourdissement réduite de %d+%%$"}, -- SpellItemEnchantment.dbc: "+26 Endurance et durée d'Etourdissement réduite de 10%"
	{"^%d+%% à la résistance aux étourdissements$"}, -- SpellItemEnchantment.dbc: "+24 à la puissance d'attaque et 5% à la résistance aux étourdissements"
	{"^%d+%% de réduction de la menace$"}, -- SpellItemEnchantment.dbc: "+14 à la puissance des sorts et 2% de réduction de la menace"
	{"^menace réduite de %d+%%$"}, -- SpellItemEnchantment.dbc: "+25 à la puissance des sorts et menace réduite de 2%", "+10 Esprit et menace réduite de 2%"
	{"^%+%d+%% à l'Intelligence$"}, -- SpellItemEnchantment.dbc: "+25 à la puissance des sorts et +2% à l'Intelligence", "+14 à la puissance des sorts & +2% à l'Intelligence"
	{"^%+%d+%% aux points de mana$"}, -- SpellItemEnchantment.dbc: "+21 au score de coup critique et +2% aux points de mana"
	{"^%d+%% au renvoi des sorts$"}, -- SpellItemEnchantment.dbc: "+25 au score de coup critique et 1% au renvoi des sorts"
	{"^une chance de rendre du mana lors des incantations$"}, -- SpellItemEnchantment.dbc: "+21 à l'Intelligence et une chance de rendre du mana lors des incantations"
	{"^effets de soin critiques augmentés de %d+%%$"}, -- SpellItemEnchantment.dbc: "+11 points de mana toutes les 5 secondes et effets de soin critiques augmentés de 3%"
	{"^réduit les dégâts des sorts reçus de %d+%%$"}, -- SpellItemEnchantment.dbc: "+32 Endurance et réduit les dégâts des sorts reçus de 2%"
	{"^augmente de %d+%% la valeur d'armure des objets$"}, -- SpellItemEnchantment.dbc: "+32 Endurance et augmente de 2% la valeur d'armure des objets"
	{"^régénère parfois vos points de vie quand critique$"}, -- SpellItemEnchantment.dbc: "+42 à la puissance d'attaque et régénère parfois vos points de vie quand critique"
	-- Meta lines whose effect would be cut by the " et " or "/" split: whole line, stat part only
	{"^%+(%d+) au score de coup critique et durée de Ralentir et Immobiliser réduite de %d+%%$", "CritRating"}, -- SpellItemEnchantment.dbc: "+21 au score de coup critique et durée de Ralentir et Immobiliser réduite de 10%"
	{"^%+(%d+) au score de coup critique et durées des ralentissements/immobilisations réduites de %d+%%$", "CritRating"}, -- SpellItemEnchantment.dbc: "+12 au score de coup critique et durées des ralentissements/immobilisations réduites de 10%"
	{"^%+(%d+) à la puissance des sort$", "SpellPower"}, -- SpellItemEnchantment.dbc: "+25 à la puissance des sort et durée de Etourdir réduite de 10%" (client typo)

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
