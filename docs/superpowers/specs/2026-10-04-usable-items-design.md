# Armes et objets utilisables

Date : 2026-10-04
Branche : `fr-2.8.11`
Cycle : quatrième sous-projet de « justesse des valeurs ». Il est né de la vérification du DPS d'arme (spike du 2026-10-04).

## Objectif

Le but reste le même : désigner le bon objet pour le personnage. Il ne faut ni proposer un objet qu'il ne peut pas porter, ni ignorer un objet qu'il peut porter.

### Constats du spike (2026-10-04)

La lecture des armes est correcte. Pour six vraies armes inspectées en jeu (51528, 51880, 50684, 51432, 50735, 51395), le DPS calculé par Pawn est égal à la ligne « (… dégâts par seconde) » du client. Le type (mêlée, distance, une main, deux mains, main gauche) et les types d'armes interdits par classe sont respectés. Le DPS n'a pas besoin d'ajustement selon le niveau : 1 DPS vaut 14 PA à tout niveau.

Deux défauts hérités de Pawn d'origine :

1. **Voleurs : toute arme « Main gauche » vaut 0.** Les trois échelles de voleur Wrath (`ClassicHawsJon.lua`, Assassinat, Combat, Finesse) contiennent `IsOffHand=PawnIgnoreStatValue`. L'Éviscérateur du gladiateur courroucé (51528, dague de main gauche) vaut 0 pour les voleurs et 1515,5 pour le guerrier Fureur. Le suivi des améliorations ne tente jamais la main gauche d'un voleur (`Pawn.lua:3578`).
2. **La ligne « Classes : … » est ignorée.** Un objet réservé à une classe est valorisé pour toutes les autres. Le Grand bâton du gladiateur courroucé (51432, « Classes : Druide ») vaut 198,8 pour « Prêtre : Sacré » et 2090,4 pour le guerrier Fureur.

### Hors périmètre

- La PA farouche : sa formule n'est pas vérifiable, car l'infobulle du client ne l'affiche pas.
- Les échelles de voleur BC (`ClassicHawsJon.lua:203-223`) : elles ne s'exécutent jamais, car le fork force `IsWrath`.
- Les poids propres à la main gauche : une arme de main gauche prend les poids de l'échelle, comme pour les autres classes qui se battent à deux armes.
- Le niveau requis, la race requise et les autres exigences de l'infobulle.
- La valeur d'une baguette pour un lanceur de sorts : HawsJon donne 0 au DPS à distance, c'est un choix de l'échelle.

## 1. Main gauche des voleurs

Le fork retire `IsOffHand=PawnIgnoreStatValue` des trois échelles de voleur de la branche Wrath, avec un commentaire. `IsFrill` et `IsShield` restent bloqués. Les tanks guerrier (`ClassicHawsJon.lua:645`) et paladin (`:158`) gardent le blocage : ils portent un bouclier.

`RatingWeightsVersion` passe de 2 à 3. Les listes de meilleurs objets du personnage sont ainsi oubliées une fois : celles des voleurs n'ont jamais compté la main gauche.

## 2. Restriction de classe

### Noms des classes

Le client remplit `LOCALIZED_CLASS_NAMES_MALE` et `LOCALIZED_CLASS_NAMES_FEMALE` au chargement de FrameXML (`Interface\FrameXML\Constants.lua`, `patch-frFR-3.MPQ` : `FillLocalizedClassList(LOCALIZED_CLASS_NAMES_MALE, false)`). Ces tables sont indexées par jeton (`PRIEST`…) et donnent les noms masculin et féminin. Pawn les lit au moment d'analyser la ligne, pas au chargement de l'addon.

Le jeton de la classe d'une échelle Classic vient de `Scale.ClassID`, par une table numéro de classe → jeton qui cite `ChrClasses.dbc` (champ 0 = numéro, champ 55 = jeton). Une échelle sans `ClassID` (personnelle ou importée) prend la classe du personnage (`select(2, UnitClass("player"))`).

### Lecture de la ligne

La ligne `ITEM_CLASSES_ALLOWED` (« Classes : %s ») cesse d'être ignorée. Sa ligne de motif dans `TooltipParsing.frFR.lua` capture la liste et porte une nouvelle source, `PawnClassesAllowed`. `PawnLookForSingleStat` passe la capture à `PawnAddClassRestriction(Stats, List)` (`Pawn.lua`, point d'accroche commenté du fork).

`PawnAddClassRestriction` reconnaît les noms sans dépendre du séparateur, que le client ne fournit pas :

- elle prend tous les noms masculins et féminins, du plus long au plus court (« Prêtresse » avant « Prêtre ») ;
- elle retire chaque nom trouvé dans la liste, mot entier, et note son jeton ;
- s'il reste autre chose que des espaces et de la ponctuation, un nom est inconnu, et aucune restriction n'est ajoutée (message en mode debug) ;
- sinon, elle ajoute `UnusableBy<JETON> = 1` pour chaque classe de `LOCALIZED_CLASS_NAMES_MALE` absente de la liste.

Si les tables du client manquent, la ligne reste comprise sans restriction.

### Valeur

`PawnGetStatWeight` renvoie `PawnIgnoreStatValue` pour `UnusableBy<JETON>` quand le jeton est celui de la classe de l'échelle. Dans les autres cas, elle renvoie `nil`, et la stat ne compte pas. Le contrôle existant de `PawnGetItemValue` rend alors l'objet inutilisable, avec une valeur de 0, comme une armure en plaques pour un prêtre.

## 3. Données

Le script `tests/extract_classes.py` (`uv run --with mpyq`, même principe que `tests/extract_gems.py`) lit `ChrClasses.dbc` et écrit `tests/data/classes.frFR.txt`. Le format est `ID<TAB>jeton<TAB>nom masculin<TAB>nom féminin`. L'en-tête cite l'archive et le md5. Relancer le script sur les mêmes données donne le même fichier. Les numéros de champs (0 ID, 23 féminin, 40 masculin, 55 jeton) sont confirmés à l'extraction et notés dans `CLAUDE.md`.

Le harnais de test remplit `LOCALIZED_CLASS_NAMES_MALE` / `_FEMALE` à partir de ce fichier, comme le fait le client. Un nom féminin vide dans le DBC (paladin, chevalier de la mort) prend le nom masculin dans le harnais.

## 4. Tests hors jeu (`luajit tests/run.lua`)

1. **Lecture :**
   - « Classes : Druide » donne `UnusableBy*` pour les neuf autres classes et rien pour `DRUID` ;
   - une liste de deux classes, construite à partir des noms du fichier de données séparés par une virgule avec et sans espace, donne huit restrictions. Aucun autre séparateur n'est attesté par les données : la vérification en jeu (section 5) donne la vraie forme ;
   - un nom féminin (« Prêtresse ») vaut le masculin ;
   - un nom inconnu ne donne aucune restriction, et la ligne reste comprise.
2. **Corpus :** les 9 lignes « Classes : … » de `tests/corpus/scan.txt` passent d'`ignored` aux stats `UnusableBy*`. Les attentes sont réécrites par script, et le texte du client n'est pas modifié.
3. **Valeur :**
   - le bâton 51432, reconstitué à partir des constantes du client avec les nombres de l'inspection en jeu, vaut 0 pour « Prêtre : Sacré » et pour le guerrier Fureur, et reste valorisé pour le druide farouche ;
   - une échelle personnelle suit la classe du personnage.
4. **Voleurs :** la dague 51528, reconstituée de la même façon, a une valeur non nulle pour les trois échelles de voleur, et `IsOffHand` n'est plus bloqué chez eux. Les tanks guerrier et paladin le gardent bloqué.
5. **Mémorisation :** une liste notée avec `RatingWeightsVersion = 2` est oubliée une fois.

## 5. Vérifications en jeu (par l'utilisateur)

Après un `/reload`, avec Mairy :

1. Survoler le bâton 51432 : plus de valeur pour « Prêtre : Sacré ».
2. `/pawnscan inspect 51376` (chasseur et chaman) et `/pawnscan inspect 49623` (Deuillelombre), puis `/reload` : je vérifie que les stats contiennent les `UnusableBy*` attendus. C'est la vraie forme des listes à plusieurs classes.
3. Pas d'erreur Lua.
