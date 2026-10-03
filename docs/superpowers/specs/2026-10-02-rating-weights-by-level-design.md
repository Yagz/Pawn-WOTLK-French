# Pawn 2.8.11 (fork frFR 3.3.5a) — poids des scores selon le niveau du personnage

Date : 2026-10-02
Branche : `fr-2.8.11`
Cycle : premier sous-projet de « justesse des valeurs ». Les autres sous-projets (crit/toucher/hâte des sorts, gemmes et bonus de sertissage, DPS d'arme) auront chacun leur propre cycle.

## Objectif

Le but n'est pas une valeur exacte. Il s'agit de désigner correctement, pour une spé, le meilleur objet pour le personnage à l'instant T. Seuls comptent donc les rapports entre les poids.

L'utilisateur joue avec les échelles « Classic » fournies par Pawn (`ClassicHawsJon.lua`, mode Wrath), sans les modifier. Ces échelles sont calibrées pour le niveau 80 : un point de score (crit, toucher…) y vaut ce qu'il rapporte au niveau 80. Or le nombre de points de score pour 1 % baisse avec le niveau, selon une courbe non linéaire. Un point de score rapporte par exemple 2,08 fois plus de % au niveau 70, 3,28 fois plus au niveau 60, et bien davantage en dessous. À tout niveau inférieur à 80, Pawn sous-évalue donc les scores face aux stats primaires, et la flèche « meilleur objet » peut se tromper.

Ce cycle ajuste les poids des scores des échelles Classic au **niveau exact** du personnage, de 1 à 80, et suit chaque montée de niveau. Il n'y a pas de paliers. La source est la table réelle du client pour chaque niveau, et le niveau appliqué est affiché dans l'interface. Le serveur ouvre son contenu par phases (60 → 70 → 80). Ces trois niveaux servent seulement de points de contrôle dans les relevés et les tests ci-dessous.

### Hors périmètre

- Les effets des stats primaires qui dépendent du niveau, comme la conversion Agilité/Intelligence → crit (`gtChanceToMeleeCrit`, `gtChanceToSpellCrit`). Cette part varie dans le même sens que les scores, mais moins fort. Elle ne change donc l'ordre que pour des objets presque à égalité, et la corriger obligerait à supposer comment HawsJon a réparti le poids de l'Intelligence entre crit et mana. Ce sera un cycle ultérieur si les résultats le justifient.
- Les seuils propres au niveau 80 (plafond de toucher contre un boss 83, etc.) et les différences de rotation en leveling : aucune donnée du client ne les décrit.
- Les échelles créées, copiées ou importées par l'utilisateur ne sont jamais modifiées. Une copie d'une échelle Classic garde les poids du niveau où elle a été faite. Une pawnstring issue d'une simulation est déjà calculée pour son niveau.
- La séparation crit/toucher/hâte des sorts et de la mêlée : la fusion actuelle de `Pawn.lua` (`PawnCombineStats`) est conservée.

## Données : `gtCombatRatings.dbc`

Source : `Data/frFR/patch-frFR.MPQ`, fichier `DBFilesClient\gtCombatRatings.dbc`. Il prime sur `locale-frFR.MPQ` (la seule différence entre les deux concerne la résilience) et il est absent de `Patch-Z.MPQ`. `PaperDollFrame.lua` vient de `patch-frFR-3.MPQ`, le plus prioritaire des quatre MPQ qui le contiennent.

Format : un en-tête WDBC, puis 3200 enregistrements d'un flottant chacun, soit 32 scores × 100 niveaux. La valeur du score `CR` (indice 1-based, comme les constantes `CR_*` du client) au niveau `L` est l'enregistrement `(CR - 1) * 100 + (L - 1)`. Elle donne le nombre de points de score pour 1 % (ou pour 1 point de défense ou d'expertise).

Relevé du 2026-10-02, limité à trois points de contrôle (la table générée contient les 80 niveaux) :

| Score (CR) | niv. 60 | niv. 70 | niv. 80 |
|---|---|---|---|
| Toucher mêlée (6) | 10 | 15,7692 | 32,79 |
| Toucher sorts (8) | 8 | 12,615 | 26,232 |
| Crit mêlée (9) / sorts (11) | 14 | 22,077 | 45,906 |
| Résilience (15) | 28,75 | 45,3365 | 94,2712 |
| Hâte mêlée (18) | 10 | 15,769 | 32,79 |
| Expertise (24) | 2,5 | 3,942 | 8,1975 |
| Pénétration d'armure (25) | 4,695 | 7,404 | 15,395 |

Pour tous ces scores, le rapport niveau 80 / niveau 60 vaut 3,279.

Correspondance entre les stats Pawn et les constantes `CR_*`. Les constantes sont définies dans `Interface\FrameXML\PaperDollFrame.lua` (`patch-frFR.MPQ`), par exemple `CR_HIT_MELEE = 6;` ou `CR_CRIT_TAKEN_MELEE = 15;`. Le script les lit dans ce fichier, sans numéros écrits en dur.

| Stat Pawn | Constante utilisée | Variantes qui doivent avoir le même rapport |
|---|---|---|
| `HitRating` | `CR_HIT_MELEE` | `CR_HIT_RANGED`, `CR_HIT_SPELL` |
| `CritRating` | `CR_CRIT_MELEE` | `CR_CRIT_RANGED`, `CR_CRIT_SPELL` |
| `HasteRating` | `CR_HASTE_MELEE` | `CR_HASTE_RANGED`, `CR_HASTE_SPELL` |
| `ExpertiseRating` | `CR_EXPERTISE` | — |
| `ArmorPenetration` | `CR_ARMOR_PENETRATION` | — |
| `DefenseRating` | `CR_DEFENSE_SKILL` | — |
| `DodgeRating` | `CR_DODGE` | — |
| `ParryRating` | `CR_PARRY` | — |
| `BlockRating` | `CR_BLOCK` | — |
| `ResilienceRating` | `CR_CRIT_TAKEN_MELEE` | — |

Pawn fusionne les variantes mêlée, distance et sorts en une seule stat. Le script d'extraction vérifie donc que, pour chaque niveau de 1 à 80, leur rapport au niveau 80 est identique (à 1e-4 près). Sinon, il échoue avec un message explicite, et la décision revient à l'utilisateur.

## Composants

### 1. Script d'extraction `tests/extract_ratings.py`

C'est un script Python conservé dans le dépôt, à la différence du script MPQ jetable du cycle précédent. Il se lance avec `uv run --with mpyq python tests/extract_ratings.py <dossier Data du client>`.

- Il lit `gtCombatRatings.dbc` en appliquant l'ordre de priorité complet des MPQ du client (`patch-frFR-3`, `-2`, `patch-frFR`, … `locale-frFR`, … `common`).
- Il lit les constantes `CR_*` dans `Interface\FrameXML\PaperDollFrame.lua`, en appliquant le même ordre de priorité des MPQ.
- Il écrit `PawnRatingLevelFactors.lua`, dont l'en-tête indique la source (MPQ et md5 de chaque fichier extrait ; pas de date, pour que la régénération soit identique) et la commande de régénération.
- Il fait la vérification des variantes décrite ci-dessus.

Le fichier généré est commité. Le relancer sur les mêmes données doit produire exactement le même fichier.

### 2. Données `PawnRatingLevelFactors.lua` (généré)

Il est chargé dans `Pawn.toc` juste avant `ClassicHawsJon.lua`. Il définit `PawnRatingPointsPerPercent[StatPawn][Niveau]` pour les niveaux 1 à 80 et les 10 stats de la table ci-dessus. Les valeurs sont celles du DBC, arrondies à 4 décimales.

Un nouveau fichier dans `Pawn.toc` exige un redémarrage complet du client, une seule fois. L'utilisateur l'a accepté.

### 3. Ajustement dans `ClassicHawsJon.lua`

- Une fonction `PawnClassicApplyRatingLevel(Level)` parcourt les échelles dont `Provider == "Classic"`.
  - Au premier passage, elle mémorise dans une table locale non sauvegardée les poids d'origine (niveau 80) des 10 stats de score.
  - Ensuite, `Values[Stat] = PoidsOrigine[Stat] * PawnRatingPointsPerPercent[Stat][80] / PawnRatingPointsPerPercent[Stat][Level]`. Les poids d'origine nuls ou absents restent absents.
  - Elle ne recalcule rien si le niveau demandé est déjà appliqué.
  - Le niveau est borné à `[1, 80]`.
  - Le niveau appliqué est mémorisé dans la variable globale non sauvegardée `PawnClassicRatingLevel`.
  - Elle termine par `PawnRecalculateScaleTotal` pour chaque échelle Classic, puis par `PawnResetTooltips()`.
- Elle est appelée à la fin de `PawnClassicScaleProvider_AddScales`, uniquement dans la branche Wrath, avec `UnitLevel("player")`.
- Elle est appelée sur `PLAYER_LEVEL_UP` avec le niveau passé en argument par l'événement, et non `UnitLevel`, qui peut encore renvoyer l'ancien niveau à ce moment-là. L'événement est écouté par une petite frame locale à `ClassicHawsJon.lua`, pour ne pas toucher à `PawnOnEvent`.
- Les poids affichés dans l'onglet Valeurs sont donc exactement ceux qu'utilise Pawn. Au niveau 80, les valeurs sont strictement identiques à celles d'avant ce cycle.
- Les valeurs ajustées ne vont pas dans les SavedVariables : `PawnUnitializePlugins` efface déjà `Values` des échelles de fournisseurs à la déconnexion.

### 4. Interface

Le niveau est affiché seulement pour une échelle Classic, quand `PawnClassicRatingLevel` est défini et inférieur à 80. Le texte est construit par `PawnClassicRatingLevelNote(ScaleName, Long)`, dans `ClassicHawsJon.lua`. Elle renvoie `nil` hors de ces conditions. Comme le harnais ne charge pas `PawnUI.lua`, cette fonction reste testable hors jeu. `PawnUI.lua` se contente de l'appeler :

- **Onglet Valeurs** (`PawnUI_ValuesTab_Refresh`) : on ajoute au texte lecture seule « Poids des scores ajustés pour le niveau %d (valeurs d'origine prévues pour le niveau 80). »
- **Onglet Échelle** (libellé `PawnUIFrame_ScaleTypeLabel`) : « Poids des scores ajustés pour le niveau %d. » est placé devant le texte lecture seule existant.
- Deux nouvelles clés, dans `Localization.lua` (enUS) et dans `Localization.frFR.lua`. Ce sont des textes d'interface propres à Pawn, et non des textes d'infobulle du client : la règle « données réelles » ne s'y applique pas.
  - En anglais : « Rating weights adjusted for level %d (original values are for level 80). » et « Rating weights adjusted for level %d. »
- Si le texte déborde de la zone prévue, la mise en page est ajustée (hauteur de la FontString ou retour à la ligne). C'est un point à vérifier en jeu.

## Tests hors jeu (`luajit tests/run.lua`)

Le harnais charge déjà les vrais fichiers de l'addon. Il faut y ajouter `PawnRatingLevelFactors.lua` et `ClassicHawsJon.lua`, et une stub `UnitLevel` réglable.

1. **Table conforme au DBC** : spot-checks sur les valeurs relevées ci-dessus (crit 60 = 14, crit 80 = 45,906, résilience 80 = 94,2712…). Le test vérifie aussi que l'en-tête du fichier généré cite sa source.
2. **Niveau 80 = aucun changement** : toutes les valeurs de toutes les échelles Classic sont identiques aux poids HawsJon du fichier.
3. **Niveau 60** :
   - le `CritRating` de « Prêtre : Ombre » vaut le poids HawsJon × 45,906 / 14 ;
   - une stat qui n'est pas un score (`Intellect`, `SpellPower`, `Stamina`) est inchangée ;
   - un score de poids nul reste absent.
4. **Montée de niveau 60 → 61** : les valeurs et `PawnClassicRatingLevel` sont mis à jour, et un second appel au même niveau ne fait rien.
5. **Niveaux hors points de contrôle** : au niveau 15, le facteur appliqué est celui de la table pour le niveau 15. Les niveaux 0 et 85 sont ramenés à 1 et 80.
6. **Échelle perso ou importée** : une échelle sans `Provider` n'est jamais modifiée.
7. **Texte d'interface** : `PawnClassicRatingLevelNote` renvoie un texte contenant « 60 » pour une échelle Classic au niveau 60. Elle renvoie `nil` au niveau 80 et pour une échelle perso. L'affichage réel dans `PawnUI.lua` est vérifié en jeu.

## Vérifications en jeu (par l'utilisateur)

Avec Mairy, prêtre niveau 60, après un redémarrage complet du client :

1. `/run print(GetCombatRatingBonus(11, 140))` doit afficher `10` : 140 points de crit des sorts = 10 % au niveau 60. Ça confirme la table côté client.
2. Onglet Valeurs de « Prêtre : Ombre » : la mention du niveau 60 apparaît, et le poids de crit vaut 3,28 fois celui du fichier HawsJon.
3. `/pawnscan inspect <objet avec score de crit>` : la valeur de l'objet augmente par rapport au relevé d'avant le changement.
4. Optionnel : comparer la somme de contrôle de `gtCombatRatings.dbc` dans le dossier `dbc` du serveur AzerothCore avec celle de l'extrait du client. C'est le serveur qui calcule les vrais effets. Si les fichiers diffèrent, il faudra extraire la table du serveur.

## Commits prévus

1. Script d'extraction, table générée, entrée `Pawn.toc` et tests de la table.
2. `PawnClassicApplyRatingLevel`, son appel au chargement, `PLAYER_LEVEL_UP` et les tests.
3. Textes et affichage dans l'interface, et leurs tests.
4. Mise à jour de `CLAUDE.md` : nouveau fichier, commande d'extraction, nombre de tests.
