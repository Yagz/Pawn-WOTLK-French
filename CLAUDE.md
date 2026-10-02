# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Pawn 2.8.11 as backported to WoW 3.3.5a by MarkosF (https://github.com/MarkosF/Pawn-WotLK-Fix), with French (frFR) tooltip parsing rebuilt from the 3.3.5a client's own data. It runs on a 3.3.5a client with `!!!ClassicAPI` installed. `!!!ClassicAPI` makes Pawn believe it runs on Wrath Classic (`WOW_PROJECT_ID`), and `Core.lua` forces `VgerCore.IsWrath = true`. Runtime is Lua 5.1.

## Commands

All commands run from the addon root.

- `luajit tests/run.lua` — unit tests plus every corpus file; exit code 1 on failure. Currently 2113 passing, 0 failures, 0 todo.
- `luajit tests/run.lua tests/corpus/X.txt` — one corpus file.
- `luajit tests/run.lua --propose tests/corpus/X.txt` — print what Pawn currently reads for each `todo` line.
- `luajit tests/gen_corpus.lua` — regenerate the corpus from `tests/data/` (adds new texts only).
- `luajit tests/import.lua logs | unknown <SV> | parsed <SV>` — import real lines; `<SV>` is `WTF/Account/<ACCOUNT>/SavedVariables/Pawn.lua`.
- In game: `/pawnscan [first last] | gems | enchants | stop | status | clear | speed <n>`, and `/pawn debug on` to print every line Pawn doesn't understand. SavedVariables are only written on `/reload` or a clean quit.
- `/pawnscan gems` iterates gem enchant IDs 2686..3879 (from GemProperties.dbc) in the first jewel slot of the base item: 3.3.5a jewel link fields take SpellItemEnchantment IDs, not gem item IDs.
- Scanning needs the items cached: first pass at `/pawnscan speed 100` to warm the cache, then `/pawnscan clear` and a fast pass (`speed 500`). New files in `Pawn.toc` need a full client restart, not `/reload`.
- `GetItemStats` exists in this client. `mismatch` entries are expected noise in gems/enchants modes and when an item has both melee and spell crit keys; the goal is "every mismatch explained", not an empty list.

## Architecture

- `TooltipParsing.lua` builds `PawnRegexes` / `PawnRightHandRegexes` from the keyed patterns in `PawnLocal.TooltipParsing` (`#` = number).
- On frFR clients, `TooltipParsing.frFR.lua` (loaded right after it) **replaces** those tables, together with the separators, the equip/use prefixes, `PawnLocal.TooltipParsing.SocketBonusPrefix` and the decimal separators. The upstream frFR patterns come from Wrath Classic and don't match 3.3.5a text.
- Most FR patterns are built at load time from the client's GlobalStrings via `PawnFrFormatToPattern` / `PawnFrPattern` / `PawnFrEquipPattern` / `PawnFrSpellPattern`.
- `Pawn.lua`: `PawnGetStatsFromTooltip` → `PawnLookForSingleStat`. On frFR it turns non-breaking spaces into spaces before matching. Rows are `{pattern, Stat, N, Source, ...}`. Unknown lines before the first understood line of a tooltip are ignored (~line 2251), so neither the scanner nor `/pawn debug` reports them.
- `PawnScan.lua` drives `PawnGetStatsForItemLink` over item IDs, gems and enchants, and stores unknown and parsed line templates and Lua errors in `PawnScanResults`.
- `tests/harness.lua` loads the real addon files under LuaJIT with `tests/wowapi.lua` stubs and the client constants in `tests/data/GlobalStrings.frFR.lua`.

## Rules

- Every FR pattern must come from real data (`tests/data/` client extracts, or lines seen in game) and cite its source in a comment. Never copy patterns from other Pawn versions (including this one's `Localization.frFR.lua`) or write French text from memory.
- Never retype client text into corpus files; generate it.
- Use the Wrath stat names valued by `ClassicHawsJon.lua` (`SpellPower`, `CritRating`, `HitRating`, `HasteRating`, `Armor`…). Spell-specific rating lines count as the combined rating.
- Lua patterns are byte-based: never put an accented letter inside `[...]` or match it with `.`.
- frFR GlobalStrings put a no-break space (`\194\160`) before ":" in ~40 constants. Every constant-derived string must go through the local `PawnFrNoNbsp` (already used by `PawnFrFormatToPattern` and the PawnFr* helpers). Never build rows with `PawnGameConstant` / `PawnGameConstantUnwrapped`: they only escape `%` and `-` (so "Tenu(e) …" breaks) and don't normalize NBSP.
- Fixes for `!!!ClassicAPI` incompatibilities stay minimal, commented, and in their own commit. Two exist: `PawnGetClassInfo` (accepts the table returned by `!!!ClassicAPI`'s `GetClassInfo`) and `PawnUI_GetQuestRewardButton` (3.3.5a reward buttons are `QuestInfoItemN`, per the client's FrameXML `QuestInfo.lua`).
- `tests/data/` was extracted from `Data/frFR/*.MPQ` with a throwaway Python + `mpyq` script. The field numbers used: `Spell.dbc` description 172, `SpellItemEnchantment.dbc` text 16, `ItemSubClass.dbc` name 12.
