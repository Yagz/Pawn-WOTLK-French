---
name: cloture-session
description: Use when the user ends a work session on this repo ("clôture la session", "on s'arrête là", "je verrai demain", "/cloture-session"), before saying goodbye.
---

# Clôture de session

Une session se termine quand la suite peut reprendre sans relire la conversation : l'état est consigné, le reste à faire est précis, les erreurs de la session sont corrigées ou notées, et les manques d'outillage sont proposés.

## Étapes (dans l'ordre)

1. **Relever l'état réel** (preuves, pas de souvenirs) :
   - `git status -sb` et `git log --oneline origin/<branche>..HEAD` : changements non commités, commits non poussés.
   - `luajit tests/run.lua 2>&1 | tail -3` : nombre de tests réussis / échecs / todo.
   - S'il reste des changements non commités, demander à l'utilisateur s'il faut les commiter. Ne jamais les abandonner sans le dire.

2. **Consigner l'avancement** dans la mémoire `pawn-fr-project-state` (une ligne de statut datée par cycle en cours, remplacée et non empilée) :
   - cycle et sous-projet en cours, dernier commit (hash), documents (spec/plan) et leur statut (écrit, validé, en cours d'exécution : tâche N/M) ;
   - décisions prises dans la session, avec leur raison si elle n'est pas dans la spec ;
   - **prochaine étape exacte** (la première action de la prochaine session).

3. **Lister le reste à faire** :
   - côté Claude : étapes restantes du plan ou du cycle ;
   - côté utilisateur : vérifications en jeu en attente (`/reload` ou redémarrage complet du client si un fichier a été ajouté à `Pawn.toc`), relectures de spec/plan attendues.

4. **Chercher les corrections à faire**. Répondre explicitement à chaque question :
   - Une affirmation de la session s'est-elle révélée fausse ou non vérifiée ? La corriger ou la signaler.
   - `CLAUDE.md` est-il à jour (nombre de tests, commandes, fichiers, règles) ? Sinon, le corriger.
   - Une mémoire est-elle devenue fausse ou en double ? La mettre à jour ou la supprimer.
   - Une consigne de l'utilisateur dans cette session doit-elle devenir une mémoire `feedback` ?
   - Un document (spec, plan) contredit-il ce qui a été décidé ou codé ?

5. **Chercher les enrichissements d'outillage**. Pour chaque cas, **proposer** (nom, rôle, déclencheur) sans créer sans accord :
   - une séquence manuelle refaite au moins deux fois (extraction MPQ, import SavedVariables…) → script dans `tests/` ;
   - une procédure à plusieurs étapes que l'utilisateur redemandera → skill dans `.claude/skills/` ;
   - une recherche large ou une vérification indépendante récurrente → agent dans `.claude/agents/`.
   Si rien ne se justifie, l'écrire : « aucun nouvel outil justifié ».

6. **Pousser ?** Si des commits ne sont pas poussés, demander à l'utilisateur. Ne jamais pousser sans accord (commande dans la mémoire `pawn-fr-project-state`).

## Message final (structure fixe, en français)

```
**Fait** : …
**État** : branche, dernier commit, tests (N réussis, 0 échec), commits non poussés.
**Reste à faire** : prochaine étape exacte, puis la suite.
**En jeu (pour toi)** : vérifications en attente, ou « rien ».
**Corrections** : ce qui a été corrigé, ou « aucune ».
**Outillage proposé** : propositions, ou « aucun nouvel outil justifié ».
```

## Erreurs fréquentes

- Résumer de mémoire sans relancer `git` ni les tests.
- Écrire « prochaine étape : continuer » au lieu d'une action précise.
- Empiler les statuts dans la mémoire au lieu de remplacer la ligne du cycle.
- Créer un skill, une commande ou un agent sans accord : à cette étape, on propose seulement.
- Oublier de signaler des commits non poussés.
