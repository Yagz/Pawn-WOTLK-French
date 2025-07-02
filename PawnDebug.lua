-- ========================================
-- PAWN DEBUG COMPLET - ANALYSE ENCODAGE
-- ========================================
-- Version complète avec analyse détaillée de l'encodage et normalisation
-- Compatible WoW 3.3.5

-- ========================================
-- CONFIGURATION DES LOGS
-- ========================================

if not PawnDebugLogs then
    PawnDebugLogs = {
        ["_created"] = date(),
        ["_version"] = "2.0_complete",
        ["sessions"] = {},
        ["settings"] = {
            ["maxLogs"] = 100,          -- Augmenté pour plus d'historique
            ["maxSessions"] = 5,        -- Garder 5 sessions max
            ["verboseMode"] = false,    -- Mode verbose dans le chat
            ["logEncoding"] = true,     -- Analyser l'encodage
            ["logNormalization"] = true, -- Tracer la normalisation
            ["logRegexTests"] = false   -- Log des tests de regex (verbeux)
        }
    }
    print("PawnDebugLogs created with full analysis")
end

PawnDebugLogs._lastUpdate = date()
PawnDebugLogs._loadCount = (PawnDebugLogs._loadCount or 0) + 1

-- Variables temporaires
local PawnDebugInitialized = false
local PawnDebugOriginalFunction = nil
local PawnDebugSessionId = nil
local PawnDebugProcessedStrings = {} -- Cache pour éviter les doublons

-- ========================================
-- ANALYSE D'ENCODAGE COMPLÈTE
-- ========================================

local function AnalyzeStringEncoding(str, label)
    if not str then 
        return {
            label = label,
            error = "nil_string",
            raw = "nil"
        }
    end
    
    local analysis = {
        label = label or "unknown",
        raw = str,
        length = strlen(str),
        bytes = {},
        hasHighBytes = false,
        hasAccents = false,
        suspiciousBytes = {},
        encodingType = "ascii"
    }
    
    -- Analyser chaque byte
    for i = 1, analysis.length do
        local byte = strbyte(str, i)
        table.insert(analysis.bytes, byte)
        
        if byte > 127 then
            analysis.hasHighBytes = true
            table.insert(analysis.suspiciousBytes, {
                position = i,
                byte = byte,
                char = strchar(byte)
            })
            
            -- Détecter le type d'encodage
            if byte >= 192 and byte <= 255 then
                analysis.hasAccents = true
                analysis.encodingType = "utf8_likely"
            elseif byte >= 128 and byte <= 191 then
                analysis.encodingType = "extended_ascii"
            end
        end
    end
    
    -- Résumé pour les logs
    analysis.summary = "len:" .. analysis.length .. 
                      (analysis.hasHighBytes and " high_bytes:" .. table.getn(analysis.suspiciousBytes) or "") ..
                      " type:" .. analysis.encodingType
    
    return analysis
end

-- ========================================
-- ANALYSE DE NORMALISATION DÉTAILLÉE
-- ========================================

local function TestNormalization(inputString)
    local normalizationResult = {
        input = inputString,
        steps = {},
        final = inputString,
        applied = false
    }
    
    if not PawnNormalizationRegexes then
        normalizationResult.error = "no_normalization_rules"
        return normalizationResult
    end
    
    local currentString = strtrim(inputString)
    if currentString ~= inputString then
        table.insert(normalizationResult.steps, {
            rule = "trim",
            before = inputString,
            after = currentString,
            applied = true
        })
        normalizationResult.applied = true
    end
    
    -- Tester chaque règle de normalisation
    for i, Entry in pairs(PawnNormalizationRegexes) do
        local regex, replacement = Entry[1], Entry[2]
        local beforeRule = currentString
        local afterRule, count = gsub(currentString, regex, replacement, 1)
        
        local step = {
            rule = i,
            regex = regex,
            replacement = replacement,
            before = beforeRule,
            after = afterRule,
            applied = count > 0,
            beforeEncoding = AnalyzeStringEncoding(beforeRule, "before_rule_" .. i),
            afterEncoding = count > 0 and AnalyzeStringEncoding(afterRule, "after_rule_" .. i) or nil
        }
        
        table.insert(normalizationResult.steps, step)
        
        if count > 0 then
            currentString = afterRule
            normalizationResult.applied = true
            normalizationResult.appliedRule = i
            break -- Première règle qui s'applique
        end
    end
    
    normalizationResult.final = currentString
    return normalizationResult
end

-- ========================================
-- SYSTÈME DE LOGS AVANCÉ
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
        print("Started debug session: " .. PawnDebugSessionId)
        
        -- Nettoyer les anciennes sessions si trop nombreuses
        local sessionCount = 0
        for _ in pairs(PawnDebugLogs.sessions) do sessionCount = sessionCount + 1 end
        
        if sessionCount > PawnDebugLogs.settings.maxSessions then
            -- Garder seulement les plus récentes
            local sessionList = {}
            for sessionId in pairs(PawnDebugLogs.sessions) do
                table.insert(sessionList, sessionId)
            end
            table.sort(sessionList)
            
            -- Supprimer les plus anciennes
            while table.getn(sessionList) > PawnDebugLogs.settings.maxSessions do
                local oldestSession = table.remove(sessionList, 1)
                PawnDebugLogs.sessions[oldestSession] = nil
            end
        end
    end
    
    return PawnDebugLogs.sessions[PawnDebugSessionId]
end

local function AddComprehensiveLog(logType, inputString, result, details)
    local session = GetCurrentSession()
    
    -- Éviter les doublons récents (même string dans les 5 dernières secondes)
    local stringKey = inputString or "nil"
    local currentTime = GetTime()
    if PawnDebugProcessedStrings[stringKey] and 
       (currentTime - PawnDebugProcessedStrings[stringKey]) < 5 then
        return -- Skip les doublons récents
    end
    PawnDebugProcessedStrings[stringKey] = currentTime
    
    -- Créer le log détaillé
    local logEntry = {
        timestamp = date("%H:%M:%S"),
        type = logType,
        input = inputString or "nil",
        result = result or "unknown"
    }
    
    -- Analyse d'encodage si activée
    if PawnDebugLogs.settings.logEncoding and inputString then
        logEntry.encoding = AnalyzeStringEncoding(inputString, "input")
    end
    
    -- Test de normalisation si activé
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
    
    -- Statistiques
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
    
    return logEntry
end

-- ========================================
-- FONCTION DEBUG PRINCIPALE COMPLÈTE
-- ========================================

local function PawnLookForSingleStat_Complete(RegexTable, Stats, ThisString, DebugMessages)
    -- Si pas de debug, utiliser l'original
    if not DebugMessages or not PawnDebugOriginalFunction then
        if PawnDebugOriginalFunction then
            return PawnDebugOriginalFunction(RegexTable, Stats, ThisString, DebugMessages)
        else
            return false
        end
    end
    
    local verbose = PawnDebugLogs.settings.verboseMode
    
    if verbose then
        print("=== Analyzing: \"" .. (ThisString or "NIL") .. "\" ===")
    end
    
    -- Analyse immédiate de l'input
    local logDetails = {}
    
    if not ThisString or ThisString == "" then
        AddComprehensiveLog("FAIL", ThisString, "empty_input", {
            reason = "empty_or_nil"
        })
        if verbose then print("FAIL: Empty input") end
        return false
    end
    
    -- Analyser les mots-clés présents
    local keywords = {}
    local keywordList = {"Force", "Endurance", "Intelligence", "Agilité", "Esprit", 
                        "Score", "Puissance", "Résistance", "Dégâts", "Vitesse",
                        "Hâte", "Critique", "Touchier", "Précision"}
    
    for _, keyword in ipairs(keywordList) do
        if strfind(ThisString, keyword) then
            table.insert(keywords, keyword)
        end
    end
    
    logDetails.keywords = keywords
    logDetails.hasKnownKeywords = table.getn(keywords) > 0
    
    -- Tester avec la fonction originale
    local originalSuccess = PawnDebugOriginalFunction(RegexTable, Stats, ThisString, false)
    
    if originalSuccess then
        -- SUCCÈS
        if verbose then print("SUCCESS: Regex matched") end
        
        AddComprehensiveLog("SUCCESS", ThisString, "matched", logDetails)
        return true
    else
        -- ÉCHEC - Analyse approfondie
        if verbose then 
            print("FAIL: No regex match")
            if table.getn(keywords) > 0 then
                print("Keywords found: " .. table.concat(keywords, ", "))
            end
        end
        
        -- Analyser pourquoi ça échoue
        logDetails.reason = table.getn(keywords) > 0 and "pattern_mismatch" or "no_keywords"
        
        -- Si on a des mots-clés mais pas de match, c'est probablement un problème de pattern
        if table.getn(keywords) > 0 and PawnDebugLogs.settings.logRegexTests then
            logDetails.regexAnalysis = {
                testedPatterns = {},
                suggestedFixes = {}
            }
            
            -- Tester quelques patterns similaires (limité pour éviter le spam)
            local testedCount = 0
            for i, Entry in pairs(RegexTable or {}) do
                if testedCount >= 5 then break end
                if Entry and Entry[1] then
                    for _, kw in ipairs(keywords) do
                        if strfind(Entry[1], kw) then
                            table.insert(logDetails.regexAnalysis.testedPatterns, {
                                index = i,
                                pattern = Entry[1],
                                matchesKeyword = kw
                            })
                            testedCount = testedCount + 1
                            break
                        end
                    end
                end
            end
        end
        
        AddComprehensiveLog("FAIL", ThisString, "no_match", logDetails)
        return false
    end
end

-- ========================================
-- COMMANDES DE GESTION AVANCÉES
-- ========================================

function PawnDebugShowStatus()
    print("=== PAWN DEBUG STATUS ===")
    print("Initialized: " .. tostring(PawnDebugInitialized))
    print("Version: " .. (PawnDebugLogs._version or "unknown"))
    print("Load count: " .. (PawnDebugLogs._loadCount or "0"))
    print("Current session: " .. (PawnDebugSessionId or "none"))
    
    if PawnDebugSessionId then
        local session = PawnDebugLogs.sessions[PawnDebugSessionId]
        print("Session stats:")
        print("  Total: " .. session.stats.total)
        print("  Success: " .. session.stats.success)
        print("  Failed: " .. session.stats.failed)
        print("  Normalized: " .. session.stats.normalized)
        print("  Encoding issues: " .. session.stats.encoding_issues)
    end
    
    print("Settings:")
    print("  Max logs: " .. PawnDebugLogs.settings.maxLogs)
    print("  Verbose mode: " .. tostring(PawnDebugLogs.settings.verboseMode))
    print("  Log encoding: " .. tostring(PawnDebugLogs.settings.logEncoding))
    print("  Log normalization: " .. tostring(PawnDebugLogs.settings.logNormalization))
end

function PawnDebugToggleVerbose()
    PawnDebugLogs.settings.verboseMode = not PawnDebugLogs.settings.verboseMode
    print("Verbose mode: " .. tostring(PawnDebugLogs.settings.verboseMode))
end

function PawnDebugToggleEncoding()
    PawnDebugLogs.settings.logEncoding = not PawnDebugLogs.settings.logEncoding
    print("Encoding analysis: " .. tostring(PawnDebugLogs.settings.logEncoding))
end

function PawnDebugToggleRegexTests()
    PawnDebugLogs.settings.logRegexTests = not PawnDebugLogs.settings.logRegexTests
    print("Regex testing: " .. tostring(PawnDebugLogs.settings.logRegexTests))
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
    
    print("=== MANUAL TEST ===")
    
    -- Force verbose mode temporairement
    local oldVerbose = PawnDebugLogs.settings.verboseMode
    local oldRegexTests = PawnDebugLogs.settings.logRegexTests
    PawnDebugLogs.settings.verboseMode = true
    PawnDebugLogs.settings.logRegexTests = true
    
    local stats = {}
    PawnLookForSingleStat_Complete(PawnStatRegexes, stats, testString, true)
    
    -- Restaurer les settings
    PawnDebugLogs.settings.verboseMode = oldVerbose
    PawnDebugLogs.settings.logRegexTests = oldRegexTests
    
    print("Test completed - check logs with PawnDebugShowRecent()")
end

function PawnDebugShowRecent()
    if not PawnDebugSessionId then
        print("No active session")
        return
    end
    
    local session = PawnDebugLogs.sessions[PawnDebugSessionId]
    print("=== RECENT LOGS ===")
    
    local logCount = table.getn(session.logs)
    local startIndex = math.max(1, logCount - 9) -- 10 derniers logs
    
    for i = startIndex, logCount do
        local log = session.logs[i]
        print(log.timestamp .. " [" .. log.type .. "] \"" .. log.input .. "\" -> " .. log.result)
        
        if log.encoding and log.encoding.hasHighBytes then
            print("  Encoding: " .. log.encoding.summary)
        end
        
        if log.normalization and log.normalization.applied then
            print("  Normalized: rule " .. (log.normalization.appliedRule or "unknown"))
        end
        
        if log.keywords and table.getn(log.keywords) > 0 then
            print("  Keywords: " .. table.concat(log.keywords, ", "))
        end
    end
end

function PawnDebugForceTest()
    print("=== COMPREHENSIVE FORCE TEST ===")
    
    -- Test de base
    AddComprehensiveLog("TEST", "Force test", "manual", {
        testType = "forced",
        timestamp = date()
    })
    
    -- Test avec différents cas
    local testCases = {
        "+15 Force",
        "Endurance +22", 
        "Score de toucher +35",
        "Intelligence +18",
        "Test sans keywords"
    }
    
    print("Testing " .. table.getn(testCases) .. " cases...")
    for i, testCase in ipairs(testCases) do
        PawnDebugTestString(testCase)
    end
    
    PawnDebugShowStatus()
    print("Check SavedVariables/Pawn.lua for detailed logs")
end

-- ========================================
-- INITIALISATION
-- ========================================

local function InitializeDebug()
    if PawnLookForSingleStat then
        PawnDebugOriginalFunction = PawnLookForSingleStat
        PawnLookForSingleStat = PawnLookForSingleStat_Complete
        PawnDebugInitialized = true
        print("Pawn Debug Complete loaded!")
        print("Commands: PawnDebugForceTest(), PawnDebugShowStatus(), PawnDebugTestString()")
        return true
    else
        return false
    end
end

-- Event handler
local frame = CreateFrame("Frame")
frame:RegisterEvent("ADDON_LOADED")

frame:SetScript("OnEvent", function(self, event, addonName)
    if addonName == "Pawn" then
        local timer = 0
        local updateFrame = CreateFrame("Frame")
        updateFrame:SetScript("OnUpdate", function(self, elapsed)
            timer = timer + elapsed
            if timer > 2 and InitializeDebug() then
                self:SetScript("OnUpdate", nil)
            end
        end)
    end
end)

-- Export des fonctions
_G.PawnDebugForceTest = PawnDebugForceTest
_G.PawnDebugShowStatus = PawnDebugShowStatus
_G.PawnDebugTestString = PawnDebugTestString
_G.PawnDebugShowRecent = PawnDebugShowRecent
_G.PawnDebugToggleVerbose = PawnDebugToggleVerbose
_G.PawnDebugToggleEncoding = PawnDebugToggleEncoding
_G.PawnDebugToggleRegexTests = PawnDebugToggleRegexTests

print("Pawn Debug Complete script loaded")