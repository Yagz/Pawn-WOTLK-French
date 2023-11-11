-- Pawn by Vger-Azjol-Nerub
-- www.vgermods.com
-- © 2006-2010 Green Eclipse.  This mod is released under the Creative Commons Attribution-NonCommercial-NoDerivs 3.0 license.
-- See Readme.htm for more information.
--
-- Wowhead scales
------------------------------------------------------------

local ScaleProviderName = "Wowhead"

function PawnWowheadScaleProvider_AddScales()



------------------------------------------------------------
-- Warrior
------------------------------------------------------------

PawnAddPluginScale(
	ScaleProviderName,
	"WarriorArms",
	PawnWowheadScale_WarriorArms,
	"c79c6e",
	{
		["Strength"] = 1.073, ["HitRating"] = 1.561, ["ExpertiseRating"] = 0.634, ["CritRating"] = 0.927, ["Agility"] = 0.78, ["ArmorPenetration"] = 0.829, ["HasteRating"] = 0.341, ["Ap"] = 0.488, ["Armor"] = 0.01, ["Stamina"] = .1, ["IsWand"] = -1000000, ["MetaSocketEffect"] = 100, ["MeleeDps"] = 6.049
	},
	1
)

PawnAddPluginScale(
	ScaleProviderName,
	"WarriorFury",
	PawnWowheadScale_WarriorFury,
	"c79c6e",
	{
		["ExpertiseRating"] = 2.5, ["Strength"] = 3.25, ["CritRating"] = 1.875, ["Agility"] = 1.25, ["ArmorPenetration"] = 3.125, ["HitRating"] = 2.5, ["HasteRating"] = 1.875, ["Ap"] = 1.25, ["Armor"] = 0.025, ["Stamina"] = .1, ["IsWand"] = -1000000, ["MetaSocketEffect"] = 100, ["MeleeDps"] = 27.5
	},
	1
)

PawnAddPluginScale(
	ScaleProviderName,
	"WarriorTank",
	PawnWowheadScale_WarriorTank,
	"c79c6e",
	{
		["Stamina"] = 2, ["DodgeRating"] = 1.4, ["DefenseRating"] = 1.6, ["BlockValue"] = 1.18, ["Agility"] = 1.2, ["ParryRating"] = 1.16, ["BlockRating"] = 0.7, ["Strength"] = 0.66, ["ExpertiseRating"] = 1.34, ["HitRating"] = 0.4, ["ArmorPenetration"] = 0.4, ["CritRating"] = 0.4, ["Armor"] = 0.1, ["HasteRating"] = 0.4, ["Ap"] = 0.12, ["IsWand"] = -1000000, ["MetaSocketEffect"] = 100, ["MeleeDps"] = 20, ["BonusArmor"] = 0.1
	},
	1
)

------------------------------------------------------------
-- Paladin
------------------------------------------------------------

PawnAddPluginScale(
	ScaleProviderName,
	"PaladinHoly",
	PawnWowheadScale_PaladinHoly,
	"f58cba",
	{
		["Intellect"] = 3.264, ["Mp5"] = 2.374, ["SpellPower"] = 2.374, ["CritRating"] = 2.671, ["HasteRating"] = 1.78, ["Stamina"] = .1, ["IsDagger"] = -1000000, ["IsFist"] = -1000000, ["IsStaff"] = -1000000, ["IsBow"] = -1000000, ["IsCrossbow"] = -1000000, ["IsGun"] = -1000000, ["IsThrown"] = -1000000, ["IsWand"] = -1000000, ["MetaSocketEffect"] = 100
	},
	1
)

PawnAddPluginScale(
	ScaleProviderName,
	"PaladinTank",
	PawnWowheadScale_PaladinTank,
	"f58cba",
	{
		["Stamina"] = 2.5, ["Agility"] = 1.9, ["ExpertiseRating"] = 1.975, ["DodgeRating"] = 2.35, ["DefenseRating"] = 2.15, ["ParryRating"] = 2.15, ["Armor"] = 0.15, ["BlockRating"] = 1.3, ["BlockValue"] = 2.15, ["IsDagger"] = -1000000, ["IsFist"] = -1000000, ["IsStaff"] = -1000000, ["IsBow"] = -1000000, ["IsCrossbow"] = -1000000, ["IsGun"] = -1000000, ["IsThrown"] = -1000000, ["IsWand"] = -1000000, ["MetaSocketEffect"] = 100, ["SpellPower"] = 0.15, ["HitRating"] = 1.45, ["BonusArmor"] = 0.15, ["CritRating"] = 0.075, ["Ap"] = 0.15, ["MeleeDps"] = 12.5
	},
	1
)

PawnAddPluginScale(
	ScaleProviderName,
	"PaladinRetribution",
	PawnWowheadScale_PaladinRetribution,
	"f58cba",
	{
		["MeleeDps"] = 5.988, ["HitRating"] = 2.695, ["Strength"] = 2.994, ["ExpertiseRating"] = 4.491, ["CritRating"] = 2.156, ["Ap"] = 1.228, ["Agility"] = 2.096, ["HasteRating"] = 2.036, ["ArmorPenetration"] = 1.886, ["SpellPower"] = 1.198, ["Stamina"] = .1, ["IsDagger"] = -1000000, ["IsFist"] = -1000000, ["IsStaff"] = -1000000, ["IsBow"] = -1000000, ["IsCrossbow"] = -1000000, ["IsGun"] = -1000000, ["IsThrown"] = -1000000, ["IsWand"] = -1000000, ["MetaSocketEffect"] = 100, ["Speed"] = 2.096, 
	},
	1
)

------------------------------------------------------------
-- Hunter
------------------------------------------------------------

PawnAddPluginScale(
	ScaleProviderName,
	"HunterBeastMastery",
	PawnWowheadScale_HunterBeastMastery,
	"abd473",
	{
		["RangedDps"] = 12.5, ["HitRating"] = 3.25, ["Agility"] = 2.5, ["CritRating"] = 1.75, ["Intellect"] = 0.1, ["Ap"] = 1, ["ArmorPenetration"] = 1.75, ["HasteRating"] = 2.75, ["Stamina"] = .1, ["IsPlate"] = -1000000, ["IsShield"] = -1000000, ["IsMace"] = -1000000, ["Is2HMace"] = -1000000, ["IsWand"] = -1000000, ["MetaSocketEffect"] = 100
	},
	1
)

PawnAddPluginScale(
	ScaleProviderName,
	"HunterMarksman",
	PawnWowheadScale_HunterMarksman,
	"abd473",
	{
		["RangedDps"] = 12.5, ["HitRating"] = 3.25, ["Agility"] = 2.5, ["CritRating"] = 1.75, ["Intellect"] = 0.1, ["ArmorPenetration"] = 1.75, ["HasteRating"] = 2.75, ["Stamina"] = .1, ["IsPlate"] = -1000000, ["IsShield"] = -1000000, ["IsMace"] = -1000000, ["Is2HMace"] = -1000000, ["IsWand"] = -1000000, ["MetaSocketEffect"] = 100
	},
	1
)

PawnAddPluginScale(
	ScaleProviderName,
	"HunterSurvival",
	PawnWowheadScale_HunterSurvival,
	"abd473",
	{
		["RangedDps"] = 12.5, ["HitRating"] = 3.25, ["Agility"] = 2.5, ["CritRating"] = 1.75, ["Intellect"] = 0.1, ["Ap"] = 1, ["ArmorPenetration"] = 1.75, ["HasteRating"] = 2.75, ["Stamina"] = .1, ["IsPlate"] = -1000000, ["IsShield"] = -1000000, ["IsMace"] = -1000000, ["Is2HMace"] = -1000000, ["IsWand"] = -1000000, ["MetaSocketEffect"] = 100
	},
	1
)

------------------------------------------------------------
-- Rogue
------------------------------------------------------------

PawnAddPluginScale(
	ScaleProviderName,
	"RogueAssassination",
	PawnWowheadScale_RogueAssassination,
	"fff569",
	{
		["MeleeDps"] = 8, ["Agility"] = 2.3, ["ExpertiseRating"] = 2, ["HitRating"] = 2, ["CritRating"] = 1.5, ["Ap"] = 1, ["ArmorPenetration"] = 1.5, ["HasteRating"] = 1.8, ["Strength"] = 1.1, ["Stamina"] = .1, ["IsPlate"] = -1000000, ["IsMail"] = -1000000, ["IsShield"] = -1000000, ["IsPolearm"] = -1000000, ["IsStaff"] = -1000000, ["Is2HAxe"] = -1000000, ["Is2HMace"] = -1000000, ["Is2HSword"] = -1000000, ["IsWand"] = -1000000, ["MetaSocketEffect"] = 100
	},
	1
)

PawnAddPluginScale(
	ScaleProviderName,
	"RogueCombat",
	PawnWowheadScale_RogueCombat,
	"fff569",
	{
		["MeleeDps"] = 8, ["Agility"] = 2.3, ["ExpertiseRating"] = 2, ["HitRating"] = 2, ["CritRating"] = 1.5, ["Ap"] = 1, ["ArmorPenetration"] = 1.5, ["HasteRating"] = 1.8, ["Strength"] = 1.1, ["Stamina"] = .1, ["IsPlate"] = -1000000, ["IsMail"] = -1000000, ["IsShield"] = -1000000, ["IsPolearm"] = -1000000, ["IsStaff"] = -1000000, ["Is2HAxe"] = -1000000, ["Is2HMace"] = -1000000, ["Is2HSword"] = -1000000, ["IsWand"] = -1000000, ["MetaSocketEffect"] = 100
	},
	1
)

PawnAddPluginScale(
	ScaleProviderName,
	"RogueSubtlety",
	PawnWowheadScale_RogueSubtlety,
	"fff569",
	{
		["MeleeDps"] = 8, ["Agility"] = 2.3, ["ExpertiseRating"] = 2, ["HitRating"] = 2, ["CritRating"] = 1.5, ["Ap"] = 1, ["ArmorPenetration"] = 1.5, ["HasteRating"] = 1.8, ["Strength"] = 1.1, ["Stamina"] = .1, ["IsPlate"] = -1000000, ["IsMail"] = -1000000, ["IsShield"] = -1000000, ["IsPolearm"] = -1000000, ["IsStaff"] = -1000000, ["Is2HAxe"] = -1000000, ["Is2HMace"] = -1000000, ["Is2HSword"] = -1000000, ["IsWand"] = -1000000, ["MetaSocketEffect"] = 100
	},
	1
)

------------------------------------------------------------
-- Priest
------------------------------------------------------------

PawnAddPluginScale(
	ScaleProviderName,
	"PriestDiscipline",
	PawnWowheadScale_PriestDiscipline,
	"ffffff",
	{
		["SpellPower"] = 2.667, ["Mp5"] = 3.333, ["Intellect"] = 2.333, ["HasteRating"] = 4, ["CritRating"] = 1.333, ["Spirit"] = 2.333, ["Stamina"] = .1, ["IsPlate"] = -1000000, ["IsMail"] = -1000000, ["IsLeather"] = -1000000, ["IsShield"] = -1000000, ["IsAxe"] = -1000000, ["Is2HAxe"] = -1000000, ["IsFist"] = -1000000, ["IsPolearm"] = -1000000, ["IsSword"] = -1000000, ["Is2HSword"] = -1000000, ["Is2HMace"] = -1000000, ["MetaSocketEffect"] = 100
	},
	1
)

PawnAddPluginScale(
	ScaleProviderName,
	"PriestHoly",
	PawnWowheadScale_PriestHoly,
	"ffffff",
	{
		["SpellPower"] = 2.667, ["Mp5"] = 3.333, ["Intellect"] = 2.333, ["HasteRating"] = 4, ["CritRating"] = 1.333, ["Spirit"] = 2.333, ["Stamina"] = .1, ["IsPlate"] = -1000000, ["IsMail"] = -1000000, ["IsLeather"] = -1000000, ["IsShield"] = -1000000, ["IsAxe"] = -1000000, ["Is2HAxe"] = -1000000, ["IsFist"] = -1000000, ["IsPolearm"] = -1000000, ["IsSword"] = -1000000, ["Is2HSword"] = -1000000, ["Is2HMace"] = -1000000, ["MetaSocketEffect"] = 100
	},
	1
)

PawnAddPluginScale(
	ScaleProviderName,
	"PriestShadow",
	PawnWowheadScale_PriestShadow,
	"ffffff",
	{
		["HitRating"] = 3.333, ["ShadowSpellDamage"] = 3.333, ["SpellPower"] = 3.333, ["CritRating"] = 3.333, ["HasteRating"] = 3.333, ["Spirit"] = 0.333, ["Intellect"] = 0.167, ["Stamina"] = .1, ["IsPlate"] = -1000000, ["IsMail"] = -1000000, ["IsLeather"] = -1000000, ["IsShield"] = -1000000, ["IsAxe"] = -1000000, ["Is2HAxe"] = -1000000, ["IsFist"] = -1000000, ["IsPolearm"] = -1000000, ["IsSword"] = -1000000, ["Is2HSword"] = -1000000, ["Is2HMace"] = -1000000, ["MetaSocketEffect"] = 100
	},
	1
)

------------------------------------------------------------
-- DK
------------------------------------------------------------

PawnAddPluginScale(
	ScaleProviderName,
	"DeathKnightBloodTank",
	PawnWowheadScale_DeathKnightBloodTank,
	"ff4d6b",
	{
		["MeleeDps"] = 20, ["Stamina"] = 2, ["DefenseRating"] = 1.6, ["Agility"] = 1.2, ["DodgeRating"] = 1.4, ["ParryRating"] = 1.16, ["ExpertiseRating"] = 1.34, ["Strength"] = 0.66, ["ArmorPenetration"] = 0.4, ["CritRating"] = 0.4, ["Armor"] = 0.1, ["HitRating"] = 1.34, ["HasteRating"] = 0.4, ["Ap"] = 0.12, ["IsShield"] = -1000000, ["IsDagger"] = -1000000, ["IsFist"] = -1000000, ["IsStaff"] = -1000000, ["IsBow"] = -1000000, ["IsCrossbow"] = -1000000, ["IsGun"] = -1000000, ["IsThrown"] = -1000000, ["IsWand"] = -1000000, ["MetaSocketEffect"] = 100, ["BonusArmor"] = 0.1
	},
	1
)

PawnAddPluginScale(
	ScaleProviderName,
	"DeathKnightFrostDps",
	PawnWowheadScale_DeathKnightFrostDps,
	"ff4d6b",
	{
		["MeleeDps"] = 62.5, ["HitRating"] = 1.25, ["Strength"] = 2.6, ["ExpertiseRating"] = 1.25, ["ArmorPenetration"] = 1.25, ["CritRating"] = 1.25, ["Ap"] = 1.25, ["HasteRating"] = 1.25, ["Armor"] = 1, ["Stamina"] = .1, ["IsShield"] = -1000000, ["IsDagger"] = -1000000, ["IsFist"] = -1000000, ["IsStaff"] = -1000000, ["IsBow"] = -1000000, ["IsCrossbow"] = -1000000, ["IsGun"] = -1000000, ["IsThrown"] = -1000000, ["IsWand"] = -1000000, ["MetaSocketEffect"] = 100, ["Agility"] = 0.625
	},
	1
)

PawnAddPluginScale(
	ScaleProviderName,
	"DeathKnightUnholyDps",
	PawnWowheadScale_DeathKnightUnholyDps,
	"ff4d6b",
	{
		["MeleeDps"] = 62.5, ["HitRating"] = 1.25, ["Strength"] = 2.6, ["ExpertiseRating"] = 1.25, ["ArmorPenetration"] = 1.25, ["CritRating"] = 1.25, ["Ap"] = 1.25, ["HasteRating"] = 1.25, ["Armor"] = 1, ["Stamina"] = .1, ["IsShield"] = -1000000, ["IsDagger"] = -1000000, ["IsFist"] = -1000000, ["IsStaff"] = -1000000, ["IsBow"] = -1000000, ["IsCrossbow"] = -1000000, ["IsGun"] = -1000000, ["IsThrown"] = -1000000, ["IsWand"] = -1000000, ["MetaSocketEffect"] = 100, ["Agility"] = 0.625
	},
	1
)

------------------------------------------------------------
-- Shaman
------------------------------------------------------------

PawnAddPluginScale(
	ScaleProviderName,
	"ShamanElemental",
	PawnWowheadScale_ShamanElemental,
	"6e95ff",
	{
		["HitRating"] = 3.333, ["SpellPower"] = 3.333, ["HasteRating"] = 3.333, ["CritRating"] = 3.333, ["Intellect"] = 0.567, ["Stamina"] = .1, ["IsPlate"] = -1000000, ["IsPolearm"] = -1000000, ["IsSword"] = -1000000, ["Is2HSword"] = -1000000, ["IsBow"] = -1000000, ["IsCrossbow"] = -1000000, ["IsGun"] = -1000000, ["IsThrown"] = -1000000, ["IsWand"] = -1000000, ["MetaSocketEffect"] = 100
	},
	1
)

PawnAddPluginScale(
	ScaleProviderName,
	"ShamanEnhancement",
	PawnWowheadScale_ShamanEnhancement,
	"6e95ff",
	{
		["MeleeDps"] = 16.667, ["HitRating"] = 1.342, ["ExpertiseRating"] = 4.51, ["Agility"] = 2.232, ["Intellect"] = 55, ["CritRating"] = 0.318, ["HasteRating"] = 3.078, ["Strength"] = 2, ["Ap"] = 1.667, ["SpellPower"] = 0.758, ["ArmorPenetration"] = 3, ["Stamina"] = .1, ["IsPlate"] = -1000000, ["IsPolearm"] = -1000000, ["IsSword"] = -1000000, ["Is2HSword"] = -1000000, ["IsBow"] = -1000000, ["IsCrossbow"] = -1000000, ["IsGun"] = -1000000, ["IsThrown"] = -1000000, ["IsWand"] = -1000000, ["MetaSocketEffect"] = 100
	},
	1
)

PawnAddPluginScale(
	ScaleProviderName,
	"ShamanRestoration",
	PawnWowheadScale_ShamanRestoration,
	"6e95ff",
	{
		["Mp5"] = 4.615, ["Intellect"] = 3.846, ["SpellPower"] = 3.846, ["CritRating"] = 3.846, ["HasteRating"] = 4.615, ["Stamina"] = .1, ["IsPlate"] = -1000000, ["IsPolearm"] = -1000000, ["IsSword"] = -1000000, ["Is2HSword"] = -1000000, ["IsBow"] = -1000000, ["IsCrossbow"] = -1000000, ["IsGun"] = -1000000, ["IsThrown"] = -1000000, ["IsWand"] = -1000000, ["MetaSocketEffect"] = 100
	},
	1
)

------------------------------------------------------------
-- Mage
------------------------------------------------------------

PawnAddPluginScale(
	ScaleProviderName,
	"MageArcane",
	PawnWowheadScale_MageArcane,
	"69ccf0",
	{
		["HitRating"] = 2.727, ["HasteRating"] = 3.03, ["ArcaneSpellDamage"] = 3.333, ["SpellPower"] = 3.333, ["CritRating"] = 2.423, ["Intellect"] = 2.12, ["Spirit"] = 0.607, ["Stamina"] = .1, ["IsPlate"] = -1000000, ["IsMail"] = -1000000, ["IsLeather"] = -1000000, ["IsShield"] = -1000000, ["IsAxe"] = -1000000, ["Is2HAxe"] = -1000000, ["IsFist"] = -1000000, ["IsMace"] = -1000000, ["Is2HMace"] = -1000000, ["IsPolearm"] = -1000000, ["Is2HSword"] = -1000000, ["IsBow"] = -1000000, ["IsCrossbow"] = -1000000, ["IsGun"] = -1000000, ["IsThrown"] = -1000000, ["MetaSocketEffect"] = 100, ["Mp5"] = 1.517
	},
	1
)

PawnAddPluginScale(
	ScaleProviderName,
	"MageFire",
	PawnWowheadScale_MageFire,
	"69ccf0",
	{
		["HitRating"] = 4.167, ["HasteRating"] = 3.057, ["FireSpellDamage"] = 3.333, ["SpellPower"] = 3.333, ["CritRating"] = 2.5, ["Intellect"] = 1.39, ["Stamina"] = .1, ["IsPlate"] = -1000000, ["IsMail"] = -1000000, ["IsLeather"] = -1000000, ["IsShield"] = -1000000, ["IsAxe"] = -1000000, ["Is2HAxe"] = -1000000, ["IsFist"] = -1000000, ["IsMace"] = -1000000, ["Is2HMace"] = -1000000, ["IsPolearm"] = -1000000, ["Is2HSword"] = -1000000, ["IsBow"] = -1000000, ["IsCrossbow"] = -1000000, ["IsGun"] = -1000000, ["IsThrown"] = -1000000, ["MetaSocketEffect"] = 100, ["Mp5"] = 1.39, ["Spirit"] = 0.557
	},
	1
)

PawnAddPluginScale(
	ScaleProviderName,
	"MageFrost",
	PawnWowheadScale_MageFrost,
	"69ccf0",
	{
		["HitRating"] = 5.15, ["HasteRating"] = 4.39, ["FrostSpellDamage"] = 3.333, ["SpellPower"] = 3.333, ["CritRating"] = 2.137, ["Intellect"] = 0.617, ["Stamina"] = .1, ["IsPlate"] = -1000000, ["IsMail"] = -1000000, ["IsLeather"] = -1000000, ["IsShield"] = -1000000, ["IsAxe"] = -1000000, ["Is2HAxe"] = -1000000, ["IsFist"] = -1000000, ["IsMace"] = -1000000, ["Is2HMace"] = -1000000, ["IsPolearm"] = -1000000, ["Is2HSword"] = -1000000, ["IsBow"] = -1000000, ["IsCrossbow"] = -1000000, ["IsGun"] = -1000000, ["IsThrown"] = -1000000, ["MetaSocketEffect"] = 100, ["Mp5"] = 1.463, ["Spirit"] = 0.557
	},
	1
)

------------------------------------------------------------
-- Warlock
------------------------------------------------------------

PawnAddPluginScale(
	ScaleProviderName,
	"WarlockAffliction",
	PawnWowheadScale_WarlockAffliction,
	"bca5ff",
	{
		["HitRating"] = 4.667, ["ShadowSpellDamage"] = 3.333, ["SpellPower"] = 3.333, ["HasteRating"] = 3.667, ["CritRating"] = 2, ["Intellect"] = 0.667, ["Stamina"] = .1, ["IsPlate"] = -1000000, ["IsMail"] = -1000000, ["IsLeather"] = -1000000, ["IsShield"] = -1000000, ["IsAxe"] = -1000000, ["Is2HAxe"] = -1000000, ["IsFist"] = -1000000, ["IsMace"] = -1000000, ["Is2HMace"] = -1000000, ["IsPolearm"] = -1000000, ["Is2HSword"] = -1000000, ["IsBow"] = -1000000, ["IsCrossbow"] = -1000000, ["IsGun"] = -1000000, ["IsThrown"] = -1000000, ["MetaSocketEffect"] = 100
	},
	1
)

PawnAddPluginScale(
	ScaleProviderName,
	"WarlockDemonology",
	PawnWowheadScale_WarlockDemonology,
	"bca5ff",
	{
		["HitRating"] = 5.333, ["HasteRating"] = 4, ["ShadowSpellDamage"] = 3.333, ["SpellPower"] = 3.333, ["CritRating"] = 2.667, ["Intellect"] = 1.333, ["Stamina"] = .1, ["IsPlate"] = -1000000, ["IsMail"] = -1000000, ["IsLeather"] = -1000000, ["IsShield"] = -1000000, ["IsAxe"] = -1000000, ["Is2HAxe"] = -1000000, ["IsFist"] = -1000000, ["IsMace"] = -1000000, ["Is2HMace"] = -1000000, ["IsPolearm"] = -1000000, ["Is2HSword"] = -1000000, ["IsBow"] = -1000000, ["IsCrossbow"] = -1000000, ["IsGun"] = -1000000, ["IsThrown"] = -1000000, ["MetaSocketEffect"] = 100
	},
	1
)

PawnAddPluginScale(
	ScaleProviderName,
	"WarlockDestruction",
	PawnWowheadScale_WarlockDestruction,
	"bca5ff",
	{
		["HitRating"] = 5.333, ["HasteRating"] = 4, ["ShadowSpellDamage"] = 3.333, ["SpellPower"] = 3.333, ["CritRating"] = 2.667, ["Intellect"] = 1.333, ["Stamina"] = .1, ["IsPlate"] = -1000000, ["IsMail"] = -1000000, ["IsLeather"] = -1000000, ["IsShield"] = -1000000, ["IsAxe"] = -1000000, ["Is2HAxe"] = -1000000, ["IsFist"] = -1000000, ["IsMace"] = -1000000, ["Is2HMace"] = -1000000, ["IsPolearm"] = -1000000, ["Is2HSword"] = -1000000, ["IsBow"] = -1000000, ["IsCrossbow"] = -1000000, ["IsGun"] = -1000000, ["IsThrown"] = -1000000, ["MetaSocketEffect"] = 100
	},
	1
)

------------------------------------------------------------
-- Druid
------------------------------------------------------------

PawnAddPluginScale(
	ScaleProviderName,
	"DruidBalance",
	PawnWowheadScale_DruidBalance,
	"ff7d0a",
	{
		["HitRating"] = 4, ["SpellPower"] = 3.333, ["ArcaneSpellDamage"] = 3.333, ["HasteRating"] = 2.667, ["CritRating"] = 2, ["Spirit"] = 1, ["Intellect"] = 1.333, ["Stamina"] = .1, ["IsPlate"] = -1000000, ["IsMail"] = -1000000, ["IsShield"] = -1000000, ["IsAxe"] = -1000000, ["Is2HAxe"] = -1000000, ["IsSword"] = -1000000, ["Is2HSword"] = -1000000, ["IsBow"] = -1000000, ["IsCrossbow"] = -1000000, ["IsGun"] = -1000000, ["IsThrown"] = -1000000, ["IsWand"] = -1000000, ["MetaSocketEffect"] = 100, ["Mp5"] = 2
	},
	1
)

PawnAddPluginScale(
	ScaleProviderName,
	"DruidFeralDps",
	PawnWowheadScale_DruidFeralDps,
	"ff7d0a",
	{
		["Agility"] = 2.758, ["ArmorPenetration"] = 2.59, ["Strength"] = 2.266, ["CritRating"] = 1.623, ["ExpertiseRating"] = 2.407, ["HitRating"] = 2.407, ["FeralAp"] = 1, ["Ap"] = 1, ["HasteRating"] = 0.927, ["Stamina"] = .1, ["IsPlate"] = -1000000, ["IsMail"] = -1000000, ["IsShield"] = -1000000, ["IsAxe"] = -1000000, ["Is2HAxe"] = -1000000, ["IsSword"] = -1000000, ["Is2HSword"] = -1000000, ["IsBow"] = -1000000, ["IsCrossbow"] = -1000000, ["IsGun"] = -1000000, ["IsThrown"] = -1000000, ["IsWand"] = -1000000, ["MetaSocketEffect"] = 100
	},
	1
)

PawnAddPluginScale(
	ScaleProviderName,
	"DruidFeralTank",
	PawnWowheadScale_DruidFeralTank,
	"ff7d0a",
	{
		["Agility"] = 1.482, ["Stamina"] = 1.561, ["DodgeRating"] = 0.243, ["DefenseRating"] = 0.232, ["ExpertiseRating"] = 2.28, ["Strength"] = 1.133, ["Armor"] = 0.286, ["HitRating"] = 1.123, ["HasteRating"] = 0.831, ["Ap"] = 0.5, ["FeralAp"] = 0.5, ["CritRating"] = 1.009, ["IsPlate"] = -1000000, ["IsMail"] = -1000000, ["IsShield"] = -1000000, ["IsAxe"] = -1000000, ["Is2HAxe"] = -1000000, ["IsSword"] = -1000000, ["Is2HSword"] = -1000000, ["IsBow"] = -1000000, ["IsCrossbow"] = -1000000, ["IsGun"] = -1000000, ["IsThrown"] = -1000000, ["IsWand"] = -1000000, ["MetaSocketEffect"] = 100, ["ArmorPenetration"] = 0.879, ["Resilience"] = 0.116
	},
	1
)

PawnAddPluginScale(
	ScaleProviderName,
	"DruidRestoration",
	PawnWowheadScale_DruidRestoration,
	"ff7d0a",
	{
		["SpellPower"] = 3.125, ["Mp5"] = 1.563, ["HasteRating"] = 3.125, ["Intellect"] = 0.891, ["Spirit"] = 1.238, ["CritRating"] = 0.313, ["Stamina"] = .1, ["IsPlate"] = -1000000, ["IsMail"] = -1000000, ["IsShield"] = -1000000, ["IsAxe"] = -1000000, ["Is2HAxe"] = -1000000, ["IsSword"] = -1000000, ["Is2HSword"] = -1000000, ["IsBow"] = -1000000, ["IsCrossbow"] = -1000000, ["IsGun"] = -1000000, ["IsThrown"] = -1000000, ["IsWand"] = -1000000, ["MetaSocketEffect"] = 100
	},
	1
)

------------------------------------------------------------

-- PawnWowheadScaleProviderOptions.LastAdded keeps track of the last time that we tried to automatically enable scales for this character.
if not PawnWowheadScaleProviderOptions then PawnWowheadScaleProviderOptions = { } end
if not PawnWowheadScaleProviderOptions.LastAdded then PawnWowheadScaleProviderOptions.LastAdded = 0 end

local _, Class = UnitClass("player")
if PawnWowheadScaleProviderOptions.LastAdded < 1 then
	-- Enable round one of scales based on the player's class.
	if Class == "WARRIOR" then
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "WarriorFury"), true)
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "WarriorTank"), true)
	elseif Class == "PALADIN" then
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "PaladinHoly"), true)
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "PaladinTank"), true)
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "PaladinRetribution"), true)
	elseif Class == "HUNTER" then
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "HunterBeastMastery"), true)
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "HunterMarksman"), true)
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "HunterSurvival"), true)
	elseif Class == "ROGUE" then
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "RogueAssassination"), true)
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "RogueCombat"), true)
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "RogueSubtlety"), true)
	elseif Class == "PRIEST" then
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "PriestDiscipline"), true)
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "PriestHoly"), true)
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "PriestShadow"), true)
	elseif Class == "DEATHKNIGHT" then
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "DeathKnightBloodDps"), true)
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "DeathKnightBloodTank"), true)
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "DeathKnightFrostDps"), true)
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "DeathKnightFrostTank"), true)
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "DeathKnightUnholyDps"), true)
	elseif Class == "SHAMAN" then
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "ShamanElemental"), true)
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "ShamanEnhancement"), true)
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "ShamanRestoration"), true)
	elseif Class == "MAGE" then
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "MageArcane"), true)
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "MageFire"), true)
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "MageFrost"), true)
	elseif Class == "WARLOCK" then
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "WarlockAffliction"), true)
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "WarlockDemonology"), true)
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "WarlockDestruction"), true)
	elseif Class == "DRUID" then
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "DruidBalance"), true)
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "DruidFeralDps"), true)
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "DruidFeralTank"), true)
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "DruidRestoration"), true)
	end
end

if PawnWowheadScaleProviderOptions.LastAdded < 2 then
	if Class == "WARRIOR" then
		PawnSetScaleVisible(PawnGetProviderScaleName(ScaleProviderName, "WarriorArms"), true)
	end
end

-- Don't reenable those scales again after the user has disabled them previously.
PawnWowheadScaleProviderOptions.LastAdded = 2

-- After this function terminates there's no need for it anymore, so cause it to self-destruct to save memory.
PawnWowheadScaleProvider_AddScales = nil

end -- PawnWowheadScaleProvider_AddScales

------------------------------------------------------------

PawnAddPluginScaleProvider(ScaleProviderName, PawnWowheadScale_Provider, PawnWowheadScaleProvider_AddScales)
