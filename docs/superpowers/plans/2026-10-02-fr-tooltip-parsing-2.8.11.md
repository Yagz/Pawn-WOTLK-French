# Lecture des infobulles frFR (Pawn 2.8.11 MarkosF, client 3.3.5a) — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Objectif :** sur le client WoW 3.3.5a frFR, le portage Pawn 2.8.11 reconnaît et compte correctement les stats des infobulles d'objets (Vanilla, TBC, WotLK). La preuve en est un banc d'essai hors jeu alimenté par des données réelles du client, et un scanner en jeu.

**Architecture :**
- Un nouveau fichier, `TooltipParsing.frFR.lua`, est chargé après `TooltipParsing.lua`. Sur un client frFR, il remplace les tables d'analyse de la 2.8.11 (motifs Wrath Classic) par des motifs tirés uniquement des fichiers du client frFR et des relevés en jeu.
- `PawnScan.lua` vérifie en jeu tous les objets du client.
- `tests/` exécute le vrai code de Pawn sous LuaJIT, sur des lignes générées à partir des données du client.

**Technologies :**
- Lua 5.1 (client 3.3.5a, avec !!!ClassicAPI) ;
- LuaJIT (`/usr/bin/luajit`) pour les tests ;
- Python 3 + `mpyq`, dans un environnement virtuel du scratchpad, pour lire les MPQ (scripts non commités).

**Spec :** `docs/superpowers/specs/2026-10-02-fr-tooltip-parsing-2.8.11-design.md`

## Global Constraints

- **Dossier de travail** `LIVE="/mnt/stock/Games/World of Warcraft/Interface/AddOns/Pawn"`, sur la branche `fr-2.8.11`. Le chemin contient des espaces, donc il faut toujours le citer. Toutes les commandes `luajit tests/...` se lancent depuis `$LIVE`.
- **Scratchpad :** `SCRATCH=/tmp/claude-1000/-mnt-stock-Games-World-of-Warcraft-Interface-AddOns-Pawn/873b834f-ddd8-47d4-a98e-d8a2bff8abe0/scratchpad`. Il contient `venv/` (avec `mpyq`). S'il a disparu, le recréer comme indiqué en tâche 1.
- **Client frFR :** `/mnt/stock/Games/World of Warcraft/Data/frFR`. Ordre de priorité des MPQ : `patch-frFR-3.MPQ`, `patch-frFR-2.MPQ`, `patch-frFR.MPQ`, `locale-frFR.MPQ`.
- **Moteur :** ne modifier aucun fichier existant de la 2.8.11, sauf `Pawn.toc` (ajouts de fichiers et de SavedVariables). Si une incompatibilité avec !!!ClassicAPI impose un correctif, il doit être minimal, commenté, et faire l'objet d'un commit à part, comme celui de `PawnGetClassInfo` (déjà fait).
- **Données réelles uniquement.** Aucun motif, texte ni nom ne vient de la branche `main`, des motifs FR existants de la 2.8.11 (`Localization.frFR.lua`), de VgerMods ou de la mémoire. Chaque ligne des tables FR cite sa source : `GlobalStrings: CONSTANTE`, `Spell.dbc`, `SpellItemEnchantment.dbc`, `ItemSubClass.dbc`, `logs` ou `scan`.
- **Ne jamais retaper un texte du client dans un fichier de tests.** Les cas sont produits par les générateurs, à partir des octets extraits.
- **Noms de stats :** ceux que valorisent les échelles Wrath de la 2.8.11 (`Strength`, `Agility`, `Stamina`, `Intellect`, `Spirit`, `Ap`, `Rap`, `FeralAp`, `HitRating`, `CritRating`, `HasteRating`, `ExpertiseRating`, `ArmorPenetration`, `SpellPower`, `SpellPenetration`, `Mp5`, `Hp5`, `Health`, `Mana`, `Armor`, `BlockValue`, `BlockRating`, `DefenseRating`, `DodgeRating`, `ParryRating`, `ResilienceRating`, `FireSpellDamage`, `ShadowSpellDamage`, `NatureSpellDamage`, `ArcaneSpellDamage`, `FrostSpellDamage`, `HolySpellDamage`, `AllResist`, `FireResist`, `ShadowResist`, `NatureResist`, `ArcaneResist`, `FrostResist`, `MinDamage`, `MaxDamage`, `Dps`, `Speed`, `RedSocket`, `YellowSocket`, `BlueSocket`, `MetaSocket`, `PrismaticSocket`, `IsRanged`, `IsOneHand`, `IsTwoHand`, `IsMainHand`, `IsOffHand`, `IsFrill`, `IsAxe`, `IsBow`, `IsCrossbow`, `IsDagger`, `IsFist`, `IsGun`, `IsMace`, `IsPolearm`, `IsStaff`, `IsSword`, `IsWand`, `IsThrown`, `IsCloth`, `IsLeather`, `IsMail`, `IsPlate`, `IsShield`).
  - Les variantes « des sorts » des scores comptent comme les scores combinés (`CritRating`, `HitRating`, `HasteRating`).
- **Lua 5.1 :** pas de `goto`, pas de `//`, pas d'opérateurs binaires, `unpack` et non `table.unpack`. Les motifs Lua travaillent sur des **octets** : jamais de caractère accentué dans une classe `[...]`, ni visé par `.`.
- **Espaces insécables :** sur un client frFR, le moteur 2.8.11 remplace `\194\160` par une espace avant l'analyse (`LookForNBSP`). Les motifs FR s'écrivent donc avec des espaces normales.
- **Fichiers :** les fichiers de la 2.8.11 sont en UTF-8 avec BOM et fins de ligne LF. Les nouveaux fichiers sont en UTF-8 sans BOM, LF. Ne pas toucher au BOM de `Pawn.toc`.
- **Commits :** un par tâche au minimum. Le message se termine par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.
- **Points de vérification en jeu (tâches 6 et 10) :** l'exécutant **s'arrête** et attend le retour de l'utilisateur. Il ne simule jamais un résultat de jeu. Rappel à donner à chaque fois : WoW n'écrit les SavedVariables que sur `/reload` ou sur une sortie propre (Échap → Quitter le jeu). `/chatlog` ne produit pas de fichier chez l'utilisateur : lui demander de **coller** la sortie du chat.

## Review Focus

1. **Objet qui n'existe pas ou que le serveur ne renvoie jamais :** le scan l'abandonne après 3 essais, sans bloquer. Testé en tâche 4.
2. **Scan interrompu par un `/reload` :** `/pawnscan` sans argument reprend à la position sauvegardée. Testé en tâche 4.
3. **Pic de latence :** le scanner ne traite pas plus d'une seconde d'entrées d'un coup. Testé en tâche 4.
4. **Vitesse et DPS avec virgule ou point décimal (« Vitesse 2,60 » / « 2.60 ») :** lecture correcte. Testé en tâche 7 (cas générés).
5. **Client enUS :** `TooltipParsing.frFR.lua` ne change rien. Testé en tâches 3 et 9.

---

### Task 1 : Extraire les données du client frFR

**Files :**
- Create: `tests/data/GlobalStrings.frFR.lua`, `tests/data/spell_templates.frFR.txt`, `tests/data/enchant_texts.frFR.txt`, `tests/data/itemsubclass.frFR.txt`
- Script (non commité) : `$SCRATCH/tools/extract.py`

**Interfaces :**
- Produit :
  - `GlobalStrings.frFR.lua` : les lignes `CONSTANTE = "texte";` du client, copiées telles quelles. On garde chaque constante citée par un fichier `.lua` de l'addon, plus les familles utiles à l'analyse.
  - `spell_templates.frFR.txt` : lignes `nombre<TAB>modèle`, où `#` remplace la valeur.
  - `enchant_texts.frFR.txt` : lignes `nombre<TAB>modèle<TAB>exemple réel`.
  - `itemsubclass.frFR.txt` : lignes `classe<TAB>sous-classe<TAB>nom`, pour les classes 2, 4 et 6.

- [ ] **Step 1 : Écrire le script d'extraction**

```bash
mkdir -p "$SCRATCH/tools"
[ -x "$SCRATCH/venv/bin/python" ] || { python3 -m venv "$SCRATCH/venv" && "$SCRATCH/venv/bin/pip" -q install mpyq; }
cat > "$SCRATCH/tools/extract.py" <<'EOF'
# Extracts the frFR 3.3.5a client data used by Pawn's tests.  Usage: extract.py <addon dir> <tests/data dir>
import collections, glob, re, struct, sys
import mpyq

GAME = "/mnt/stock/Games/World of Warcraft/Data/frFR/"
ARCHIVES = ["patch-frFR-3.MPQ", "patch-frFR-2.MPQ", "patch-frFR.MPQ", "locale-frFR.MPQ"]  # newest first
ADDON, OUT = sys.argv[1], sys.argv[2]

def read(name):
    for archive in ARCHIVES:
        mpq = mpyq.MPQArchive(GAME + archive, listfile=True)
        if name.encode() in (mpq.files or []):
            return mpq.read_file(name)
    raise SystemExit("not found: " + name)

def dbc(name):
    data = read("DBFilesClient\\" + name)
    count, fields, size, _ = struct.unpack("<4I", data[4:20])
    strings = data[20 + count * size:]
    def text(offset):
        return strings[offset:strings.find(b"\0", offset)].decode("utf-8")
    rows = [struct.unpack_from("<%dI" % fields, data, 20 + r * size) for r in range(count)]
    return rows, text

# 1. GlobalStrings.lua: every constant named in the addon's Lua files, plus the tooltip families.
used = set()
for path in glob.glob(ADDON + "/**/*.lua", recursive=True):
    used |= set(re.findall(rb"\b[A-Z][A-Z0-9_]{2,}\b", open(path, "rb").read()))
FAMILIES = re.compile(rb"^(ITEM_|INVTYPE_|EMPTY_SOCKET|DAMAGE_|SINGLE_DAMAGE|PLUS_DAMAGE|DPS_TEMPLATE|ARMOR_TEMPLATE|"
                      rb"SHIELD_BLOCK_TEMPLATE|DURABILITY_TEMPLATE|CONTAINER_SLOTS|LOCKED|ENCRYPTED|MAJOR_GLYPH|"
                      rb"MINOR_GLYPH|CURRENTLY_EQUIPPED|RETRIEVING_ITEM_INFO|ENCHANT_|SPEED|RESISTANCE\d_NAME)")
lines = []
for line in read("Interface\\FrameXML\\GlobalStrings.lua").splitlines():
    m = re.match(rb"^([A-Z][A-Z0-9_]*) = ", line)
    if m and (m.group(1) in used or FAMILIES.match(line)):
        lines.append(line)
with open(OUT + "/GlobalStrings.frFR.lua", "wb") as f:
    f.write(b"-- Subset of Interface\\FrameXML\\GlobalStrings.lua from the frFR 3.3.5a client (newest frFR MPQ).\n")
    f.write(b"\n".join(lines) + b"\n")

# 2. Spell.dbc: frFR description (field 172), turned into one-number templates.
def template(desc):
    t = re.sub(r"\$[lL]([^:;]*):([^;]*);", r"\2", desc)        # $lsingular:plural;
    t = re.sub(r"\$/[\d.]+;\$?\d*[a-zA-Z]\d?", "#", t)         # $/10;s1
    t = re.sub(r"\$\*[\d.]+;\$?\d*[a-zA-Z]\d?", "#", t)        # $*2;s1
    t = re.sub(r"\$\{[^}]*\}", "#", t)                          # ${...}
    return re.sub(r"\$\d*[a-zA-Z]\d?", "#", t)                  # $s1, $o1, $d, $12345s1
rows, text = dbc("Spell.dbc")
counts = collections.Counter()
STAT_START = re.compile(r"^(Augmente|Améliore|Rend|Restaure|Réduit|Diminue|Accroît|\+)")
for row in rows:
    t = template(text(row[172]))
    if t.count("#") == 1 and len(t) <= 120 and STAT_START.match(t) and " pendant " not in t and "$" not in t:
        counts[t] += 1
with open(OUT + "/spell_templates.frFR.txt", "w", encoding="utf-8", newline="\n") as f:
    f.write("# Spell.dbc (frFR) description templates, # = value, count = number of spells.  Kept: 1 value, no duration, count >= 3.\n")
    for t, n in counts.most_common():
        if n >= 3:
            f.write("%d\t%s\n" % (n, t))

# 3. SpellItemEnchantment.dbc: frFR text (field 16) of every enchant, gem and socket bonus.
rows, text = dbc("SpellItemEnchantment.dbc")
examples, counts = {}, collections.Counter()
for row in rows:
    t = text(row[16])
    if t:
        key = re.sub(r"\d+", "#", t)
        counts[key] += 1
        examples.setdefault(key, t)
with open(OUT + "/enchant_texts.frFR.txt", "w", encoding="utf-8", newline="\n") as f:
    f.write("# SpellItemEnchantment.dbc (frFR) texts: count<TAB>template<TAB>first real example.\n")
    for key, n in counts.most_common():
        f.write("%d\t%s\t%s\n" % (n, key, examples[key]))

# 4. ItemSubClass.dbc: frFR display name (field 12) for weapons (2), armor (4) and projectiles (6).
rows, text = dbc("ItemSubClass.dbc")
with open(OUT + "/itemsubclass.frFR.txt", "w", encoding="utf-8", newline="\n") as f:
    f.write("# ItemSubClass.dbc (frFR): class<TAB>subclass<TAB>display name.\n")
    for row in rows:
        name = text(row[12])
        if row[0] in (2, 4, 6) and name and "OBSOLETE" not in name:
            f.write("%d\t%d\t%s\n" % (row[0], row[1], name))
EOF
```

- [ ] **Step 2 : Lancer l'extraction et vérifier**

```bash
cd "$LIVE"
mkdir -p tests/data
"$SCRATCH/venv/bin/python" "$SCRATCH/tools/extract.py" . tests/data
grep -E '^(ITEM_SOCKET_BONUS|ITEM_SPELL_TRIGGER_ONEQUIP|DAMAGE_TEMPLATE_WITH_SCHOOL|ITEM_MOD_CRIT_RATING|MOUNT) ' tests/data/GlobalStrings.frFR.lua
head -3 tests/data/spell_templates.frFR.txt tests/data/enchant_texts.frFR.txt
grep -P '^2\t7\t' tests/data/itemsubclass.frFR.txt
```

Résultat attendu :
- `ITEM_SOCKET_BONUS = "Bonus de sertissage : %s";`, `ITEM_SPELL_TRIGGER_ONEQUIP = "Équipé :";`, `DAMAGE_TEMPLATE_WITH_SCHOOL = "%d - %d points de dégâts (%s)";`, ainsi que `ITEM_MOD_CRIT_RATING` et `MOUNT` présents ;
- `421	Augmente la puissance des sorts de #.` et `135	+# à la puissance des sorts	…` en tête ;
- `2	7	Epée`.

- [ ] **Step 3 : Commit**

```bash
git add tests/data
git commit -m "Add frFR client data extracted from the 3.3.5a MPQs for the tests

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2 : Banc d'essai hors jeu

**Files :**
- Create: `tests/wowapi.lua`, `tests/corpus.lua`, `tests/harness.lua`, `tests/run.lua`, `tests/unit.lua`

**Interfaces :**
- Produit :
  - `Harness.Load()` ;
  - `Harness.Files` : la liste des fichiers de l'addon chargés, dans l'ordre du `.toc` (les tâches 3 et 4 y ajoutent les leurs) ;
  - `Harness.ParseLine(Left, Right) -> Raw, Understood, Errors`, où `Raw` contient les stats trouvées par `PawnLookForSingleStat` avant le post-traitement ;
  - `Corpus.ParseCase`, `Corpus.FormatStats`, `Corpus.ReadFile`, `Corpus.Files`, `Corpus.Append(Path, Entries, Header)`, où `Entries` est une liste de `{ Text, Expect }` ;
  - API factice : `WowApiSetTooltip(Name, Lines)`, `WowApiItems[id] = { Name, EquipLoc }`, `WowApiItemTooltips[lien] = Lines`, `WowApiHyperlinks`, `WowApiMessages`, `WowApiTime` ;
  - `luajit tests/run.lua [--propose] [fichiers...]`.

- [ ] **Step 1 : Écrire `tests/wowapi.lua`**

```lua
-- Minimal stand-ins for the WoW 3.3.5a API (with !!!ClassicAPI), so Pawn 2.8.11's real files run under LuaJIT.
-- Loaded by tests/harness.lua; run everything from the addon root.

function GetLocale() return os.getenv("PAWN_TEST_LOCALE") or "frFR" end
function GetBuildInfo() return "3.3.5", "12340", "Jun 24 2010", 30300 end

-- Project constants as defined by !!!ClassicAPI (Util/Constants.lua).
WOW_PROJECT_MAINLINE, WOW_PROJECT_CLASSIC, WOW_PROJECT_BURNING_CRUSADE_CLASSIC, WOW_PROJECT_WRATH_CLASSIC = 1, 2, 5, 11
WOW_PROJECT_ID = WOW_PROJECT_WRATH_CLASSIC
LE_EXPANSION_CLASSIC, LE_EXPANSION_BURNING_CRUSADE, LE_EXPANSION_WRATH_OF_THE_LICH_KING = 0, 1, 2
LE_EXPANSION_LEVEL_CURRENT = 2

strfind, strsub, strlen, strlower, strupper = string.find, string.sub, string.len, string.lower, string.upper
strbyte, strchar, strrep, format = string.byte, string.char, string.rep, string.format
gsub, gmatch, tinsert, tremove = string.gsub, string.gmatch, table.insert, table.remove
floor, ceil, abs, min, max = math.floor, math.ceil, math.abs, math.min, math.max

function strtrim(Text, Chars)
	local Class = "[" .. gsub(Chars or " \t\r\n", "[%]%%%^%-]", "%%%0") .. "]"
	Text = gsub(Text, "^" .. Class .. "+", "")
	return (gsub(Text, Class .. "+$", ""))
end

function getglobal(Name) return _G[Name] end
function setglobal(Name, Value) _G[Name] = Value end
function hooksecurefunc() end

WowApiTime = 0
function GetTime() return WowApiTime end

-- VgerCore.Message writes here; tests look for "ERROR:" in it.
WowApiMessages = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(self, Text) table.insert(WowApiMessages, tostring(Text)) end }

SlashCmdList = {}

-- Items known to the fake client: WowApiItems[ID] = { Name, EquipLoc }.  Unknown IDs behave like uncached items.
WowApiItems = {}
function GetItemInfo(ID)
	local Item = WowApiItems[ID]
	if not Item then return nil end
	return Item[1], "item:" .. ID, 3, 100, 80, "Armure", "Tissu", 1, Item[2]
end

-- Fake tooltip lines.
local FontString = {}
FontString.__index = FontString
function FontString:GetText() return self.Text end
function FontString:SetText(Text) self.Text = Text end
function FontString:GetTextColor() return 0, 1, 0 end -- green: a socket bonus counts as active
function FontString:SetTextColor() end

-- WowApiItemTooltips[Link] = Lines: what SetHyperlink shows for that link.  WowApiHyperlinks: every link shown.
WowApiItemTooltips = {}
WowApiHyperlinks = {}

-- Any method a test doesn't define is a no-op.
local function NoOp() end

local Tooltip = {}
Tooltip.__index = function(_, Key) return rawget(Tooltip, Key) or NoOp end
function Tooltip:NumLines() return self.Count end
function Tooltip:ClearLines() self.Count = 0 end
function Tooltip:GetItem() return nil, nil end
function Tooltip:SetHyperlink(Link)
	table.insert(WowApiHyperlinks, Link)
	WowApiSetTooltip(self.Name, WowApiItemTooltips[Link] or {})
end

-- Fills the fake tooltip called Name.  Each entry of Lines is a left-side string or { Left, Right }.
function WowApiSetTooltip(Name, Lines)
	local T = rawget(_G, Name)
	if not T then
		T = setmetatable({ Name = Name, Count = 0 }, Tooltip)
		_G[Name] = T
	end
	for i, Entry in ipairs(Lines) do
		local Left, Right = Entry, nil
		if type(Entry) == "table" then Left, Right = Entry[1], Entry[2] end
		_G[Name .. "TextLeft" .. i] = setmetatable({ Text = Left }, FontString)
		_G[Name .. "TextRight" .. i] = setmetatable({ Text = Right }, FontString)
	end
	T.Count = #Lines
	return T
end

local Frame = {}
Frame.__index = function(_, Key) return rawget(Frame, Key) or NoOp end
function Frame:SetScript(Name, Script) self.Scripts[Name] = Script end
function Frame:GetScript(Name) return self.Scripts[Name] end
function Frame:Show() self.Shown = true end
function Frame:Hide() self.Shown = false end
function Frame:IsShown() return self.Shown end
function CreateFrame(Type, Name)
	if Type == "GameTooltip" then return WowApiSetTooltip(Name or "WowApiAnonymousTooltip", {}) end
	local F = setmetatable({ Scripts = {}, Shown = true }, Frame)
	if Name then _G[Name] = F end
	return F
end
UIParent = CreateFrame("Frame", "UIParent")
WorldFrame = CreateFrame("Frame", "WorldFrame")
```

- [ ] **Step 2 : Écrire `tests/corpus.lua`**

```lua
-- Reads and writes the test corpus files (tests/corpus/*.txt).
-- Line format:  left[ || right] => expectation   (or  || right => expectation)
-- expectation: ignored | unhandled | todo | Stat=value[; Stat=value]
-- The LAST " => " on the line separates the text from the expectation.
local Corpus = {}

function Corpus.FormatStats(Stats)
	local Keys = {}
	for Key in pairs(Stats) do table.insert(Keys, Key) end
	table.sort(Keys)
	local Parts = {}
	for _, Key in ipairs(Keys) do table.insert(Parts, Key .. "=" .. string.format("%.10g", Stats[Key])) end
	return table.concat(Parts, "; ")
end

-- Returns a Case, or nil for blank and comment lines, or nil plus an error message.
function Corpus.ParseCase(Line)
	Line = Line:gsub("\r$", "")
	if Line:match("^%s*$") or Line:match("^#") then return nil end
	local Text, Expect = Line:match("^(.*) => (.-)%s*$")
	if not Text then return nil, "missing ' => '" end
	Text = Text:gsub("%s+$", "")
	local Left, Right
	if Text:sub(1, 3) == "|| " then
		Left, Right = "", Text:sub(4)
	else
		Left, Right = Text:match("^(.-)%s+|| (.*)$")
		if not Left then Left = Text end
	end
	local Case = { Left = Left, Right = Right, Text = Text }
	if Expect == "ignored" or Expect == "unhandled" or Expect == "todo" then
		Case.Kind = Expect
		return Case
	end
	Case.Kind, Case.Stats = "stats", {}
	for Part in Expect:gmatch("[^;]+") do
		local Stat, Value = Part:match("^%s*(%w+)=(%-?[%d%.]+)%s*$")
		if not Stat then return nil, "bad expectation '" .. Part .. "'" end
		Case.Stats[Stat] = tonumber(Value)
	end
	return Case
end

function Corpus.ReadFile(Path)
	local Cases, Errors, Number = {}, {}, 0
	for Line in io.lines(Path) do
		Number = Number + 1
		local Case, Err = Corpus.ParseCase(Line)
		if Case then
			Case.File, Case.Line = Path, Number
			table.insert(Cases, Case)
		elseif Err then
			table.insert(Errors, Path .. ":" .. Number .. ": " .. Err)
		end
	end
	return Cases, Errors
end

function Corpus.Files()
	local Files = {}
	local Pipe = io.popen("ls tests/corpus/*.txt 2>/dev/null")
	for Path in Pipe:lines() do table.insert(Files, Path) end
	Pipe:close()
	return Files
end

-- Appends "Text => Expect" lines to Path, skipping texts already present in Path or in any corpus file.
-- Writes Header first when Path doesn't exist yet.  Returns the number of lines added.
function Corpus.Append(Path, Entries, Header)
	local Known = {}
	local Paths = Corpus.Files()
	local Existing = io.open(Path, "r")
	if Existing then Existing:close() table.insert(Paths, Path) end
	for _, File in ipairs(Paths) do
		for _, Case in ipairs((Corpus.ReadFile(File))) do Known[Case.Text] = true end
	end
	local Out = assert(io.open(Path, "a"))
	if not Existing and Header then Out:write(Header, "\n") end
	local Added = 0
	for _, Entry in ipairs(Entries) do
		if not Known[Entry.Text] then
			Out:write(Entry.Text, " => ", Entry.Expect, "\n")
			Known[Entry.Text] = true
			Added = Added + 1
		end
	end
	Out:close()
	return Added
end

return Corpus
```

- [ ] **Step 3 : Écrire `tests/harness.lua`**

```lua
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
```

- [ ] **Step 4 : Écrire `tests/run.lua`**

```lua
-- Runs the offline tests: unit tests (tests/unit.lua), then the corpus files.
-- Usage, from the addon root:
--   luajit tests/run.lua                      all unit tests and all tests/corpus/*.txt
--   luajit tests/run.lua FILE...              unit tests and the given corpus files
--   luajit tests/run.lua --propose FILE...    print "text => current reading" for every todo case
package.path = "./tests/?.lua;" .. package.path
local Harness = require("harness")
local Corpus = require("corpus")
Harness.Load()

local Propose = arg[1] == "--propose"
local Files = {}
for i = Propose and 2 or 1, #arg do table.insert(Files, arg[i]) end
if #Files == 0 then Files = Corpus.Files() end

local function Reading(Raw, Understood)
	if not Understood then return "unhandled" end
	if next(Raw) == nil then return "ignored" end
	return Corpus.FormatStats(Raw)
end

if Propose then
	for _, Path in ipairs(Files) do
		for _, Case in ipairs((Corpus.ReadFile(Path))) do
			if Case.Kind == "todo" then
				local Raw, Understood = Harness.ParseLine(Case.Left, Case.Right)
				print(Case.Text .. " => " .. Reading(Raw, Understood))
			end
		end
	end
	os.exit(0)
end

local Failures, Passed, Todo = 0, 0, 0

for _, Test in ipairs(require("unit")) do
	local Ok, Err = pcall(Test.Run)
	if Ok then Passed = Passed + 1 else Failures = Failures + 1 print("UNIT  " .. Test.Name .. " : " .. tostring(Err)) end
end

local function SameStats(A, B)
	for Key, Value in pairs(A) do
		if not B[Key] or math.abs(B[Key] - Value) > 1e-6 then return false end
	end
	for Key in pairs(B) do if not A[Key] then return false end end
	return true
end

local function Check(Case)
	local Raw, Understood, Errors = Harness.ParseLine(Case.Left, Case.Right)
	if #Errors > 0 then return false, "erreur : " .. table.concat(Errors, " | ") end
	if Case.Kind == "todo" then return "todo" end
	if Case.Kind == "unhandled" then
		if not Understood then return true end
		return false, "devrait rester non comprise, lue comme [" .. Corpus.FormatStats(Raw) .. "]"
	end
	if not Understood then return false, "non comprise" end
	local Expected = Case.Stats or {}
	if SameStats(Raw, Expected) then return true end
	return false, "attendu [" .. Corpus.FormatStats(Expected) .. "], obtenu [" .. Corpus.FormatStats(Raw) .. "]"
end

for _, Path in ipairs(Files) do
	local Cases, Errors = Corpus.ReadFile(Path)
	for _, Err in ipairs(Errors) do Failures = Failures + 1 print("FORMAT " .. Err) end
	for _, Case in ipairs(Cases) do
		local Result, Reason = Check(Case)
		if Result == "todo" then
			Todo = Todo + 1
		elseif Result then
			Passed = Passed + 1
		else
			Failures = Failures + 1
			print(string.format("ECHEC %s:%d  %s  -> %s", Path, Case.Line, Case.Text, Reason))
		end
	end
end

print(string.format("%d réussis, %d échecs, %d à classer (todo)", Passed, Failures, Todo))
os.exit(Failures == 0 and 0 or 1)
```

- [ ] **Step 5 : Écrire `tests/unit.lua`, avec les premiers tests**

```lua
-- Unit tests run by tests/run.lua.  A test fails by raising an error.
local Corpus = require("corpus")
local Harness = require("harness")

local Tests = {}
local function Test(Name, Run) table.insert(Tests, { Name = Name, Run = Run }) end
local function Equal(Got, Expected, What)
	if Got ~= Expected then
		error((What or "valeur") .. " : attendu " .. tostring(Expected) .. ", obtenu " .. tostring(Got), 2)
	end
end

Test("corpus : texte de gauche, texte de droite et stats", function()
	local Case = Corpus.ParseCase("Dégâts : 10 - 20 || Vitesse 2,60  => MinDamage=10; MaxDamage=20")
	Equal(Case.Left, "Dégâts : 10 - 20", "gauche")
	Equal(Case.Right, "Vitesse 2,60", "droite")
	Equal(Case.Kind, "stats", "type")
	Equal(Case.Stats.MinDamage, 10, "MinDamage")
	Equal(Case.Stats.MaxDamage, 20, "MaxDamage")
end)

Test("corpus : texte de droite seul", function()
	local Case = Corpus.ParseCase("|| Epée => IsSword=1")
	Equal(Case.Left, "", "gauche")
	Equal(Case.Right, "Epée", "droite")
	Equal(Case.Text, "|| Epée", "texte")
end)

Test("corpus : le dernier ' => ' sépare l'attente", function()
	local Case = Corpus.ParseCase("a => b => unhandled")
	Equal(Case.Left, "a => b", "gauche")
	Equal(Case.Kind, "unhandled", "type")
end)

Test("corpus : commentaires, lignes vides et lignes mal formées", function()
	Equal(Corpus.ParseCase("# note"), nil, "commentaire")
	Equal(Corpus.ParseCase("   "), nil, "vide")
	local Case, Err = Corpus.ParseCase("+5 Force => Force5")
	Equal(Case, nil, "cas")
	Equal(Err ~= nil, true, "erreur signalée")
end)

Test("corpus : format des stats", function()
	Equal(Corpus.FormatStats({ Speed = 2.6, Agility = 12 }), "Agility=12; Speed=2.6")
end)

Test("corpus : Append ne crée pas de doublon", function()
	local Path = os.tmpname()
	os.remove(Path)
	Equal(Corpus.Append(Path, { { Text = "ligne A", Expect = "todo" } }, "# entête"), 1, "premier ajout")
	Equal(Corpus.Append(Path, { { Text = "ligne A", Expect = "todo" }, { Text = "ligne B", Expect = "todo" } }), 1, "second ajout")
	Equal(#Corpus.ReadFile(Path), 2, "cas dans le fichier")
	os.remove(Path)
end)

Test("wowapi : strtrim", function()
	Equal(strtrim("  +5 Force \r\n"), "+5 Force")
end)

Test("harness : une constante FR du client est comprise", function()
	local Raw, Understood, Errors = Harness.ParseLine(ITEM_SOULBOUND)
	Equal(#Errors, 0, "erreurs")
	Equal(Understood, true, "comprise")
	Equal(next(Raw), nil, "stats")
end)

Test("harness : une ligne inconnue est signalée", function()
	local _, Understood = Harness.ParseLine("Ligne qui n'existe dans aucune table")
	Equal(Understood, false, "comprise")
end)

Test("harness : l'essai en jeu se reproduit hors jeu (dégâts d'Arcanes non compris par la 2.8.11)", function()
	local Line = format(DAMAGE_TEMPLATE_WITH_SCHOOL, 83, 156, "Arcanes")
	Equal(Line, "83 - 156 points de dégâts (Arcanes)", "texte rendu")
	local _, Understood = Harness.ParseLine(Line)
	Equal(Understood, false, "comprise par les motifs Wrath Classic")
end)

return Tests
```

Le dernier test reproduit hors jeu l'échec observé en jeu sur le Récolteur d'essence. Il valide le banc d'essai lui-même. La tâche 8 le remplacera par le test inverse.

- [ ] **Step 6 : Lancer les tests**

Run : `cd "$LIVE" && luajit tests/run.lua`

Résultat attendu : `10 réussis, 0 échecs, 0 à classer (todo)` et code de sortie 0.

Si un fichier de l'addon échoue au chargement :
- avec `attempt to call … (a nil value)` sur une fonction WoW : ajouter l'imitation minimale dans `tests/wowapi.lua` ;
- sur une constante absente : vérifier qu'elle existe dans le `GlobalStrings.lua` du client. Si oui, l'ajouter à `FAMILIES` dans `extract.py` et relancer la tâche 1, étape 2. Si non, elle est aussi absente en jeu et `nil` est le comportement réel.

Ne jamais modifier un fichier de la 2.8.11 pour faire passer le banc.

- [ ] **Step 7 : Commit**

```bash
git add tests
git commit -m "Add offline test harness running Pawn 2.8.11's real parser under LuaJIT

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3 : Squelette de `TooltipParsing.frFR.lua`

**Files :**
- Create: `TooltipParsing.frFR.lua`
- Modify: `Pawn.toc` (ajouter `TooltipParsing.frFR.lua` juste après `TooltipParsing.lua`)
- Modify: `tests/harness.lua` (même ajout dans `Harness.Files`)
- Test: `tests/unit.lua`

**Interfaces :**
- Produit :
  - `PawnFrFormatToPattern(Format) -> motif non ancré` ;
  - `PawnFrPattern(Name)` (`"^...$"` pour la constante `Name`, avec une erreur explicite si elle est absente) ;
  - `PawnFrEquipPattern(Name)` (la même chose, précédée de « Équipé : ») ;
  - `PawnFrSpellPattern(Template)` (« Équipé : » + modèle de `Spell.dbc`, où `#` remplace la valeur) ;
  - les globales FR `PawnSeparators`, `PawnSeparatorIgnorePrefixes`, `PawnNormalizationRegexes`, `PawnLocal.TooltipParsing.SocketBonusPrefix`, `PawnLocal.ThousandsSeparator`, `PawnLocal.DecimalSeparator`.
  - À ce stade, `PawnRegexes` et `PawnRightHandRegexes` restent ceux de la 2.8.11. La tâche 8 les remplace.

- [ ] **Step 1 : Écrire les tests qui échouent (dans `tests/unit.lua`, avant `return Tests`)**

```lua
Test("frFR : conversion des formats GlobalStrings", function()
	Equal(PawnFrFormatToPattern("%c%d Endurance"), "%+?(%-?%d+) Endurance", "%c%d")
	Equal(PawnFrFormatToPattern("Augmente de %d le score de coup critique."), "Augmente de (%d+) le score de coup critique%.", "%d")
	Equal(PawnFrFormatToPattern("(%.1f dégâts par seconde)"), "%(([%d%.,]+) dégâts par seconde%)", "%.1f")
	Equal(PawnFrFormatToPattern("%2$s %1$d |4emplacement:emplacements;"), ".- (%d+) .-", "positionnel et |4")
	Equal(PawnFrFormatToPattern("%1$c%2$d à la résistance %3$s"), "%+?(%-?%d+) à la résistance .-", "positionnel %c%d")
	Equal(PawnFrFormatToPattern("%d%% de chances"), "(%d+)%% de chances", "%%")
end)

Test("frFR : un motif construit depuis le client lit la ligne du client", function()
	Equal(("+15 Endurance"):match(PawnFrPattern("ITEM_MOD_STAMINA")), "15", "Endurance")
	local Low, High = ("83 - 156 points de dégâts (Arcanes)"):match(PawnFrPattern("DAMAGE_TEMPLATE_WITH_SCHOOL"))
	Equal(Low, "83", "minimum")
	Equal(High, "156", "maximum")
	Equal(("Équipé : Augmente de 20 le score de toucher."):match(PawnFrEquipPattern("ITEM_MOD_HIT_RATING")), "20", "Équipé")
	Equal(("Équipé : Augmente la puissance des sorts d'Ombre de 33."):match(PawnFrSpellPattern("Augmente la puissance des sorts d'Ombre de #.")), "33", "Spell.dbc")
end)

Test("frFR : une constante absente est signalée par son nom", function()
	local Ok, Err = pcall(PawnFrPattern, "CONSTANTE_QUI_N_EXISTE_PAS")
	Equal(Ok, false, "échec attendu")
	Equal(tostring(Err):find("CONSTANTE_QUI_N_EXISTE_PAS", 1, true) ~= nil, true, "nom dans le message")
end)

Test("frFR : globales d'analyse issues du client", function()
	Equal(PawnLocal.TooltipParsing.SocketBonusPrefix, "Bonus de sertissage : ", "préfixe du bonus de châsse")
	Equal(PawnSeparatorIgnorePrefixes[2], ITEM_SPELL_TRIGGER_ONEQUIP, "Équipé :")
end)

Test("frFR : rien n'est redéfini sur un client enUS", function()
	local Chunk = assert(loadfile("TooltipParsing.frFR.lua"))
	local Env = setmetatable({ GetLocale = function() return "enUS" end }, { __index = _G })
	setfenv(Chunk, Env)
	Chunk()
	for _, Name in ipairs({ "PawnFrFormatToPattern", "PawnSeparators", "PawnSeparatorIgnorePrefixes", "PawnRegexes", "PawnRightHandRegexes" }) do
		Equal(rawget(Env, Name), nil, Name)
	end
end)
```

- [ ] **Step 2 : Vérifier qu'ils échouent**

Run : `luajit tests/run.lua`

Résultat attendu : 5 lignes `UNIT …` en échec, par exemple `attempt to call global 'PawnFrFormatToPattern'` ou `cannot open TooltipParsing.frFR.lua`.

- [ ] **Step 3 : Écrire `TooltipParsing.frFR.lua`**

```lua
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

-- Turns a GlobalStrings.lua format into a Lua pattern (not anchored).
-- %d and %c%d capture a number, %.1f captures a decimal number (dot or comma), %% is a literal percent sign,
-- %s and |4singular:plural; match any text without capturing.  Positional forms such as %1$d are accepted.
function PawnFrFormatToPattern(Format)
	local Pattern = gsub(Format, "%%%%", "\005")
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
	ITEM_SPELL_TRIGGER_ONEQUIP, -- GlobalStrings: "Équipé :"
	ITEM_SPELL_TRIGGER_ONUSE, -- GlobalStrings: "Utiliser :"
	ITEM_SPELL_TRIGGER_ONPROC, -- GlobalStrings: "Chances quand vous touchez :"
}

-- Normalizations applied before the regexes.
PawnNormalizationRegexes =
{
	{"^|c........(.+)$", "%1"}, -- color codes (same as TooltipParsing.lua)
	{"^([^%+%-%d][^%+]-) %+(%d+)$", "+%2 %1"}, -- SpellItemEnchantment.dbc: "Agilité +10" --> "+10 Agilité"
}

-- GlobalStrings: ITEM_SOCKET_BONUS = "Bonus de sertissage : %s"
PawnLocal.TooltipParsing.SocketBonusPrefix = gsub(ITEM_SOCKET_BONUS, "%%s", "")

-- No thousands separator; decimals may use a comma or a point (Pawn turns "," into "." before tonumber).
PawnLocal.ThousandsSeparator = ""
PawnLocal.DecimalSeparator = ","
```

- [ ] **Step 4 : Ajouter le fichier au `.toc` et au banc**

Dans `Pawn.toc`, ajouter la ligne `TooltipParsing.frFR.lua` juste après `TooltipParsing.lua`. Ne toucher ni au BOM ni aux autres lignes.

Dans `tests/harness.lua`, ajouter `"TooltipParsing.frFR.lua",` juste après `"TooltipParsing.lua",` dans `Harness.Files`.

- [ ] **Step 5 : Lancer les tests**

Run : `luajit tests/run.lua`

Résultat attendu : `15 réussis, 0 échecs, 0 à classer (todo)`.

- [ ] **Step 6 : Commit**

```bash
git add TooltipParsing.frFR.lua Pawn.toc tests/harness.lua tests/unit.lua
git commit -m "Add frFR tooltip parsing skeleton built on client GlobalStrings

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4 : Scanner en jeu `PawnScan.lua`

**Files :**
- Create: `PawnScan.lua`
- Modify: `Pawn.toc` (`PawnScan.lua` à la fin, après `ClassicHawsJon.lua` ; `## SavedVariables: PawnCommon, PawnScanResults`)
- Modify: `tests/harness.lua` (ajouter `"PawnScan.lua",` à la fin de `Harness.Files`)
- Test: `tests/unit.lua`

**Interfaces :**
- Consomme : `PawnGetStatsForItemLink(Link, false) -> Stats, SocketBonusStats, UnknownLines`, `PawnLookForSingleStat`, `PawnAddStatsToTable`, `PawnRightHandRegexes`, `VgerCore.Message`, et les tables `PawnGemQualityLevels` / `PawnMetaGemQualityLevels` (lignes `{ niveau, { { ID = n, ... }, ... } }`).
- Produit :
  - `PawnScan.Template(Line)` ;
  - `PawnScan.FormatStats(Stats)`, au même format que `Corpus.FormatStats` ;
  - `PawnScan.RecordItem(Link, Example) -> "ok" | "nok" | "skip" | "error"` ;
  - `PawnScan.GetEntry(State, Index)`, `PawnScan.Start(Mode, First, Last, Base)`, `PawnScan.Resume()`, `PawnScan.Stop()`, `PawnScan.Step(Now) -> bool`, `PawnScan.OnUpdate(Delta)`, `PawnScan.Command(Text)`.
  - La SavedVariable `PawnScanResults` contient : `unknown[modèle] = { count, example, line }`, `parsed[modèle] = { line, stats }`, `mismatch`, `errors`, `summary = { scanned, ok, nok }`, `state = { mode, next, last, base, gems, running }` et `socketedExample`.

- [ ] **Step 1 : Écrire les tests qui échouent (dans `tests/unit.lua`, avant `return Tests`)**

```lua
local function ResetScan()
	if PawnScan then PawnScan.Stop() end
	PawnScanResults = nil
	WowApiItems, WowApiItemTooltips, WowApiHyperlinks = {}, {}, {}
end

Test("scan : modèle d'une ligne", function()
	Equal(PawnScan.Template("Augmente de 12 le score de toucher."), "Augmente de # le score de toucher.")
end)

Test("scan : même format de stats que le corpus", function()
	local Stats = { Speed = 2.6, Agility = 12, MinDamage = 10 }
	Equal(PawnScan.FormatStats(Stats), Corpus.FormatStats(Stats))
end)

Test("scan : lignes inconnues regroupées par modèle, lignes comprises échantillonnées", function()
	ResetScan()
	WowApiItemTooltips["item:1"] = { "Casque A", "Équipé : Fait une chose de 12 étrange.", EMPTY_SOCKET_RED }
	WowApiItemTooltips["item:2"] = { "Casque B", "Équipé : Fait une chose de 30 étrange." }
	Equal(PawnScan.RecordItem("item:1", 1), "nok", "objet 1")
	Equal(PawnScan.RecordItem("item:2", 2), "nok", "objet 2")
	local Entry = PawnScanResults.unknown["Équipé : Fait une chose de # étrange."]
	Equal(Entry.count, 2, "nombre")
	Equal(Entry.example, 1, "exemple")
	Equal(Entry.line, "Équipé : Fait une chose de 12 étrange.", "ligne réelle")
	Equal(PawnScanResults.parsed[EMPTY_SOCKET_RED].stats, "RedSocket=1", "ligne comprise")
	Equal(PawnScanResults.summary.scanned, 2, "objets analysés")
	Equal(PawnScanResults.socketedExample, 1, "objet à châsses")
end)

Test("scan : un objet qui ne répond jamais est abandonné après 3 essais", function()
	ResetScan()
	local Calls = 0
	local RealGetItemInfo = GetItemInfo
	GetItemInfo = function() Calls = Calls + 1 return nil end
	PawnScan.Start("range", 5, 5)
	local Now, Steps = 0, 0
	while PawnScan.Step(Now) do
		Now, Steps = Now + 0.25, Steps + 1
		assert(Steps < 100, "le scan ne se termine pas")
	end
	GetItemInfo = RealGetItemInfo
	PawnScan.Stop()
	Equal(Calls, 3, "appels à GetItemInfo")
	Equal(#WowApiHyperlinks, 1, "amorçage par infobulle cachée")
	Equal(WowApiHyperlinks[1], "item:5", "lien amorcé")
end)

Test("scan : reprise après /reload", function()
	ResetScan()
	for ID = 10, 12 do
		WowApiItems[ID] = { "Casque " .. ID, "INVTYPE_HEAD" }
		WowApiItemTooltips["item:" .. ID] = { "Casque " .. ID, INVTYPE_HEAD }
	end
	PawnScan.Start("range", 10, 12)
	PawnScan.Step(0)
	PawnScan.Stop()
	PawnScan.Command("")
	Equal(PawnScanResults.state.next, 11, "position reprise")
	while PawnScan.Step(0) do end
	PawnScan.Stop()
	Equal(PawnScanResults.summary.scanned, 3, "objets analysés")
end)

Test("scan : un pic de latence ne traite pas plus d'une seconde d'entrées", function()
	ResetScan()
	for ID = 100, 200 do
		WowApiItems[ID] = { "Bague", "INVTYPE_FINGER" }
		WowApiItemTooltips["item:" .. ID] = { "Bague", INVTYPE_FINGER }
	end
	PawnScan.Start("range", 100, 200)
	PawnScan.OnUpdate(30)
	Equal(PawnScanResults.state.next, 100 + PawnScan.ItemsPerSecond, "position")
	PawnScan.Stop()
end)

Test("scan : les objets non équipables sont ignorés", function()
	ResetScan()
	WowApiItems[20] = { "Sac", "INVTYPE_BAG" }
	WowApiItems[21] = { "Potion", "" }
	PawnScan.Start("range", 20, 21)
	while PawnScan.Step(0) do end
	PawnScan.Stop()
	Equal(PawnScanResults.summary.scanned, 0, "objets analysés")
end)

Test("scan : écart avec GetItemStats", function()
	ResetScan()
	WowApiItemTooltips["item:300"] = { "Bottes", INVTYPE_FEET }
	GetItemStats = function() return { ITEM_MOD_STAMINA_SHORT = 15 } end
	PawnScan.RecordItem("item:300", 300)
	GetItemStats = nil
	Equal(PawnScanResults.mismatch["300 Stamina"], "jeu 15, Pawn 0")
end)

Test("scan : mode gemmes", function()
	ResetScan()
	local RealLevels, RealMeta = PawnGemQualityLevels, PawnMetaGemQualityLevels
	PawnGemQualityLevels = { { 0, { { ID = 40000, R = true, Stats = { Strength = 12 } } } } }
	PawnMetaGemQualityLevels = { { 0, { { ID = 41285, Stats = { CritRating = 21 } } } } }
	WowApiItems[999] = { "Plastron", "INVTYPE_CHEST" }
	PawnScan.Start("gems", 1, 0, 999)
	PawnScan.Stop()
	PawnGemQualityLevels, PawnMetaGemQualityLevels = RealLevels, RealMeta
	Equal(PawnScanResults.state.last, 2, "nombre de gemmes")
	Equal(PawnScan.GetEntry(PawnScanResults.state, 1).Link, "item:999:0:40000:0:0:0:0:0", "lien")
end)
```

- [ ] **Step 2 : Vérifier qu'ils échouent**

Run : `luajit tests/run.lua`

Résultat attendu : les 9 tests `scan : …` échouent (`attempt to index global 'PawnScan' (a nil value)`).

- [ ] **Step 3 : Écrire `PawnScan.lua`**

```lua
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
			if Tries == 0 then PrimerTooltip:SetHyperlink("item:" .. Entry.Require) end
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
			PrimerTooltip:SetHyperlink("item:" .. Base)
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
```

- [ ] **Step 4 : Ajouter le fichier au `.toc` et au banc**

Dans `Pawn.toc` :
- la ligne `## SavedVariables: PawnCommon` devient `## SavedVariables: PawnCommon, PawnScanResults` ;
- ajouter `PawnScan.lua` en dernière ligne, après `ClassicHawsJon.lua`.

Dans `tests/harness.lua`, ajouter `"PawnScan.lua",` à la fin de `Harness.Files`.

- [ ] **Step 5 : Lancer les tests**

Run : `luajit tests/run.lua`

Résultat attendu : `24 réussis, 0 échecs, 0 à classer (todo)`.

- [ ] **Step 6 : Commit**

```bash
git add PawnScan.lua Pawn.toc tests/harness.lua tests/unit.lua
git commit -m "Add in-game item scanner recording tooltip lines and errors

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 5 : Importer les relevés dans le jeu de tests

**Files :**
- Create: `tests/import.lua`
- Create: `tests/corpus/logs.txt` (produit par l'outil)

**Interfaces :**
- Consomme : `Corpus.Append`, `tests/data/pawndebuglogs.frFR.txt`, la SavedVariable `PawnScanResults`.
- Produit :
  - `luajit tests/import.lua logs` ;
  - `luajit tests/import.lua unknown <SavedVariables/Pawn.lua>` (affiche aussi `mismatch` et `errors`) ;
  - `luajit tests/import.lua parsed <SavedVariables/Pawn.lua>`.

- [ ] **Step 1 : Écrire `tests/import.lua`**

```lua
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
```

- [ ] **Step 2 : Importer les relevés et vérifier**

```bash
mkdir -p tests/corpus
luajit tests/import.lua logs
luajit tests/import.lua logs
luajit tests/run.lua | tail -1
```

Résultat attendu :
- le premier import affiche `179 lignes ajoutées`, le second `0 lignes ajoutées` ;
- `run.lua` se termine par `24 réussis, 0 échecs, 179 à classer (todo)`.

- [ ] **Step 3 : Commit**

```bash
git add tests/import.lua tests/corpus/logs.txt
git commit -m "Add corpus import tool and the recorded in-game lines (unclassified)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 6 : Vérification en jeu n° 1 — scan de référence (utilisateur)

**Files :**
- Create: `tests/corpus/scan.txt` (produit par l'outil)

L'exécutant **s'arrête** et transmet les instructions suivantes, puis attend le retour de l'utilisateur.

- [ ] **Step 1 : Instructions à transmettre**

> 1. Lance WoW (ou fais `/reload`). Si BugSack signale une erreur `Pawn`, colle-la-moi.
> 2. Tape `/run print(GetItemStats)` et note le résultat (`function: …` ou `nil`).
> 3. Petit scan : `/pawnscan 40000 40100`, attends environ 30 secondes, puis `/pawnscan status`. Note la ligne affichée.
> 4. Si le nombre d'objets analysés est supérieur à 0, lance le scan complet : `/pawnscan 1 56000`. Il dure environ 1 h 30 au premier passage, et tu peux faire autre chose pendant ce temps.
>    - En cas de déconnexion : reconnecte-toi et tape `/pawnscan` ; le scan reprend.
>    - En cas de saccades : `/pawnscan speed 5`.
> 5. À la fin (message « scan terminé »), tape `/reload`, puis **Échap → Quitter le jeu**. C'est ce qui écrit `WTF/Account/<COMPTE>/SavedVariables/Pawn.lua`.
> 6. Dis-moi : le résultat de l'étape 2, la ligne de l'étape 3, et le compte utilisé.

- [ ] **Step 2 : Si le petit scan donne 0 objet analysé**

Ne pas lancer le scan complet. Chercher la cause avec le skill `superpowers:systematic-debugging`, en partant de `PawnScanResults.errors` et de BugSack.

- [ ] **Step 3 : Importer le scan**

```bash
SV="/mnt/stock/Games/World of Warcraft/WTF/Account/<COMPTE>/SavedVariables/Pawn.lua"
luajit tests/import.lua unknown "$SV"
```

Résultat attendu : `N lignes ajoutées à tests/corpus/scan.txt`. Noter les lignes `ÉCART` et `ERREUR` affichées.

Chaque `ERREUR` est une incompatibilité possible avec !!!ClassicAPI. La traiter avec `superpowers:systematic-debugging` : un correctif minimal dans le code de la 2.8.11, commenté et commité à part, comme celui de `PawnGetClassInfo`.

Ne **pas** importer `parsed` à ce stade : ce sont encore les motifs Wrath Classic qui sont actifs.

- [ ] **Step 4 : Commit**

```bash
git add tests/corpus/scan.txt
git commit -m "Add baseline in-game scan: real frFR tooltip lines (unclassified)

GetItemStats: <résultat de l'étape 2>

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 7 : Générer le jeu de tests à partir des données du client

**Files :**
- Create: `tests/gen_corpus.lua`
- Create: `tests/corpus/globalstrings.txt`, `itemsubclass.txt`, `spells.txt`, `enchants.txt` (produits par l'outil)

**Interfaces :**
- Consomme : `tests/data/*.frFR.*`, `Corpus.Append`.
- Produit : `luajit tests/gen_corpus.lua`. Le script n'ajoute que les textes absents, donc on peut le relancer sans écraser les classements.

- [ ] **Step 1 : Écrire `tests/gen_corpus.lua`**

```lua
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
	{ Equip .. Render(ITEM_MOD_CRIT_MELEE_RATING, 20), "CritRating=20" },
	{ Equip .. Render(ITEM_MOD_CRIT_RANGED_RATING, 20), "CritRating=20" },
	{ Equip .. Render(ITEM_MOD_CRIT_SPELL_RATING, 20), "CritRating=20" },
	{ Equip .. Render(ITEM_MOD_HIT_RATING, 20), "HitRating=20" },
	{ Equip .. Render(ITEM_MOD_HIT_MELEE_RATING, 20), "HitRating=20" },
	{ Equip .. Render(ITEM_MOD_HIT_RANGED_RATING, 20), "HitRating=20" },
	{ Equip .. Render(ITEM_MOD_HIT_SPELL_RATING, 20), "HitRating=20" },
	{ Equip .. Render(ITEM_MOD_HASTE_RATING, 20), "HasteRating=20" },
	{ Equip .. Render(ITEM_MOD_HASTE_MELEE_RATING, 20), "HasteRating=20" },
	{ Equip .. Render(ITEM_MOD_HASTE_RANGED_RATING, 20), "HasteRating=20" },
	{ Equip .. Render(ITEM_MOD_HASTE_SPELL_RATING, 20), "HasteRating=20" },
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
```

- [ ] **Step 2 : Générer et constater l'état de départ**

```bash
luajit tests/gen_corpus.lua
luajit tests/gen_corpus.lua   # second run: "0 cas ajoutés" partout
luajit tests/run.lua | tail -3
```

Résultat attendu :
- `run.lua` échoue (code 1). C'est la table Wrath Classic de la 2.8.11 qui est encore active, donc beaucoup de cas de `globalstrings.txt` sont `non comprise` ou mal lus ;
- `spells.txt` et `enchants.txt` sont en `todo`.

- [ ] **Step 3 : Commit**

```bash
git add tests/gen_corpus.lua tests/corpus
git commit -m "Generate test corpus from client GlobalStrings, ItemSubClass, Spell and enchant data

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 8 : Tables `PawnRegexes` et `PawnRightHandRegexes` FR

**Files :**
- Modify: `TooltipParsing.frFR.lua` (ajouter les tables à la fin)
- Modify: `tests/unit.lua` (inverser le test de l'essai en jeu)
- Modify: `tests/corpus/logs.txt`, `scan.txt`, `spells.txt`, `enchants.txt` (classement des `todo`)

**Interfaces :**
- Consomme : `PawnFrPattern`, `PawnFrEquipPattern`, `PawnFrSpellPattern`, `PawnGameConstant` / `PawnGameConstantUnwrapped` (définis dans `Core.lua`), `PawnMultipleStatsFixed` / `PawnMultipleStatsExtract`.
- Produit : `PawnRegexes` et `PawnRightHandRegexes` en FR.

**Règles de classement d'un cas `todo`** (à appliquer ligne par ligne) :

| Le texte est… | Attente |
|---|---|
| une stat permanente et sans condition du porteur, dans la liste des noms de stats (Global Constraints) | `Stat=valeur` (plusieurs stats séparées par `; `) |
| une ligne d'information sans effet (prérequis, durabilité, sac, durée, enchantement temporaire, effet de méta-gemme) | `ignored` |
| un effet que Pawn ne chiffre pas : proc, chance, pourcentage, effet de classe ou de sort nommé, compétence d'arme, vitesse de déplacement, sort de grimoire, effet conditionnel | `unhandled` |
| un nom d'objet, un texte de sort du grimoire ou un fragment coupé par l'ancien découpage (seulement dans `logs.txt`) | supprimer la ligne |

Une ligne qui mêle une stat et un effet non chiffrable (« Vitesse mineure et +6 à l'Agilité ») est `unhandled`.

- [ ] **Step 1 : Inverser le test de l'essai en jeu dans `tests/unit.lua`**

Remplacer le test `harness : l'essai en jeu se reproduit hors jeu (dégâts d'Arcanes non compris par la 2.8.11)` par :

```lua
Test("frFR : les dégâts d'Arcanes du Récolteur d'essence sont lus", function()
	local Raw, Understood, Errors = Harness.ParseLine(format(DAMAGE_TEMPLATE_WITH_SCHOOL, 83, 156, "Arcanes"))
	Equal(#Errors, 0, "erreurs")
	Equal(Understood, true, "comprise")
	Equal(Raw.MinDamage, 83, "MinDamage")
	Equal(Raw.MaxDamage, 156, "MaxDamage")
end)
```

Run : `luajit tests/run.lua tests/corpus/globalstrings.txt`

Résultat attendu : ce test échoue (`comprise : attendu true, obtenu false`).

- [ ] **Step 2 : Ajouter les tables à la fin de `TooltipParsing.frFR.lua`**

```lua
------------------------------------------------------------
-- Tooltip regexes (same row format as TooltipParsing.lua: first match wins)
------------------------------------------------------------

local Fr, FrEquip, FrSpell = PawnFrPattern, PawnFrEquipPattern, PawnFrSpellPattern
local Fixed, Extract = PawnMultipleStatsFixed, PawnMultipleStatsExtract

PawnRegexes =
{
	-- ========================================
	-- Ignored lines
	-- ========================================
	{PawnGameConstant(ITEM_QUALITY0_DESC)}, -- GlobalStrings
	{PawnGameConstant(ITEM_QUALITY1_DESC)}, -- GlobalStrings
	{PawnGameConstant(ITEM_QUALITY2_DESC)}, -- GlobalStrings
	{PawnGameConstant(ITEM_QUALITY3_DESC)}, -- GlobalStrings
	{PawnGameConstant(ITEM_QUALITY4_DESC)}, -- GlobalStrings
	{PawnGameConstant(ITEM_QUALITY5_DESC)}, -- GlobalStrings
	{PawnGameConstant(ITEM_QUALITY7_DESC)}, -- GlobalStrings
	{PawnGameConstant(ITEM_HEROIC)}, -- GlobalStrings
	{PawnGameConstant(ITEM_HEROIC_EPIC)}, -- GlobalStrings
	{Fr("ITEM_LEVEL")}, -- GlobalStrings
	{PawnGameConstant(ITEM_UNSELLABLE)}, -- GlobalStrings
	{PawnGameConstant(ITEM_SOULBOUND)}, -- GlobalStrings
	{PawnGameConstant(ITEM_BIND_ON_EQUIP)}, -- GlobalStrings
	{PawnGameConstant(ITEM_BIND_ON_PICKUP)}, -- GlobalStrings
	{PawnGameConstant(ITEM_BIND_ON_USE)}, -- GlobalStrings
	{PawnGameConstant(ITEM_BIND_TO_ACCOUNT)}, -- GlobalStrings (ITEM_ACCOUNTBOUND has the same text)
	{"^" .. PawnGameConstantUnwrapped(ITEM_UNIQUE)}, -- GlobalStrings: also ITEM_UNIQUE_MULTIPLE, ITEM_UNIQUE_EQUIPPABLE, ITEM_LIMIT_CATEGORY*
	{"^" .. PawnGameConstantUnwrapped(ITEM_BIND_QUEST)}, -- GlobalStrings
	{PawnGameConstant(ITEM_STARTS_QUEST)}, -- GlobalStrings
	{PawnGameConstant(ITEM_CONJURED)}, -- GlobalStrings
	{PawnGameConstant(ITEM_PROSPECTABLE)}, -- GlobalStrings
	{PawnGameConstant(ITEM_MILLABLE)}, -- GlobalStrings
	{PawnGameConstant(ITEM_DISENCHANT_NOT_DISENCHANTABLE)}, -- GlobalStrings
	{Fr("ITEM_DISENCHANT_MIN_SKILL")}, -- GlobalStrings; logs: "Le désenchantement nécessite Enchantement (175)"
	{PawnGameConstant(ITEM_ENCHANT_DISCLAIMER)}, -- GlobalStrings
	{PawnGameConstant(LOCKED)}, -- GlobalStrings; logs: "Verrouillé(e)"
	{PawnGameConstant(ENCRYPTED)}, -- GlobalStrings
	{PawnGameConstant(ITEM_SPELL_KNOWN)}, -- GlobalStrings
	{PawnGameConstant(RETRIEVING_ITEM_INFO)}, -- GlobalStrings; logs
	{"^%d+ charges?$"}, -- GlobalStrings: ITEM_SPELL_CHARGES "%d |4charge:charges;" (by hand: the generic form would match any "N ...")
	{PawnGameConstant(ITEM_SPELL_CHARGES_NONE)}, -- GlobalStrings
	{PawnGameConstant(INVTYPE_HEAD)}, -- GlobalStrings
	{PawnGameConstant(INVTYPE_NECK)}, -- GlobalStrings
	{PawnGameConstant(INVTYPE_SHOULDER)}, -- GlobalStrings
	{PawnGameConstant(INVTYPE_CLOAK)}, -- GlobalStrings
	{PawnGameConstant(INVTYPE_ROBE)}, -- GlobalStrings (INVTYPE_CHEST has the same text)
	{PawnGameConstant(INVTYPE_BODY)}, -- GlobalStrings
	{PawnGameConstant(INVTYPE_TABARD)}, -- GlobalStrings
	{PawnGameConstant(INVTYPE_WRIST)}, -- GlobalStrings
	{PawnGameConstant(INVTYPE_HAND)}, -- GlobalStrings
	{PawnGameConstant(INVTYPE_WAIST)}, -- GlobalStrings
	{PawnGameConstant(INVTYPE_FEET)}, -- GlobalStrings
	{PawnGameConstant(INVTYPE_LEGS)}, -- GlobalStrings
	{PawnGameConstant(INVTYPE_FINGER)}, -- GlobalStrings
	{PawnGameConstant(INVTYPE_TRINKET)}, -- GlobalStrings
	{PawnGameConstant(INVTYPE_RELIC)}, -- GlobalStrings
	{PawnGameConstant(INVTYPE_AMMO)}, -- GlobalStrings
	{PawnGameConstant(MAJOR_GLYPH)}, -- GlobalStrings
	{PawnGameConstant(MINOR_GLYPH)}, -- GlobalStrings
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
	{"|cff%x%x%x%x%x%x" .. ENCHANT_CONDITION_REQUIRES}, -- GlobalStrings: meta gem requirements ("Nécessite ...")
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
	{PawnGameConstant(INVTYPE_RANGED), "IsRanged", 1, Fixed}, -- GlobalStrings
	{PawnGameConstant(INVTYPE_RANGEDRIGHT), "IsRanged", 1, Fixed}, -- GlobalStrings
	{PawnGameConstant(INVTYPE_THROWN), "IsRanged", 1, Fixed}, -- GlobalStrings
	{PawnGameConstant(INVTYPE_WEAPON), "IsOneHand", 1, Fixed}, -- GlobalStrings
	{PawnGameConstant(INVTYPE_2HWEAPON), "IsTwoHand", 1, Fixed}, -- GlobalStrings
	{PawnGameConstant(INVTYPE_WEAPONMAINHAND), "IsMainHand", 1, Fixed}, -- GlobalStrings
	{PawnGameConstant(INVTYPE_WEAPONOFFHAND), "IsOffHand", 1, Fixed}, -- GlobalStrings (INVTYPE_SHIELD has the same text)
	{PawnGameConstant(INVTYPE_HOLDABLE), "IsFrill", 1, Fixed}, -- GlobalStrings
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
	{PawnGameConstant(EMPTY_SOCKET_RED), "RedSocket", 1, Fixed}, -- GlobalStrings
	{PawnGameConstant(EMPTY_SOCKET_YELLOW), "YellowSocket", 1, Fixed}, -- GlobalStrings
	{PawnGameConstant(EMPTY_SOCKET_BLUE), "BlueSocket", 1, Fixed}, -- GlobalStrings
	{PawnGameConstant(EMPTY_SOCKET_NO_COLOR), "PrismaticSocket", 1, Fixed}, -- GlobalStrings
	{PawnGameConstant(EMPTY_SOCKET_META), "MetaSocket", 1, Fixed}, -- GlobalStrings

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
	{"^" .. SPEED .. " ([%d%.,]+)$", "Speed"}, -- GlobalStrings: SPEED
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
```

- [ ] **Step 3 : Faire passer les tests unitaires, `globalstrings.txt` et `itemsubclass.txt`**

Run : `luajit tests/run.lua tests/corpus/globalstrings.txt tests/corpus/itemsubclass.txt`

Résultat attendu : `… réussis, 0 échecs, 0 à classer`.

Pour chaque échec, chercher le texte exact de la constante dans `tests/data/GlobalStrings.frFR.lua`, puis corriger la ligne de motif concernée. Les causes probables sont un ordre de lignes ou un texte différent de celui attendu. Ne jamais modifier une attente générée pour qu'elle colle à Pawn : c'est le client qui fait foi.

- [ ] **Step 4 : Classer `logs.txt`**

1. Lancer `luajit tests/run.lua --propose tests/corpus/logs.txt`.
2. Pour chaque ligne, décider de l'attente correcte d'après le **texte** et le tableau de classement, pas d'après la lecture proposée.
3. Remplacer `todo` dans `tests/corpus/logs.txt`, ou supprimer la ligne (nom d'objet, sort du grimoire, fragment).

Exemples :
- `+12 au score de défense et +5% à la valeur de blocage du bouclier => DefenseRating=12` ;
- `Équipé : Augmente la durée de Marteau de la justice de 0.5 sec. => unhandled` ;
- `Bottes en vignesang` : supprimée ;
- `Mana : 16` : supprimée.

Une ligne qui doit porter une stat et que Pawn ne lit pas encore demande une ligne de motif, avec la source `logs`.

- [ ] **Step 5 : Classer `spells.txt` et `enchants.txt`**

Même procédure. Les noms d'enchantements d'arme sans valeur (« Croisé », « Croque-roc 3 », « Arme de givre 2 ») sont des procs, donc `unhandled`. Les compétences d'arme (« +7 à la compétence Epée ») et les sorts qui ne portent pas sur le porteur (« Rend 12 points de vie à une cible alliée ») sont aussi `unhandled`.

- [ ] **Step 6 : Classer `scan.txt`**

Même procédure. La source d'une nouvelle ligne de motif est `scan`, et le commentaire cite l'exemple réel et le numéro d'objet (`PawnScanResults.unknown[...].example`).

- [ ] **Step 7 : Tout le banc au vert**

Run : `luajit tests/run.lua`

Résultat attendu : `… réussis, 0 échecs, 0 à classer (todo)` et code de sortie 0.

- [ ] **Step 8 : Commit**

```bash
git add TooltipParsing.frFR.lua tests/unit.lua tests/corpus
git commit -m "Replace Wrath Classic frFR tooltip regexes with patterns built from 3.3.5a client data

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 9 : Garde-fou client enUS

**Files :**
- Test: `tests/unit.lua`

- [ ] **Step 1 : Ajouter le test (avant `return Tests`)**

Il vérifie que sur un client enUS, la table de la 2.8.11 reste en place, même avec `TooltipParsing.frFR.lua` chargé.

```lua
Test("enUS : les tables d'analyse restent celles de la 2.8.11", function()
	local Env = setmetatable({ GetLocale = function() return "enUS" end }, { __index = _G })
	Env.PawnRegexes = { { "^sentinelle$" } }
	local Chunk = assert(loadfile("TooltipParsing.frFR.lua"))
	setfenv(Chunk, Env)
	Chunk()
	Equal(Env.PawnRegexes[1][1], "^sentinelle$", "PawnRegexes inchangé")
	Equal(rawget(Env, "PawnRightHandRegexes"), nil, "PawnRightHandRegexes non redéfini")
end)
```

- [ ] **Step 2 : Lancer**

Run : `luajit tests/run.lua`

Résultat attendu : 0 échec.

- [ ] **Step 3 : Commit**

```bash
git add tests/unit.lua
git commit -m "Test that enUS clients keep Pawn 2.8.11's parsing tables

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 10 : Vérification en jeu n° 2 (utilisateur), puis itération

L'exécutant **s'arrête** et transmet les instructions suivantes.

- [ ] **Step 1 : Instructions à transmettre**

> 1. En jeu (`/reload` si tu es déjà connecté) : `/pawnscan clear`, puis `/pawnscan 1 56000`. Ce passage est plus rapide, le cache étant rempli.
> 2. À la fin : `/pawnscan gems`, puis, une fois terminé, `/pawnscan enchants`.
> 3. Contrôle visuel avec Mairy :
>    - `/pawn debug on`, puis survole le **Récolteur d'essence**. Il ne doit plus y avoir ni `(?) ne comprend pas "83 - 156 points de dégâts (Arcanes)"` ni l'erreur sur la vitesse et les dégâts.
>    - Survole aussi quelques objets avec gemmes, enchantement et bonus de châsse : une valeur Pawn doit s'afficher. Pense à décocher l'option « valeurs uniquement pour les améliorations » si nécessaire.
>    - Colle-moi les lignes `(?) ne comprend pas` qui restent.
> 4. `/reload`, puis Échap → Quitter le jeu.
> 5. Dis-moi quand c'est fait.

- [ ] **Step 2 : Importer**

```bash
SV="/mnt/stock/Games/World of Warcraft/WTF/Account/<COMPTE>/SavedVariables/Pawn.lua"
luajit tests/import.lua unknown "$SV"
luajit tests/import.lua parsed "$SV"
luajit tests/run.lua
```

- [ ] **Step 3 : Relire `regression.txt`, les écarts et les erreurs**

Pour chaque ligne importée dans `regression.txt`, vérifier que la lecture de Pawn correspond au texte (bonne stat, bonne valeur). Une lecture fausse est un défaut du motif : corriger l'attente, puis la ligne de motif.

Traiter aussi chaque `ÉCART` et chaque `ERREUR`. Les erreurs se traitent avec `superpowers:systematic-debugging`.

- [ ] **Step 4 : Itérer**

S'il reste des `todo` dans `scan.txt`, des échecs ou des erreurs, reprendre la tâche 8 à partir de l'étape 6, puis cette tâche à partir de l'étape 1.

On s'arrête quand :
- le scan ne laisse que des lignes inconnues classées `unhandled` ;
- `errors` et `mismatch` sont vides ;
- `luajit tests/run.lua` passe sans `todo`.

- [ ] **Step 5 : Commit**

```bash
git add TooltipParsing.frFR.lua tests/corpus
git commit -m "Second in-game scan: classify remaining lines, add regression corpus

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 11 : Documentation

**Files :**
- Create: `CLAUDE.md`, `Readme.md` (`README.markos.md` reste tel quel)

- [ ] **Step 1 : Écrire `CLAUDE.md`**

````markdown
# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Pawn 2.8.11 as backported to WoW 3.3.5a by MarkosF (https://github.com/MarkosF/Pawn-WotLK-Fix), with French (frFR) tooltip parsing rebuilt from the 3.3.5a client's own data. It runs on a 3.3.5a client with `!!!ClassicAPI` installed. `!!!ClassicAPI` makes Pawn believe it runs on Wrath Classic (`WOW_PROJECT_ID`), and `Core.lua` forces `VgerCore.IsWrath = true`. Runtime is Lua 5.1.

## Commands

All commands run from the addon root.

- `luajit tests/run.lua` — unit tests plus every corpus file; exit code 1 on failure.
- `luajit tests/run.lua tests/corpus/X.txt` — one corpus file.
- `luajit tests/run.lua --propose tests/corpus/X.txt` — print what Pawn currently reads for each `todo` line.
- `luajit tests/gen_corpus.lua` — regenerate the corpus from `tests/data/` (adds new texts only).
- `luajit tests/import.lua logs | unknown <SV> | parsed <SV>` — import real lines; `<SV>` is `WTF/Account/<ACCOUNT>/SavedVariables/Pawn.lua`.
- In game: `/pawnscan [first last] | gems | enchants | stop | status | clear | speed <n>`, and `/pawn debug on` to print every line Pawn doesn't understand. SavedVariables are only written on `/reload` or a clean quit.

## Architecture

- `TooltipParsing.lua` builds `PawnRegexes` / `PawnRightHandRegexes` from the keyed patterns in `PawnLocal.TooltipParsing` (`#` = number).
- On frFR clients, `TooltipParsing.frFR.lua` (loaded right after it) **replaces** those tables, together with the separators, the equip/use prefixes, `PawnLocal.TooltipParsing.SocketBonusPrefix` and the decimal separators. The upstream frFR patterns come from Wrath Classic and don't match 3.3.5a text.
- Most FR patterns are built at load time from the client's GlobalStrings via `PawnFrFormatToPattern` / `PawnFrPattern` / `PawnFrEquipPattern` / `PawnFrSpellPattern`.
- `Pawn.lua`: `PawnGetStatsFromTooltip` → `PawnLookForSingleStat`. On frFR it turns non-breaking spaces into spaces before matching. Rows are `{pattern, Stat, N, Source, ...}`.
- `PawnScan.lua` drives `PawnGetStatsForItemLink` over item IDs, gems and enchants, and stores unknown and parsed line templates and Lua errors in `PawnScanResults`.
- `tests/harness.lua` loads the real addon files under LuaJIT with `tests/wowapi.lua` stubs and the client constants in `tests/data/GlobalStrings.frFR.lua`.

## Rules

- Every FR pattern must come from real data (`tests/data/` client extracts, or lines seen in game) and cite its source in a comment. Never copy patterns from other Pawn versions (including this one's `Localization.frFR.lua`) or write French text from memory.
- Never retype client text into corpus files; generate it.
- Use the Wrath stat names valued by `ClassicHawsJon.lua` (`SpellPower`, `CritRating`, `HitRating`, `HasteRating`, `Armor`…). Spell-specific rating lines count as the combined rating.
- Lua patterns are byte-based: never put an accented letter inside `[...]` or match it with `.`.
- Fixes for `!!!ClassicAPI` incompatibilities stay minimal, commented, and in their own commit (see `PawnGetClassInfo`).
- `tests/data/` was extracted from `Data/frFR/*.MPQ` with a throwaway Python + `mpyq` script. The field numbers used: `Spell.dbc` description 172, `SpellItemEnchantment.dbc` text 16, `ItemSubClass.dbc` name 12.
````

- [ ] **Step 2 : Écrire `Readme.md`**

```markdown
# Pawn 2.8.11 — client WoW 3.3.5a en français

Le portage de Pawn 2.8.11 vers 3.3.5a par MarkosF ([Pawn-WotLK-Fix](https://github.com/MarkosF/Pawn-WotLK-Fix), voir `README.markos.md`), avec une lecture des infobulles **frFR** refaite à partir des données réelles du client 3.3.5a et vérifiée en jeu.

- Nécessite **!!!ClassicAPI**.
- `/pawnscan` vérifie en jeu que Pawn comprend les infobulles. Voir `CLAUDE.md`.
- Documentation d'origine : [Readme.htm](Readme.htm).
```

- [ ] **Step 3 : Vérification finale**

```bash
luajit tests/run.lua
for f in *.lua VgerCore/*.lua; do luajit -b "$f" /dev/null || echo "ERREUR $f"; done
git status --short
```

Résultat attendu : 0 échec et 0 `todo`, aucune ligne `ERREUR`, et `git status` n'affiche que `CLAUDE.md` et `Readme.md`.

- [ ] **Step 4 : Commit**

```bash
git add CLAUDE.md Readme.md
git commit -m "Document the frFR fork of the 2.8.11 backport, its tests and the in-game scanner

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```
