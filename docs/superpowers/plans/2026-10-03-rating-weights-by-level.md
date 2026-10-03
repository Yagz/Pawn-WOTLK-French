# Poids des scores selon le niveau — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Ajuster, au niveau exact du personnage (1 à 80), les poids des 10 stats de score des échelles « Classic » (HawsJon, mode Wrath), à partir de la table `gtCombatRatings.dbc` du client.

**Architecture:** un script Python conservé dans le dépôt extrait la table du client vers un fichier Lua généré, `PawnRatingLevelFactors.lua`. `ClassicHawsJon.lua` mémorise les poids d'origine (niveau 80) des échelles Classic, puis les multiplie par `P[80] / P[Niveau]` au chargement et à chaque `PLAYER_LEVEL_UP`. Une fonction testable hors jeu fournit le texte que `PawnUI.lua` affiche.

**Tech Stack:** Lua 5.1 (client 3.3.5a), LuaJIT pour les tests (`luajit tests/run.lua`), Python 3 + `mpyq` via `uv`.

**Spec:** `docs/superpowers/specs/2026-10-02-rating-weights-by-level-design.md`

## Global Constraints

- Les données viennent du client réel (`Data/frFR/*.MPQ`), et le fichier généré cite sa source. Aucune valeur n'est tapée à la main.
- Stats Pawn concernées (exactement 10) : `HitRating`, `CritRating`, `HasteRating`, `ExpertiseRating`, `ArmorPenetration`, `DefenseRating`, `DodgeRating`, `ParryRating`, `BlockRating`, `ResilienceRating`.
- Formule : `Values[Stat] = Origine[Stat] * (P[Stat][80] / P[Stat][Niveau])`. Les parenthèses sont obligatoires : au niveau 80 le facteur vaut alors exactement 1.0 et les valeurs restent identiques au bit près.
- Niveau borné à `[1, 80]`.
- Seules les échelles dont `Provider == "Classic"` sont modifiées. Les échelles perso, copiées ou importées ne le sont jamais.
- Les valeurs ajustées ne sont pas sauvegardées. `PawnUnitializePlugins` efface déjà `Values` des échelles de fournisseurs.
- Relancer le script sur les mêmes données doit produire exactement le même fichier.
- Un nouveau fichier dans `Pawn.toc` demande un redémarrage complet du client.
- Les correctifs `!!!ClassicAPI` ne sont pas concernés et ne doivent pas être mêlés à ces commits.
- Les messages de commit sont en anglais et se terminent par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Écarts assumés par rapport à la spec (relevés pendant la préparation)

1. **Pas de date dans l'en-tête généré.** Une date rendrait la régénération non reproductible. L'en-tête cite à la place, pour chaque fichier source, l'archive MPQ et le md5 du fichier extrait. La spec est corrigée dans la tâche 1.
2. **L'ordre de priorité des MPQ est complet.** `PaperDollFrame.lua` existe dans `patch-frFR-3`, `patch-frFR-2`, `patch-frFR` et `locale-frFR`. La spec ne citait que les deux derniers. Le script utilise une liste explicite, de la plus prioritaire à la moins prioritaire, et l'en-tête indique quelle archive a fourni chaque fichier. `Patch-Z.MPQ` (patch du serveur) ne contient aucun des deux fichiers (vérifié le 2026-10-03), donc sa place exacte dans la liste n'a pas d'effet ici.
3. **Valeurs de contrôle à 4 décimales.** Le tableau de la spec tronque certaines valeurs. Les tests utilisent les valeurs arrondies de la table générée : résilience 80 = 94,2712, toucher 70 = 15,7692, expertise 80 = 8,1975. La spec est corrigée dans la tâche 1.
4. **Le niveau n'est retenu que si au moins une échelle Classic a été ajustée.** Sans cette règle, un appel fait avant la création des échelles bloquerait l'appel du chargement au même niveau.
5. **`SpellHitRating` / `SpellCritRating` / `SpellHasteRating` ne sont pas touchés.** Ils ne sont pas dans les valeurs finales des échelles Classic Wrath : on l'a vérifié hors jeu sur « Prêtre : Ombre », ils valent `nil` avant et après `PawnCorrectScaleErrors`, qui les fusionne avec les stats combinées en mode Wrath (`Pawn.lua:3206-3212`).

## Review Focus

- **Niveau hors bornes (0, négatif, 85, `nil`)** : il doit être ramené à 1 ou 80 sans erreur. Test « niveaux 15, 0 et 85 » (tâche 2).
- **`PLAYER_LEVEL_UP` ou appel avant que les échelles existent** (`PawnCommon.Scales` absent ou vide) : aucune erreur, et l'appel du chargement au même niveau doit quand même ajuster. Test « appel avant la création des échelles » (tâche 2).
- **Allers-retours de niveau (60 → 61 → 60)** : les valeurs ne doivent pas se cumuler et doivent revenir exactement à celles du premier passage au niveau 60. Test « montée de niveau » (tâche 2).
- **Copie d'une échelle Classic par l'utilisateur (pas de `Provider`)** : elle ne doit jamais changer, à aucun niveau. Test « échelle perso ou importée » (tâche 2).
- **Score absent (poids 0 retiré par `PawnAddPluginScale`)** : il doit rester absent à tous les niveaux, sans apparaître avec une valeur 0. Test « niveau 60 » (tâche 2).

---

### Task 1 : stubs, script d'extraction, table générée et tests de la table

**Files:**
- Modify: `tests/wowapi.lua` (fin du fichier)
- Modify: `tests/harness.lua:5-21` (liste `Harness.Files`) et `Harness.Load`
- Create: `tests/extract_ratings.py`
- Create (généré) : `PawnRatingLevelFactors.lua`
- Modify: `Pawn.toc` (ligne avant `ClassicHawsJon.lua`)
- Modify: `tests/unit.lua` (avant `return Tests`)
- Modify: `docs/superpowers/specs/2026-10-02-rating-weights-by-level-design.md` (écarts 1 à 3)

**Interfaces:**
- Produces: la globale `PawnRatingPointsPerPercent[Stat][Level]`, avec `Stat` parmi les 10 stats Pawn et `Level` de 1 à 80. Chaque valeur est un nombre de points de score pour 1 % (ou pour 1 point de défense ou d'expertise), arrondi à 4 décimales.
- Produces (tests) : les stubs `WowApiPlayerLevel`, `UnitLevel`, `UnitClass`, `GetClassInfo`, `RAID_CLASS_COLORS`, `sort` et `wipe` dans `tests/wowapi.lua`, et `PawnUIFrame_ScaleSelector_Refresh` dans le harnais.

- [ ] **Step 1 : ajouter les stubs et charger `ClassicHawsJon.lua` dans le harnais**

À la fin de `tests/wowapi.lua` :

```lua
-- Player and classes, as !!!ClassicAPI provides them on 3.3.5a (GetClassInfo returns a C_CreatureInfo-style table).
WowApiPlayerLevel = 80
function UnitLevel(Unit) return WowApiPlayerLevel end
function UnitClass(Unit) return "Prêtre", "PRIEST", 5 end
local ClassFiles = { "WARRIOR", "PALADIN", "HUNTER", "ROGUE", "PRIEST", "DEATHKNIGHT", "SHAMAN", "MAGE", "WARLOCK", nil, "DRUID" }
function GetClassInfo(ID) return { className = ClassFiles[ID], classFile = ClassFiles[ID], classID = ID } end
RAID_CLASS_COLORS = setmetatable({}, { __index = function() return { colorStr = "ffffffff" } end })

sort = table.sort
function wipe(T) for Key in pairs(T) do T[Key] = nil end return T end
```

Dans `tests/harness.lua`, remplacer le commentaire et la fin de la liste :

```lua
-- Same order as Pawn.toc; UI files and the Ask Mr. Robot provider are left out.
Harness.Files = {
	...
	"Pawn.lua",
	"ClassicHawsJon.lua",
	"PawnScan.lua",
}
```

Dans `Harness.Load`, après la ligne `WowApiSetTooltip(PawnPrivateTooltipName, {})` :

```lua
	function PawnUIFrame_ScaleSelector_Refresh() end -- PawnUI.lua isn't loaded
	PawnPlayerFullName = "Mairy-Test" -- normally set by PawnInitialize
```

- [ ] **Step 2 : vérifier que rien ne change**

Run: `luajit tests/run.lua`
Expected: `2285 réussis, 0 échecs, 0 à classer (todo)`. `ClassicHawsJon.lua` ne fait qu'enregistrer son fournisseur au chargement, sans créer d'échelle.

- [ ] **Step 3 : écrire les tests de la table**

Dans `tests/unit.lua`, juste avant `return Tests` :

```lua
------------------------------------------------------------
-- Rating weights by level (spec 2026-10-02). Keep these tests last: they fill PawnCommon.Scales.
------------------------------------------------------------

local RatingStats = { "HitRating", "CritRating", "HasteRating", "ExpertiseRating", "ArmorPenetration",
	"DefenseRating", "DodgeRating", "ParryRating", "BlockRating", "ResilienceRating" }

Test("niveaux : table des scores conforme au DBC", function()
	local P = PawnRatingPointsPerPercent
	for _, Stat in ipairs(RatingStats) do Equal(#P[Stat], 80, "niveaux de " .. Stat) end
	Equal(P.CritRating[60], 14, "crit 60")
	Equal(P.CritRating[80], 45.906, "crit 80")
	Equal(P.HitRating[70], 15.7692, "toucher 70")
	Equal(P.HitRating[80], 32.79, "toucher 80")
	Equal(P.ExpertiseRating[60], 2.5, "expertise 60")
	Equal(P.ResilienceRating[60], 28.75, "résilience 60")
	Equal(P.ResilienceRating[80], 94.2712, "résilience 80")
	local Count = 0
	for _ in pairs(P) do Count = Count + 1 end
	Equal(Count, #RatingStats, "nombre de stats")
end)

Test("niveaux : la table générée cite sa source", function()
	local File = assert(io.open("PawnRatingLevelFactors.lua", "r"))
	local Content = File:read("*a")
	File:close()
	for _, Needle in ipairs({ "tests/extract_ratings.py", "gtCombatRatings.dbc", "patch-frFR.MPQ", "PaperDollFrame.lua", "md5 " }) do
		assert(Content:find(Needle, 1, true), "en-tête sans « " .. Needle .. " »")
	end
end)
```

- [ ] **Step 4 : vérifier que les tests échouent**

Run: `luajit tests/run.lua`
Expected: 2 échecs `UNIT  niveaux : …`, l'un sur l'indexation de `PawnRatingPointsPerPercent` (nil), l'autre sur l'ouverture de `PawnRatingLevelFactors.lua`. 2285 réussis.

- [ ] **Step 5 : écrire `tests/extract_ratings.py`**

```python
"""Extracts the combat rating table of the frFR 3.3.5a client into PawnRatingLevelFactors.lua.

Usage, from the addon root:
    uv run --with mpyq python tests/extract_ratings.py "../../../Data"

Running it again on the same client data writes the same file, byte for byte.
"""
import hashlib
import os
import re
import struct
import sys

import mpyq

# Highest priority first, as the client loads them. Patch-Z.MPQ (server patch) holds neither file read here,
# so its exact rank doesn't matter for this script.
ARCHIVES = [
    "frFR/patch-frFR-3.MPQ", "frFR/patch-frFR-2.MPQ", "frFR/patch-frFR.MPQ",
    "Patch-Z.MPQ", "patch-3.MPQ", "patch-2.MPQ", "patch.MPQ",
    "frFR/lichking-locale-frFR.MPQ", "frFR/expansion-locale-frFR.MPQ", "frFR/locale-frFR.MPQ",
    "lichking.MPQ", "expansion.MPQ", "common-2.MPQ", "common.MPQ",
]
DBC = "DBFilesClient\\gtCombatRatings.dbc"
PAPERDOLL = "Interface\\FrameXML\\PaperDollFrame.lua"
OUTPUT = "PawnRatingLevelFactors.lua"
LEVELS_IN_DBC = 100
MAX_LEVEL = 80

# Pawn stat -> client constants. The first one gives the values; Pawn merges the others into the same stat,
# so they must scale exactly the same way with level.
STATS = [
    ("HitRating", ["CR_HIT_MELEE", "CR_HIT_RANGED", "CR_HIT_SPELL"]),
    ("CritRating", ["CR_CRIT_MELEE", "CR_CRIT_RANGED", "CR_CRIT_SPELL"]),
    ("HasteRating", ["CR_HASTE_MELEE", "CR_HASTE_RANGED", "CR_HASTE_SPELL"]),
    ("ExpertiseRating", ["CR_EXPERTISE"]),
    ("ArmorPenetration", ["CR_ARMOR_PENETRATION"]),
    ("DefenseRating", ["CR_DEFENSE_SKILL"]),
    ("DodgeRating", ["CR_DODGE"]),
    ("ParryRating", ["CR_PARRY"]),
    ("BlockRating", ["CR_BLOCK"]),
    ("ResilienceRating", ["CR_CRIT_TAKEN_MELEE"]),
]


def read_file(data_dir, name):
    """Returns (archive, bytes) from the highest-priority archive that holds name."""
    for archive in ARCHIVES:
        path = os.path.join(data_dir, archive)
        if not os.path.exists(path):
            continue
        data = mpyq.MPQArchive(path, listfile=False).read_file(name)
        if data:
            return archive, data
    sys.exit("introuvable dans les MPQ : " + name)


def read_constants(text):
    return {name: int(value) for name, value in re.findall(r"^(CR_[A-Z_]+)\s*=\s*(\d+);", text, re.M)}


def read_dbc(data):
    magic, records, fields, record_size, _ = struct.unpack("<4s4i", data[:20])
    if magic != b"WDBC" or fields != 1 or record_size != 4 or records % LEVELS_IN_DBC != 0:
        sys.exit("format de gtCombatRatings.dbc inattendu : %r %d %d %d" % (magic, records, fields, record_size))
    return struct.unpack("<%df" % records, data[20:20 + records * 4])


def lua_number(value):
    text = "%.4f" % round(value, 4)
    return text.rstrip("0").rstrip(".")


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    data_dir = sys.argv[1]
    dbc_archive, dbc = read_file(data_dir, DBC)
    lua_archive, lua = read_file(data_dir, PAPERDOLL)
    constants = read_constants(lua.decode("utf-8", "replace"))
    values = read_dbc(dbc)

    def points(constant, level):
        if constant not in constants:
            sys.exit("constante absente de PaperDollFrame.lua : " + constant)
        return values[(constants[constant] - 1) * LEVELS_IN_DBC + (level - 1)]

    for stat, names in STATS:
        for level in range(1, MAX_LEVEL + 1):
            reference = points(names[0], MAX_LEVEL) / points(names[0], level)
            for name in names[1:]:
                ratio = points(name, MAX_LEVEL) / points(name, level)
                if abs(ratio - reference) > 1e-4 * reference:
                    sys.exit("%s : %s et %s n'évoluent pas pareil au niveau %d (%.6f / %.6f), décision à prendre"
                             % (stat, names[0], name, level, reference, ratio))

    out = [
        "-- Generated by tests/extract_ratings.py: do not edit.",
        "-- Regenerate from the addon root: uv run --with mpyq python tests/extract_ratings.py \"../../../Data\"",
        "-- Values: %s from Data/%s (md5 %s)" % (DBC, dbc_archive, hashlib.md5(dbc).hexdigest()),
        "-- CR_* constants: %s from Data/%s (md5 %s)" % (PAPERDOLL, lua_archive, hashlib.md5(lua).hexdigest()),
        "-- PawnRatingPointsPerPercent[Stat][Level]: rating points for 1% (1 point of defense or expertise)",
        "-- at that level, rounded to 4 decimals. Melee, ranged and spell variants scale the same way (checked).",
        "",
        "PawnRatingPointsPerPercent =",
        "{",
    ]
    for stat, names in STATS:
        out.append("\t[\"%s\"] = { -- %s = %d" % (stat, names[0], constants[names[0]]))
        row = [lua_number(points(names[0], level)) for level in range(1, MAX_LEVEL + 1)]
        for start in range(0, MAX_LEVEL, 10):
            out.append("\t\t" + ", ".join(row[start:start + 10]) + ",")
        out.append("\t},")
    out.append("}")
    with open(OUTPUT, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(out) + "\n")
    print("%s écrit (valeurs : %s, constantes : %s)" % (OUTPUT, dbc_archive, lua_archive))


if __name__ == "__main__":
    main()
```

- [ ] **Step 6 : générer la table, deux fois**

Run: `uv run --with mpyq python tests/extract_ratings.py "../../../Data" && md5sum PawnRatingLevelFactors.lua && uv run --with mpyq python tests/extract_ratings.py "../../../Data" && md5sum PawnRatingLevelFactors.lua`
Expected: `PawnRatingLevelFactors.lua écrit (valeurs : frFR/patch-frFR.MPQ, constantes : frFR/patch-frFR-3.MPQ)`, deux fois, avec le même md5. Ouvrir le fichier et vérifier que la ligne 6 de `CritRating` (niveaux 51 à 60) se termine par `14,` et que la dernière ligne (71 à 80) se termine par `45.906,`.

- [ ] **Step 7 : charger la table dans le client et dans le harnais**

Dans `Pawn.toc`, entre `AskMrRobot.lua` et `ClassicHawsJon.lua` :

```
PawnRatingLevelFactors.lua
```

Dans `tests/harness.lua`, `Harness.Files`, juste avant `"ClassicHawsJon.lua"` :

```lua
	"PawnRatingLevelFactors.lua",
```

- [ ] **Step 8 : vérifier que les tests passent**

Run: `luajit tests/run.lua`
Expected: `2287 réussis, 0 échecs, 0 à classer (todo)`

- [ ] **Step 9 : corriger la spec (écarts 1 à 3)**

Dans la spec :
- section « Données » : remplacer « Il prime sur `locale-frFR.MPQ` (la seule différence entre les deux concerne la résilience) et il est absent de `Patch-Z.MPQ`. » par « Il prime sur `locale-frFR.MPQ` (la seule différence entre les deux concerne la résilience) et il est absent de `Patch-Z.MPQ`. `PaperDollFrame.lua` vient de `patch-frFR-3.MPQ`, le plus prioritaire des quatre MPQ qui le contiennent. » ;
- tableau du relevé : 15,769 → 15,7692, 94,271 → 94,2712, 45,337 → 45,3365, 8,197 → 8,1975 ;
- composant 1 : remplacer « Il lit `gtCombatRatings.dbc` en appliquant l'ordre de priorité des MPQ (`patch-frFR` avant `locale-frFR`). » par « Il lit `gtCombatRatings.dbc` en appliquant l'ordre de priorité complet des MPQ du client (`patch-frFR-3`, `-2`, `patch-frFR`, … `locale-frFR`, … `common`). » ;
- composant 1 : remplacer « dont l'en-tête indique la source (MPQ, fichier, date) » par « dont l'en-tête indique la source (MPQ et md5 de chaque fichier extrait ; pas de date, pour que la régénération soit identique) » ;
- tests, point 1 : « résilience 80 = 94,271 » → « résilience 80 = 94,2712 ».

- [ ] **Step 10 : commit**

```bash
git add tests/wowapi.lua tests/harness.lua tests/extract_ratings.py PawnRatingLevelFactors.lua Pawn.toc tests/unit.lua docs/superpowers/specs/2026-10-02-rating-weights-by-level-design.md
git commit -m "Extract the client's combat rating table by level into PawnRatingLevelFactors.lua

tests/extract_ratings.py reads gtCombatRatings.dbc and the CR_* constants from
the frFR client MPQs, checks that melee, ranged and spell variants scale the
same way, and writes the table with its sources and their md5.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2 : `PawnClassicApplyRatingLevel`, appel au chargement et `PLAYER_LEVEL_UP`

**Files:**
- Modify: `ClassicHawsJon.lua` : fin de la branche Wrath (juste avant `else` / `VgerCore.Fail("Failed to set up default Pawn scales…")`, ~ligne 650), nouveau bloc avant le bloc d'enregistrement final (~ligne 688)
- Modify: `tests/unit.lua` (après les tests de la tâche 1, avant `return Tests`)

**Interfaces:**
- Consumes: `PawnRatingPointsPerPercent[Stat][Level]` (tâche 1).
- Produces:
  - `PawnClassicApplyRatingLevel(Level)` : ne renvoie rien. `Level` est un nombre ou `nil`, ramené à un entier de `[1, 80]` (`nil` donne 80).
  - `PawnClassicRatingLevel` : niveau appliqué, `nil` tant qu'aucune échelle Classic n'a été ajustée.
  - La frame nommée `PawnClassicRatingLevelFrame`, qui écoute `PLAYER_LEVEL_UP`.

- [ ] **Step 1 : écrire les tests**

Dans `tests/unit.lua`, après les tests de la tâche 1 :

```lua
local function Near(Got, Expected, What)
	if type(Got) ~= "number" or math.abs(Got - Expected) > 1e-9 * math.max(1, math.abs(Expected)) then
		error((What or "valeur") .. " : attendu " .. tostring(Expected) .. ", obtenu " .. tostring(Got), 2)
	end
end

local ShadowPriest = '"Classic":PRIEST3'

-- Creates the Classic scales once, like a login at level 60.  Level80[ScaleName] keeps each scale's values as
-- PawnAddPluginScale stored them (HawsJon weights, zeros removed), before any level adjustment.
local Level80, LevelAtLogin
local function ClassicScales()
	if Level80 then return end
	Level80 = {}
	local Original = PawnAddPluginScale
	PawnAddPluginScale = function(Provider, ScaleName, ...)
		Original(Provider, ScaleName, ...)
		local FullName = PawnGetProviderScaleName(Provider, ScaleName)
		local Copy = {}
		for Stat, Value in pairs(PawnCommon.Scales[FullName].Values) do Copy[Stat] = Value end
		Level80[FullName] = Copy
	end
	PawnCommon.Scales = PawnCommon.Scales or {}
	WowApiPlayerLevel = 60
	PawnInitializePlugins()
	PawnAddPluginScale = Original
	LevelAtLogin = PawnClassicRatingLevel
end

local function CopyValues(ScaleName)
	local Copy = {}
	for Stat, Value in pairs(PawnCommon.Scales[ScaleName].Values) do Copy[Stat] = Value end
	return Copy
end

Test("niveaux : un appel avant la création des échelles ne bloque pas le chargement", function()
	Equal(Level80, nil, "échelles pas encore créées")
	PawnClassicApplyRatingLevel(60)
	Equal(PawnClassicRatingLevel, nil, "aucun niveau retenu sans échelle")
	ClassicScales()
	Equal(LevelAtLogin, 60, "niveau appliqué au chargement")
	Near(PawnCommon.Scales[ShadowPriest].Values.CritRating, Level80[ShadowPriest].CritRating * (45.906 / 14), "crit d'Ombre")
end)

Test("niveaux : niveau 60, seuls les scores changent et un score absent reste absent", function()
	ClassicScales()
	PawnClassicApplyRatingLevel(60)
	local Values, Original = PawnCommon.Scales[ShadowPriest].Values, Level80[ShadowPriest]
	Near(Values.CritRating, Original.CritRating * (45.906 / 14), "CritRating")
	Near(Values.HitRating, Original.HitRating * (32.79 / 10), "HitRating")
	for _, Stat in ipairs({ "Intellect", "SpellPower", "Stamina", "Spirit" }) do
		Equal(Values[Stat], Original[Stat], Stat)
	end
	Equal(Original.ExpertiseRating, nil, "expertise absente au niveau 80")
	Equal(Values.ExpertiseRating, nil, "expertise absente au niveau 60")
end)

Test("niveaux : niveau 80, toutes les échelles Classic sont identiques aux poids HawsJon", function()
	ClassicScales()
	PawnClassicApplyRatingLevel(80)
	Equal(PawnClassicRatingLevel, 80, "niveau")
	local Scales = 0
	for ScaleName, Original in pairs(Level80) do
		Scales = Scales + 1
		local Values = PawnCommon.Scales[ScaleName].Values
		for Stat, Value in pairs(Original) do Equal(Values[Stat], Value, ScaleName .. " " .. Stat) end
		for Stat in pairs(Values) do assert(Original[Stat] ~= nil, ScaleName .. " : stat ajoutée " .. Stat) end
	end
	assert(Scales > 20, "échelles Classic créées : " .. Scales)
	PawnClassicApplyRatingLevel(60)
end)

Test("niveaux : montée de niveau 60 → 61 par l'événement, sans cumul au retour à 60", function()
	ClassicScales()
	PawnClassicApplyRatingLevel(60)
	local At60 = CopyValues(ShadowPriest)
	local Frame = PawnClassicRatingLevelFrame
	Frame:GetScript("OnEvent")(Frame, "PLAYER_LEVEL_UP", 61)
	Equal(PawnClassicRatingLevel, 61, "niveau après l'événement")
	local P = PawnRatingPointsPerPercent.CritRating
	Near(PawnCommon.Scales[ShadowPriest].Values.CritRating, Level80[ShadowPriest].CritRating * (P[80] / P[61]), "crit 61")
	PawnCommon.Scales[ShadowPriest].Values.CritRating = 123
	PawnClassicApplyRatingLevel(61)
	Equal(PawnCommon.Scales[ShadowPriest].Values.CritRating, 123, "second appel au même niveau sans effet")
	PawnClassicApplyRatingLevel(60)
	for Stat, Value in pairs(At60) do Equal(PawnCommon.Scales[ShadowPriest].Values[Stat], Value, "retour à 60 : " .. Stat) end
end)

Test("niveaux : niveaux 15, 0, 85 et nil", function()
	ClassicScales()
	local P = PawnRatingPointsPerPercent.CritRating
	local Crit = Level80[ShadowPriest].CritRating
	PawnClassicApplyRatingLevel(15)
	Equal(PawnClassicRatingLevel, 15, "niveau 15")
	Near(PawnCommon.Scales[ShadowPriest].Values.CritRating, Crit * (P[80] / P[15]), "crit 15")
	PawnClassicApplyRatingLevel(0)
	Equal(PawnClassicRatingLevel, 1, "0 ramené à 1")
	Near(PawnCommon.Scales[ShadowPriest].Values.CritRating, Crit * (P[80] / P[1]), "crit 1")
	PawnClassicApplyRatingLevel(85)
	Equal(PawnClassicRatingLevel, 80, "85 ramené à 80")
	PawnClassicApplyRatingLevel(60)
	PawnClassicApplyRatingLevel(nil)
	Equal(PawnClassicRatingLevel, 80, "nil ramené à 80")
	PawnClassicApplyRatingLevel(60)
end)

Test("niveaux : une échelle perso ou importée n'est jamais modifiée", function()
	ClassicScales()
	PawnCommon.Scales["Ma copie"] = { Values = { CritRating = 0.61, HitRating = 1.12, Intellect = 0.19 } }
	PawnCommon.Scales["Importée"] = { Values = { CritRating = 10.35, HasteRating = 10.96 } }
	for _, Level in ipairs({ 80, 60, 15, 61 }) do
		PawnClassicApplyRatingLevel(Level)
		Equal(PawnCommon.Scales["Ma copie"].Values.CritRating, 0.61, "copie au niveau " .. Level)
		Equal(PawnCommon.Scales["Ma copie"].Values.HitRating, 1.12, "copie toucher au niveau " .. Level)
		Equal(PawnCommon.Scales["Importée"].Values.CritRating, 10.35, "importée au niveau " .. Level)
	end
	PawnCommon.Scales["Ma copie"], PawnCommon.Scales["Importée"] = nil, nil
	PawnClassicApplyRatingLevel(60)
end)
```

- [ ] **Step 2 : vérifier que les tests échouent**

Run: `luajit tests/run.lua`
Expected: 6 échecs `UNIT  niveaux : …`, avec `attempt to call global 'PawnClassicApplyRatingLevel' (a nil value)` ou une erreur sur `PawnClassicRatingLevelFrame`. 2287 réussis.

- [ ] **Step 3 : écrire la fonction et la frame**

Dans `ClassicHawsJon.lua`, juste avant le bloc final `if VgerCore.IsClassic or VgerCore.IsBurningCrusade or VgerCore.IsWrath then` (et après la ligne `------------------------------------------------------------` qui le précède) :

```lua
-- Fork frFR 3.3.5a: the Wrath weights above are for level 80, but a rating point gives more % at lower levels
-- (gtCombatRatings.dbc, see PawnRatingLevelFactors.lua).  Scale the rating weights of the Classic scales to the
-- character's level so that items with ratings are ranked correctly while leveling.

-- Level-80 weights of the rating stats, per scale name, saved the first time each scale is adjusted.  Not saved to disk.
local OriginalRatingWeights = {}

-- Level applied to the Classic scales; nil until at least one Classic scale has been adjusted.  Not saved to disk.
PawnClassicRatingLevel = nil

function PawnClassicApplyRatingLevel(Level)
	Level = max(1, min(80, floor(tonumber(Level) or 80)))
	if Level == PawnClassicRatingLevel or not PawnCommon or not PawnCommon.Scales then return end

	local Adjusted = {}
	for ScaleName, Scale in pairs(PawnCommon.Scales) do
		if Scale.Provider == ScaleProviderName and Scale.Values then
			local Originals = OriginalRatingWeights[ScaleName]
			if not Originals then
				Originals = {}
				for Stat in pairs(PawnRatingPointsPerPercent) do Originals[Stat] = Scale.Values[Stat] end
				OriginalRatingWeights[ScaleName] = Originals
			end
			for Stat, Points in pairs(PawnRatingPointsPerPercent) do
				-- Parentheses keep the factor at exactly 1 on level 80.
				if Originals[Stat] then Scale.Values[Stat] = Originals[Stat] * (Points[80] / Points[Level]) end
			end
			tinsert(Adjusted, ScaleName)
		end
	end
	-- Only remember the level once something was adjusted, so that a call made before the scales exist doesn't block the next one.
	if #Adjusted == 0 then return end
	PawnClassicRatingLevel = Level

	for _, ScaleName in pairs(Adjusted) do PawnRecalculateScaleTotal(ScaleName) end
	PawnResetTooltips()
end

if VgerCore.IsWrath then
	-- UnitLevel can still return the old level during PLAYER_LEVEL_UP, so use the level the event passes.
	local LevelFrame = CreateFrame("Frame", "PawnClassicRatingLevelFrame")
	LevelFrame:RegisterEvent("PLAYER_LEVEL_UP")
	LevelFrame:SetScript("OnEvent", function(self, Event, Level) PawnClassicApplyRatingLevel(Level) end)
end

------------------------------------------------------------

```

À la fin de la branche Wrath de `PawnClassicScaleProvider_AddScales`, juste après le dernier `PawnAddPluginScaleFromTemplate(…)` (Guerrier Protection) et avant `	else` / `		VgerCore.Fail("Failed to set up default Pawn scales…`, ajouter :

```lua

		-- Fork frFR 3.3.5a: these weights are for level 80; scale the rating weights to the character's level.
		PawnClassicApplyRatingLevel(UnitLevel("player"))
```

- [ ] **Step 4 : vérifier que les tests passent**

Run: `luajit tests/run.lua`
Expected: `2293 réussis, 0 échecs, 0 à classer (todo)`

- [ ] **Step 5 : commit**

```bash
git add ClassicHawsJon.lua tests/unit.lua
git commit -m "Scale Classic rating weights to the character's level

PawnClassicApplyRatingLevel multiplies the level-80 rating weights of the
Classic scales by points-per-percent(80) / points-per-percent(level), from the
client's gtCombatRatings table. It runs when the scales are created and on
PLAYER_LEVEL_UP; user, copied and imported scales are never touched.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3 : mention du niveau dans l'interface

**Files:**
- Modify: `ClassicHawsJon.lua` (juste après `PawnClassicApplyRatingLevel`)
- Modify: `Localization.lua` (table `UI`, entre `"ScaleTypeNormal"` et `"ScaleTypeReadOnly"`, et entre `"ValuesNormalizeTooltip"` et `"ValuesRemove"`)
- Modify: `Localization.frFR.lua` (mêmes emplacements, lignes ~669 et ~684)
- Modify: `PawnUI.lua:368-369` (onglet Échelle) et `PawnUI.lua:401-402` (onglet Valeurs)
- Modify: `PawnUI.xml:563-566` (`PawnUIFrame_ScaleTypeLabel`)
- Modify: `tests/unit.lua` (après les tests de la tâche 2)

**Interfaces:**
- Consumes: `PawnClassicRatingLevel` (tâche 2), `ShadowPriest` et `ClassicScales()` dans `tests/unit.lua` (tâche 2).
- Produces: `PawnClassicRatingLevelNote(ScaleName, Long)`. Elle renvoie une chaîne ou `nil`. `Long` (booléen) choisit le texte de l'onglet Valeurs. Clés de localisation : `PawnLocal.UI.ScaleTypeRatingLevel` et `PawnLocal.UI.ValuesRatingLevel`, chacune avec un `%d`.

- [ ] **Step 1 : écrire le test**

```lua
Test("niveaux : mention du niveau pour l'interface", function()
	ClassicScales()
	PawnClassicApplyRatingLevel(60)
	local Long, Short = PawnClassicRatingLevelNote(ShadowPriest, true), PawnClassicRatingLevelNote(ShadowPriest)
	Equal(Long, "Poids des scores ajustés pour le niveau 60 (valeurs d'origine prévues pour le niveau 80).", "onglet Valeurs")
	Equal(Short, "Poids des scores ajustés pour le niveau 60.", "onglet Échelle")
	PawnCommon.Scales["Ma copie"] = { Values = { CritRating = 1 } }
	Equal(PawnClassicRatingLevelNote("Ma copie", true), nil, "échelle perso")
	PawnCommon.Scales["Ma copie"] = nil
	Equal(PawnClassicRatingLevelNote("Échelle inconnue", true), nil, "échelle inconnue")
	PawnClassicApplyRatingLevel(80)
	Equal(PawnClassicRatingLevelNote(ShadowPriest, true), nil, "niveau 80")
	PawnClassicApplyRatingLevel(60)
end)
```

- [ ] **Step 2 : vérifier qu'il échoue**

Run: `luajit tests/run.lua`
Expected: 1 échec, `attempt to call global 'PawnClassicRatingLevelNote' (a nil value)`. 2293 réussis.

- [ ] **Step 3 : ajouter les textes et la fonction**

`Localization.lua`, table `UI` :

```lua
		["ScaleTypeRatingLevel"] = "Rating weights adjusted for level %d.",
```
(entre `"ScaleTypeNormal"` et `"ScaleTypeReadOnly"`)

```lua
		["ValuesRatingLevel"] = "Rating weights adjusted for level %d (original values are for level 80).",
```
(entre `"ValuesNormalizeTooltip"` et `"ValuesRemove"`)

`Localization.frFR.lua`, mêmes emplacements :

```lua
		["ScaleTypeRatingLevel"] = "Poids des scores ajustés pour le niveau %d.",
```

```lua
		["ValuesRatingLevel"] = "Poids des scores ajustés pour le niveau %d (valeurs d'origine prévues pour le niveau 80).",
```

`ClassicHawsJon.lua`, juste après la fin de `PawnClassicApplyRatingLevel` :

```lua
-- Text that tells the user a Classic scale's rating weights were adjusted, or nil if they weren't.
-- Long: the Values tab version; otherwise the Scale tab version.
function PawnClassicRatingLevelNote(ScaleName, Long)
	local Scale = PawnCommon and PawnCommon.Scales and PawnCommon.Scales[ScaleName]
	if not Scale or Scale.Provider ~= ScaleProviderName or not PawnClassicRatingLevel or PawnClassicRatingLevel >= 80 then return nil end
	local Text = Long and PawnLocal.UI.ValuesRatingLevel or PawnLocal.UI.ScaleTypeRatingLevel
	if not Text then return nil end -- other localizations don't have this text
	return format(Text, PawnClassicRatingLevel)
end
```

- [ ] **Step 4 : vérifier que le test passe**

Run: `luajit tests/run.lua`
Expected: `2294 réussis, 0 échecs, 0 à classer (todo)`

- [ ] **Step 5 : afficher la mention dans `PawnUI.lua`**

Onglet Échelle (`PawnUI_ScalesTab_Refresh`), remplacer :

```lua
			PawnUIFrame_ScaleTypeLabel:SetText(PawnUIFrame_ScaleTypeLabel_ReadOnlyScaleText)
```
par :
```lua
			-- Fork frFR 3.3.5a: say when a Classic scale's rating weights were adjusted to the character's level.
			local LevelNote = PawnClassicRatingLevelNote(PawnUICurrentScale)
			PawnUIFrame_ScaleTypeLabel:SetText(LevelNote and (LevelNote .. " " .. PawnUIFrame_ScaleTypeLabel_ReadOnlyScaleText) or PawnUIFrame_ScaleTypeLabel_ReadOnlyScaleText)
```

Onglet Valeurs (`PawnUI_ValuesTab_Refresh`), remplacer :

```lua
		PawnUIFrame_ValuesWelcomeLabel:SetText(PawnUIFrame_ValuesWelcomeLabel_ReadOnlyScaleText)
```
par :
```lua
		-- Fork frFR 3.3.5a: say when a Classic scale's rating weights were adjusted to the character's level.
		local LevelNote = PawnClassicRatingLevelNote(PawnUICurrentScale, true)
		PawnUIFrame_ValuesWelcomeLabel:SetText(LevelNote and (PawnUIFrame_ValuesWelcomeLabel_ReadOnlyScaleText .. " " .. LevelNote) or PawnUIFrame_ValuesWelcomeLabel_ReadOnlyScaleText)
```

Dans `PawnUI.xml`, `PawnUIFrame_ScaleTypeLabel` : la hauteur passe de 20 à 40 et l'alignement vertical en haut, pour que le texte allongé puisse tenir sur deux lignes. L'élément suivant (« Partagez vos échelles ») est à y = -190, la place suffit.

```xml
								<FontString name="PawnUIFrame_ScaleTypeLabel" inherits="GameFontNormal" justifyH="LEFT" justifyV="TOP"><!-- You can change this scale from the Values tab. -->
									<Anchors><Anchor point="TOPLEFT"><Offset><AbsDimension x="65" y="-130"/></Offset></Anchor></Anchors>
									<Size><AbsDimension x="500" y="40" /></Size>
								</FontString>
```

- [ ] **Step 6 : relancer les tests (`PawnUI.lua` n'est pas chargé par le harnais, rien ne doit changer)**

Run: `luajit tests/run.lua && luajit -bl PawnUI.lua > /dev/null && echo syntaxe-ok`
Expected: `2294 réussis, 0 échecs, 0 à classer (todo)` puis `syntaxe-ok`

- [ ] **Step 7 : commit**

```bash
git add ClassicHawsJon.lua Localization.lua Localization.frFR.lua PawnUI.lua PawnUI.xml tests/unit.lua
git commit -m "Show the level used for Classic rating weights on the Scale and Weights tabs

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4 : `CLAUDE.md` et vérifications en jeu

**Files:**
- Modify: `CLAUDE.md`

- [ ] **Step 1 : relever le nombre de tests**

Run: `luajit tests/run.lua | tail -1`
Expected: `2294 réussis, 0 échecs, 0 à classer (todo)` (reporter le nombre réel)

- [ ] **Step 2 : mettre à jour `CLAUDE.md`**

- Section Commands : remplacer « Currently 2285 passing » par le nombre relevé. Ajouter la ligne :
  `- \`uv run --with mpyq python tests/extract_ratings.py "../../../Data"\` — regenerate \`PawnRatingLevelFactors.lua\` (gtCombatRatings.dbc + CR_* constants from the frFR MPQs); same data gives the same file.`
- Section Architecture : ajouter la puce :
  `- \`PawnRatingLevelFactors.lua\` (generated) holds the client's rating points per % for levels 1–80. \`ClassicHawsJon.lua\`'s \`PawnClassicApplyRatingLevel\` scales the 10 rating weights of the Classic scales by \`P[80] / P[level]\` at load and on \`PLAYER_LEVEL_UP\` (frame \`PawnClassicRatingLevelFrame\`); user and imported scales are never touched. \`PawnClassicRatingLevelNote\` gives the UI text.`
- Section Architecture, puce `tests/harness.lua` : mentionner qu'il charge aussi `PawnRatingLevelFactors.lua` et `ClassicHawsJon.lua`, et que les tests « niveaux » doivent rester les derniers de `unit.lua`, parce qu'ils remplissent `PawnCommon.Scales`.

- [ ] **Step 3 : commit**

```bash
git add CLAUDE.md
git commit -m "CLAUDE.md: rating weights by level, extraction command, test count

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

- [ ] **Step 4 : vérifications en jeu (par l'utilisateur, après un redémarrage complet du client)**

Avec Mairy, prêtre niveau 60 :
1. `/run for i=1,25 do local r,b=GetCombatRating(i),GetCombatRatingBonus(i) if r>0 then print(i, r, b, b>0 and r/b) end end` : pour chaque score porté, le rapport points/% correspond à la table au niveau 60 (`GetCombatRatingBonus` ne prend que l'indice du score sur 3.3.5a).
2. `/run print(PawnClassicRatingLevel)` affiche `60`.
3. Onglet Valeurs (« Poids » en français) de « Prêtre : Ombre » : la mention du niveau 60 apparaît, et le poids de crit vaut 0,61 × 45,906 / 14 ≈ 2. **Si le texte déborde sur la liste des stats**, solution de repli : n'afficher que la mention, sans le texte lecture seule (`SetText(LevelNote or PawnUIFrame_ValuesWelcomeLabel_ReadOnlyScaleText)`).
4. Onglet Échelle : la mention du niveau s'affiche seule (décision de la revue finale) et tient sur une ligne.
5. `/pawnscan inspect <objet avec score de crit>` puis `/reload` : la valeur de l'objet a augmenté par rapport au relevé d'avant.
6. Optionnel : comparer le md5 de `gtCombatRatings.dbc` du serveur AzerothCore avec celui cité dans l'en-tête de `PawnRatingLevelFactors.lua`.
