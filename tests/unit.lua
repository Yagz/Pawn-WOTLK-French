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

return Tests
