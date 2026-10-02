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

return Tests
