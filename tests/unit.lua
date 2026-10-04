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

Test("corpus : une fin de ligne s'écrit \\n et se relit", function()
	Equal(Corpus.Escape("a|r\n  |cffb"), "a|r\\n  |cffb", "échappement")
	Equal(Corpus.Unescape("a|r\\n  |cffb"), "a|r\n  |cffb", "retour")
	local Case = Corpus.ParseCase("x|r\\n  y || d\\ne => ignored")
	Equal(Case.Left, "x|r\n  y", "gauche")
	Equal(Case.Right, "d\ne", "droite")
	Equal(Case.Text, "x|r\\n  y || d\\ne", "texte tel qu'écrit")
end)

Test("corpus : Append échappe les fins de ligne et reconnaît le doublon", function()
	local Path = os.tmpname()
	os.remove(Path)
	local Text = "ligne A\nligne B"
	Equal(Corpus.Append(Path, { { Text = Text, Expect = "todo" } }), 1, "premier ajout")
	Equal(Corpus.Append(Path, { { Text = Text, Expect = "todo" } }), 0, "doublon")
	local File = assert(io.open(Path, "r"))
	local Content = File:read("*a")
	File:close()
	Equal(Content, "ligne A\\nligne B => todo\n", "contenu du fichier")
	local Cases = Corpus.ReadFile(Path)
	Equal(#Cases, 1, "un seul cas")
	Equal(Cases[1].Left, Text, "texte relu")
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

Test("frFR : les dégâts d'Arcanes du Récolteur d'essence sont lus", function()
	local Raw, Understood, Errors = Harness.ParseLine(format(DAMAGE_TEMPLATE_WITH_SCHOOL, 83, 156, "Arcanes"))
	Equal(#Errors, 0, "erreurs")
	Equal(Understood, true, "comprise")
	Equal(Raw.MinDamage, 83, "MinDamage")
	Equal(Raw.MaxDamage, 156, "MaxDamage")
end)

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
	Equal(PawnSeparatorIgnorePrefixes[2], (gsub(ITEM_SPELL_TRIGGER_ONEQUIP, "\194\160", " ")), "Équipé :")
	Equal(PawnSeparatorIgnorePrefixes[2]:find("\194\160", 1, true), nil, "pas d'espace insécable")
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

-- date() is a client global (os.date is not available in game); the offline fakes don't define it.
date = date or os.date

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
	-- The socket line comes first: Pawn ignores unknown lines before the first understood line.
	WowApiItemTooltips["item:1"] = { "Casque A", EMPTY_SOCKET_RED, "Équipé : Fait une chose de 12 étrange." }
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
	local Mismatch = PawnScanResults.mismatch["300 Stamina"]
	Equal(Mismatch, "jeu 15, Pawn 0")
end)

-- In game (scan of 2026-10-04, item 31432: crit 7 and spell crit 6), GetItemStats also counts the general rating under each
-- restricted key: CRIT 7, CRIT_MELEE 7, CRIT_RANGED 7, CRIT_SPELL 13.  That is not a reading error.
Test("scan : GetItemStats compte aussi le score général dans les clés réservées", function()
	ResetScan()
	local Equip = ITEM_SPELL_TRIGGER_ONEQUIP .. " "
	WowApiItemTooltips["item:31432"] = { "Bottes", INVTYPE_FEET, Equip .. format(ITEM_MOD_CRIT_RATING, 7), Equip .. format(ITEM_MOD_CRIT_SPELL_RATING, 6) }
	GetItemStats = function() return { ITEM_MOD_CRIT_RATING_SHORT = 7, ITEM_MOD_CRIT_MELEE_RATING_SHORT = 7,
		ITEM_MOD_CRIT_RANGED_RATING_SHORT = 7, ITEM_MOD_CRIT_SPELL_RATING_SHORT = 13 } end
	PawnScan.RecordItem("item:31432", 31432)
	GetItemStats = nil
	Equal(next(PawnScanResults.mismatch), nil, "écart")
	-- A real difference on a restricted key is still reported.
	ResetScan()
	WowApiItemTooltips["item:31433"] = { "Bottes", INVTYPE_FEET, Equip .. format(ITEM_MOD_CRIT_RATING, 7) }
	GetItemStats = function() return { ITEM_MOD_CRIT_RATING_SHORT = 7, ITEM_MOD_CRIT_SPELL_RATING_SHORT = 13 } end
	PawnScan.RecordItem("item:31433", 31433)
	GetItemStats = nil
	Equal(PawnScanResults.mismatch["31433 SpellCritRating"], "jeu 6, Pawn 0", "écart réel")
end)

Test("scan : mode gemmes", function()
	ResetScan()
	WowApiItems[999] = { "Plastron", "INVTYPE_CHEST" }
	PawnScan.Start("gems", PawnScan.FirstGemEnchantID, PawnScan.LastGemEnchantID, 999)
	PawnScan.Stop()
	local State = PawnScanResults.state
	Equal(State.next, 2686, "premier enchantement de gemme")
	Equal(State.last, 3879, "dernier enchantement de gemme")
	local First, Last = PawnScan.GetEntry(State, State.next), PawnScan.GetEntry(State, State.last)
	Equal(First.Link, "item:999:0:2686:0:0:0:0:0", "lien")
	Equal(First.Example, "gem 2686", "exemple")
	Equal(First.Require, nil, "pas de dépendance")
	Equal(Last.Link, "item:999:0:3879:0:0:0:0:0", "dernier lien")
end)

Test("enUS : les tables d'analyse restent celles de la 2.8.11", function()
	local Env = setmetatable({ GetLocale = function() return "enUS" end }, { __index = _G })
	Env.PawnRegexes = { { "^sentinelle$" } }
	local Chunk = assert(loadfile("TooltipParsing.frFR.lua"))
	setfenv(Chunk, Env)
	Chunk()
	Equal(Env.PawnRegexes[1][1], "^sentinelle$", "PawnRegexes inchangé")
	Equal(rawget(Env, "PawnRightHandRegexes"), nil, "PawnRightHandRegexes non redéfini")
end)

-- Whole-tooltip tests: run the real PawnGetStatsFromTooltip (with its post-processing) on a fake tooltip.
local function TooltipStats(Lines)
	WowApiMessages = {}
	WowApiSetTooltip("PawnTestTooltip", Lines)
	local Stats, _, Unknown = PawnGetStatsFromTooltip("PawnTestTooltip", false)
	return Stats, Unknown
end

local function SubclassName(Class, Sub)
	for Line in io.lines("tests/data/itemsubclass.frFR.txt") do
		local C, S, Name = Line:match("^(%d+)\t(%d+)\t(.+)$")
		if tonumber(C) == Class and tonumber(S) == Sub then return Name end
	end
	error("sous-classe absente de itemsubclass.frFR.txt")
end

local function FeralLine(Number)
	for Line in io.lines("tests/data/spell_templates.frFR.txt") do
		local Text = Line:match("^%d+\t(.-%sformes de f.+)$")
		if Text then return ITEM_SPELL_TRIGGER_ONEQUIP .. " " .. Text:gsub("#", tostring(Number)) end
	end
	error("ligne de puissance d'attaque en félin absente de spell_templates.frFR.txt")
end

Test("tooltip : la PA de féral d'un bâton n'est comptée qu'une fois", function()
	local Min, Max, Speed = 200, 300, 3.00
	local Stats = TooltipStats({
		"Bâton de test",
		INVTYPE_2HWEAPON,
		{ format(DAMAGE_TEMPLATE, Min, Max), SPEED .. " " .. format("%.2f", Speed) },
		FeralLine(154),
	})
	local Dps = (Min + Max) / Speed / 2
	Equal(Stats.TwoHandDps ~= nil, true, "TwoHandDps présent")
	Equal(math.abs(Stats.Dps - Dps) < 0.001, true, "Dps")
	Equal(Stats.FeralAp, PawnGetFeralAp(Stats.Dps), "FeralAp issue du Dps seulement")
end)

Test("tooltip : la valeur de blocage d'un bouclier est lue", function()
	local Stats = TooltipStats({
		"Bouclier de test",
		{ INVTYPE_SHIELD, SubclassName(4, 6) },
		format(SHIELD_BLOCK_TEMPLATE, 123),
	})
	Equal(Stats.BlockValue, 123, "BlockValue")
end)

Test("tooltip : le bonus de sertissage vert est compté", function()
	local Stats = TooltipStats({
		"Plastron de test",
		EMPTY_SOCKET_RED,
		format(ITEM_SOCKET_BONUS, "+4 Endurance"),
	})
	Equal(Stats.Stamina, 4, "Stamina du bonus")
end)

Test("tooltip : une arme à distance donne des stats de distance", function()
	local Min, Max, Speed = 100, 200, 2.50
	local Stats = TooltipStats({
		"Arc de test",
		{ INVTYPE_RANGED, SubclassName(2, 2) },
		{ format(DAMAGE_TEMPLATE, Min, Max), SPEED .. " " .. format("%.2f", Speed) },
	})
	Equal(Stats.RangedDps ~= nil and math.abs(Stats.RangedDps - (Min + Max) / Speed / 2) < 0.001, true, "RangedDps")
	Equal(Stats.RangedSpeed, Speed, "RangedSpeed")
	Equal(Stats.RangedMinDamage, Min, "RangedMinDamage")
	Equal(Stats.MeleeDps, nil, "pas de MeleeDps")
	Equal(Stats.FeralAp, nil, "pas de FeralAp")
end)

Test("frFR : une exigence de gemmes de méta est ignorée", function()
	local Stats, Unknown = TooltipStats({
		"Gemme de test",
		"+15 Endurance",
		ENCHANT_CONDITION_REQUIRES .. format(ENCHANT_CONDITION_MORE_VALUE, 2, "rouges"),
	})
	Equal(Stats.Stamina, 15, "Stamina")
	Equal(Unknown, nil, "ligne inconnue")
end)

-- Real text of the corpus case of File whose text is exactly Text as written in the file (\n escaped).
local function CorpusLeft(File, Text)
	for _, Case in ipairs((Corpus.ReadFile(File))) do
		if Case.Text == Text then return Case.Left end
	end
	error("cas absent de " .. File .. " : " .. Text)
end

-- The scanner records the pieces of a split line, not the line: the whole meta gem lines below are joined from real pieces
-- with the separator shown by the SpellItemEnchantment.dbc text of the same gem (enchants.txt).
Test("frFR : méta-gemme sertie, la stat compte et les exigences sur la même ligne sont ignorées (gemme 3642)", function()
	local Line = CorpusLeft("tests/corpus/regression.txt", "|cff808080+32 Endurance") .. " et "
		.. CorpusLeft("tests/corpus/scan.txt", "durée de Etourdir réduite de 10%|r\\n  |cff808080Nécessite au moins 3 gemmes bleue(s)")
	local Stats, Unknown = TooltipStats({ "Gemme de test", Line })
	Equal(Stats.Stamina, 32, "Stamina")
	Equal(Unknown, nil, "ligne inconnue")
end)

Test("frFR : méta-gemme sertie lue par sa ligne entière une fois les exigences retirées (gemme 2830)", function()
	local Line = CorpusLeft("tests/corpus/scan.txt", "|cff808080+12 au score de coup critique et durées des ralentissements") .. "/"
		.. CorpusLeft("tests/corpus/scan.txt", "immobilisations réduites de 10%|r\\n  |cff808080Nécessite plus de gemmes rouge(s) que de jaune(s)")
	local Stats, Unknown = TooltipStats({ "Gemme de test", Line })
	Equal(Stats.CritRating, 12, "CritRating")
	Equal(Unknown, nil, "ligne inconnue")
end)

Test("frFR : méta-gemme sans séparateur, ligne réelle entière (gemme 2689)", function()
	local Line = CorpusLeft("tests/corpus/scan.txt", "|cff808080+8 points de mana toutes les 5 sec.|r\\n  |cff808080Nécessite plus de gemmes rouge(s) que de Méta|r\\n  |cff808080Nécessite plus de gemmes jaune(s) que de rouge(s)")
	Equal(Line:find("\n", 1, true) ~= nil, true, "fin de ligne réelle")
	local Stats, Unknown = TooltipStats({ "Gemme de test", Line })
	Equal(Stats.Mp5, 8, "Mp5")
	Equal(Unknown, nil, "ligne inconnue")
end)

Test("scan : speed n'accepte qu'un nombre positif", function()
	local Before = PawnScan.ItemsPerSecond
	PawnScan.Command("speed -5")
	Equal(PawnScan.ItemsPerSecond, Before, "après speed -5")
	PawnScan.Command("speed 0")
	Equal(PawnScan.ItemsPerSecond, Before, "après speed 0")
	PawnScan.Command("speed abc")
	Equal(PawnScan.ItemsPerSecond, Before, "après speed abc")
	PawnScan.Command("speed 250")
	Equal(PawnScan.ItemsPerSecond, 250, "après speed 250")
	PawnScan.ItemsPerSecond = Before
end)

Test("scan : inspect enregistre lignes, lectures, stats et lignes inconnues", function()
	ResetScan()
	WowApiItems["item:7"] = { "Casque 7", "INVTYPE_HEAD" }
	WowApiItemTooltips["item:7"] = { "Casque 7", EMPTY_SOCKET_RED, "Équipé : Fait une chose de 12 étrange." }
	local Entry = PawnScan.Inspect("item:7")
	Equal(PawnScanResults.inspect[1], Entry, "enregistré")
	Equal(Entry.link, "item:7", "lien")
	Equal(Entry.name, "Casque 7", "nom")
	Equal(type(Entry.time), "string", "date")
	Equal(#Entry.lines, 3, "lignes")
	Equal(Entry.lines[2].left, EMPTY_SOCKET_RED, "ligne 2")
	Equal(Entry.lines[3].left, "Équipé : Fait une chose de 12 étrange.", "ligne 3")
	Equal(Entry.stats, "RedSocket=1", "stats")
	Equal(Entry.socketBonus, "", "bonus de châsse")
	Equal(Entry.unknown[1], "Équipé : Fait une chose de 12 étrange.", "ligne inconnue")
	Equal(type(Entry.values), "table", "valeurs")
	local Understood, Unknown
	for i, Read in ipairs(Entry.reads) do
		if Read.text == EMPTY_SOCKET_RED then Understood = i; Equal(Read.understood, true, "comprise"); Equal(Read.stats, "RedSocket=1", "stats lues"); Equal(Read.side, "left", "côté") end
		if Read.text == "Équipé : Fait une chose de 12 étrange." then Unknown = i; Equal(Read.understood, false, "non comprise") end
	end
	assert(Understood and Unknown and Understood < Unknown, "lectures dans l'ordre")
end)

Test("scan : inspect d'un objet absent du cache n'enregistre rien et l'amorce", function()
	ResetScan()
	Equal(PawnScan.Inspect("item:99"), nil, "résultat")
	Equal(PawnScanResults and PawnScanResults.inspect, nil, "rien d'enregistré")
	Equal(WowApiHyperlinks[1], "item:99", "lien amorcé")
end)

Test("scan : inspect garde au plus 20 entrées", function()
	ResetScan()
	WowApiItems["item:7"] = { "Casque 7", "INVTYPE_HEAD" }
	WowApiItemTooltips["item:7"] = { "Casque 7" }
	for i = 1, 25 do
		WowApiItems["item:" .. i] = { "Casque " .. i, "INVTYPE_HEAD" }
		WowApiItemTooltips["item:" .. i] = { "Casque " .. i }
		PawnScan.Inspect("item:" .. i)
	end
	Equal(#PawnScanResults.inspect, 20, "nombre")
	Equal(PawnScanResults.inspect[1].name, "Casque 6", "le plus ancien restant")
	Equal(PawnScanResults.inspect[20].name, "Casque 25", "le plus récent")
end)

Test("scan : inspect accepte un lien collé et un numéro", function()
	ResetScan()
	WowApiItems["item:7"] = { "Casque 7", "INVTYPE_HEAD" }
	WowApiItemTooltips["item:7"] = { "Casque 7" }
	PawnScan.Command("inspect |cff0070dd|Hitem:7|h[Casque 7]|h|r")
	PawnScan.Command("inspect 7")
	PawnScan.Command("inspect item:7")
	Equal(#PawnScanResults.inspect, 3, "trois entrées")
	for i = 1, 3 do Equal(PawnScanResults.inspect[i].link, "item:7", "lien " .. i) end
	PawnScan.Command("inspect n'importe quoi")
	Equal(#PawnScanResults.inspect, 3, "argument invalide ignoré")
end)

Test("équipement : un bijou sans stats lisibles compte dans le niveau moyen (pas de GetDetailedItemLevelInfo en 3.3.5a)", function()
	ResetScan()
	WowApiItems["item:7"] = { "Bijou 7", "INVTYPE_TRINKET" }
	local OriginalLink, OriginalID, OriginalSlotData = GetInventoryItemLink, GetInventoryItemID, PawnGetItemDataForInventorySlot
	GetInventoryItemLink = function(Unit, Slot) if Slot == 13 then return "item:7" end end
	GetInventoryItemID = function(Unit, Slot) if Slot == 13 then return 7 end end
	PawnGetItemDataForInventorySlot = function() return nil end -- Pawn often reads no stats on trinkets
	local Ok, Values, Count, AverageItemLevel = pcall(PawnGetInventoryItemValues, "player")
	GetInventoryItemLink, GetInventoryItemID, PawnGetItemDataForInventorySlot = OriginalLink, OriginalID, OriginalSlotData
	assert(Ok, tostring(Values))
	Equal(AverageItemLevel, math.floor(100 / 17 + .05), "niveau moyen") -- GetItemInfo stub: item level 100; 17 slots with the ranged slot
end)

-- ITEM_MOD_* numbers of the rating effects of SpellItemEnchantment.dbc (tests/data/enchant_stats.frFR.txt).  The texts that
-- name the attack type attest them: 2506 "+28 au score de critique en mêlée" = 19, 2523 "+30 au score de toucher à distance" = 17,
-- 3607 "+40 au score de hâte à distance" = 29, 3608 "+40 au score de coup critique à distance" = 20; general ratings 31, 32, 36.
local EnchantRatingStats = { [17] = "RangedHitRating", [19] = "MeleeCritRating", [20] = "RangedCritRating",
	[29] = "RangedHasteRating", [31] = "HitRating", [32] = "CritRating", [36] = "HasteRating" }
local EnchantRatingFamily = { [16] = "HitRating", [17] = "HitRating", [18] = "HitRating", [31] = "HitRating",
	[19] = "CritRating", [20] = "CritRating", [21] = "CritRating", [32] = "CritRating",
	[28] = "HasteRating", [29] = "HasteRating", [30] = "HasteRating", [36] = "HasteRating" }

Test("frFR : les scores des enchantements suivent SpellItemEnchantment.dbc", function()
	-- A text gets its restricted rating only if every enchantment with the same text (numbers aside) has the same stat number.
	local Rows, NumbersByText = {}, {}
	for Line in io.lines("tests/data/enchant_stats.frFR.txt") do
		local ID, Number, Text = Line:match("^(%d+)\t(%d+)\t%-?%d+\t(.+)$")
		Number = tonumber(Number)
		if ID and EnchantRatingFamily[Number] then
			assert(EnchantRatingStats[Number], "numéro de stat " .. Number .. " sans type connu (enchantement " .. ID .. ") : décision à prendre")
			local Key = Text:gsub("%d+", "#") .. "|" .. EnchantRatingFamily[Number]
			NumbersByText[Key] = NumbersByText[Key] or {}
			NumbersByText[Key][Number] = true
			table.insert(Rows, { ID = ID, Number = Number, Text = Text, Key = Key })
		end
	end
	local Checked = 0
	for _, Row in ipairs(Rows) do
		local Raw, Understood = Harness.ParseLine(Row.Text)
		if Understood then -- texts Pawn doesn't read are covered by enchants.txt
			local Numbers = 0
			for _ in pairs(NumbersByText[Row.Key]) do Numbers = Numbers + 1 end
			local Family = EnchantRatingFamily[Row.Number]
			local Expected = Numbers == 1 and EnchantRatingStats[Row.Number] or Family
			local Found = {}
			for Stat in pairs(Raw) do if Stat:find(Family .. "$") then table.insert(Found, Stat) end end
			Equal(table.concat(Found, ","), Expected, "enchantement " .. Row.ID .. " « " .. Row.Text .. " »")
			Checked = Checked + 1
		end
	end
	assert(Checked > 300, "lignes vérifiées : " .. Checked)
end)

Test("frFR : Lunette suit le DBC (2724 : crit à distance), Contrepoids aussi (34 : hâte générale)", function()
	local Raw = Harness.ParseLine(CorpusLeft("tests/corpus/enchants.txt", "Lunette (+28 au score de coup critique)"))
	Equal(Raw.RangedCritRating, 28, "Lunette")
	Raw = Harness.ParseLine(CorpusLeft("tests/corpus/enchants.txt", "Contrepoids (+20 au score de hâte)"))
	Equal(Raw.HasteRating, 20, "Contrepoids")
end)

Test("scanner : GetItemStats sépare les scores réservés comme Pawn", function()
	local Map = PawnScan.ItemModToStat
	for _, Kind in ipairs({ "CRIT", "HIT", "HASTE" }) do
		local General = ({ CRIT = "CritRating", HIT = "HitRating", HASTE = "HasteRating" })[Kind]
		Equal(Map["ITEM_MOD_" .. Kind .. "_RATING_SHORT"], General, Kind)
		Equal(Map["ITEM_MOD_" .. Kind .. "_SPELL_RATING_SHORT"], "Spell" .. General, Kind .. " sorts")
		Equal(Map["ITEM_MOD_" .. Kind .. "_MELEE_RATING_SHORT"], "Melee" .. General, Kind .. " mêlée")
		Equal(Map["ITEM_MOD_" .. Kind .. "_RANGED_RATING_SHORT"], "Ranged" .. General, Kind .. " distance")
	end
end)

------------------------------------------------------------
-- Rating weights by level (spec 2026-10-02). Keep these tests last: they fill PawnCommon.Scales.
------------------------------------------------------------

local RatingStats = { "HitRating", "CritRating", "HasteRating", "ExpertiseRating", "ArmorPenetration",
	"DefenseRating", "DodgeRating", "ParryRating", "BlockRating", "ResilienceRating" }

local RestrictedRatingStats = { "SpellHitRating", "SpellCritRating", "SpellHasteRating", "MeleeHitRating", "MeleeCritRating",
	"MeleeHasteRating", "RangedHitRating", "RangedCritRating", "RangedHasteRating" }

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

------------------------------------------------------------
-- Gems (spec 2026-10-04).
------------------------------------------------------------

-- The gem tables as GemsWrath.lua defines them.  unit.lua is loaded before any test creates the Classic scales, so these are
-- still the original lists (the gem quality by character level replaces them later).  They reach GemsWrath.lua's local tables.
local WrathGemLevels, WrathMetaGemLevels = PawnGemQualityLevels, PawnMetaGemQualityLevels
local function GemTableFor(Levels, ItemLevel)
	for _, Entry in ipairs(Levels) do if Entry[1] == ItemLevel then return Entry[2] end end
end
local Gems70Rare, Meta70Rare = GemTableFor(WrathGemLevels, 100), GemTableFor(WrathMetaGemLevels, 0)

-- ITEM_MOD_* numbers of the stat effects of the GemsWrath.lua gems (tests/data/gems.frFR.txt), each attested by the text of a
-- one-stat gem enchantment: 3 "+6 Agilité" (2693), 4 "+6 Force" (2691), 5 "+6 Intelligence" (2694), 6 "+6 Esprit" (2699),
-- 7 "+9 Endurance" (2698), 12 "+6 au score de défense" (2696), 13 "+8 au score d'esquive" (2730), 14 "+8 au score de parade"
-- (2754), 31 "+6 au score de toucher" (2697), 32 "+6 au score de coup critique" (2695), 35 "+8 au score de résilience" (2759),
-- 36 "+8 au score de hâte" (3270), 37 "+12 au score d'expertise" (3379), 38 "+16 à la puissance d'attaque" (2729),
-- 43 "+3 points de mana toutes les 5 sec." (2701), 44 "+12 au score de pénétration d'armure" (3378),
-- 45 "+7 à la puissance des sorts" (2690).
local GemStatNumbers = { [3] = "Agility", [4] = "Strength", [5] = "Intellect", [6] = "Spirit", [7] = "Stamina",
	[12] = "DefenseRating", [13] = "DodgeRating", [14] = "ParryRating", [31] = "HitRating", [32] = "CritRating",
	[35] = "ResilienceRating", [36] = "HasteRating", [37] = "ExpertiseRating", [38] = "Ap", [43] = "Mp5",
	[44] = "ArmorPenetration", [45] = "SpellPower" }

Test("gemmes : chaque gemme de GemsWrath.lua a les stats et la couleur du client", function()
	assert(Gems70Rare and Meta70Rare, "tables de BC introuvables dans les listes d'origine")
	local Client = {}
	for Line in io.lines("tests/data/gems.frFR.txt") do
		local ID, Color, Effects = Line:match("^(%d+)\t(%d+)\t([%d:,]*)\t")
		if ID then
			ID = tonumber(ID)
			Client[ID] = Client[ID] or {}
			table.insert(Client[ID], { Color = tonumber(Color), Effects = Effects })
		end
	end
	local Failures, Checked = {}, 0
	local function Check(Levels, Meta)
		for _, Entry in ipairs(Levels) do
			for _, Gem in ipairs(Entry[2]) do
				local What = "gemme " .. Gem.ID
				local Lines = Client[Gem.ID]
				assert(Lines, What .. " absente de gems.frFR.txt")
				Equal(#Lines, 1, What .. " : enchantements")
				local Expected = {}
				for Number, Amount in Lines[1].Effects:gmatch("(%d+):(%d+)") do
					local Stat = GemStatNumbers[tonumber(Number)]
					assert(Stat, What .. " : numéro de stat " .. Number .. " inconnu")
					Expected[Stat] = (Expected[Stat] or 0) + tonumber(Amount)
				end
				local Got = {}
				for Stat, Amount in pairs(Gem.Stats) do
					-- Spell penetration is a spell effect (type 3) in SpellItemEnchantment.dbc, not a stat effect.
					if Stat ~= "SpellPenetration" then Got[Stat] = Amount end
				end
				local GotText, ExpectedText = Corpus.FormatStats(Got), Corpus.FormatStats(Expected)
				if GotText ~= ExpectedText then
					table.insert(Failures, What .. " : stats " .. GotText .. " au lieu de " .. ExpectedText)
				end
				local Color = (Gem.R and 2 or 0) + (Gem.Y and 4 or 0) + (Gem.B and 8 or 0)
				if not Meta and Color ~= Lines[1].Color then
					table.insert(Failures, What .. " : couleur " .. Color .. " au lieu de " .. Lines[1].Color)
				end
				Checked = Checked + 1
			end
		end
	end
	Check(WrathGemLevels, false)
	Check(WrathMetaGemLevels, true)
	assert(#Failures == 0, table.concat(Failures, " ; "))
	assert(Checked > 360, "gemmes vérifiées : " .. Checked)
end)

Test("niveaux : table des scores conforme au DBC", function()
	local P = PawnRatingPointsPerPercent
	for _, Stat in ipairs(RatingStats) do Equal(#P[Stat], 80, "niveaux de " .. Stat) end
	for _, Stat in ipairs(RestrictedRatingStats) do Equal(P[Stat] and #P[Stat], 80, "niveaux de " .. Stat) end
	Equal(P.CritRating[60], 14, "crit 60")
	Equal(P.CritRating[80], 45.906, "crit 80")
	Equal(P.HitRating[70], 15.7692, "toucher 70")
	Equal(P.HitRating[80], 32.79, "toucher 80")
	Equal(P.ExpertiseRating[60], 2.5, "expertise 60")
	Equal(P.ResilienceRating[60], 28.75, "résilience 60")
	Equal(P.ResilienceRating[80], 94.2712, "résilience 80")
	-- CR_HIT_SPELL differs from CR_HIT_MELEE in value, not in how it scales with level.
	Equal(P.SpellHitRating[60], 8, "toucher des sorts 60")
	Equal(P.SpellHitRating[80], 26.232, "toucher des sorts 80")
	Equal(P.SpellCritRating[80], 45.906, "crit des sorts 80")
	Equal(P.RangedHasteRating[80], 32.79, "hâte à distance 80")
	local Count = 0
	for _ in pairs(P) do Count = Count + 1 end
	Equal(Count, #RatingStats + #RestrictedRatingStats, "nombre de stats")
end)

Test("niveaux : la table générée cite sa source", function()
	local File = assert(io.open("PawnRatingLevelFactors.lua", "r"))
	local Content = File:read("*a")
	File:close()
	for _, Needle in ipairs({ "tests/extract_ratings.py", "gtCombatRatings.dbc", "patch-frFR.MPQ", "PaperDollFrame.lua", "md5 " }) do
		assert(Content:find(Needle, 1, true), "en-tête sans « " .. Needle .. " »")
	end
end)

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
Test("niveaux : les meilleurs objets mémorisés du personnage sont oubliés quand le niveau change", function()
	ClassicScales()
	PawnClassicApplyRatingLevel(60)
	local Scale = PawnCommon.Scales[ShadowPriest]
	Scale.PerCharacterOptions = Scale.PerCharacterOptions or {}
	Scale.PerCharacterOptions["Mairy-Test"] = Scale.PerCharacterOptions["Mairy-Test"] or {}
	Scale.PerCharacterOptions["Autre-Test"] = Scale.PerCharacterOptions["Autre-Test"] or {}
	local Stub = { Stub = true }
	Scale.PerCharacterOptions["Mairy-Test"].BestItems = Stub
	Scale.PerCharacterOptions["Autre-Test"].BestItems = Stub
	PawnClassicApplyRatingLevel(61)
	Equal(Scale.PerCharacterOptions["Mairy-Test"].BestItems, nil, "liste du personnage oubliée")
	Equal(Scale.PerCharacterOptions["Mairy-Test"].RatingLevel, 61, "niveau mémorisé")
	Equal(Scale.PerCharacterOptions["Autre-Test"].BestItems, Stub, "liste d'un autre personnage conservée")
	local Stub2 = { Stub = true }
	Scale.PerCharacterOptions["Mairy-Test"].BestItems = Stub2
	PawnClassicApplyRatingLevel(61)
	Equal(Scale.PerCharacterOptions["Mairy-Test"].BestItems, Stub2, "niveau inchangé : liste conservée")
	Scale.PerCharacterOptions["Autre-Test"] = nil
	PawnClassicApplyRatingLevel(60)
end)

------------------------------------------------------------
-- Restricted ratings (spec 2026-10-03).  They need the Classic scales too, so they stay after the level tests.
------------------------------------------------------------

local Hunter, Warrior, Enhancement = '"Classic":HUNTER1', '"Classic":WARRIOR1', '"Classic":SHAMAN2'

-- Copy of a scale's restricted weights at level 80; leaves the scales at level 60.
local function RestrictedAt80(ScaleName)
	PawnClassicApplyRatingLevel(80)
	local Copy = {}
	for Stat, Weight in pairs(PawnClassicRestrictedRatingWeights[ScaleName]) do Copy[Stat] = Weight end
	PawnClassicApplyRatingLevel(60)
	return Copy
end

Test("scores réservés : poids à niveau 80 selon le rôle de l'échelle", function()
	ClassicScales()
	local Shadow, S = RestrictedAt80(ShadowPriest), Level80[ShadowPriest]
	Equal(Shadow.SpellCritRating, S.CritRating, "Ombre : crit des sorts")
	Equal(Shadow.SpellHitRating, S.HitRating, "Ombre : toucher des sorts")
	Equal(Shadow.SpellHasteRating, S.HasteRating, "Ombre : hâte des sorts")
	Equal(Shadow.MeleeCritRating, 0, "Ombre : crit en mêlée")
	Equal(Shadow.RangedCritRating, 0, "Ombre : crit à distance")
	local Hunt, H = RestrictedAt80(Hunter), Level80[Hunter]
	Equal(Hunt.RangedCritRating, H.CritRating, "chasseur : crit à distance")
	Equal(Hunt.RangedHitRating, H.HitRating, "chasseur : toucher à distance")
	Equal(Hunt.RangedHasteRating, H.HasteRating, "chasseur : hâte à distance")
	Equal(Hunt.MeleeCritRating, 0, "chasseur : crit en mêlée")
	Equal(Hunt.SpellCritRating, 0, "chasseur : crit des sorts")
	local War, W = RestrictedAt80(Warrior), Level80[Warrior]
	Equal(War.MeleeCritRating, W.CritRating, "guerrier : crit en mêlée")
	Equal(War.MeleeHitRating, W.HitRating, "guerrier : toucher en mêlée")
	Equal(War.MeleeHasteRating, W.HasteRating, "guerrier : hâte en mêlée")
	Equal(War.RangedCritRating, 0, "guerrier : crit à distance")
	Equal(War.SpellCritRating, 0, "guerrier : crit des sorts")
	local Enh, E = RestrictedAt80(Enhancement), Level80[Enhancement]
	Equal(Enh.SpellCritRating, E.CritRating, "Amélioration : crit des sorts")
	Equal(Enh.MeleeCritRating, E.CritRating, "Amélioration : crit en mêlée")
	Equal(Enh.RangedCritRating, 0, "Amélioration : crit à distance")
end)

Test("scores réservés : chaque échelle Classic garde son poids général pour au moins un type", function()
	ClassicScales()
	PawnClassicApplyRatingLevel(80)
	local Count = 0
	for ScaleName, Values in pairs(Level80) do
		Count = Count + 1
		local Weights = PawnClassicRestrictedRatingWeights[ScaleName]
		assert(Weights, ScaleName .. " sans poids réservés")
		local IsHunter = PawnCommon.Scales[ScaleName].ClassID == 3
		local CasterOnly = not Values.Ap and (Values.SpellPower or 0) > 0
		for _, Rating in ipairs({ "HitRating", "CritRating", "HasteRating" }) do
			local General = Values[Rating] or 0
			local Spell, Melee, Ranged = Weights["Spell" .. Rating], Weights["Melee" .. Rating], Weights["Ranged" .. Rating]
			local What = ScaleName .. " " .. Rating
			for _, Weight in ipairs({ Spell, Melee, Ranged }) do assert(Weight == 0 or Weight == General, What .. " : poids inattendu " .. tostring(Weight)) end
			if General > 0 then assert(Spell == General or Melee == General or Ranged == General, What .. " : poids général perdu") end
			if IsHunter then Equal(Ranged, General, What .. " distance") Equal(Melee, 0, What .. " mêlée")
			else Equal(Ranged, 0, What .. " distance") end
			if CasterOnly then Equal(Spell, General, What .. " sorts") Equal(Melee, 0, What .. " mêlée") end
			if not Values.SpellPower then Equal(Spell, 0, What .. " sorts") end
		end
	end
	assert(Count > 20, "échelles Classic : " .. Count)
	PawnClassicApplyRatingLevel(60)
end)

Test("scores réservés : niveau 60, chaque poids suit la ligne de son score", function()
	ClassicScales()
	local P = PawnRatingPointsPerPercent
	for _, ScaleName in ipairs({ ShadowPriest, Hunter, Warrior }) do
		local At80 = RestrictedAt80(ScaleName)
		for _, Stat in ipairs(RestrictedRatingStats) do
			Near(PawnClassicRestrictedRatingWeights[ScaleName][Stat], At80[Stat] * (P[Stat][80] / P[Stat][60]), ScaleName .. " " .. Stat)
		end
	end
	Near(PawnClassicRestrictedRatingWeights[ShadowPriest].SpellHitRating, Level80[ShadowPriest].HitRating * (26.232 / 8), "toucher des sorts d'Ombre")
	local Weights = PawnClassicRestrictedRatingWeights[ShadowPriest]
	local Crit60 = Weights.SpellCritRating
	Weights.SpellCritRating = 123
	PawnClassicApplyRatingLevel(60)
	Equal(PawnClassicRestrictedRatingWeights[ShadowPriest].SpellCritRating, 123, "second appel au même niveau sans effet")
	PawnClassicApplyRatingLevel(61)
	PawnClassicApplyRatingLevel(60)
	Equal(PawnClassicRestrictedRatingWeights[ShadowPriest].SpellCritRating, Crit60, "retour à 60 sans cumul")
end)

local function ItemValue(Item, ScaleName) return (PawnGetItemValue(Item, 0, nil, ScaleName, false, true)) end

Test("scores réservés : valeur d'un objet dans les échelles Classic", function()
	ClassicScales()
	PawnClassicApplyRatingLevel(80)
	local Crit = Level80[ShadowPriest].CritRating
	Near(ItemValue({ SpellCritRating = 10 }, ShadowPriest), 10 * Crit, "crit des sorts, Ombre")
	Equal(ItemValue({ SpellCritRating = 10 }, Warrior), 0, "crit des sorts, guerrier")
	Near(ItemValue({ CritRating = 10 }, ShadowPriest), 10 * Crit, "crit général, Ombre")
	Near(ItemValue({ CritRating = 10 }, Warrior), 10 * Level80[Warrior].CritRating, "crit général, guerrier")
	Equal(ItemValue({ RangedCritRating = 14 }, ShadowPriest), 0, "crit à distance, Ombre (objet 7348)")
	Near(ItemValue({ RangedCritRating = 14 }, Hunter), 14 * Level80[Hunter].CritRating, "crit à distance, chasseur")
	PawnClassicApplyRatingLevel(60)
end)

Test("scores réservés : une échelle perso donne le poids du score général", function()
	ClassicScales()
	PawnCommon.Scales["Ma copie"] = { Values = { CritRating = 0.5, HitRating = 2, Stamina = 1 } }
	Equal(ItemValue({ MeleeCritRating = 10 }, "Ma copie"), 5, "crit en mêlée")
	Equal(ItemValue({ SpellHitRating = 4 }, "Ma copie"), 8, "toucher des sorts")
	Equal(ItemValue({ RangedHasteRating = 4 }, "Ma copie"), 0, "hâte sans poids")
	PawnCommon.Scales["Ma copie"].Values.CritRating = PawnIgnoreStatValue
	Equal(ItemValue({ SpellCritRating = 10, Stamina = 10 }, "Ma copie"), 0, "score général ignoré : objet inutilisable")
	PawnCommon.Scales["Ma copie"] = nil
end)

Test("scores réservés : les meilleurs objets notés avec les anciens poids sont oubliés une fois", function()
	ClassicScales()
	PawnClassicApplyRatingLevel(60)
	local Options = PawnCommon.Scales[ShadowPriest].PerCharacterOptions["Mairy-Test"]
	-- A list saved before this version, at the same level: the next login must forget it.
	local Stub = { Stub = true }
	Options.BestItems, Options.RatingWeightsVersion = Stub, nil
	PawnClassicRatingLevel = nil -- as on login
	PawnClassicApplyRatingLevel(60)
	Equal(Options.BestItems, nil, "liste notée avec les anciens poids oubliée")
	-- A list saved with the current weights is kept.
	local Stub2 = { Stub = true }
	Options.BestItems = Stub2
	PawnClassicRatingLevel = nil
	PawnClassicApplyRatingLevel(60)
	Equal(Options.BestItems, Stub2, "liste notée avec les poids actuels conservée")
end)

------------------------------------------------------------
-- Gem quality by character level (spec 2026-10-04).  They need the Classic scales, so they stay last.
------------------------------------------------------------

Test("gemmes : bleues de BC jusqu'au niveau 70, bleues de Wrath ensuite, quel que soit le niveau de l'objet", function()
	ClassicScales()
	Equal(PawnGemQualityLevels[1][2], Gems70Rare, "connexion au niveau 60 : gemmes")
	Equal(PawnMetaGemQualityLevels[1][2], Meta70Rare, "connexion au niveau 60 : méta")
	Equal(#PawnGemQualityLevels, 1, "une seule qualité")
	Equal(PawnWrathSetGemQualityForLevel(60), false, "même qualité")
	Equal(PawnWrathSetGemQualityForLevel(71), true, "71 : changement")
	Equal(PawnGemQualityLevels[1][2], PawnGemData80Rare, "71 : gemmes")
	Equal(PawnMetaGemQualityLevels[1][2], PawnMetaGemData80Rare, "71 : méta")
	Equal(PawnWrathSetGemQualityForLevel(80), false, "80 : même qualité")
	Equal(PawnWrathSetGemQualityForLevel(85), false, "85 ramené à 80")
	Equal(PawnWrathSetGemQualityForLevel(70), true, "70 : changement")
	Equal(PawnGemQualityLevels[1][2], Gems70Rare, "70 : gemmes")
	Equal(PawnMetaGemQualityLevels[1][2], Meta70Rare, "70 : méta")
	Equal(PawnWrathSetGemQualityForLevel(1), false, "1 : même qualité")
	Equal(PawnWrathSetGemQualityForLevel(nil), true, "nil ramené à 80")
	Equal(PawnWrathSetGemQualityForLevel(60), true, "retour à 60")
	-- The Gems tab and PawnGetItemValue ask for the quality of an item level: every level gets the single entry.
	Equal(PawnGetGemQualityForItem(PawnGemQualityLevels, 245), 0, "objet de niveau 245")
	Equal(PawnGetGemQualityForItem(PawnGemQualityLevels, 60), 0, "objet de niveau 60")
	Equal(PawnGetGemQualityForItem(PawnMetaGemQualityLevels, 1), 0, "méta, objet de niveau 1")
end)

Test("gemmes : au niveau 60, une châsse vaut la meilleure gemme bleue de BC, quel que soit le niveau de l'objet", function()
	ClassicScales()
	PawnClassicApplyRatingLevel(60)
	local Ignore = PawnCommon.IgnoreGemsWhileLeveling
	PawnCommon.IgnoreGemsWhileLeveling = false
	-- Without a socket bonus, Pawn values a socket with the best gem of any color.
	local Best = PawnFindBestGems(ShadowPriest, Gems70Rare)
	assert(Best > 0, "meilleure gemme de BC : " .. tostring(Best))
	local Socket = { RedSocket = 1 }
	Near((PawnGetItemValue(Socket, 105, nil, ShadowPriest, false, true)), Best, "objet de niveau 105")
	Near((PawnGetItemValue(Socket, 60, nil, ShadowPriest, false, true)), Best, "objet de niveau 60")
	PawnCommon.IgnoreGemsWhileLeveling = true
	Equal((PawnGetItemValue(Socket, 105, nil, ShadowPriest, false, true)), 0, "option cochée : châsse ignorée")
	PawnCommon.IgnoreGemsWhileLeveling = Ignore
end)

Test("gemmes : passage de 70 à 71, les meilleures gemmes de toutes les échelles changent", function()
	ClassicScales()
	local Frame = PawnClassicRatingLevelFrame
	local OnEvent = Frame:GetScript("OnEvent")
	OnEvent(Frame, "PLAYER_LEVEL_UP", 70)
	PawnCommon.Scales["Ma copie"] = { Values = { SpellPower = 1, Stamina = 0.5 } }
	PawnRecalculateScaleTotal("Ma copie")
	local BC = PawnFindBestGems("Ma copie", Gems70Rare, true, false, false)
	Near(PawnScaleBestGems["Ma copie"].RedSocketValue[0], BC, "70 : rouge de BC, échelle perso")
	OnEvent(Frame, "PLAYER_LEVEL_UP", 71)
	local Wrath = PawnFindBestGems("Ma copie", PawnGemData80Rare, true, false, false)
	assert(Wrath > BC, "rouge de Wrath " .. Wrath .. ", rouge de BC " .. BC)
	Near(PawnScaleBestGems["Ma copie"].RedSocketValue[0], Wrath, "71 : rouge de Wrath, échelle perso")
	Near(PawnScaleBestGems[ShadowPriest].PrismaticSocketValue[0], (PawnFindBestGems(ShadowPriest, PawnGemData80Rare)), "71 : Ombre")
	PawnCommon.Scales["Ma copie"] = nil
	PawnRecalculateScaleTotal("Ma copie") -- forgets its best gems
	OnEvent(Frame, "PLAYER_LEVEL_UP", 60)
	Near(PawnScaleBestGems[ShadowPriest].PrismaticSocketValue[0], (PawnFindBestGems(ShadowPriest, Gems70Rare)), "retour à 60 : Ombre")
end)

Test("gemmes : sans PawnWrathSetGemQualityForLevel, la montée de niveau ajuste les scores sans erreur", function()
	ClassicScales()
	local Set = PawnWrathSetGemQualityForLevel
	PawnWrathSetGemQualityForLevel = nil
	local Frame = PawnClassicRatingLevelFrame
	local Ok, Err = pcall(Frame:GetScript("OnEvent"), Frame, "PLAYER_LEVEL_UP", 75)
	PawnWrathSetGemQualityForLevel = Set
	assert(Ok, tostring(Err))
	Equal(PawnClassicRatingLevel, 75, "scores ajustés")
	Equal(PawnGemQualityLevels[1][2], Gems70Rare, "gemmes inchangées")
	Frame:GetScript("OnEvent")(Frame, "PLAYER_LEVEL_UP", 60)
end)

Test("gemmes : les meilleurs objets notés avant les châsses supposées sont oubliés une fois", function()
	ClassicScales()
	PawnClassicApplyRatingLevel(60)
	local Scale = PawnCommon.Scales[ShadowPriest]
	Scale.PerCharacterOptions = Scale.PerCharacterOptions or {}
	Scale.PerCharacterOptions["Mairy-Test"] = Scale.PerCharacterOptions["Mairy-Test"] or {}
	local Options = Scale.PerCharacterOptions["Mairy-Test"]
	Options.BestItems, Options.RatingWeightsVersion = { Stub = true }, 1
	PawnClassicRatingLevel = nil -- as on login
	PawnClassicApplyRatingLevel(60)
	Equal(Options.BestItems, nil, "liste notée avec la version 1 oubliée")
	assert(Options.RatingWeightsVersion > 1, "version mémorisée : " .. tostring(Options.RatingWeightsVersion))
end)

Test("gemmes : les meilleurs objets d'une échelle perso sont oubliés quand les gemmes supposées changent", function()
	ClassicScales()
	local Frame = PawnClassicRatingLevelFrame
	local OnEvent = Frame:GetScript("OnEvent")
	OnEvent(Frame, "PLAYER_LEVEL_UP", 70)
	PawnCommon.Scales["Ma copie"] = { Values = { SpellPower = 1 }, PerCharacterOptions = { ["Mairy-Test"] = {}, ["Autre-Test"] = {} } }
	local Options, Other = PawnCommon.Scales["Ma copie"].PerCharacterOptions["Mairy-Test"], PawnCommon.Scales["Ma copie"].PerCharacterOptions["Autre-Test"]
	-- A list saved before RatingWeightsVersion 2 is forgotten once, on login.
	local Stub = { Stub = true }
	Options.BestItems, Other.BestItems = Stub, Stub
	PawnClassicRatingLevel = nil -- as on login
	PawnClassicApplyRatingLevel(70)
	Equal(Options.BestItems, nil, "connexion : liste notée avant la version 2 oubliée")
	Equal(Other.BestItems, Stub, "connexion : liste d'un autre personnage conservée")
	local Stub2 = { Stub = true }
	Options.BestItems = Stub2
	PawnClassicRatingLevel = nil
	PawnClassicApplyRatingLevel(70)
	Equal(Options.BestItems, Stub2, "connexion suivante : liste conservée")
	-- Level up without a change of gems: the list stays.
	OnEvent(Frame, "PLAYER_LEVEL_UP", 69)
	Equal(Options.BestItems, Stub2, "69 : mêmes gemmes, liste conservée")
	-- 70 -> 71: Wrath gems, the list was scored with BC gems.
	OnEvent(Frame, "PLAYER_LEVEL_UP", 71)
	Equal(Options.BestItems, nil, "71 : liste oubliée")
	Equal(Other.BestItems, Stub, "71 : liste d'un autre personnage conservée")
	PawnCommon.Scales["Ma copie"] = { Values = { SpellPower = 1 } } -- no PerCharacterOptions at all
	OnEvent(Frame, "PLAYER_LEVEL_UP", 60)
	PawnCommon.Scales["Ma copie"] = nil
	PawnRecalculateScaleTotal("Ma copie")
end)

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
return Tests
