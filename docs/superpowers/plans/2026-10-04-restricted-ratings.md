# Scores réservés aux sorts, à la mêlée ou à la distance — plan d'implémentation

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Lire les scores de toucher, de coup critique et de hâte réservés aux sorts, à la mêlée ou à la distance comme des stats à part (`SpellCritRating`, `MeleeCritRating`, `RangedCritRating`…), et leur donner dans les échelles Classic le poids de leur type (0 si le type ne sert pas à l'échelle).

**Architecture:** `Pawn.lua` déclare les 9 stats réservées et leur score général, et `PawnGetItemValue` passe par `PawnGetStatWeight` : poids réservé de l'échelle Classic s'il existe, sinon poids du score général. `ClassicHawsJon.lua` calcule les poids réservés de chaque échelle Classic à partir de ses propres valeurs au niveau 80 (rôle déduit de `Ap` et `SpellPower`). Il les range dans `PawnClassicRestrictedRatingWeights` et les ajuste au niveau avec les nouvelles lignes de `PawnRatingLevelFactors.lua`. `TooltipParsing.frFR.lua` produit les stats réservées. Pour les enchantements, le choix s'appuie sur une extraction de `SpellItemEnchantment.dbc`.

**Tech Stack:** Lua 5.1 (client 3.3.5a), LuaJIT pour les tests (`luajit tests/run.lua`), Python 3 + `mpyq` via `uv`.

**Spec:** `docs/superpowers/specs/2026-10-03-restricted-ratings-design.md`

## Global Constraints

- Les 9 stats réservées, exactement : `SpellHitRating`, `SpellCritRating`, `SpellHasteRating`, `MeleeHitRating`, `MeleeCritRating`, `MeleeHasteRating`, `RangedHitRating`, `RangedCritRating`, `RangedHasteRating`.
- Le type physique secondaire de la classe vaut 0 : la mêlée pour le chasseur (`ClassID` 3), la distance pour toutes les autres classes.
- Les échelles personnelles, copiées ou importées ne sont jamais modifiées. Une stat réservée y prend le poids du score général.
- Si le score général est marqué « ignorer » (`<= PawnIgnoreStatValue`), un objet qui porte la stat réservée reste inutilisable.
- `Scale.Values`, le total de normalisation, la sauvegarde, l'onglet Poids et l'onglet Comparer ne changent pas. Le score général reste fusionné par `PawnCombineStats`.
- Au niveau 80, chaque poids réservé est égal au bit près au poids relevé : on garde la formule `Poids80 * (P[Stat][80] / P[Stat][Niveau])` avec ses parenthèses.
- Chaque motif FR vient des données réelles et cite sa source. Aucun texte du client n'est retapé dans le corpus : les attentes sont réécrites par script.
- Lua est byte-based : pas de lettre accentuée dans `[...]` ni avec `.`.
- Les tests qui remplissent `PawnCommon.Scales` restent à la fin de `tests/unit.lua`.
- Les correctifs `!!!ClassicAPI` ne sont pas concernés et ne doivent pas être mêlés à ces commits.
- Les messages de commit sont en anglais et se terminent par `Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>`.

## Écarts assumés par rapport à la spec (relevés pendant la préparation)

1. **Les tables HawsJon Wrath n'ont qu'un poids par score** (décision de l'utilisateur, 2026-10-04). La spec suppose que la table passée à `PawnAddPluginScaleFromTemplate` sépare `CritRating` (physique) et `SpellCritRating` (sorts). C'est vrai dans la branche Classic/BC de `ClassicHawsJon.lua`, mais Pawn utilise la branche Wrath (`VgerCore.IsWrath` forcé), où aucune des 31 échelles n'a de `Spell*Rating`. Le type auquel s'applique le poids combiné se déduit des valeurs de l'échelle :
   - échelle « sorts » si `SpellPower > 0` ;
   - échelle « physique » si `Ap > 0` ou si `SpellPower` est absent. Le type physique est la distance pour le chasseur, la mêlée pour les autres classes ;
   - une échelle peut être les deux (Amélioration, Protection et Vindicte paladin, Farouche tank) : sorts **et** type physique prennent alors le poids combiné ;
   - tout autre type prend 0.
2. **Contrepoids reste en hâte générale.** `SpellItemEnchantment.dbc` donne pour l'enchantement 34 « Contrepoids (+20 au score de hâte) » le numéro de stat 36 (hâte générale). Lunette 2724 « Lunette (+28 au score de coup critique) » porte le numéro 20 (crit à distance) et passe à `RangedCritRating`.
3. **« +# au score de coup critique » reste général.** Les enchantements 2857 et 2858 (« +2 au score de coup critique ») portent le numéro 19 (crit mêlée), les autres du même texte le 32 (crit général). Selon la règle de la spec, le motif reste en `CritRating`.
4. **Les tests de poids sont placés après les tests de niveau**, pas avant. Ils ont besoin des échelles Classic (`ClassicScales()`), et ce sont les tests qui remplissent `PawnCommon.Scales` qui doivent rester en dernier.
5. **Les valeurs enUS changent.** Les tables de lecture enUS ne bougent pas. Mais la lecture enUS d'origine produit déjà `SpellCritRating`, `SpellHitRating` et `SpellHasteRating`, qui valaient 0 en Wrath (stat fusionnée et retirée de l'échelle). Ces stats prennent désormais le poids réservé ou le poids général.
6. **Les meilleurs objets mémorisés sont oubliés une fois.** Les listes `BestItems` sauvegardées ont été notées avec les poids fusionnés, et une note mémorisée ne fait que monter. Un objet « crit des sorts » surévalué cacherait donc les vraies améliorations d'un guerrier, même au niveau 80. Une version des poids, `RatingWeightsVersion`, mémorisée à côté de `RatingLevel`, fait oublier ces listes une seule fois.
7. **Les 9 lignes de niveau sont ajoutées à `PawnRatingLevelFactors.lua`.** Le toucher des sorts n'a pas les mêmes valeurs que le toucher général (8 contre 10 au niveau 60, 26,232 contre 32,79 au niveau 80). Seul le rapport entre niveaux est le même, donc on ne peut pas réutiliser la ligne générale.
8. **Objet de vérification « crit des sorts » :** 24256 « Ceinturon de saccage », stat 21 (crit des sorts) = 20, d'après le cache des objets du client `Cache/WDB/frFR/itemcache.wdb`.

## Review Focus

- **Une classe entière dont les poids réservés valent tous 0** (classification ratée, par exemple `ClassID` absent) : chaque échelle Classic qui a un poids général > 0 doit le garder pour au moins un type. Test « chaque échelle Classic garde son poids général » (tâche 2).
- **Liste `BestItems` sauvegardée avant la mise à jour, au même niveau** : elle doit être oubliée une fois au chargement, puis conservée. Test « version des poids » (tâche 2).
- **Score général « ignoré » dans une échelle perso** : un objet portant la stat réservée doit rester inutilisable (valeur 0). Test « échelle perso » (tâche 2).
- **Allers-retours de niveau et second appel au même niveau** : les poids réservés ne doivent ni se cumuler ni changer. Test « niveau 60 » (tâche 2).
- **Enchantement au texte général mais au numéro de stat réservé** (2857/2858) : il doit rester général. Test « enchantements suivant SpellItemEnchantment.dbc » (tâche 3).

---

### Task 1 : lignes de niveau des scores réservés

**Files:**
- Modify: `tests/extract_ratings.py:30-43` (liste `STATS`)
- Regenerate: `PawnRatingLevelFactors.lua`
- Modify: `tests/unit.lua` (test « niveaux : table des scores conforme au DBC », vers la ligne 475)

**Interfaces:**
- Produces: `PawnRatingPointsPerPercent[Stat][Level]` pour les 9 stats réservées, en plus des 10 existantes. `Spell*` vient de `CR_*_SPELL`, `Melee*` de `CR_*_MELEE`, `Ranged*` de `CR_*_RANGED`.

- [ ] **Step 1 : écrire le test qui échoue**

Dans `tests/unit.lua`, remplacer le test « niveaux : table des scores conforme au DBC » par :

```lua
local RestrictedRatingStats = { "SpellHitRating", "SpellCritRating", "SpellHasteRating", "MeleeHitRating", "MeleeCritRating",
	"MeleeHasteRating", "RangedHitRating", "RangedCritRating", "RangedHasteRating" }

Test("niveaux : table des scores conforme au DBC", function()
	local P = PawnRatingPointsPerPercent
	for _, Stat in ipairs(RatingStats) do Equal(#P[Stat], 80, "niveaux de " .. Stat) end
	for _, Stat in ipairs(RestrictedRatingStats) do Equal(#P[Stat], 80, "niveaux de " .. Stat) end
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
```

- [ ] **Step 2 : lancer les tests pour voir l'échec**

Run: `luajit tests/run.lua`
Expected: `UNIT  niveaux : table des scores conforme au DBC : ... attempt to get length of field ...` ou `niveaux de SpellHitRating : attendu 80, obtenu nil`.

- [ ] **Step 3 : ajouter les lignes au script et régénérer**

Dans `tests/extract_ratings.py`, juste après `("ResilienceRating", ["CR_CRIT_TAKEN_MELEE"]),`, ajouter :

```python
    # Ratings that only apply to spells, melee or ranged attacks (PawnRestrictedRatingStats in Pawn.lua).
    ("SpellHitRating", ["CR_HIT_SPELL"]),
    ("SpellCritRating", ["CR_CRIT_SPELL"]),
    ("SpellHasteRating", ["CR_HASTE_SPELL"]),
    ("MeleeHitRating", ["CR_HIT_MELEE"]),
    ("MeleeCritRating", ["CR_CRIT_MELEE"]),
    ("MeleeHasteRating", ["CR_HASTE_MELEE"]),
    ("RangedHitRating", ["CR_HIT_RANGED"]),
    ("RangedCritRating", ["CR_CRIT_RANGED"]),
    ("RangedHasteRating", ["CR_HASTE_RANGED"]),
```

Puis, depuis la racine de l'addon :

Run: `uv run --with mpyq python tests/extract_ratings.py "../../../Data"`
Expected: `PawnRatingLevelFactors.lua écrit (valeurs : frFR/patch-frFR.MPQ, constantes : frFR/patch-frFR-3.MPQ)`

Run: `git diff --stat PawnRatingLevelFactors.lua`
Expected: uniquement des ajouts (les 10 lignes existantes ne changent pas). Relancer le script et vérifier que `git diff` ne bouge plus (reproductible).

- [ ] **Step 4 : lancer les tests**

Run: `luajit tests/run.lua`
Expected: `2296 réussis, 0 échecs, 0 à classer (todo)`. Le test « niveau 80, toutes les échelles Classic sont identiques aux poids HawsJon » doit rester vert : il prouve que la boucle de `PawnClassicApplyRatingLevel` n'écrit pas les nouvelles stats dans `Scale.Values`.

- [ ] **Step 5 : commit**

```bash
git add tests/extract_ratings.py PawnRatingLevelFactors.lua tests/unit.lua
git commit -m "Rating factors: add rows for spell, melee and ranged ratings

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 2 : poids des stats réservées et valeur d'un objet

**Files:**
- Modify: `Pawn.lua` (après `PawnIgnoreStatValue`, l. 73 ; boucles de `PawnGetItemValue`, l. ~2694 et ~2795)
- Modify: `ClassicHawsJon.lua:691-736` (bloc des poids selon le niveau)
- Modify: `tests/unit.lua` (fin du fichier, après le dernier test de niveau)

**Interfaces:**
- Consumes: `PawnRatingPointsPerPercent[Stat]` pour les 9 stats réservées (tâche 1).
- Produces:
  - `PawnRestrictedRatingStats[Stat] = GeneralStat` (Pawn.lua), table globale de 9 entrées, par exemple `SpellCritRating = "CritRating"`.
  - `PawnGetStatWeight(ScaleName, ScaleValues, Stat)` → poids (nombre ou nil). Pour une stat non réservée, renvoie `ScaleValues[Stat]`.
  - `PawnClassicRestrictedRatingWeights[ScaleFullName][Stat]` → poids au niveau du personnage, pour les 9 stats, pour chaque échelle `Provider == "Classic"`.
  - `PawnClassicRestrictedRatingsAt80(Values, ClassID)` → table des 9 poids au niveau 80.

- [ ] **Step 1 : écrire les tests qui échouent**

À la fin de `tests/unit.lua`, juste avant `return Tests` :

```lua
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
```

- [ ] **Step 2 : lancer les tests pour voir l'échec**

Run: `luajit tests/run.lua`
Expected: les 6 nouveaux tests `scores réservés : …` échouent (`attempt to index global 'PawnClassicRestrictedRatingWeights' (a nil value)`, puis valeur 0 au lieu de 5 pour l'échelle perso). Les autres restent verts.

- [ ] **Step 3 : stats réservées et poids dans `Pawn.lua`**

Juste après `PawnBigUpgradeThreshold = 100 ...` (l. 74), ajouter :

```lua

-- Fork frFR 3.3.5a: ratings that only apply to spells, melee or ranged attacks, and the general rating each one belongs to.
-- 3.3.5a items still show them apart; a scale without a weight for one uses the weight of its general rating.
PawnRestrictedRatingStats =
{
	SpellHitRating = "HitRating", SpellCritRating = "CritRating", SpellHasteRating = "HasteRating",
	MeleeHitRating = "HitRating", MeleeCritRating = "CritRating", MeleeHasteRating = "HasteRating",
	RangedHitRating = "HitRating", RangedCritRating = "CritRating", RangedHasteRating = "HasteRating",
}
```

Juste avant `function PawnGetItemValue(` (l. ~2680), ajouter :

```lua
-- Fork frFR 3.3.5a: weight of Stat in a scale.  A restricted rating (PawnRestrictedRatingStats) takes the weight the
-- Classic scales give it (PawnClassicRestrictedRatingWeights, ClassicHawsJon.lua), or else the weight of its general rating;
-- if the general rating is ignored, so is the restricted one.
function PawnGetStatWeight(ScaleName, ScaleValues, Stat)
	local General = PawnRestrictedRatingStats[Stat]
	if not General then return ScaleValues[Stat] end
	local GeneralValue = ScaleValues[General]
	if GeneralValue and GeneralValue <= PawnIgnoreStatValue then return GeneralValue end
	local Restricted = PawnClassicRestrictedRatingWeights and PawnClassicRestrictedRatingWeights[ScaleName]
	if Restricted and Restricted[Stat] then return Restricted[Stat] end
	return GeneralValue
end

```

Dans `PawnGetItemValue`, remplacer la première ligne de la boucle sur l'objet :

```lua
	for Stat, Quantity in pairs(Item) do
		ThisValue = ScaleValues[Stat]
```

par :

```lua
	for Stat, Quantity in pairs(Item) do
		ThisValue = PawnGetStatWeight(ScaleName, ScaleValues, Stat)
```

Et dans la boucle du bonus de sertissage, remplacer :

```lua
					for Stat, Quantity in pairs(SocketBonus) do
						ThisValue = ScaleValues[Stat]
```

par :

```lua
					for Stat, Quantity in pairs(SocketBonus) do
						ThisValue = PawnGetStatWeight(ScaleName, ScaleValues, Stat)
```

Le message de debug existant (`PawnLocal.ValueCalculationMessage`, avec `Stat` et `ThisValue`) affiche déjà la stat réservée et le poids utilisé.

- [ ] **Step 4 : poids réservés des échelles Classic dans `ClassicHawsJon.lua`**

Après `PawnClassicRatingLevel = nil` (l. 699), ajouter :

```lua

-- Fork frFR 3.3.5a: weights of the ratings that only apply to spells, melee or ranged attacks (PawnRestrictedRatingStats),
-- per scale name, at the character's level.  PawnGetStatWeight uses them for the Classic scales.  Not saved to disk.
PawnClassicRestrictedRatingWeights = {}

-- Level-80 restricted weights, per scale name, computed the first time each scale is adjusted.
local OriginalRestrictedWeights = {}

-- Bump when the weights change in a way that makes the best items saved per character wrong (1: restricted ratings).
local RatingWeightsVersion = 1

-- Level-80 weights of the restricted ratings of a Wrath Classic scale, from the scale's own values.  The HawsJon Wrath weights
-- have one weight per rating, for the attacks the spec uses: spells if the scale values spell power, and its physical attacks
-- (ranged for hunters, melee for everyone else) if it values attack power or not spell power.  Other attacks get 0.
function PawnClassicRestrictedRatingsAt80(Values, ClassID)
	local UsesSpells = (Values.SpellPower or 0) > 0
	local PhysicalKind
	if (Values.Ap or 0) > 0 or not UsesSpells then PhysicalKind = (ClassID == 3) and "Ranged" or "Melee" end
	local Weights = {}
	for Stat, General in pairs(PawnRestrictedRatingStats) do
		local Applies = (UsesSpells and strfind(Stat, "^Spell")) or (PhysicalKind and strfind(Stat, "^" .. PhysicalKind))
		Weights[Stat] = Applies and (Values[General] or 0) or 0
	end
	return Weights
end
```

Dans `PawnClassicApplyRatingLevel`, remplacer :

```lua
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
```

par :

```lua
			local Originals = OriginalRatingWeights[ScaleName]
			if not Originals then
				Originals = {}
				for Stat in pairs(PawnRatingPointsPerPercent) do Originals[Stat] = Scale.Values[Stat] end
				OriginalRatingWeights[ScaleName] = Originals
				OriginalRestrictedWeights[ScaleName] = PawnClassicRestrictedRatingsAt80(Scale.Values, Scale.ClassID)
			end
			for Stat, Points in pairs(PawnRatingPointsPerPercent) do
				-- Parentheses keep the factor at exactly 1 on level 80.
				if Originals[Stat] then Scale.Values[Stat] = Originals[Stat] * (Points[80] / Points[Level]) end
			end
			local Restricted = {}
			for Stat, Weight in pairs(OriginalRestrictedWeights[ScaleName]) do
				local Points = PawnRatingPointsPerPercent[Stat]
				Restricted[Stat] = Weight * (Points[80] / Points[Level])
			end
			PawnClassicRestrictedRatingWeights[ScaleName] = Restricted
```

Et remplacer :

```lua
			if CharacterOptions and CharacterOptions.RatingLevel ~= Level then
				CharacterOptions.BestItems = nil
				CharacterOptions.RatingLevel = Level
			end
```

par :

```lua
			if CharacterOptions and (CharacterOptions.RatingLevel ~= Level or CharacterOptions.RatingWeightsVersion ~= RatingWeightsVersion) then
				CharacterOptions.BestItems = nil
				CharacterOptions.RatingLevel = Level
				CharacterOptions.RatingWeightsVersion = RatingWeightsVersion
			end
```

Mettre à jour le commentaire au-dessus (« Forget them when the level changes ») :

```lua
			-- The best items saved for this character were scored with the old weights, and stored scores only ever go up,
			-- so they would hide real upgrades.  Forget them when the level or the weights change (as PawnSetStatValue does
			-- when weights change).  Other characters' lists were scored at their own levels and stay valid until they log in.
```

- [ ] **Step 5 : lancer les tests**

Run: `luajit tests/run.lua`
Expected: `2302 réussis, 0 échecs, 0 à classer (todo)` (2296 + 6). Le test existant « les meilleurs objets mémorisés du personnage sont oubliés quand le niveau change » doit rester vert.

- [ ] **Step 6 : commit**

```bash
git add Pawn.lua ClassicHawsJon.lua tests/unit.lua
git commit -m "Give spell, melee and ranged ratings their own weight in the Classic scales

The Wrath HawsJon tables have one weight per rating; the scale's own attack
power and spell power weights say which attacks it applies to. Other scales
fall back on the general rating. Saved best items are forgotten once.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 3 : lecture des scores réservés (frFR), données de SpellItemEnchantment.dbc et scanner

**Files:**
- Create: `tests/extract_enchant_stats.py`
- Create (généré) : `tests/data/enchant_stats.frFR.txt`
- Modify: `TooltipParsing.frFR.lua:235-245, 311-312, 322, 368-372, 395-397`
- Modify: `PawnScan.lua:33-44` (`PawnScan.ItemModToStat`)
- Modify: `tests/gen_corpus.lua:37-47`
- Modify (attentes réécrites par script) : `tests/corpus/globalstrings.txt`, `regression.txt`, `spells.txt`, `scan.txt`, `enchants.txt`
- Modify: `tests/unit.lua` (avant la section « Rating weights by level »)

**Interfaces:**
- Consumes: `PawnRestrictedRatingStats` (tâche 2), qui sert au script de réécriture du corpus.
- Produces: les stats réservées dans les stats lues d'un objet frFR. `tests/data/enchant_stats.frFR.txt` : une ligne par effet de stat (type 5) de `SpellItemEnchantment.dbc`, au format `ID<TAB>numéro de stat<TAB>montant<TAB>texte`.

- [ ] **Step 1 : script d'extraction de SpellItemEnchantment.dbc**

Créer `tests/extract_enchant_stats.py` :

```python
"""Extracts the stat effects of SpellItemEnchantment.dbc (frFR 3.3.5a client) into tests/data/enchant_stats.frFR.txt.

Usage, from the addon root:
    uv run --with mpyq python tests/extract_enchant_stats.py "../../../Data"

Running it again on the same client data writes the same file, byte for byte.
"""
import hashlib
import struct
import sys

from extract_ratings import read_file

DBC = "DBFilesClient\\SpellItemEnchantment.dbc"
OUTPUT = "tests/data/enchant_stats.frFR.txt"
# Fields (32-bit, from 0): 0 ID, 2-4 effect type, 5-7 effect amount (min), 11-13 effect argument, 16 frFR text.
FIELDS = 38
STAT_EFFECT = 5  # ITEM_ENCHANTMENT_TYPE_STAT: the argument is the ITEM_MOD_* stat number


def main():
    if len(sys.argv) != 2:
        sys.exit(__doc__)
    archive, data = read_file(sys.argv[1], DBC)
    magic, records, fields, record_size, _ = struct.unpack("<4s4i", data[:20])
    if magic != b"WDBC" or fields != FIELDS or record_size != FIELDS * 4:
        sys.exit("format de SpellItemEnchantment.dbc inattendu : %r %d %d" % (magic, fields, record_size))
    strings = data[20 + records * record_size:]

    def text(offset):
        return strings[offset:strings.index(b"\0", offset)].decode("utf-8")

    out = [
        "# Generated by tests/extract_enchant_stats.py: do not edit.",
        "# Source: %s from Data/%s (md5 %s)" % (DBC, archive, hashlib.md5(data).hexdigest()),
        "# Fields (32-bit, from 0): 0 ID, 2-4 effect type (5 = stat), 5-7 amount, 11-13 stat number (ITEM_MOD_*), 16 frFR text.",
        "# One line per stat effect: ID<TAB>stat number<TAB>amount<TAB>text",
    ]
    for index in range(records):
        start = 20 + index * record_size
        row = struct.unpack("<%di" % FIELDS, data[start:start + record_size])
        for effect in range(3):
            if row[2 + effect] == STAT_EFFECT:
                out.append("%d\t%d\t%d\t%s" % (row[0], row[11 + effect], row[5 + effect], text(row[16])))
    with open(OUTPUT, "w", encoding="utf-8", newline="\n") as handle:
        handle.write("\n".join(out) + "\n")
    print("%s écrit (%d effets, %s)" % (OUTPUT, len(out) - 4, archive))


if __name__ == "__main__":
    main()
```

Run: `uv run --with mpyq python tests/extract_enchant_stats.py "../../../Data"`
Expected: `tests/data/enchant_stats.frFR.txt écrit (2066 effets, frFR/patch-frFR-3.MPQ)`. Relancer, puis `git status --short tests/data` : le fichier ne doit pas changer entre les deux passes.

Run: `grep -P "^(34|2724|2857|2506|3607|3608|2523)\t" tests/data/enchant_stats.frFR.txt`
Expected : `34	36	20	Contrepoids …`, `2724	20	28	Lunette …`, `2857	19	2	+2 au score de coup critique`, `2506	19	28	…`, `3607	29	40	…`, `3608	20	40	…`, `2523	17	30	…`.

- [ ] **Step 2 : écrire les tests qui échouent**

Dans `tests/unit.lua`, juste avant le bloc `-- Rating weights by level (spec 2026-10-02)`, ajouter :

```lua
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
```

`CorpusLeft` est défini plus haut dans `unit.lua` (l. ~351). Les nouveaux tests doivent donc venir après lui. Le bloc « Rating weights by level » est déjà plus bas, ce qui convient.

- [ ] **Step 3 : lancer les tests pour voir l'échec**

Run: `luajit tests/run.lua 2>&1 | grep -v "^ECHEC" | tail -5`
Expected: les 3 nouveaux tests échouent, par exemple `enchantement 2506 « +28 au score de critique en mêlée » : attendu MeleeCritRating, obtenu CritRating`, `Lunette : attendu 28, obtenu nil`, `CRIT sorts : attendu SpellCritRating, obtenu CritRating`.

- [ ] **Step 4 : produire les stats réservées dans `TooltipParsing.frFR.lua`**

Remplacer les lignes 235-237 :

```lua
	{FrEquip("ITEM_MOD_CRIT_MELEE_RATING"), "MeleeCritRating"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_CRIT_RANGED_RATING"), "RangedCritRating"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_CRIT_SPELL_RATING"), "SpellCritRating"}, -- GlobalStrings (a separate rating server-side: PawnRestrictedRatingStats)
```

les lignes 239-241 :

```lua
	{FrEquip("ITEM_MOD_HIT_MELEE_RATING"), "MeleeHitRating"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_HIT_RANGED_RATING"), "RangedHitRating"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_HIT_SPELL_RATING"), "SpellHitRating"}, -- GlobalStrings
```

les lignes 243-245 :

```lua
	{FrEquip("ITEM_MOD_HASTE_MELEE_RATING"), "MeleeHasteRating"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_HASTE_RANGED_RATING"), "RangedHasteRating"}, -- GlobalStrings
	{FrEquip("ITEM_MOD_HASTE_SPELL_RATING"), "SpellHasteRating"}, -- GlobalStrings
```

les lignes 311-312 :

```lua
	{FrSpell("Augmente le score de coup critique des sorts de #."), "SpellCritRating"}, -- Spell.dbc
	{FrSpell("Augmente votre score de coup critique à distance de #."), "RangedCritRating"}, -- scan: "Équipé : Augmente votre score de coup critique à distance de 14." (item 7348)
```

la ligne 322 (le commentaire seul change) :

```lua
	{"^%+?(%d+) au score de coup critique$", "CritRating"}, -- SpellItemEnchantment.dbc (also "+30 à la puissance des sorts et 20 au score de coup critique"); stays general: 2857 and 2858 have stat 19 (melee crit), the others 32 (crit)
```

les lignes 368-372 :

```lua
	{"^%+(%d+) au score de critique en mêlée$", "MeleeCritRating"}, -- SpellItemEnchantment.dbc (2506: stat 19, melee crit)
	{"^%+(%d+) au score de coup critique à distance$", "RangedCritRating"}, -- SpellItemEnchantment.dbc (3608: stat 20, ranged crit)
	{"^%+(%d+) aux score de toucher$", "HitRating"}, -- SpellItemEnchantment.dbc: "+11 aux score de toucher"
	{"^%+(%d+) au score de toucher à distance$", "RangedHitRating"}, -- SpellItemEnchantment.dbc (2523: stat 17, ranged hit)
	{"^%+(%d+) au score de hâte à distance$", "RangedHasteRating"}, -- SpellItemEnchantment.dbc (3607: stat 29, ranged haste)
```

la ligne 395 :

```lua
	{"^Lunette %(%+(%d+) au score de coup critique%)$", "RangedCritRating"}, -- SpellItemEnchantment.dbc (2724: stat 20, ranged crit)
```

et la ligne 397 (le commentaire seul change) :

```lua
	{"^Contrepoids %(%+(%d+) au score de hâte%)$", "HasteRating"}, -- SpellItemEnchantment.dbc (34: stat 36, general haste)
```

- [ ] **Step 5 : séparer les scores réservés dans `PawnScan.ItemModToStat`**

Dans `PawnScan.lua`, remplacer les 12 entrées `ITEM_MOD_CRIT_*`, `ITEM_MOD_HIT_*`, `ITEM_MOD_HASTE_*` par :

```lua
	ITEM_MOD_CRIT_RATING_SHORT = "CritRating",
	ITEM_MOD_CRIT_MELEE_RATING_SHORT = "MeleeCritRating",
	ITEM_MOD_CRIT_RANGED_RATING_SHORT = "RangedCritRating",
	ITEM_MOD_CRIT_SPELL_RATING_SHORT = "SpellCritRating",
	ITEM_MOD_HIT_RATING_SHORT = "HitRating",
	ITEM_MOD_HIT_MELEE_RATING_SHORT = "MeleeHitRating",
	ITEM_MOD_HIT_RANGED_RATING_SHORT = "RangedHitRating",
	ITEM_MOD_HIT_SPELL_RATING_SHORT = "SpellHitRating",
	ITEM_MOD_HASTE_RATING_SHORT = "HasteRating",
	ITEM_MOD_HASTE_MELEE_RATING_SHORT = "MeleeHasteRating",
	ITEM_MOD_HASTE_RANGED_RATING_SHORT = "RangedHasteRating",
	ITEM_MOD_HASTE_SPELL_RATING_SHORT = "SpellHasteRating",
```

- [ ] **Step 6 : attentes de `tests/gen_corpus.lua`**

Lignes 37-47 : changer seulement l'attente (2ᵉ élément) des 9 entrées réservées, pour que les futures générations attendent la bonne stat :

```lua
	{ Equip .. Render(ITEM_MOD_CRIT_MELEE_RATING, 20), "MeleeCritRating=20" },
	{ Equip .. Render(ITEM_MOD_CRIT_RANGED_RATING, 20), "RangedCritRating=20" },
	{ Equip .. Render(ITEM_MOD_CRIT_SPELL_RATING, 20), "SpellCritRating=20" },
```

et de même pour `HIT_*` (`MeleeHitRating=20`, `RangedHitRating=20`, `SpellHitRating=20`) et `HASTE_*` (`MeleeHasteRating=20`, `RangedHasteRating=20`, `SpellHasteRating=20`). Les lignes générales `ITEM_MOD_CRIT_RATING`, `ITEM_MOD_HIT_RATING` et `ITEM_MOD_HASTE_RATING` ne changent pas.

- [ ] **Step 7 : réécrire les attentes du corpus par script**

Créer dans le dossier scratchpad de la session un script `reclassify.lua`, à ne pas committer :

```lua
-- Rewrites the expectation of the corpus cases now read as the restricted version of their expected general rating
-- (same amount, single stat).  Only the text after the last " => " changes; the client text is kept byte for byte.
package.path = "./tests/?.lua;" .. package.path
local Harness = require("harness")
local Corpus = require("corpus")
Harness.Load()
for _, Path in ipairs(Corpus.Files()) do
	local New = {}
	for _, Case in ipairs((Corpus.ReadFile(Path))) do
		if Case.Kind == "stats" then
			local ExpectedStat, ExpectedValue = next(Case.Stats)
			local Raw, Understood = Harness.ParseLine(Case.Left, Case.Right)
			local Stat, Value = next(Raw)
			if Understood and ExpectedStat and next(Case.Stats, ExpectedStat) == nil and Stat and next(Raw, Stat) == nil
				and PawnRestrictedRatingStats[Stat] == ExpectedStat and Value == ExpectedValue then
				New[Case.Line] = Corpus.FormatStats(Raw)
			end
		end
	end
	if next(New) then
		local Lines = {}
		for Line in io.lines(Path) do table.insert(Lines, Line) end
		for Number, Expectation in pairs(New) do
			Lines[Number] = Lines[Number]:match("^(.*) => ") .. " => " .. Expectation
			print(Path .. ":" .. Number .. "  " .. Lines[Number])
		end
		local File = assert(io.open(Path, "w"))
		File:write(table.concat(Lines, "\n") .. "\n")
		File:close()
	end
end
```

Run: `luajit <scratchpad>/reclassify.lua`
Expected : environ 25 lignes réécrites, toutes avec une stat `Spell*`, `Melee*` ou `Ranged*` et le même montant : 9 dans `globalstrings.txt`, `regression.txt:55,66,79,140,141` plus les lignes « 28 … des sorts », « 37 … hâte des sorts » et « 4 … toucher des sorts », `spells.txt:159`, `scan.txt:157`, `enchants.txt:270,271,314,423,424`. `enchants.txt:207` (Contrepoids) et `enchants.txt:276` (« …/+10 au score de toucher ») ne changent pas.

Run: `git diff --stat tests/corpus && git diff tests/corpus | grep "^[-+][^-+]" | grep -v "Rating=" `
Expected: la deuxième commande ne sort rien (seules les attentes ont changé). Vérifier aussi que chaque fichier garde sa dernière ligne vide (`git diff` ne montre pas de `\ No newline at end of file`).

- [ ] **Step 8 : lancer tous les tests**

Run: `luajit tests/run.lua`
Expected: `2305 réussis, 0 échecs, 0 à classer (todo)` (2302 + 3). Si un cas du corpus échoue encore, lire l'écart : une ligne à plusieurs stats qui contient un score réservé se reclasse à la main en recopiant l'attente affichée par `--propose`, après l'avoir passée en `todo` (jamais en retapant le texte).

- [ ] **Step 9 : commit**

```bash
git add tests/extract_enchant_stats.py tests/data/enchant_stats.frFR.txt TooltipParsing.frFR.lua PawnScan.lua tests/gen_corpus.lua tests/corpus tests/unit.lua
git commit -m "frFR: read spell, melee and ranged ratings as their own stats

Scope and counterweight follow SpellItemEnchantment.dbc (extracted to
tests/data/enchant_stats.frFR.txt): the crit scope is ranged-only, the
counterweight is general haste.

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

### Task 4 : documentation (CLAUDE.md, spec)

**Files:**
- Modify: `CLAUDE.md` (Commands, Architecture, Rules)
- Modify: `docs/superpowers/specs/2026-10-03-restricted-ratings-design.md`

- [ ] **Step 1 : CLAUDE.md**

1. Commands : remplacer `Currently 2296 passing` par le nombre affiché à la tâche 3 (attendu 2305). Ajouter après la ligne `uv run --with mpyq python tests/extract_ratings.py …` :
   `- \`uv run --with mpyq python tests/extract_enchant_stats.py "../../../Data"\` — regenerate \`tests/data/enchant_stats.frFR.txt\` (stat effects of SpellItemEnchantment.dbc: ID, ITEM_MOD_* stat number, amount, text).`
2. Architecture, après le paragraphe `PawnRatingLevelFactors.lua` : ajouter
   `- Spell-, melee- and ranged-only ratings are read as their own stats (\`PawnRestrictedRatingStats\` in \`Pawn.lua\`: \`SpellCritRating\`, \`MeleeHitRating\`, \`RangedHasteRating\`…). \`PawnGetStatWeight\` gives them the weight from \`PawnClassicRestrictedRatingWeights\` (Classic scales), else the weight of the general rating. \`ClassicHawsJon.lua\` derives those weights from each Wrath scale's own values (one weight per rating: spells if \`SpellPower > 0\`, ranged for hunters / melee for others if \`Ap > 0\` or no \`SpellPower\`, 0 otherwise) and scales them by level with their own \`PawnRatingPointsPerPercent\` rows. \`RatingWeightsVersion\` forgets saved best items once when the weights change.`
3. Architecture, phrase sur le harnais : remplacer `the level tests must stay last in \`unit.lua\` because they populate \`PawnCommon.Scales\`` par `the tests that populate \`PawnCommon.Scales\` (rating level, restricted ratings) must stay last in \`unit.lua\``.
4. Rules : remplacer `Spell-specific rating lines count as the combined rating.` par `Spell-, melee- and ranged-only rating lines produce their restricted stat (\`SpellCritRating\`…); an enchantment text gets one only if every enchantment with that text has the same stat number in \`tests/data/enchant_stats.frFR.txt\`.`
5. Rules, ligne `tests/data/` : ajouter les champs `SpellItemEnchantment.dbc` effect type 2-4, amount 5-7, stat number 11-13 (en plus du texte 16).

- [ ] **Step 2 : corriger la spec**

Dans `docs/superpowers/specs/2026-10-03-restricted-ratings-design.md` :
- section 2, « Relevé des poids d'origine » : remplacer la phrase sur `CritRating` / `SpellCritRating` « encore séparés » et le tableau par la règle de l'écart 1 du plan (rôle déduit de `Ap` et `SpellPower`, décision du 2026-10-04) ;
- section 1, « Lunettes et contrepoids » : ajouter le résultat (Lunette 2724 → stat 20 → `RangedCritRating` ; Contrepoids 34 → stat 36 → reste `HasteRating` ; « +# au score de coup critique » mêlé 19/32 → reste général) et les champs (type 2-4, montant 5-7, numéro 11-13, texte 16) ;
- section 2, « Ajustement au niveau » : les 9 lignes sont ajoutées (le toucher des sorts diffère en valeur) ;
- section 2 : ajouter « Les meilleurs objets mémorisés sont oubliés une fois (`RatingWeightsVersion`) » ;
- section 1, « Clients anglais » : les valeurs des `Spell*Rating` enUS passent de 0 au poids réservé ou général ;
- section 3 : les tests de poids viennent après les tests de niveau ;
- section 4, point 2 : objet 24256 « Ceinturon de saccage ».

- [ ] **Step 3 : vérifier et committer**

Run: `luajit tests/run.lua | tail -1`
Expected: `2305 réussis, 0 échecs, 0 à classer (todo)`

```bash
git add CLAUDE.md docs/superpowers/specs/2026-10-03-restricted-ratings-design.md
git commit -m "Docs: restricted ratings (reading, weights, DBC fields, test order)

Co-Authored-By: Claude Opus 5.5 <noreply@anthropic.com>"
```

---

## Vérifications en jeu (par l'utilisateur, après redémarrage complet du client)

1. Avec Mairy (prêtre), `/pawnscan inspect 7348`, puis `/reload` : la ligne « … à distance de 14 » donne `RangedCritRating=14`, et la valeur des échelles prêtre ne compte rien pour elle.
2. `/pawnscan inspect 24256` (« Ceinturon de saccage », crit des sorts 20) : `SpellCritRating=20`, valeur positive dans « Prêtre : Ombre ». Sur un personnage physique, ou avec `/pawn debug on` et le survol de l'objet, le poids affiché pour `SpellCritRating` vaut 0 dans une échelle guerrier.
3. Onglet Comparer avec 24256 contre un autre objet : pas d'erreur Lua (la stat réservée n'apparaît pas dans la liste, comme prévu).
4. Un scan rapide en mode objets : pas de nouvelle erreur, et pas de nouvel écart `mismatch` inexpliqué sur les scores réservés.
