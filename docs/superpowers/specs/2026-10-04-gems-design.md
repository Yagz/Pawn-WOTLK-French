# Gemmes supposées dans les châsses

Date : 2026-10-04
Branche : `fr-2.8.11`
Cycle : troisième sous-projet de « justesse des valeurs ». Le premier (poids des scores selon le niveau) et le deuxième (scores réservés aux sorts, à la mêlée ou à la distance) sont terminés. Le suivant est le DPS d'arme.

## Objectif

Comme pour les sous-projets précédents, le but est de désigner le bon objet pour le personnage, pas une valeur exacte.

L'utilisateur sertit toujours ses objets, y compris pendant la progression, et y met toujours les meilleures gemmes bleues (rares) de l'extension en cours : celles de BC en phase 70, celles de Wrath en phase 80.

Pawn ne fait pas ce choix aujourd'hui (constaté le 2026-10-04) :

- **L'option « Ignorer les châsses des objets de bas niveau » est cochée** (`PawnCommon.IgnoreGemsWhileLeveling`, valeur par défaut). Les châsses et le bonus de sertissage d'un objet de niveau inférieur à `PawnMinimumItemLevelToConsiderGems` (187) ne comptent pas. En jeu, l'objet 24256 vaut 71,53 dans « Prêtre : Sacré » au niveau 60. Si ses deux châsses étaient comptées avec les gemmes que Pawn suppose aujourd'hui, il vaudrait 101,96 (calcul hors jeu).
- **Quand l'option est décochée, la gemme supposée dépend du niveau de l'objet** (`PawnGemQualityLevels`, `GemsWrath.lua:723`) :

  | Niveau d'objet | Gemmes supposées |
  |---|---|
  | moins de 90 | blanches de niveau 60 |
  | 90 à 99 | vertes de BC |
  | 100 à 150 | bleues de BC |
  | 151 à 164 | épiques de BC |
  | 165 à 199 | vertes de Wrath |
  | 200 à 244 | bleues de Wrath |
  | 245 et plus | épiques de Wrath |

- **Trois gemmes de `GemsWrath.lua` sont fausses** d'après le client :

  | Gemme | Erreur | Conséquence |
  |---|---|---|
  | 24030 | notée `SpellDamage = 9` au lieu de `SpellPower = 9` | `SpellDamage` ne vaut rien dans les échelles Wrath : jamais choisie |
  | 32196 | notée `SpellDamage = 12` au lieu de `SpellPower = 12` | idem |
  | 23100 (Sovereign Shadow Draenite, `GemsWrath.lua:120`) | porte l'ID de la gemme orange 23100 (Agilité 3, toucher 3, rouge et jaune, juste à la ligne 78) | son ID dans le client est 23111 (Force 3, Endurance 4, couleur 10 = rouge et bleu) : la gemme 23111 manque, la 23100 est en double |

  Les 366 autres gemmes ont les mêmes stats et la même couleur que le client.

### Décisions

- La qualité de gemme dépend du niveau du personnage, pas du niveau de l'objet (option A). Jusqu'au niveau 70, ce sont les meilleures bleues de BC. À partir du niveau 71, ce sont les meilleures bleues de Wrath. Il en va de même pour les méta-gemmes. Limite acceptée : en phase 80, un personnage encore sous le niveau 70 se voit supposer des bleues de BC.
- L'option « Ignorer les châsses des objets de bas niveau » n'est pas modifiée par le code. L'utilisateur la décoche dans le jeu.

### Hors périmètre

- Les effets des méta-gemmes : le poids `MetaSocket` des échelles HawsJon ne change pas.
- Les gemmes vertes et épiques : leurs tables restent dans le fichier mais ne servent plus.
- `PawnMinimumItemLevelToConsiderGems` (187).
- Le DPS d'arme : sous-projet suivant.

## 1. Qualité de gemme selon le niveau du personnage (`GemsWrath.lua`)

La fonction `PawnWrathSetGemQualityForLevel(Level)` est ajoutée à la fin de `GemsWrath.lua`, dans le bloc `if VgerCore.IsWrath`. Les tables de gemmes y sont des variables locales. Elle remplace :

- `PawnGemQualityLevels` par `{ { 0, PawnGemData70Rare } }` si `Level <= 70`, sinon par `{ { 0, PawnGemData80Rare } }` ;
- `PawnMetaGemQualityLevels` par `{ { 0, PawnMetaGemData70Rare } }` si `Level <= 70`, sinon par `{ { 0, PawnMetaGemData80Rare } }`.

Le niveau est borné à `[1, 80]` comme dans `PawnClassicApplyRatingLevel`. La fonction retient la qualité choisie et renvoie `true` seulement si elle a changé.

Avec une seule entrée de niveau 0, `PawnGetGemQualityForItem` renvoie 0 pour tout objet : toutes les châsses supposent la même qualité, quel que soit le niveau de l'objet.

### Moments de l'appel

- **Au chargement :** dans `PawnClassicScaleProvider_AddScales` (`ClassicHawsJon.lua`), juste avant `PawnClassicApplyRatingLevel(UnitLevel("player"))`. `PawnInitialize` recalcule ensuite les meilleures gemmes de toutes les échelles (`Pawn.lua:532`).
- **Au passage de niveau :** dans le gestionnaire `PLAYER_LEVEL_UP` de `PawnClassicRatingLevelFrame`. Si la qualité a changé, Pawn appelle `PawnRecalculateScaleTotal` pour **toutes** les échelles de `PawnCommon.Scales`, échelles personnelles comprises, puis `PawnResetTooltips()`.
- **Avant le premier appel**, les tables d'origine restent en place. Le premier appel se fait toujours avant le premier calcul de valeur.

### Meilleurs objets mémorisés

Les listes `BestItems` sauvegardées ont été notées sans les châsses ou avec d'autres gemmes. `RatingWeightsVersion` (`ClassicHawsJon.lua`) passe de 1 à 2, ce qui les fait oublier une fois, comme au sous-projet 2.

## 2. Données de gemmes vérifiées contre le client

### Extraction

Le script `tests/extract_gems.py` (`uv run --with mpyq`, même principe que `tests/extract_enchant_stats.py`) écrit `tests/data/gems.frFR.txt`. Il lit deux fichiers du client :

- **`SpellItemEnchantment.dbc`** : enchantements de gemme, c'est-à-dire ceux dont le champ 33 (objet d'origine) n'est pas 0. Il relève l'identifiant de la gemme, les effets de stat (type 5 : numéro `ITEM_MOD_*` et montant) et le texte.
- **`GemProperties.dbc`** : couleur, par l'enchantement. Les numéros de champs sont confirmés à l'extraction et notés dans `CLAUDE.md`. Premiers relevés : 1 = enchantement, 4 = couleur, avec 1 = méta, 2 = rouge, 4 = jaune, 8 = bleu.

Format du fichier : une ligne par gemme, `IDgemme<TAB>couleur<TAB>numéro:montant[,numéro:montant]<TAB>texte`. L'en-tête cite les archives et le md5 des deux fichiers. Relancer le script sur les mêmes données donne le même fichier.

### Test

Pour chaque gemme de `GemsWrath.lua` (toutes les tables), le test vérifie :

- **ses stats** : celles de `gems.frFR.txt`, une fois les numéros convertis en stats Pawn par une table du test qui cite sa source ;
- **sa couleur** : `R`, `Y` et `B` correspondent aux bits 2, 4 et 8. Les méta-gemmes ne sont pas concernées.

La pénétration des sorts n'est pas un effet de stat dans le DBC (c'est un effet de type sort) : le test ignore `SpellPenetration`, avec un commentaire qui le dit. Une gemme absente du fichier fait échouer le test.

### Corrections

- 24030 et 32196 : `SpellDamage` devient `SpellPower` (9 et 12).
- Ligne 120 (Sovereign Shadow Draenite) : `ID = 23100` devient `ID = 23111`, stats et couleurs inchangées.

Chaque ligne corrigée cite `SpellItemEnchantment.dbc` en commentaire.

## 3. Tests hors jeu (`luajit tests/run.lua`)

Les tests qui créent les échelles Classic restent à la fin de `tests/unit.lua`.

1. **Données** : chaque gemme de `GemsWrath.lua` correspond au client (section 2).
2. **Qualité** : aux niveaux 1, 60 et 70, la table est celle des bleues de BC ; aux niveaux 71 et 80, celle des bleues de Wrath. Un second appel au même niveau renvoie `false`.
3. **Valeur d'un objet à châsses** : l'option est décochée et le personnage est au niveau 60. Pour un objet de niveau 105 à une châsse rouge sans bonus de sertissage, la châsse vaut la meilleure gemme de `PawnGemData70Rare` dans l'échelle, toutes couleurs confondues (Pawn envisage de ne pas respecter la couleur quand le bonus ne compense pas). Un objet de niveau 60 avec la même châsse obtient la même valeur. Option cochée, la châsse d'un objet de niveau 105 vaut 0.
4. **Passage de 70 à 71** : la meilleure gemme d'une échelle personnelle change de la table BC à la table Wrath, sans autre appel que celui de l'événement.
5. **Meilleurs objets** : une liste notée avec `RatingWeightsVersion = 1` est oubliée une fois.
6. **Clients non Wrath** : la fonction n'existe que dans le bloc `IsWrath`, et le gestionnaire vérifie qu'elle existe avant de l'appeler.

## 4. Vérifications en jeu (par l'utilisateur)

Après un redémarrage complet du client, avec Mairy (niveau 60) :

1. Décocher « Ignorer les châsses des objets de bas niveau » dans les options de Pawn.
2. `/pawn debug on`, puis survoler 24256. Les gemmes citées doivent être des bleues de BC, et la valeur doit compter les deux châsses ou le bonus de sertissage.
3. `/pawnscan inspect 24256` puis `/reload` : la valeur de « Prêtre : Sacré » est plus élevée qu'avant (71,53).
4. Onglet Comparer avec deux objets à châsses : pas d'erreur Lua.
