# Scores réservés aux sorts, à la mêlée ou à la distance

Date : 2026-10-03
Branche : `fr-2.8.11`
Cycle : deuxième sous-projet de « justesse des valeurs ». Le premier (poids des scores selon le niveau) est terminé ; les suivants sont les gemmes et bonus de sertissage, puis le DPS d'arme.

## Objectif

Comme pour le premier sous-projet, le but est de désigner le bon objet pour le personnage, pas une valeur exacte.

En 3.3.5a, la plupart des objets portent des scores généraux (« Augmente de # le score de coup critique. »), qui comptent pour la mêlée, la distance et les sorts. Certains objets, surtout anciens, portent un score réservé à un seul type :

- « Augmente de # le score de coup critique des sorts. », « … de toucher des sorts. », « … de hâte des sorts. » ;
- « Augmente de # le score de coup critique en mêlée. » ;
- « Augmente de # le score de coup critique à distance. », lunettes « +# au score de hâte à distance »…

Toutes ces formes ont été reconnues par le scan en jeu du 2026-10-02 (section `parsed` de `PawnScanResults`). Côté serveur, un score réservé n'agit que sur son type. Or Pawn les lit toutes comme le score général (`TooltipParsing.frFR.lua`, l. 235-245, 311-312, 368-372), puis les échelles Classic fusionnent les poids physique et sorts en gardant le plus grand (`PawnCombineStats`, `Pawn.lua:3209-3213`). Un guerrier voit donc un objet « crit des sorts » valoir autant qu'un objet « crit », et un prêtre Ombre fait la même erreur avec un objet « crit en mêlée ».

Ce cycle donne à chaque score réservé le poids de son type, dans les échelles Classic (HawsJon) que l'utilisateur emploie.

### Décisions

- Découpage en trois types : sorts, mêlée, distance (option B).
- Le type physique secondaire de la classe vaut **0** : le score « en mêlée » pour le chasseur, le score « à distance » pour toutes les autres classes. Aucune donnée du client ne permet de chiffrer une fraction (option A).
- Approche : nouvelles stats lues, poids réservés gardés dans une table à part, sans toucher aux tables de poids des échelles (approche 1).

### Hors périmètre

- Les scores liés à une école de magie (« Augmente le score de coup critique des sorts de Nature de # »), que Pawn ne lit pas aujourd'hui.
- Les effets « Utiliser » et les effets déclenchés (« … ont une chance d'augmenter votre score de hâte des sorts de # »), que Pawn ne valorise pas.
- Les gemmes, y compris les gemmes BC à `SpellCritRating` de `GemsBurningCrusade.lua` : sous-projet 3.
- L'affichage des poids réservés dans les onglets Poids et Comparer.
- Les échelles personnelles, copiées ou importées : une stat réservée y prend le poids général, donc leur comportement ne change pas.

## 1. Lecture des lignes (`TooltipParsing.frFR.lua`)

Les motifs ne changent pas ; seule la stat produite change.

| Lignes | Stat produite |
|---|---|
| `ITEM_MOD_CRIT_SPELL_RATING`, `ITEM_MOD_HIT_SPELL_RATING`, `ITEM_MOD_HASTE_SPELL_RATING` (GlobalStrings), « Augmente le score de coup critique des sorts de # » (Spell.dbc) | `SpellCritRating`, `SpellHitRating`, `SpellHasteRating` |
| `ITEM_MOD_CRIT_MELEE_RATING`, `ITEM_MOD_HIT_MELEE_RATING`, `ITEM_MOD_HASTE_MELEE_RATING`, « +# au score de critique en mêlée » (SpellItemEnchantment.dbc) | `MeleeCritRating`, `MeleeHitRating`, `MeleeHasteRating` |
| `ITEM_MOD_CRIT_RANGED_RATING`, `ITEM_MOD_HIT_RANGED_RATING`, `ITEM_MOD_HASTE_RANGED_RATING`, « Augmente votre score de coup critique à distance de # » (scan, objet 7348), « +# au score de coup critique / toucher / hâte à distance » (SpellItemEnchantment.dbc) | `RangedCritRating`, `RangedHitRating`, `RangedHasteRating` |
| Toutes les autres lignes de score | inchangé (`CritRating`, `HitRating`, `HasteRating`) |

Les neuf stats réservées sont appelées ci-dessous « stats réservées ».

### Lunettes et contrepoids : décision par le DBC

« Lunette (+# au score de coup critique) » (l. 395) et « Contrepoids (+# au score de hâte) » (l. 397) ne disent pas dans leur texte si l'effet est réservé. `SpellItemEnchantment.dbc` donne, pour chaque enchantement, le type de chaque effet et son argument ; pour un effet de type stat, l'argument est le numéro `ITEM_MOD_*` (19 = crit mêlée, 20 = crit distance, 21 = crit sorts, 32 = crit général, etc.).

On extrait ces champs des MPQ frFR avec un script `uv run --with mpyq`, dans l'esprit de `tests/extract_ratings.py`, vers un fichier de données dans `tests/data/`. Chaque motif d'enchantement concerné reçoit la stat qu'indique le DBC pour tous les enchantements qui portent ce texte, avec la source citée en commentaire. Si des enchantements de même texte ont des numéros de stat différents, ou si le numéro ne correspond à aucun type connu, la ligne reste en score général, et le plan le note.

Les numéros de champs exacts sont déterminés au moment de l'extraction et notés dans `CLAUDE.md`, comme pour les champs déjà utilisés.

### Scanner (`PawnScan.lua`)

La table qui relie les clés de `GetItemStats` aux stats de Pawn (`PawnScan.lua:35-45`) suit la même séparation : `ITEM_MOD_CRIT_SPELL_RATING_SHORT` → `SpellCritRating`, etc. Les comparaisons `mismatch` continuent ainsi de comparer des stats équivalentes.

### Clients anglais

Ils gardent les tables de lecture de Pawn 2.8.11. Le test enUS existant le vérifie.

## 2. Poids (`ClassicHawsJon.lua`, `Pawn.lua`)

### Relevé des poids d'origine

Dans `ClassicHawsJon.lua`, chaque appel à `PawnAddPluginScaleFromTemplate` reçoit la table HawsJon complète, où `CritRating` (physique) et `SpellCritRating` (sorts) sont encore séparés. `PawnAddPluginScaleFromTemplate` copie cette table dans les valeurs de l'échelle (`Pawn.lua:5596`), et c'est la copie que `PawnCorrectScaleErrors` fusionne ; la table passée en argument reste intacte.

Pour chaque échelle Classic, on enregistre donc, à partir de cette table, ses poids réservés au niveau 80 :

| Stat réservée | Poids |
|---|---|
| `SpellCritRating`, `SpellHitRating`, `SpellHasteRating` | poids sorts HawsJon de même nom |
| `MeleeCritRating`, `MeleeHitRating`, `MeleeHasteRating` | poids physique HawsJon (`CritRating`, `HitRating`, `HasteRating`), ou 0 si la classe est chasseur (`ClassID` 3) |
| `RangedCritRating`, `RangedHitRating`, `RangedHasteRating` | poids physique HawsJon si la classe est chasseur, 0 sinon |

Un poids absent de la table HawsJon compte comme 0.

Ces poids sont rangés dans `PawnClassicRestrictedRatingWeights[NomInterneÉchelle][Stat]`. La table n'est pas sauvegardée : elle est reconstruite à chaque chargement, comme `OriginalRatingWeights`.

### Ajustement au niveau

`PawnClassicApplyRatingLevel` applique aussi à cette table le facteur `P[80] / P[niveau]` du sous-projet 1. Chaque stat réservée prend la ligne de `PawnRatingPointsPerPercent` de son propre score client (crit sorts, crit mêlée, crit distance, etc.). Si `PawnRatingLevelFactors.lua` ne contient pas encore ces lignes, le script d'extraction les ajoute à partir de `gtCombatRatings.dbc` et des constantes `CR_*`. Si une variante a exactement les mêmes valeurs que le score général, on peut utiliser la ligne générale, mais le test le vérifie.

Un deuxième appel au même niveau ne change rien. Les poids réservés à niveau 80 sont identiques aux poids relevés.

### Calcul de la valeur (`PawnGetItemValue`)

Pour une stat réservée, le poids utilisé est, dans l'ordre :

1. le poids de `PawnClassicRestrictedRatingWeights` pour cette échelle, s'il existe (échelle Classic) ;
2. sinon le poids de la stat générale correspondante dans l'échelle (`CritRating`, `HitRating`, `HasteRating`). Les échelles personnelles et importées donnent donc la même valeur qu'aujourd'hui.

Si la stat générale correspondante est marquée « ignorer » (poids `<= PawnIgnoreStatValue`), l'objet reste inutilisable, comme aujourd'hui. Le message de calcul du mode debug affiche la stat réservée et le poids utilisé.

### Ce qui ne change pas

- Le score général reste fusionné par `PawnCombineStats` : le poids le plus grand entre physique et sorts.
- Les tables `Scale.Values`, leur total de normalisation, la sauvegarde et l'onglet Poids.
- Le comparateur (onglet Comparer) n'est pas modifié. On vérifie en jeu qu'il n'y a pas d'erreur Lua avec un objet à stat réservée.

## 3. Tests hors jeu (`luajit tests/run.lua`)

Les tests de poids s'ajoutent dans `tests/unit.lua` avant les tests de niveau, qui doivent rester en dernier.

1. **Lecture** : les lignes réservées du corpus (`globalstrings`, `spells`, `enchants`, `scan`, `regression`) attendent leur stat réservée ; les lignes générales sont inchangées. Les attentes sont régénérées par les outils du corpus, jamais retapées.
2. **Lunettes et contrepoids** : la stat attendue correspond au numéro de stat extrait de `SpellItemEnchantment.dbc`, cité dans le test.
3. **Poids à niveau 80** :
   - « Prêtre : Ombre » : `SpellCritRating` = poids sorts HawsJon ; `MeleeCritRating` = `RangedCritRating` = 0 ;
   - une échelle chasseur : `RangedCritRating` = poids physique ; `MeleeCritRating` = 0 ;
   - une échelle guerrier : `MeleeCritRating` = poids physique ; `RangedCritRating` = 0 ; `SpellCritRating` = poids sorts HawsJon (0 pour ces échelles).
   Même vérification pour toucher et hâte sur au moins une échelle.
4. **Niveau 60** : chaque poids réservé vaut son poids à niveau 80 × `P[80] / P[60]` de sa ligne.
5. **Valeur d'un objet** : un objet « +10 crit sorts » vaut 10 × le poids sorts dans « Prêtre : Ombre » et 0 dans une échelle guerrier ; un objet « +10 crit » général garde sa valeur actuelle.
6. **Échelle personnelle** : une stat réservée y prend le poids de la stat générale.
7. **Clients anglais** : le test existant reste vert.

## 4. Vérifications en jeu (par l'utilisateur)

Après un redémarrage complet du client :

1. Avec Mairy (prêtre), `/pawnscan inspect 7348` : la ligne « … à distance de 14 » donne `RangedCritRating=14`, de valeur 0 dans les échelles prêtre.
2. `/pawnscan inspect` sur un objet portant un score « crit des sorts », dont l'identifiant est trouvé pendant le plan : valeur positive pour l'échelle Ombre, nulle pour une échelle physique.
3. Onglet Comparer avec l'un de ces objets : pas d'erreur Lua.
4. Un scan rapide en mode objets : pas de nouvelle erreur, et pas de nouvel écart `mismatch` inexpliqué.
