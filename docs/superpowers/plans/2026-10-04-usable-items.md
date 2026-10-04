# Armes et objets utilisables — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Un objet réservé à d'autres classes vaut 0 pour une échelle, et les armes de main gauche comptent pour les voleurs.

**Architecture:** La ligne « Classes : … » passe par une nouvelle source de ligne, `PawnClassesAllowed`. `PawnAddClassRestriction` y reconnaît les noms de classe du client et ajoute `UnusableBy<JETON>` pour chaque classe absente de la liste. `PawnGetStatWeight` donne le poids « inutilisable » à la stat de la classe de l'échelle, puis le contrôle existant met la valeur à 0. Les échelles de voleur Wrath perdent leur blocage de la main gauche, et `RatingWeightsVersion` passe à 3.

**Tech Stack:** Lua 5.1 (WoW 3.3.5a), LuaJIT pour les tests, Python 3 + `mpyq` (via `uv`) pour l'extraction.

**Spec:** `docs/superpowers/specs/2026-10-04-usable-items-design.md`

## Global Constraints

- Les tests tournent avec `luajit tests/run.lua` depuis la racine de l'addon. Les tests qui créent les échelles Classic restent à la fin de `tests/unit.lua`.
- Toute donnée française vient du client (`tests/data/`, GlobalStrings) et cite sa source. Ne jamais retaper de texte du client dans un fichier de corpus : les attentes sont réécrites par script, le texte ne change pas.
- Les modifications de fichiers d'origine (`Core.lua`, `Pawn.lua`, `ClassicHawsJon.lua`) sont minimales et commentées « Fork frFR 3.3.5a ».
- Motifs Lua : ils travaillent octet par octet, donc jamais de lettre accentuée dans `[...]`.
- Commits en anglais, terminés par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`. Ne jamais pousser.
- Les échelles de voleur BC (`ClassicHawsJon.lua:203-223`) ne changent pas.

## Review Focus

1. Un nom de classe féminin qui contient le masculin (« Prêtresse » ⊃ « Prêtre ») : le plus long doit être retiré d'abord. Couvert par « un nom féminin vaut le masculin » (Task 1).
2. Une ligne « Classes : » dont un nom est inconnu : aucune restriction, ligne toujours comprise, pas d'objet caché à tort. Couvert par « un nom inconnu ne restreint rien » (Task 1).
3. Un client sans `LOCALIZED_CLASS_NAMES_MALE` : la ligne reste comprise et rien ne plante. Couvert par « sans les tables du client » (Task 1).
4. Une échelle personnelle sans `ClassID` : elle suit la classe du personnage. Couvert par « une échelle perso suit la classe du personnage » (Task 2).
5. `PawnGetStatWeight` est appelée pour chaque stat de chaque objet. Le point d'accroche ne doit rien changer aux autres stats, ni aux scores réservés. Couvert par la suite complète (2313 tests existants), Task 2.

---

### Task 1: Lecture de la ligne « Classes : … »

**Files:**
- Create: `tests/extract_classes.py`
- Create: `tests/data/classes.frFR.txt` (généré)
- Modify: `tests/harness.lua` (`Harness.Load`)
- Modify: `Core.lua:22` (nouvelle constante de source)
- Modify: `TooltipParsing.frFR.lua:171` (ligne `ITEM_CLASSES_ALLOWED`)
- Modify: `Pawn.lua` (`PawnAddClassRestriction` avant `PawnGetStatWeight`, branche dans `PawnLookForSingleStat`)
- Modify: `tests/unit.lua` (nouvelle section avant la section « Gems »)
- Modify: `tests/corpus/scan.txt` (9 attentes, par script)
- Modify: `CLAUDE.md`

**Interfaces:**
- Produces: `PawnClassesAllowed` (constante de source, `Core.lua`) ; `PawnAddClassRestriction(Stats, List, DebugMessages)` (`Pawn.lua`), qui ajoute `UnusableBy<JETON> = 1`. Dans `tests/unit.lua`, au niveau du fichier : `Classes[Token] = { ID, Male, Female }`, lu depuis `tests/data/classes.frFR.txt`. La Task 2 s'en sert.

- [ ] **Step 1: Écrire le script d'extraction**

`tests/extract_classes.py` :

```python
"""Extracts the classes of the frFR 3.3.5a client into tests/data/classes.frFR.txt (ChrClasses.dbc): ID, token, male and
female names.  The client fills LOCALIZED_CLASS_NAMES_MALE / _FEMALE with these names (FrameXML Constants.lua).

Usage, from the addon root:
    uv run --with mpyq python tests/extract_classes.py "../../../Data"

Running it again on the same client data writes the same file, byte for byte.
"""
import hashlib
import struct
import sys

sys.dont_write_bytecode = True  # importing extract_ratings would otherwise leave tests/__pycache__ behind
from extract_ratings import read_file

DBC = "DBFilesClient\\ChrClasses.dbc"
OUTPUT = "tests/data/classes.frFR.txt"
# ChrClasses.dbc fields (32-bit, from 0): 0 ID, 23 frFR female name, 40 frFR male name, 55 token.
FIELDS = 60


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    archive, data = read_file(sys.argv[1], DBC)
    magic, records, fields, record_size, _ = struct.unpack("<4s4i", data[:20])
    if magic != b"WDBC" or fields != FIELDS or record_size != FIELDS * 4:
        sys.exit("format de ChrClasses.dbc inattendu : %r %d %d" % (magic, fields, record_size))
    strings = data[20 + records * record_size:]

    def text(offset):
        return strings[offset:strings.index(b"\0", offset)].decode("utf-8")

    out = [
        "# Generated by tests/extract_classes.py: do not edit.",
        "# Source: %s from Data/%s (md5 %s)" % (DBC, archive, hashlib.md5(data).hexdigest()),
        "# Fields (32-bit, from 0): 0 ID, 23 female name, 40 male name, 55 token. An empty female name is empty in the DBC.",
        "# One line per class: ID<TAB>token<TAB>male name<TAB>female name",
    ]
    for index in range(records):
        start = 20 + index * record_size
        row = struct.unpack("<%di" % FIELDS, data[start:start + record_size])
        out.append("%d\t%s\t%s\t%s" % (row[0], text(row[55]), text(row[40]), text(row[23])))
    with open(OUTPUT, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(out) + "\n")
    print("%s écrit (%d classes, %s)" % (OUTPUT, len(out) - 4, archive))


if __name__ == "__main__":
    main()
```

- [ ] **Step 2: Lancer l'extraction, deux fois**

Run: `uv run --with mpyq python tests/extract_classes.py "../../../Data" && md5sum tests/data/classes.frFR.txt && uv run --with mpyq python tests/extract_classes.py "../../../Data" && md5sum tests/data/classes.frFR.txt && cat tests/data/classes.frFR.txt && ls tests/__pycache__ 2>&1 | head -1`
Expected :
- les deux md5 sont identiques ;
- il y a 10 classes (IDs 1 à 9 et 11), avec les jetons `WARRIOR`, `PALADIN`, `HUNTER`, `ROGUE`, `PRIEST`, `DEATHKNIGHT`, `SHAMAN`, `MAGE`, `WARLOCK`, `DRUID` ;
- la ligne 5 est `5	PRIEST	Prêtre	Prêtresse` ;
- `tests/__pycache__` n'existe pas.

- [ ] **Step 3: Remplir les tables du client dans le harnais**

Dans `tests/harness.lua`, `Harness.Load`, juste après `LoadGlobalStrings("tests/data/GlobalStrings.frFR.lua")` :

```lua
	-- FrameXML's Constants.lua fills these with FillLocalizedClassList; the names come from ChrClasses.dbc.  An empty female
	-- name in the DBC (paladin, death knight) takes the male name here.
	LOCALIZED_CLASS_NAMES_MALE, LOCALIZED_CLASS_NAMES_FEMALE = {}, {}
	for Line in io.lines("tests/data/classes.frFR.txt") do
		local Token, Male, Female = Line:match("^%d+\t(%u+)\t([^\t]+)\t([^\t]*)$")
		if Token then
			LOCALIZED_CLASS_NAMES_MALE[Token] = Male
			LOCALIZED_CLASS_NAMES_FEMALE[Token] = Female ~= "" and Female or Male
		end
	end
```

- [ ] **Step 4: Écrire les tests de lecture (échouent en partie)**

Dans `tests/unit.lua`, juste avant les trois lignes :

```lua
------------------------------------------------------------
-- Gems (spec 2026-10-04).
------------------------------------------------------------
```

insérer :

```lua
------------------------------------------------------------
-- Class restriction (spec 2026-10-04, usable items).
------------------------------------------------------------

-- Classes of the client (tests/data/classes.frFR.txt, from ChrClasses.dbc): Classes[Token] = { ID, Male, Female }.
local Classes = {}
for Line in io.lines("tests/data/classes.frFR.txt") do
	local ID, Token, Male, Female = Line:match("^(%d+)\t(%u+)\t([^\t]+)\t([^\t]*)$")
	if ID then Classes[Token] = { ID = tonumber(ID), Male = Male, Female = Female } end
end

-- The UnusableBy* tokens read from a line, sorted and joined, and whether the line was understood.
local function Restrictions(Line)
	local Raw, Understood = Harness.ParseLine(Line)
	local Tokens = {}
	for Stat, Value in pairs(Raw) do
		local Token = Stat:match("^UnusableBy(%u+)$")
		assert(Token and Value == 1, "stat inattendue " .. Stat)
		table.insert(Tokens, Token)
	end
	table.sort(Tokens)
	return table.concat(Tokens, ","), Understood
end

-- Every class token except the given ones, sorted and joined.
local function AllBut(...)
	local Skip, Tokens = {}, {}
	for _, Token in ipairs({ ... }) do Skip[Token] = true end
	for Token in pairs(Classes) do if not Skip[Token] then table.insert(Tokens, Token) end end
	table.sort(Tokens)
	return table.concat(Tokens, ",")
end

Test("classes : une ligne à une classe rend l'objet inutilisable par les neuf autres", function()
	local Got, Understood = Restrictions(format(ITEM_CLASSES_ALLOWED, Classes.DRUID.Male))
	Equal(Understood, true, "ligne comprise")
	Equal(Got, AllBut("DRUID"), "restrictions")
	Equal(select(2, Got:gsub(",", "")) + 1, 9, "neuf classes")
end)

Test("classes : une liste de deux classes, avec ou sans espace après la virgule", function()
	local Expected = AllBut("HUNTER", "SHAMAN")
	Equal((Restrictions(format(ITEM_CLASSES_ALLOWED, Classes.HUNTER.Male .. ", " .. Classes.SHAMAN.Male))), Expected, "virgule et espace")
	Equal((Restrictions(format(ITEM_CLASSES_ALLOWED, Classes.HUNTER.Male .. "," .. Classes.SHAMAN.Male))), Expected, "virgule seule")
end)

Test("classes : un nom féminin vaut le masculin, même quand il le contient", function()
	assert(Classes.PRIEST.Female:find(Classes.PRIEST.Male, 1, true), "le nom féminin contient le masculin")
	Equal((Restrictions(format(ITEM_CLASSES_ALLOWED, Classes.PRIEST.Female))), AllBut("PRIEST"), "nom féminin")
	Equal((Restrictions(format(ITEM_CLASSES_ALLOWED, Classes.PRIEST.Female .. ", " .. Classes.MAGE.Male))), AllBut("PRIEST", "MAGE"), "féminin dans une liste")
end)

Test("classes : un nom inconnu ne restreint rien et la ligne reste comprise", function()
	local Got, Understood = Restrictions(format(ITEM_CLASSES_ALLOWED, Classes.MAGE.Male .. ", Inconnu"))
	Equal(Understood, true, "ligne comprise")
	Equal(Got, "", "aucune restriction")
end)

Test("classes : sans les tables du client, la ligne reste comprise sans restriction", function()
	local Male = LOCALIZED_CLASS_NAMES_MALE
	LOCALIZED_CLASS_NAMES_MALE = nil
	local Ok, Got, Understood = pcall(Restrictions, format(ITEM_CLASSES_ALLOWED, Classes.DRUID.Male))
	LOCALIZED_CLASS_NAMES_MALE = Male
	assert(Ok, tostring(Got))
	Equal(Understood, true, "ligne comprise")
	Equal(Got, "", "aucune restriction")
end)

```

- [ ] **Step 5: Vérifier l'échec**

Run: `luajit tests/run.lua 2>&1 | grep "^UNIT" ; luajit tests/run.lua 2>&1 | tail -1`
Expected : 3 lignes `UNIT  classes : …` (« une ligne à une classe », « une liste de deux classes », « un nom féminin »). Elles échouent sur `restrictions` / `virgule et espace` / `nom féminin`, avec une chaîne vide obtenue. Les tests « nom inconnu » et « sans les tables » passent déjà : la ligne est ignorée aujourd'hui, ce sont des garde-fous. Total : 2315 réussis, 3 échecs.

- [ ] **Step 6: Ajouter la source `PawnClassesAllowed`**

`Core.lua`, après `PawnMultipleStatsExtract = "_MultipleExtract"` :

```lua
PawnClassesAllowed = "_ClassesAllowed" -- Fork frFR 3.3.5a: the capture is a class list, read by PawnAddClassRestriction (Pawn.lua)
```

`TooltipParsing.frFR.lua:171`, remplacer :

```lua
	{Fr("ITEM_CLASSES_ALLOWED")}, -- GlobalStrings
```

par :

```lua
	{"^" .. gsub(PawnFrFormatToPattern(ITEM_CLASSES_ALLOWED), "%.%-", "(.+)") .. "$", "UnusableBy", 1, PawnClassesAllowed}, -- GlobalStrings: ITEM_CLASSES_ALLOWED; the list is read by PawnAddClassRestriction (Pawn.lua)
```

- [ ] **Step 7: Ajouter `PawnAddClassRestriction` et la branche de `PawnLookForSingleStat`**

`Pawn.lua`, juste avant `function PawnGetStatWeight(ScaleName, ScaleValues, Stat)` :

```lua
-- Fork frFR 3.3.5a: reads the class list of an ITEM_CLASSES_ALLOWED line ("Classes : Druide") and adds UnusableBy<TOKEN> = 1
-- for every class it doesn't list; PawnGetStatWeight makes the item unusable for a scale of such a class.  The client gives
-- no list separator, so each class name it knows (LOCALIZED_CLASS_NAMES_MALE / _FEMALE, filled by FrameXML) is removed from
-- the list, longest first ("Prêtresse" before "Prêtre").  If anything but spaces and punctuation is left, a name is
-- unknown and no restriction is added: better a value too many than an item hidden by mistake.
function PawnAddClassRestriction(Stats, List, DebugMessages)
	if type(LOCALIZED_CLASS_NAMES_MALE) ~= "table" or type(LOCALIZED_CLASS_NAMES_FEMALE) ~= "table" then return end
	local Names = {}
	for _, Localized in ipairs({ LOCALIZED_CLASS_NAMES_MALE, LOCALIZED_CLASS_NAMES_FEMALE }) do
		for Token, Name in pairs(Localized) do tinsert(Names, { Name = Name, Token = Token }) end
	end
	sort(Names, function(A, B) return strlen(A.Name) > strlen(B.Name) end)
	local Allowed, Rest, Count = {}, " " .. List .. " "
	for _, Entry in ipairs(Names) do
		local Escaped = gsub(Entry.Name, "[%^%$%(%)%%%.%[%]%*%+%-%?]", "%%%0")
		-- A name only counts as a whole word: spaces or punctuation on both sides, kept for the next name.
		Rest, Count = gsub(Rest, "([%s%p])" .. Escaped .. "([%s%p])", "%1%2")
		if Count > 0 then Allowed[Entry.Token] = true end
	end
	if strfind(Rest, "[^%s%p]") or not next(Allowed) then
		if DebugMessages then PawnDebugMessage("Classes : liste non reconnue, aucune restriction : " .. List) end
		return
	end
	for Token in pairs(LOCALIZED_CLASS_NAMES_MALE) do
		if not Allowed[Token] then PawnAddStatToTable(Stats, "UnusableBy" .. Token, 1) end
	end
end

```

Dans `PawnLookForSingleStat`, remplacer :

```lua
			elseif Source == PawnMultipleStatsFixed then
```

par :

```lua
			elseif Source == PawnClassesAllowed then
				-- Fork frFR 3.3.5a: a class list ("Classes : Druide").
				PawnAddClassRestriction(Stats, Matches[1], DebugMessages)
			elseif Source == PawnMultipleStatsFixed then
```

- [ ] **Step 8: Vérifier les tests unitaires et l'échec attendu du corpus**

Run: `luajit tests/run.lua 2>&1 | grep -c "Classes : " ; luajit tests/run.lua 2>&1 | grep "^UNIT" ; luajit tests/run.lua 2>&1 | tail -1`
Expected : aucune ligne `UNIT`. 9 échecs de corpus, un par ligne « Classes : … » de `tests/corpus/scan.txt` : l'attente est `ignored` et Pawn lit maintenant les `UnusableBy*`. Total : 2309 réussis, 9 échecs.

- [ ] **Step 9: Réécrire les attentes du corpus par script**

Run :

```bash
luajit - <<'EOF'
package.path = "./tests/?.lua;" .. package.path
local Harness = require("harness"); local Corpus = require("corpus"); Harness.Load()
local Prefix = ITEM_CLASSES_ALLOWED:match("^(.-)%%s")
local Path, Out, Changed = "tests/corpus/scan.txt", {}, 0
for Line in io.lines(Path) do
	local Text = Line:match("^(.-) => ignored$")
	if Text and Text:sub(1, #Prefix) == Prefix then
		Line = Text .. " => " .. Corpus.FormatStats((Harness.ParseLine(Text)))
		Changed = Changed + 1
	end
	table.insert(Out, Line)
end
local File = io.open(Path, "w"); File:write(table.concat(Out, "\n") .. "\n"); File:close()
print(Changed .. " lignes réécrites")
EOF
git diff --stat tests/corpus/scan.txt; luajit tests/run.lua 2>&1 | tail -1
```

Expected : `9 lignes réécrites`, et `scan.txt` montre 9 lignes changées, avec seulement la partie après « => » modifiée. Total : 2318 réussis, 0 échec, 0 todo.

- [ ] **Step 10: Mettre à jour `CLAUDE.md`**

Dans « Commands », après la ligne `extract_gems.py` :

```markdown
- `uv run --with mpyq python tests/extract_classes.py "../../../Data"` — regenerate `tests/data/classes.frFR.txt` (ChrClasses.dbc: ID, token, male and female names). The test harness fills `LOCALIZED_CLASS_NAMES_MALE` / `_FEMALE` from it, as the client's FrameXML does.
```

Dans « Rules », dans la dernière puce, remplacer `` `ItemSubClass.dbc` name 12.`` par `` `ItemSubClass.dbc` name 12, `ChrClasses.dbc` 0 ID, 23 female name, 40 male name, 55 token.``

Remplacer `Currently 2313 passing` par `Currently 2318 passing`.

- [ ] **Step 11: Commit**

```bash
git add tests/extract_classes.py tests/data/classes.frFR.txt tests/harness.lua Core.lua TooltipParsing.frFR.lua Pawn.lua tests/unit.lua tests/corpus/scan.txt CLAUDE.md
git commit -m "$(cat <<'EOF'
frFR: read the class list of "Classes : ..." lines

Each class the line doesn't list gets an UnusableBy<TOKEN> stat. Class names
come from the client's LOCALIZED_CLASS_NAMES tables (ChrClasses.dbc).

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
)"
```

---

### Task 2: Valeur des objets réservés, main gauche des voleurs

**Files:**
- Modify: `Pawn.lua` (`PawnClassTokens`, `PawnGetScaleClassToken`, début de `PawnGetStatWeight`)
- Modify: `ClassicHawsJon.lua:521`, `:532`, `:543` (voleurs Wrath) ; `RatingWeightsVersion` (~ligne 711)
- Modify: `tests/unit.lua` (fin du fichier ; une assertion du test « gemmes : les meilleurs objets notés avant les châsses supposées »)
- Modify: `CLAUDE.md`

**Interfaces:**
- Consumes: `Classes` (Task 1, `tests/unit.lua`) ; `TooltipStats`, `SubclassName` (`tests/unit.lua`, tests d'infobulles) ; `ClassicScales()`, `ShadowPriest` (section niveaux) ; `UnusableBy<TOKEN>` (Task 1).
- Produces: `PawnClassTokens[ClassID] -> token` et `PawnGetScaleClassToken(ScaleName) -> token` (`Pawn.lua`).

- [ ] **Step 1: Écrire les tests (échouent)**

Dans le test existant « gemmes : les meilleurs objets notés avant les châsses supposées sont oubliés une fois », remplacer :

```lua
	Equal(Options.RatingWeightsVersion, 2, "version mémorisée")
```

par :

```lua
	assert(Options.RatingWeightsVersion > 1, "version mémorisée : " .. tostring(Options.RatingWeightsVersion))
```

À la fin de `tests/unit.lua`, juste avant `return Tests` :

```lua

------------------------------------------------------------
-- Usable items (spec 2026-10-04).  They need the Classic scales, so they stay last.
------------------------------------------------------------

local Feral, Fury = '"Classic":DRUID2', '"Classic":WARRIOR2'
local Rogues = { '"Classic":ROGUE1', '"Classic":ROGUE2', '"Classic":ROGUE3' }

-- Tooltips built from client constants, with the numbers of the items inspected in game on 2026-10-04.
local function Plus(Format, Number) return format(Format, 43, Number) end -- %c43 = "+"
local function DruidStaff() -- 51432, "Classes : Druide"
	return (TooltipStats({ "Bâton de test", { INVTYPE_2HWEAPON, SubclassName(2, 10) },
		{ format(DAMAGE_TEMPLATE, 521, 782), SPEED .. " 2.00" }, Plus(ITEM_MOD_AGILITY, 167), Plus(ITEM_MOD_STAMINA, 275),
		format(ITEM_CLASSES_ALLOWED, Classes.DRUID.Male) }))
end
local function OffHandDagger() -- 51528
	return (TooltipStats({ "Dague de test", { INVTYPE_WEAPONOFFHAND, SubclassName(2, 15) },
		{ format(DAMAGE_TEMPLATE, 315, 586), SPEED .. " 1.80" }, Plus(ITEM_MOD_STAMINA, 118) }))
end
local function UsableValue(Item, ScaleName) return (PawnGetItemValue(Item, 264, nil, ScaleName, false, true)) end

Test("objets utilisables : un objet réservé au druide vaut 0 pour les autres classes", function()
	ClassicScales()
	for Token, Class in pairs(Classes) do Equal(PawnClassTokens[Class.ID], Token, "jeton de la classe " .. Class.ID) end
	local Staff = DruidStaff()
	Equal(Staff.UnusableByPRIEST, 1, "restriction lue")
	Equal(UsableValue(Staff, ShadowPriest), 0, "Prêtre : Ombre")
	Equal(UsableValue(Staff, Fury), 0, "guerrier Fureur")
	assert(UsableValue(Staff, Feral) > 0, "druide farouche : " .. tostring(UsableValue(Staff, Feral)))
end)

Test("objets utilisables : une échelle perso suit la classe du personnage", function()
	ClassicScales()
	PawnCommon.Scales["Ma copie"] = { Values = { Agility = 1, Stamina = 1 } }
	local Staff = DruidStaff()
	local AsPriest = UsableValue(Staff, "Ma copie") -- tests/wowapi.lua: the character is a priest
	local Original = UnitClass
	UnitClass = function() return Classes.DRUID.Male, "DRUID", Classes.DRUID.ID end
	local AsDruid = UsableValue(Staff, "Ma copie")
	UnitClass = Original
	PawnCommon.Scales["Ma copie"] = nil
	Equal(AsPriest, 0, "personnage prêtre")
	Equal(AsDruid, 167 + 275, "personnage druide")
end)

Test("objets utilisables : une arme de main gauche compte pour les voleurs, pas pour les tanks", function()
	ClassicScales()
	local Dagger = OffHandDagger()
	for _, Rogue in ipairs(Rogues) do
		Equal(PawnCommon.Scales[Rogue].Values.IsOffHand, nil, Rogue .. " : main gauche")
		assert(UsableValue(Dagger, Rogue) > 0, Rogue .. " : " .. tostring(UsableValue(Dagger, Rogue)))
	end
	Equal(PawnCommon.Scales['"Classic":WARRIOR3'].Values.IsOffHand, PawnIgnoreStatValue, "guerrier Protection")
	Equal(PawnCommon.Scales['"Classic":PALADIN2'].Values.IsOffHand, PawnIgnoreStatValue, "paladin Protection")
end)

Test("objets utilisables : les meilleurs objets notés avant cette version sont oubliés une fois", function()
	ClassicScales()
	PawnClassicApplyRatingLevel(60)
	local Scale = PawnCommon.Scales[ShadowPriest]
	Scale.PerCharacterOptions = Scale.PerCharacterOptions or {}
	Scale.PerCharacterOptions["Mairy-Test"] = Scale.PerCharacterOptions["Mairy-Test"] or {}
	local Options = Scale.PerCharacterOptions["Mairy-Test"]
	Options.BestItems, Options.RatingWeightsVersion = { Stub = true }, 2
	PawnClassicRatingLevel = nil -- as on login
	PawnClassicApplyRatingLevel(60)
	Equal(Options.BestItems, nil, "liste notée avec la version 2 oubliée")
	Equal(Options.RatingWeightsVersion, 3, "version mémorisée")
end)
```

- [ ] **Step 2: Vérifier l'échec**

Run: `luajit tests/run.lua 2>&1 | grep "^UNIT" ; luajit tests/run.lua 2>&1 | tail -1`
Expected : 4 lignes `UNIT  objets utilisables : …` :
- « réservé au druide » : erreur sur `PawnClassTokens` (nil) ;
- « échelle perso » : `personnage prêtre`, avec 442 obtenu ;
- « main gauche » : `"Classic":ROGUE1 : main gauche`, avec -1000000 obtenu ;
- « oubliés une fois » : `liste notée avec la version 2 oubliée`.

Total : 2318 réussis, 4 échecs.

- [ ] **Step 3: Implémenter la valeur dans `Pawn.lua`**

Juste avant `function PawnAddClassRestriction(Stats, List, DebugMessages)` :

```lua
-- Fork frFR 3.3.5a: class token by class ID (ChrClasses.dbc: field 0 = ID, field 55 = token).
PawnClassTokens = { [1] = "WARRIOR", [2] = "PALADIN", [3] = "HUNTER", [4] = "ROGUE", [5] = "PRIEST", [6] = "DEATHKNIGHT",
	[7] = "SHAMAN", [8] = "MAGE", [9] = "WARLOCK", [11] = "DRUID" }

-- Fork frFR 3.3.5a: the class token a scale is for: its ClassID (Classic scales), else the character's class (the user's
-- own and imported scales).
function PawnGetScaleClassToken(ScaleName)
	local Scale = PawnCommon.Scales[ScaleName]
	if Scale and Scale.ClassID then return PawnClassTokens[Scale.ClassID] end
	local _, Token = UnitClass("player")
	return Token
end

```

Dans `PawnGetStatWeight`, remplacer la première ligne du corps :

```lua
	local General = PawnRestrictedRatingStats[Stat]
```

par :

```lua
	-- Fork frFR 3.3.5a: an item restricted to other classes (PawnAddClassRestriction) is unusable for a scale of this class.
	local Token = strmatch(Stat, "^UnusableBy(%u+)$")
	if Token then
		if Token == PawnGetScaleClassToken(ScaleName) then return PawnIgnoreStatValue end
		return nil
	end
	local General = PawnRestrictedRatingStats[Stat]
```

`strmatch` est une fonction globale de WoW. Si `tests/wowapi.lua` ne la définit pas (`grep -n strmatch tests/wowapi.lua`), il faut l'ajouter à la ligne 13 de `tests/wowapi.lua`, de cette forme :

```lua
strfind, strsub, strlen, strlower, strupper, strmatch = string.find, string.sub, string.len, string.lower, string.upper, string.match
```

- [ ] **Step 4: Débloquer la main gauche des voleurs et monter la version (`ClassicHawsJon.lua`)**

Dans la branche Wrath (après `elseif VgerCore.IsWrath then`), uniquement pour les trois échelles de voleur (lignes 521, 532, 543), remplacer :

```lua
			{ IsOffHand=PawnIgnoreStatValue, IsFrill=PawnIgnoreStatValue, IsShield=PawnIgnoreStatValue,
```

par :

```lua
			{ IsFrill=PawnIgnoreStatValue, IsShield=PawnIgnoreStatValue, -- fork frFR 3.3.5a: was also IsOffHand; rogues dual-wield
```

Les occurrences BC (lignes 203, 213, 223) ne changent pas. Le script de modification remplace seulement les occurrences situées après l'index de `elseif VgerCore.IsWrath then`, et vérifie qu'il y en a exactement 3.

Version :

```lua
-- Bump when the weights change in a way that makes the best items saved per character wrong (1: restricted ratings;
-- 2: sockets valued with the gems of the character's expansion; 3: rogue off-hand weapons and class-restricted items).
local RatingWeightsVersion = 3
```

- [ ] **Step 5: Vérifier que tout passe**

Run: `luajit tests/run.lua 2>&1 | grep "^UNIT" ; luajit tests/run.lua 2>&1 | tail -1`
Expected : aucune ligne `UNIT`. Total : 2322 réussis, 0 échec, 0 todo.

- [ ] **Step 6: Mettre à jour `CLAUDE.md`**

Remplacer `Currently 2318 passing` par `Currently 2322 passing`.

Dans « Architecture », après la puce « Sockets: … » :

```markdown
- Usable items: a "Classes : …" line (`ITEM_CLASSES_ALLOWED`) goes through the source `PawnClassesAllowed` (`Core.lua`) to `PawnAddClassRestriction`, which recognizes the client's class names (`LOCALIZED_CLASS_NAMES_MALE` / `_FEMALE`, longest first, no separator assumed) and adds `UnusableBy<TOKEN>` for every class the line doesn't list; an unknown name adds nothing. `PawnGetStatWeight` makes that stat unusable for a scale of that class (`PawnGetScaleClassToken`: the scale's `ClassID`, else the character's class). The Wrath rogue scales no longer block off-hand weapons (`IsOffHand`).
```

- [ ] **Step 7: Commit**

```bash
git add Pawn.lua ClassicHawsJon.lua tests/unit.lua tests/wowapi.lua CLAUDE.md
git commit -m "$(cat <<'EOF'
Value class-restricted items at 0 for other classes; rogues use off-hand weapons

A scale's class is its ClassID, else the character's class. Saved best items
are forgotten once.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>
EOF
)"
```
