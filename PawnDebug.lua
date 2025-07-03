-- ========================================
-- PAWN DEBUG HYBRIDE - WoW 3.3.5 CORRIGÉ
-- Mode Minimal (défaut) + Mode Verbeux (optionnel)
-- ========================================

-- Variables globales
PawnDebugInitialized = false
PawnDebugOriginalFunction = nil
PawnDebugSessionId = nil
local PawnDebugProcessedStrings = {}

-- ========================================
-- STRUCTURE HYBRIDE PERSISTANTE
-- ========================================

if not PawnDebugLogs then
    PawnDebugLogs = {
        -- Mode minimal - échecs uniquement (compact)
        failed_only = {},
        
        -- Mode verbeux - sessions détaillées (quand activé)
        sessions = {},
        
        -- Statistiques partagées
        stats = {
            total_processed = 0,
            unique_failures = 0,
            total_success = 0,
            last_updated = ""
        },
        
        -- Paramètres persistants (sauvés)
        settings = {
            enabled = false,
            verboseMode = false,           -- PERSISTANT: Mode choisi
            anti_spam_seconds = 5,
            maxLogs = 200,                 -- Pour mode verbeux
            maxSessions = 3,               -- Pour mode verbeux
            logEncoding = true,            -- Analyse encodage (verbeux)
            logNormalization = true,       -- Test normalisation (verbeux)
            logRegexTests = false          -- Détail regex (verbeux)
        },
        
        -- Métadonnées
        _version = "1.2_fixed",
        _loadCount = 0
    }
end

-- Incrémenter le compteur de chargement
PawnDebugLogs._loadCount = (PawnDebugLogs._loadCount or 0) + 1

-- ========================================
-- DÉTECTION DE MOTS-CLÉS FRANÇAIS (CORRIGÉ)
-- ========================================

local FrenchKeywords = {
    -- Stats principales
    "Force", "Agilité", "Endurance", "Intelligence", "Esprit",
    
    -- Scores et ratings
    "Score", "score", "défense", "toucher", "critique", "hâte",
    "pénétration", "régénération", "maîtrise",
    
    -- Types d'équipement et combat
    "Armure", "armure", "dégâts", "Dégâts", "arme",
    "Bloquer", "bloquer", "parade", "esquive",  -- AJOUTÉ: Bloquer manquait !
    
    -- Termes d'équipement
    "Équipé", "Lié", "quand", "ramassé", "utilisé",
    
    -- Chiffres avec + ou espaces (patterns simples)
    "^%+%d", "^%d+", ": %d+", "de %d+"
}

local function HasFrenchKeywords(str)
    if not str then return false end
    
    for _, keyword in pairs(FrenchKeywords) do
        if strfind(str, keyword) then
            return true
        end
    end
    
    return false
end

-- ========================================
-- FONCTIONS D'ANALYSE POUR MODE VERBEUX
-- ========================================

local function AnalyzeStringEncoding(inputString, label)
    if not inputString then return nil end
    
    local analysis = {
        hasHighBytes = false,
        suspiciousPatterns = {},
        byteAnalysis = {},
        summary = ""
    }
    
    -- Analyser chaque caractère
    for i = 1, strlen(inputString) do
        local byte = strbyte(inputString, i)
        table.insert(analysis.byteAnalysis, byte)
        
        if byte > 127 then
            analysis.hasHighBytes = true
        end
        
        -- Patterns UTF-8 corrompus typiques
        if byte == 195 then -- Ã
            local nextByte = strbyte(inputString, i + 1)
            if nextByte then
                table.insert(analysis.suspiciousPatterns, "UTF8_CORRUPTION")
            end
        end
    end
    
    analysis.summary = (analysis.hasHighBytes and "HIGH_BYTES" or "ASCII_ONLY") .. 
                      (table.getn(analysis.suspiciousPatterns) > 0 and "_CORRUPT" or "_CLEAN")
    
    return analysis
end

local function TestNormalization(inputString)
    if not inputString or not PawnCleanString then 
        return {applied = false, result = inputString} 
    end
    
    local normalized = PawnCleanString(inputString)
    return {
        applied = (normalized ~= inputString),
        original = inputString,
        result = normalized,
        appliedRule = normalized ~= inputString and "encoding_fix" or nil
    }
end

-- ========================================
-- GESTION DES SESSIONS (MODE VERBEUX)
-- ========================================

local function GetCurrentSession()
    if not PawnDebugSessionId then
        PawnDebugSessionId = date("%m%d_%H%M")
        PawnDebugLogs.sessions[PawnDebugSessionId] = {
            started = date(),
            logs = {},
            stats = {
                total = 0,
                success = 0,
                failed = 0,
                normalized = 0,
                encoding_issues = 0
            }
        }
        
        -- Nettoyer les anciennes sessions
        local sessionCount = 0
        for _ in pairs(PawnDebugLogs.sessions) do sessionCount = sessionCount + 1 end
        
        if sessionCount > PawnDebugLogs.settings.maxSessions then
            local sessionList = {}
            for sessionId in pairs(PawnDebugLogs.sessions) do
                table.insert(sessionList, sessionId)
            end
            table.sort(sessionList)
            
            while table.getn(sessionList) > PawnDebugLogs.settings.maxSessions do
                local oldestSession = table.remove(sessionList, 1)
                PawnDebugLogs.sessions[oldestSession] = nil
            end
        end
    end
    
    return PawnDebugLogs.sessions[PawnDebugSessionId]
end

-- ========================================
-- LOGGING MINIMAL (Mode par défaut)
-- ========================================

local function LogMinimal(inputString, result)
    if not inputString or inputString == "" then return end
    
    -- Anti-spam
    local currentTime = GetTime()
    if PawnDebugProcessedStrings[inputString] and 
       (currentTime - PawnDebugProcessedStrings[inputString]) < PawnDebugLogs.settings.anti_spam_seconds then
        return
    end
    PawnDebugProcessedStrings[inputString] = currentTime
    
    -- Statistiques globales
    PawnDebugLogs.stats.total_processed = PawnDebugLogs.stats.total_processed + 1
    if result then
        PawnDebugLogs.stats.total_success = PawnDebugLogs.stats.total_success + 1
        return -- Ne pas logger les succès en mode minimal
    end
    
    -- Nettoyer la string
    local cleanString = inputString
    if PawnCleanString then
        cleanString = PawnCleanString(inputString)
    end
    
    -- Logger uniquement les échecs
    if not PawnDebugLogs.failed_only[cleanString] then
        PawnDebugLogs.failed_only[cleanString] = {
            count = 0,
            has_keywords = HasFrenchKeywords(cleanString),
            last_seen = date("%m-%d")
        }
        PawnDebugLogs.stats.unique_failures = PawnDebugLogs.stats.unique_failures + 1
    end
    
    PawnDebugLogs.failed_only[cleanString].count = PawnDebugLogs.failed_only[cleanString].count + 1
    PawnDebugLogs.failed_only[cleanString].last_seen = date("%m-%d")
    PawnDebugLogs.stats.last_updated = date("%H:%M")
end

-- ========================================
-- LOGGING VERBEUX (Mode optionnel)
-- ========================================

local function LogVerbose(logType, inputString, result, details)
    local session = GetCurrentSession()
    
    -- Anti-spam pour les détails verbeux aussi
    local stringKey = inputString or "nil"
    local currentTime = GetTime()
    if PawnDebugProcessedStrings[stringKey] and 
       (currentTime - PawnDebugProcessedStrings[stringKey]) < PawnDebugLogs.settings.anti_spam_seconds then
        return
    end
    PawnDebugProcessedStrings[stringKey] = currentTime
    
    -- Créer le log détaillé
    local logEntry = {
        timestamp = date("%H:%M:%S"),
        type = logType,
        input = inputString or "nil",
        result = result or "unknown"
    }
    
    -- Analyses optionnelles
    if PawnDebugLogs.settings.logEncoding and inputString then
        logEntry.encoding = AnalyzeStringEncoding(inputString, "input")
    end
    
    if PawnDebugLogs.settings.logNormalization and inputString then
        logEntry.normalization = TestNormalization(inputString)
    end
    
    -- Ajouter les détails spécifiques
    if details then
        for k, v in pairs(details) do
            logEntry[k] = v
        end
    end
    
    -- Ajouter à la session
    table.insert(session.logs, logEntry)
    session.stats.total = session.stats.total + 1
    
    -- Statistiques de session
    if logType == "SUCCESS" then
        session.stats.success = session.stats.success + 1
    elseif logType == "FAIL" then
        session.stats.failed = session.stats.failed + 1
    end
    
    if logEntry.normalization and logEntry.normalization.applied then
        session.stats.normalized = session.stats.normalized + 1
    end
    
    if logEntry.encoding and logEntry.encoding.hasHighBytes then
        session.stats.encoding_issues = session.stats.encoding_issues + 1
    end
    
    -- Limiter la taille des logs
    if table.getn(session.logs) > PawnDebugLogs.settings.maxLogs then
        table.remove(session.logs, 1)
    end
    
    -- AUSSI logger en mode minimal pour garder les stats globales
    LogMinimal(inputString, result == "success" or result == true)
end

-- ========================================
-- FONCTION DEBUG PRINCIPALE HYBRIDE (CORRIGÉE)
-- ========================================

local function PawnLookForSingleStat_Hybrid(RegexTable, Stats, ThisString, DebugMessages)
    -- Si debug désactivé, utiliser l'original directement
    if not PawnDebugLogs.settings.enabled then
        if PawnDebugOriginalFunction then
            return PawnDebugOriginalFunction(RegexTable, Stats, ThisString, DebugMessages)
        else
            return false
        end
    end
    
    -- Appeler la fonction originale pour obtenir le résultat
    local result = false
    if PawnDebugOriginalFunction then
        result = PawnDebugOriginalFunction(RegexTable, Stats, ThisString, DebugMessages)
    end
    
    -- Logger selon le mode choisi
    if ThisString and ThisString ~= "" then
        if PawnDebugLogs.settings.verboseMode then
            -- Mode verbeux : log détaillé
            local logType = result and "SUCCESS" or "FAIL"
            local details = {
                regex_count = RegexTable and table.getn(RegexTable) or 0,
                stats_count = Stats and table.getn(Stats) or 0
            }
            
            -- Tests de regex détaillés si activés
            if PawnDebugLogs.settings.logRegexTests and RegexTable and not result then
                details.tested_regexes = {}
                for i, regex in pairs(RegexTable) do
                    if regex.Pattern then
                        local testResult = strfind(ThisString or "", regex.Pattern)
                        table.insert(details.tested_regexes, {
                            pattern = regex.Pattern,
                            matched = testResult ~= nil
                        })
                    end
                end
            end
            
            LogVerbose(logType, ThisString, result, details)
            
            -- Message dans le chat si verbeux
            if result then
                print("DEBUG SUCCESS: \"" .. (ThisString or "NIL") .. "\"")
            else
                print("DEBUG FAIL: \"" .. (ThisString or "NIL") .. "\"")
            end
        else
            -- Mode minimal : log compact
            LogMinimal(ThisString, result)
        end
    end
    
    return result
end

-- ========================================
-- COMMANDES DE GESTION
-- ========================================

function PawnDebugShowStatus()
    print("=== PAWN DEBUG STATUS ===")
    print("Initialized: " .. tostring(PawnDebugInitialized))
    print("Hook active: " .. tostring(PawnLookForSingleStat == PawnLookForSingleStat_Hybrid))
    print("Mode: " .. (PawnDebugLogs.settings.verboseMode and "VERBEUX" or "MINIMAL"))
    print("Enabled: " .. tostring(PawnDebugLogs.settings.enabled))
    print("Load count: " .. PawnDebugLogs._loadCount)
    print("Version: " .. PawnDebugLogs._version)
    
    -- Statistiques globales
    print("\n--- STATISTIQUES GLOBALES ---")
    print("Total processed: " .. PawnDebugLogs.stats.total_processed)
    print("Success: " .. PawnDebugLogs.stats.total_success)
    print("Unique failures: " .. PawnDebugLogs.stats.unique_failures)
    print("Last updated: " .. PawnDebugLogs.stats.last_updated)
    
    -- Statistiques de session (mode verbeux)
    if PawnDebugLogs.settings.verboseMode and PawnDebugSessionId then
        local session = PawnDebugLogs.sessions[PawnDebugSessionId]
        print("\n--- SESSION ACTUELLE (" .. PawnDebugSessionId .. ") ---")
        print("Total: " .. session.stats.total)
        print("Success: " .. session.stats.success)
        print("Failed: " .. session.stats.failed)
        print("Normalized: " .. session.stats.normalized)
        print("Encoding issues: " .. session.stats.encoding_issues)
    end
    
    -- Top échecs (toujours disponible)
    print("\n--- TOP FAILURES ---")
    local failures = {}
    for str, data in pairs(PawnDebugLogs.failed_only) do
        table.insert(failures, {str = str, count = data.count, keywords = data.has_keywords})
    end
    
    -- Tri par count
    for i = 1, table.getn(failures) do
        for j = i + 1, table.getn(failures) do
            if failures[i].count < failures[j].count then
                local temp = failures[i]
                failures[i] = failures[j]
                failures[j] = temp
            end
        end
    end
    
    for i = 1, min(5, table.getn(failures)) do
        local f = failures[i]
        local kwIndicator = f.keywords and "[KW]" or "[  ]"
        print(kwIndicator .. " " .. f.count .. "x: \"" .. f.str .. "\"")
    end
    
    print("\n--- PARAMÈTRES ---")
    print("Anti-spam: " .. PawnDebugLogs.settings.anti_spam_seconds .. "s")
    if PawnDebugLogs.settings.verboseMode then
        print("Max logs: " .. PawnDebugLogs.settings.maxLogs)
        print("Log encoding: " .. tostring(PawnDebugLogs.settings.logEncoding))
        print("Log normalization: " .. tostring(PawnDebugLogs.settings.logNormalization))
        print("Log regex tests: " .. tostring(PawnDebugLogs.settings.logRegexTests))
    end
end

function PawnDebugShowRecent()
    if PawnDebugLogs.settings.verboseMode then
        -- Mode verbeux : logs de session
        if not PawnDebugSessionId then
            print("No active session")
            return
        end
        
        local session = PawnDebugLogs.sessions[PawnDebugSessionId]
        print("=== RECENT LOGS (VERBOSE) ===")
        
        local logCount = table.getn(session.logs)
        local startIndex = max(1, logCount - 9)
        
        for i = startIndex, logCount do
            local log = session.logs[i]
            print(log.timestamp .. " [" .. log.type .. "] \"" .. log.input .. "\" -> " .. log.result)
            
            if log.encoding and log.encoding.hasHighBytes then
                print("  Encoding: " .. log.encoding.summary)
            end
            
            if log.normalization and log.normalization.applied then
                print("  Normalized: " .. (log.normalization.appliedRule or "unknown"))
            end
            
            if log.tested_regexes then
                print("  Tested " .. table.getn(log.tested_regexes) .. " regexes")
            end
        end
    else
        -- Mode minimal : échecs du jour
        print("=== RECENT FAILURES (MINIMAL) ===")
        
        local todayFailures = {}
        local today = date("%m-%d")
        
        for str, data in pairs(PawnDebugLogs.failed_only) do
            if data.last_seen == today then
                table.insert(todayFailures, {
                    str = str, 
                    count = data.count, 
                    keywords = data.has_keywords
                })
            end
        end
        
        if table.getn(todayFailures) == 0 then
            print("No failures today")
            return
        end
        
        print("Today's failures (" .. table.getn(todayFailures) .. "):")
        for i = 1, min(10, table.getn(todayFailures)) do
            local f = todayFailures[i]
            local kwIndicator = f.keywords and "[KW]" or "[  ]"
            print(kwIndicator .. " " .. f.count .. "x: \"" .. f.str .. "\"")
        end
    end
end

function PawnDebugTestString(testString)
    if not testString then
        print("Usage: PawnDebugTestString(\"text to test\")")
        return
    end
    
    if not PawnStatRegexes then
        print("PawnStatRegexes not found!")
        return
    end
    
    print("=== TESTING: \"" .. testString .. "\" ===")
    print("Mode: " .. (PawnDebugLogs.settings.verboseMode and "VERBEUX" or "MINIMAL"))
    
    -- Forcer l'activation temporaire
    local wasEnabled = PawnDebugLogs.settings.enabled
    PawnDebugLogs.settings.enabled = true
    
    local stats = {}
    local result = PawnLookForSingleStat_Hybrid(PawnStatRegexes, stats, testString, true)
    
    -- Restaurer l'état
    PawnDebugLogs.settings.enabled = wasEnabled
    
    print("Result: " .. (result and "SUCCESS" or "FAILED"))
    print("Has keywords: " .. tostring(HasFrenchKeywords(testString)))
end

-- ========================================
-- COMMANDES DE MODE (SIMPLIFIÉES)
-- ========================================

function PawnDebugSetVerbose()
    PawnDebugLogs.settings.verboseMode = true
    print("Debug mode: VERBEUX (persistant)")
    print("Logs détaillés avec sessions, encodage, et normalisation")
end

function PawnDebugSetMinimal()
    PawnDebugLogs.settings.verboseMode = false
    print("Debug mode: MINIMAL (persistant)")
    print("Logs compacts, échecs uniquement")
end

function PawnDebugToggleMode()
    if PawnDebugLogs.settings.verboseMode then
        PawnDebugSetMinimal()
    else
        PawnDebugSetVerbose()
    end
end

function PawnDebugEnable()
    PawnDebugLogs.settings.enabled = true
    local mode = PawnDebugLogs.settings.verboseMode and "VERBEUX" or "MINIMAL"
    print("Pawn debug ENABLED - Mode: " .. mode)
    print("Survolez des objets pour commencer le logging")
end

function PawnDebugDisable()
    PawnDebugLogs.settings.enabled = false
    print("Pawn debug DISABLED")
end

-- ========================================
-- FONCTIONS DE DIAGNOSTIC
-- ========================================

function PawnDebugTestCompatibility()
    print("=== TEST COMPATIBILITÉ WoW 3.3.5 ===")
    
    -- Test des fonctions Lua utilisées
    local functions = {
        {name = "strchar", func = strchar, test = function() return strchar(65) == "A" end},
        {name = "strbyte", func = strbyte, test = function() return strbyte("A") == 65 end},
        {name = "strlen", func = strlen, test = function() return strlen("test") == 4 end},
        {name = "strfind", func = strfind, test = function() return strfind("test", "es") == 2 end},
        {name = "strsub", func = strsub, test = function() return strsub("test", 2, 3) == "es" end},
        {name = "strlower", func = strlower, test = function() return strlower("TEST") == "test" end},
        {name = "strtrim", func = strtrim, test = function() return strtrim(" test ") == "test" end},
        {name = "gsub", func = gsub, test = function() return gsub("test", "t", "x") == "xesx" end},
        {name = "table.getn", func = table.getn, test = function() return table.getn({1,2,3}) == 3 end},
        {name = "date", func = date, test = function() return date() ~= nil end},
        {name = "GetTime", func = GetTime, test = function() return GetTime() ~= nil end},
    }
    
    local allOK = true
    for _, func in pairs(functions) do
        local status = "MISSING"
        if func.func then
            local success, result = pcall(func.test)
            if success and result then
                status = "OK"
            else
                status = "ERROR"
                allOK = false
            end
        else
            allOK = false
        end
        print(func.name .. ": " .. status)
    end
    
    -- Test des fonctions locales
    print("\n--- FONCTIONS LOCALES ---")
    print("min(5,3): " .. min(5,3) .. " (expect 3)")
    print("max(5,3): " .. max(5,3) .. " (expect 5)")
    print("floor(3.7): " .. floor(3.7) .. " (expect 3)")
    
    -- Test du parser d'arguments
    print("\n--- PARSER D'ARGUMENTS ---")
    local testArgs = ParseArgs("debug on verbose")
    print("ParseArgs result count: " .. table.getn(testArgs))
    for i, arg in pairs(testArgs) do
        print("  " .. i .. ": '" .. arg .. "'")
    end
    
    print("")
    print("Compatibilité WoW 3.3.5: " .. (allOK and "OK" or "PROBLÈME"))
    return allOK
end

function PawnDebugDiagnostic()
    print("=== DIAGNOSTIC SYSTÈME ===")
    
    -- Test de compatibilité d'abord
    local compatible = PawnDebugTestCompatibility()
    if not compatible then
        print("❌ PROBLÈME DE COMPATIBILITÉ - Arrêt du diagnostic")
        return
    end
    
    print("\n--- FONCTIONS PAWN ---")
    -- Vérifier les fonctions critiques
    print("PawnLookForSingleStat: " .. (PawnLookForSingleStat and "OK" or "MISSING"))
    print("PawnStatRegexes: " .. (PawnStatRegexes and "OK (" .. table.getn(PawnStatRegexes) .. " regex)" or "MISSING"))
    print("PawnCleanString: " .. (PawnCleanString and "OK" or "MISSING"))
    
    -- Vérifier le hook
    print("\n--- HOOK DEBUG ---")
    print("Hook installé: " .. tostring(PawnLookForSingleStat == PawnLookForSingleStat_Hybrid))
    print("Fonction originale sauvée: " .. tostring(PawnDebugOriginalFunction ~= nil))
    print("Debug initialisé: " .. tostring(PawnDebugInitialized))
    
    -- Test rapide
    print("\n--- TEST RAPIDE ---")
    local testResult = PawnDebugOriginalFunction and "OK" or "MISSING"
    print("Test fonction originale: " .. testResult)
    
    -- État des logs
    print("\n--- ÉTAT DES LOGS ---")
    local failureCount = 0
    for _ in pairs(PawnDebugLogs.failed_only) do failureCount = failureCount + 1 end
    print("Échecs en mémoire: " .. failureCount)
    print("Total traité: " .. PawnDebugLogs.stats.total_processed)
    print("Enabled: " .. tostring(PawnDebugLogs.settings.enabled))
    print("Mode: " .. (PawnDebugLogs.settings.verboseMode and "VERBEUX" or "MINIMAL"))
    
    print("\n--- RECOMMANDATIONS ---")
    if not PawnDebugInitialized then
        print("❌ Système non initialisé - Attendez 5 secondes et retestez")
    elseif not PawnDebugLogs.settings.enabled then
        print("⚠️  Debug désactivé - Tapez /pawnon")
    elseif PawnDebugLogs.stats.total_processed == 0 then
        print("⚠️  Aucun traitement - Survolez des objets français")
    else
        print("✅ Système opérationnel!")
    end
end

-- ========================================
-- FONCTIONS UTILITAIRES WoW 3.3.5
-- ========================================

-- Math helper functions for WoW 3.3.5 compatibility
local function min(a, b)
    if a < b then return a else return b end
end

local function max(a, b)
    if a > b then return a else return b end
end

local function floor(x)
    return x - (x % 1)
end

-- Parser de texte compatible WoW 3.3.5 (sans string.gmatch)
local function ParseArgs(text)
    local args = {}
    if not text or text == "" then
        return args
    end
    
    -- Nettoyer et diviser manuellement
    text = strtrim(text)
    local current = ""
    local inSpace = false
    
    for i = 1, strlen(text) do
        local char = strsub(text, i, i)
        if char == " " then
            if not inSpace and current ~= "" then
                table.insert(args, strlower(current))
                current = ""
            end
            inSpace = true
        else
            current = current .. char
            inSpace = false
        end
    end
    
    -- Ajouter le dernier argument
    if current ~= "" then
        table.insert(args, strlower(current))
    end
    
    return args
end

-- ========================================
-- COMMANDES SLASH PERSONNALISÉES
-- ========================================

-- Commandes principales
SLASH_PAWNDEBUG1 = "/pawndebug"
SLASH_PAWNDEBUGSTATUS1 = "/pawnstatus"
SLASH_PAWNDEBUGON1 = "/pawnon"
SLASH_PAWNDEBUGOFF1 = "/pawnoff"

SlashCmdList["PAWNDEBUG"] = function(text)
    local args = ParseArgs(text)
    
    if table.getn(args) == 0 or args[1] == "help" then
        print("=== COMMANDES PAWN DEBUG ===")
        print("/pawndebug help          - Cette aide")
        print("/pawnon                  - Activer debug")
        print("/pawnoff                 - Désactiver debug")
        print("/pawnstatus              - État et statistiques")
        print("")
        print("--- MODES ---")
        print("/pawndebug minimal       - Mode compact")
        print("/pawndebug verbose       - Mode détaillé")
        print("/pawndebug toggle        - Alterner modes")
        print("")
        print("--- FONCTIONS SCRIPT ---")
        print("PawnDebugShowRecent()    - Logs récents")
        print("PawnDebugTestString()    - Test manuel")
        print("PawnDebugDiagnostic()    - Diagnostic système")
    elseif args[1] == "minimal" then
        PawnDebugSetMinimal()
    elseif args[1] == "verbose" then
        PawnDebugSetVerbose()
    elseif args[1] == "toggle" then
        PawnDebugToggleMode()
    elseif args[1] == "on" then
        PawnDebugEnable()
    elseif args[1] == "off" then
        PawnDebugDisable()
    elseif args[1] == "status" then
        PawnDebugShowStatus()
    elseif args[1] == "diagnostic" then
        PawnDebugDiagnostic()
    else
        print("Commande inconnue. Tapez /pawndebug help")
    end
end

SlashCmdList["PAWNDEBUGSTATUS"] = PawnDebugShowStatus
SlashCmdList["PAWNDEBUGON"] = PawnDebugEnable  
SlashCmdList["PAWNDEBUGOFF"] = PawnDebugDisable

-- ========================================
-- INITIALISATION AMÉLIORÉE
-- ========================================

local function InitializeHybridDebug()
    if PawnLookForSingleStat then
        -- Sauver la fonction originale
        PawnDebugOriginalFunction = PawnLookForSingleStat
        
        -- Remplacer par notre version hybride
        PawnLookForSingleStat = PawnLookForSingleStat_Hybrid
        
        PawnDebugInitialized = true
        local mode = PawnDebugLogs.settings.verboseMode and "VERBEUX" or "MINIMAL"
        print("✅ Pawn Debug HYBRIDE loaded - Mode: " .. mode .. " (WoW 3.3.5)")
        print("📋 Commandes: /pawndebug help")
        print("🔧 Quick start: /pawnon puis survolez des objets français")
        print("🧪 Test: /script PawnDebugTestCompatibility()")
        return true
    else
        return false
    end
end

-- Event handler amélioré
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")
frame:RegisterEvent("PLAYER_ENTERING_WORLD")

local initAttempts = 0
local maxInitAttempts = 10

frame:SetScript("OnEvent", function(self, event, addonName)
    if event == "ADDON_LOADED" and addonName == "Pawn" then
        -- Essayer d'initialiser immédiatement
        if InitializeHybridDebug() then
            return
        end
        
        -- Si ça échoue, essayer périodiquement
        local timer = 0
        local updateFrame = CreateFrame("Frame")
        updateFrame:SetScript("OnUpdate", function(self, elapsed)
            timer = timer + elapsed
            if timer > 1 then -- Essayer chaque seconde
                timer = 0
                initAttempts = initAttempts + 1
                
                if InitializeHybridDebug() or initAttempts >= maxInitAttempts then
                    self:SetScript("OnUpdate", nil)
                    if initAttempts >= maxInitAttempts then
                        print("❌ Pawn Debug: Échec d'initialisation après " .. maxInitAttempts .. " tentatives")
                        print("⚠️  Tapez /script PawnDebugDiagnostic() pour plus d'infos")
                    end
                end
            end
        end)
    elseif event == "PLAYER_ENTERING_WORLD" then
        -- Seconde chance après que le joueur soit entré dans le monde
        if not PawnDebugInitialized then
            local timer = 0
            local updateFrame = CreateFrame("Frame")
            updateFrame:SetScript("OnUpdate", function(self, elapsed)
                timer = timer + elapsed
                if timer > 3 and InitializeHybridDebug() then
                    self:SetScript("OnUpdate", nil)
                end
            end)
        end
    end
end)

-- ========================================
-- EXPORT DES FONCTIONS
-- ========================================

-- Fonctions principales
_G.PawnDebugShowStatus = PawnDebugShowStatus
_G.PawnDebugShowRecent = PawnDebugShowRecent
_G.PawnDebugTestString = PawnDebugTestString
_G.PawnDebugEnable = PawnDebugEnable
_G.PawnDebugDisable = PawnDebugDisable
_G.PawnDebugDiagnostic = PawnDebugDiagnostic
_G.PawnDebugTestCompatibility = PawnDebugTestCompatibility

-- Gestion des modes
_G.PawnDebugSetVerbose = PawnDebugSetVerbose
_G.PawnDebugSetMinimal = PawnDebugSetMinimal
_G.PawnDebugToggleMode = PawnDebugToggleMode

print("Pawn Debug HYBRIDE script loaded")
print("✅ Paramètres sauvés automatiquement dans SavedVariables")
print("📋 Tapez /pawndebug help pour commencer")