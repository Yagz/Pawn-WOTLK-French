# Pawn 2.8.11 (portage MarkosF) — lecture des infobulles frFR sur le client 3.3.5a

Date : 2026-10-02
Branche : `fr-2.8.11`, créée depuis `markos-2.8.11` (import de [MarkosF/Pawn-WotLK-Fix](https://github.com/MarkosF/Pawn-WotLK-Fix), Pawn 2.8.11 porté en 3.3.5a, avec le correctif !!!ClassicAPI de l'essai).
Remplace : `docs/superpowers/specs/2026-10-02-fr-tooltip-parsing-design.md` (branche `fr-335`, base 1.3.12, abandonnée après l'essai en jeu).

## Objectif

Sur le client WoW 3.3.5a en `frFR`, Pawn 2.8.11 doit reconnaître toutes les stats des infobulles d'objets et les compter correctement. Cela vaut pour les objets Vanilla, TBC et WotLK, car le serveur ouvre son contenu par phases. Ce cycle couvre **uniquement l'analyse des infobulles**.

### Hors périmètre (cycles ultérieurs)

- Relecture des textes d'interface FR de la 2.8.11 (ils sont conservés tels quels).
- Échelles et gemmes par phase (60 / 70 / 80).
- Fusion dans `main`.

## Constat de départ (essai en jeu du 2026-10-02)

- **La 2.8.11 se charge sur le client de l'utilisateur**, qui a !!!ClassicAPI installé, à une condition : le correctif de `PawnGetClassInfo`. !!!ClassicAPI renvoie une table là où Pawn attend trois valeurs. Avec ce correctif, il n'y a aucune erreur Pawn, les échelles « Classic » (mode Wrath) sont créées et les valeurs sont calculées.
- **Ses motifs FR viennent de Wrath Classic et ne collent pas au client 3.3.5.**
  - En jeu, sur le Récolteur d'essence, Pawn signale `(?) ne comprend pas "83 - 156 points de dégâts (Arcanes)"`, puis l'erreur « couldn't read speed and damage stats ».
  - Hors jeu, sur les textes réels du client, seuls 25 % des modèles d'enchantements et de gemmes et 6 % des lignes relevées en jeu sont reconnus. Parmi les lignes manquées : puissance des sorts par école (« Augmente la puissance des sorts d'Ombre de 33. »), résistances (« +5 à la résistance au Feu »), « +3 Armure »…

## Principe : partir uniquement des données réelles

Aucun motif ni texte n'est repris d'office d'une source tierce : ni de l'ancienne tentative (`main`), ni des motifs FR existants de la 2.8.11 ou de VgerMods. Chaque motif FR doit pouvoir être justifié par une de ces sources :

1. **Les fichiers du client frFR 3.3.5a**, extraits des MPQ de `Data/frFR/` (le patch le plus récent l'emporte) :
   - `Interface/FrameXML/GlobalStrings.lua` : les formats exacts des lignes d'infobulle ;
   - `DBFilesClient/Spell.dbc` (description frFR, champ 172) : les formulations « Équipé : … » des objets anciens ;
   - `DBFilesClient/SpellItemEnchantment.dbc` (texte frFR, champ 16) : le texte de chaque enchantement, gemme et bonus de châsse ;
   - `DBFilesClient/ItemSubClass.dbc` (nom frFR, champ 12) : les types d'armes et d'armures (« Epée », sans accent).
2. **Les lignes relevées en jeu** :
   - `tests/data/pawndebuglogs.frFR.txt`, soit 179 lignes de l'ancien `PawnDebugLogs`, déjà sauvegardées ;
   - le scanner en jeu (section 5) ;
   - le débogage de Pawn (`/pawn debug on`), recopié par l'utilisateur.

## Décisions

- **La lecture FR vit dans un nouveau fichier, `TooltipParsing.frFR.lua`, chargé juste après `TooltipParsing.lua`.** Sa première instruction est `if GetLocale() ~= "frFR" then return end`. Sur un client frFR, il **remplace entièrement** :
  - `PawnRegexes` et `PawnRightHandRegexes` ;
  - `PawnSeparators`, `PawnSeparatorIgnorePrefixes` et `PawnNormalizationRegexes` ;
  - `PawnLocal.TooltipParsing.SocketBonusPrefix`, seule clé lue directement par `Pawn.lua` ;
  - `PawnLocal.ThousandsSeparator` et `PawnLocal.DecimalSeparator`, réglés d'après les données réelles.

  Les autres fichiers de la 2.8.11 ne changent pas, à deux exceptions près : le correctif !!!ClassicAPI de `Pawn.lua`, déjà fait, et le `.toc`.
- **Les noms de stats sont ceux que valorisent les échelles Wrath de la 2.8.11** (`ClassicHawsJon.lua`, mode Wrath) : `SpellPower`, `CritRating`, `HitRating`, `HasteRating`, `ExpertiseRating`, `ArmorPenetration`, `Armor`, `Mp5`, `Hp5`, `Health`, `Mana`, `FireSpellDamage`…
  - En 3.3.5, les scores sont unifiés : une ligne « score de coup critique / toucher / hâte des sorts » compte comme `CritRating`, `HitRating` ou `HasteRating`.
  - Les stats propres à Classic (`SpellDamage`, `Healing`, `SpellCritRating`…) ne sont pas utilisées.
- **La dépendance à !!!ClassicAPI est assumée** et documentée dans `CLAUDE.md`.
- **Les textes d'interface FR de la 2.8.11 sont conservés.** Ils ne relèvent pas de l'analyse des infobulles.

## Conception

### 1. `TooltipParsing.frFR.lua`

- **Une fonction globale, `PawnFrFormatToPattern(Format)`**, convertit un format de `GlobalStrings.lua` en motif Lua :
  - `%d` et `%c%d` deviennent des captures de nombres ;
  - `%.1f` devient une capture décimale ;
  - `%%` devient un `%` littéral ;
  - `%s` et `|4a:b;` correspondent à n'importe quel texte, sans capture ;
  - les formes positionnelles (`%1$d`) sont acceptées.

  Les motifs qui viennent du client sont construits **à l'exécution** à partir de ses constantes (par exemple `ITEM_SPELL_TRIGGER_ONEQUIP .. " " .. ITEM_MOD_CRIT_RATING`). Ils collent donc exactement au texte affiché.
- **Les tables suivent le format de lignes de la 2.8.11** : `{motif, Stat, N, Source, ...}`, avec `PawnMultipleStatsFixed`, `PawnMultipleStatsExtract` et `PawnSingleStatMultiplier` définis dans `Core.lua`.
  - L'ordre compte : la première correspondance gagne.
  - **Chaque ligne cite sa source en commentaire** : `GlobalStrings: CONSTANTE`, `Spell.dbc`, `SpellItemEnchantment.dbc`, `ItemSubClass.dbc`, `logs` ou `scan`.
- **Règle des motifs Lua sur des octets.** Un caractère accentué ne doit jamais apparaître dans une classe `[...]`, ni être visé par `.`. Les variantes (`’`, espace insécable) ne sont ajoutées que si une donnée réelle les montre.
- **Les effets que Pawn ne chiffre pas restent non compris** et affichent `(?)` : procs, effets de classe, pourcentages, compétences d'arme. Ils sont classés `unhandled` dans le jeu de tests.

### 2. Banc d'essai hors jeu (`tests/`)

`tests/` n'est pas listé dans le `.toc`, donc WoW ne le charge pas.

- **`tests/wowapi.lua`** imite l'API WoW nécessaire au **chargement** des fichiers de la 2.8.11 et à l'analyse.
  - Le premier travail est d'inventorier ce que ces fichiers appellent au chargement : `GetBuildInfo`, `CreateFrame`, `hooksecurefunc`, `UnitClass`… Ensuite, on imite seulement ce qui est nécessaire, jamais en modifiant le code de Pawn.
  - Les constantes du projet que fournit !!!ClassicAPI (`WOW_PROJECT_ID`…) sont reproduites d'après ses propres fichiers.
  - Toute lecture d'une constante WoW absente (nom en MAJUSCULES) provoque une erreur explicite.
- **`tests/data/GlobalStrings.frFR.lua`** contient le sous-ensemble utile du `GlobalStrings.lua` du client.
- **`tests/harness.lua`** charge les fichiers de l'addon dans l'ordre du `.toc` (les fichiers d'interface et de fournisseurs d'échelles seulement s'ils sont nécessaires). Il expose **`ParseLine(gauche, droite)`**, qui fait passer une ligne dans le vrai `PawnGetStatsFromTooltip` à travers une infobulle factice. La fonction renvoie :
  - les stats brutes trouvées, avant le post-traitement de Pawn ;
  - si la ligne a été comprise ;
  - les erreurs (`VgerCore.Fail` ou exception Lua).
- **`luajit tests/run.lua [--propose] [fichiers]`** (lancé depuis la racine de l'addon) exécute les tests unitaires et le jeu de tests. Il sort avec le code 1 s'il y a au moins un échec. `--propose` affiche la lecture actuelle des lignes à classer.

### 3. Jeu de tests (`tests/corpus/*.txt`)

**Format :** une ligne par cas. Les lignes vides et celles qui commencent par `#` sont ignorées. Le séparateur est la **dernière** occurrence de ` => `.

```
<texte de gauche>[ || <texte de droite>]  => Stat=valeur[; Stat2=valeur]
|| <texte de droite seul>                 => Stat=valeur
<texte>                                   => ignored | unhandled | todo
```

- `ignored` : la ligne est comprise, mais elle ne vaut aucune stat.
- `unhandled` : la ligne doit rester non comprise.
- `todo` : la ligne n'est pas encore classée. Elle apparaît dans le bilan sans faire échouer le banc.

**Les textes ne sont jamais retapés à la main** : ils sont générés à partir des octets extraits.

| Fichier | Contenu | Origine |
|---|---|---|
| `globalstrings.txt` | une ligne par format de `GlobalStrings.lua` utile, avec la stat attendue | `tests/gen_corpus.lua` |
| `itemsubclass.txt` | types d'armes et d'armures (texte de droite) | `tests/gen_corpus.lua` |
| `spells.txt` | une ligne « Équipé : … » par modèle de `Spell.dbc`, classée à la main | `tests/gen_corpus.lua`, puis classement |
| `enchants.txt` | un exemple réel par modèle de `SpellItemEnchantment.dbc`, classé à la main | `tests/gen_corpus.lua`, puis classement |
| `logs.txt` | les 179 lignes de `PawnDebugLogs`, classées (noms d'objets et sorts du grimoire retirés) | `tests/import.lua logs`, puis classement |
| `scan.txt` | un exemple réel par modèle de ligne non comprise relevé par le scanner | `tests/import.lua unknown`, puis classement |
| `regression.txt` | les lignes comprises relevées par le scanner, relues | `tests/import.lua parsed` |

L'extraction des MPQ se fait en Python, avec `mpyq`, dans un environnement virtuel du scratchpad. Les scripts d'extraction ne sont pas commités ; seules les données utiles le sont, dans `tests/data/`.

### 4. Scanner en jeu (`PawnScan.lua`)

Ce fichier est ajouté au `.toc`, avec la SavedVariable `PawnScanResults`. Il appelle `PawnGetStatsForItemLink(lien, false)`, qui renvoie `Stats, SocketBonusStats, UnknownLines`, sans modifier le moteur.

**Commandes :**
- **`/pawnscan [début fin]`** parcourt les numéros d'objets (par défaut 1 à 56 000) et ne garde que les objets équipables.
  - Un objet absent du cache est redemandé jusqu'à 3 fois, à 1 s d'intervalle. À la première absence, le scanner sollicite aussi le serveur par une infobulle cachée (`SetHyperlink`).
  - Sans argument, la commande reprend le scan interrompu.
- **`/pawnscan gems [objet]`** et **`/pawnscan enchants [objet]`** testent les gemmes (tables de gemmes de la 2.8.11) et les enchantements (identifiants 1 à 4 000), posés sur un objet à châsses.
- **`/pawnscan stop | status | clear | speed <n>`**.

**Fonctionnement :**
- Débit par défaut : 10 entrées par seconde, grâce à un cadre `OnUpdate`. Après un pic de latence, le scanner ne rattrape pas plus d'une seconde de retard.
- La position est sauvegardée, donc le scan reprend après un `/reload`.

**Résultats, regroupés par modèle (les nombres sont remplacés par `#`) :**
- `unknown[modèle] = { count, example, line }` ;
- `parsed[modèle] = { line, stats }` ;
- `errors[exemple]` : chaque erreur Lua attrapée pendant l'analyse, pour faire remonter d'autres incompatibilités avec !!!ClassicAPI ;
- `summary`.

**Vérification des valeurs.** Si `GetItemStats` existe (à vérifier avec `/run print(GetItemStats)`, puisque !!!ClassicAPI peut la fournir), les écarts avec les clés `ITEM_MOD_*_SHORT` sont enregistrés dans `mismatch`.

**Rappel :** WoW n'écrit les SavedVariables que lors d'un `/reload` ou d'une sortie propre (Échap → Quitter le jeu).

### 5. Déroulé et points de vérification en jeu

1. Extraction des données du client, banc d'essai, squelette `TooltipParsing.frFR.lua`, scanner, import.
2. **Vérification en jeu n° 1 (scan de référence).**
   - Petit scan (`/pawnscan 40000 40100`, puis `status`), puis scan complet.
   - À ce stade, ce sont encore les motifs Wrath Classic de la 2.8.11 qui sont actifs. Le scan relève donc l'ensemble réel des lignes que Pawn ne comprend pas.
3. Génération du jeu de tests à partir des données du client, classement, écriture des tables FR, jusqu'à ce que `luajit tests/run.lua` passe.
4. **Vérification en jeu n° 2.** Scan complet, puis `gems` et `enchants`, plus un contrôle visuel. On recommence l'étape 3 tant qu'il reste des lignes.
5. Documentation (`CLAUDE.md`, `Readme.md`).

## Critères de réussite

1. `luajit tests/run.lua` passe sans aucun échec, et il ne reste aucune ligne `todo`.
2. Un `/pawnscan` complet sur le client FR ne laisse **aucune ligne `unknown` portant une stat que Pawn sait évaluer**. Les lignes inconnues restantes sont toutes classées `unhandled`. `gems` et `enchants` ne laissent aucune ligne inconnue non classée. `errors` est vide, et `mismatch` aussi si `GetItemStats` existe.
3. Contrôle visuel en jeu par l'utilisateur. Le Récolteur d'essence (19435) affiche ses dégâts (Arcanes) sans `(?)` ni erreur. Quelques objets avec gemmes, enchantement et bonus de châsse affichent une valeur.
4. Sur un client enUS, `TooltipParsing.frFR.lua` ne change rien.

## Risques

- **!!!ClassicAPI peut cacher d'autres incompatibilités** que celle de `GetClassInfo`. Le scanner les relève (`errors`), et BugSack aussi. Chaque correctif dans le code de la 2.8.11 est minimal, commenté et commité à part.
- **Le banc d'essai doit imiter beaucoup d'API** pour charger `Pawn.lua` de la 2.8.11 (5 800 lignes). Si c'est ingérable, il charge `TooltipParsing.frFR.lua` et seulement les fonctions d'analyse de `Pawn.lua` (`PawnGetStatsFromTooltip`, `PawnLookForSingleStat`, `PawnFindStringInRegexTable` et leurs dépendances), extraites à la lecture du fichier.
- **Les requêtes d'objets absents du cache peuvent provoquer une déconnexion** si le débit est trop élevé. Le débit est donc réglable, et le scan peut reprendre.
- **`Spell.dbc` ne dit pas quels sorts sont portés par des objets.** `spells.txt` contient aussi des sorts de classe, qui sont classés `unhandled`. C'est le scan qui fait foi.
- **Le séparateur décimal du client** (« Vitesse 2,60 » ou « 2.60 », DPS) n'est pas connu d'avance. Il est réglé d'après le scan, et les deux formes sont acceptées tant qu'il n'est pas confirmé.
