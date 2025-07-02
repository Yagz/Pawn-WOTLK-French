-- ========================================
-- PAWN ENCODING FIX - COMPATIBLE WOW 3.3.5
-- ========================================
-- Correction automatique de l'encodage corrompu
-- 100% compatible avec WoW 3.3.5 et Lua 5.1

-- ========================================
-- 1. DIAGNOSTIC ET ANALYSE
-- ========================================

function PawnAnalyzeFileEncoding()
    print("=== ANALYSE ENCODAGE FICHIERS ===")
    
    -- Test 1: Vérifier le contenu de vos regex
    if PawnStatRegexes then
        print("Searching for Agility patterns in your regex...")
        local found = false
        for i, entry in pairs(PawnStatRegexes) do
            if entry[1] and strfind(entry[1], "Agil") then
                local pattern = entry[1]
                print("Found pattern #" .. i .. ": \"" .. pattern .. "\"")
                
                -- Analyser les bytes du pattern
                print("  Bytes analysis:")
                for j = 1, strlen(pattern) do
                    local byte = strbyte(pattern, j)
                    local char = strchar(byte)
                    if byte > 127 then
                        print("    " .. j .. ": " .. byte .. " ('" .. char .. "') HIGH BYTE")
                    end
                end
                found = true
                break
            end
        end
        if not found then
            print("No Agility pattern found in regex")
        end
    else
        print("PawnStatRegexes not found")
    end
    
    -- Test 2: Créer des strings de test
    print("")
    print("=== STRING COMPARISON ===")
    
    -- Version UTF-8 correcte
    local correctUTF8 = "Agilité"
    print("Correct UTF-8 'Agilité':")
    for i = 1, strlen(correctUTF8) do
        local byte = strbyte(correctUTF8, i)
        print("  " .. i .. ": " .. byte .. " ('" .. strchar(byte) .. "')")
    end
    
    -- Version corrompue (ce que WoW envoie)
    local corruptedFromWoW = "AgilitÃ©"
    print("")
    print("Corrupted from WoW 'AgilitÃ©':")
    for i = 1, strlen(corruptedFromWoW) do
        local byte = strbyte(corruptedFromWoW, i)
        print("  " .. i .. ": " .. byte .. " ('" .. strchar(byte) .. "')")
    end
end

function PawnShowCurrentRegexContent()
    print("=== CURRENT REGEX CONTENT ===")
    
    if not PawnStatRegexes then
        print("PawnStatRegexes not available")
        return
    end
    
    -- Chercher et afficher toutes les regex avec des accents
    local accentedPatterns = {}
    local count = 0
    for i, entry in pairs(PawnStatRegexes) do
        if entry[1] then
            local pattern = entry[1]
            -- Vérifier si contient des bytes > 127 (accents/caractères spéciaux)
            local hasAccents = false
            for j = 1, strlen(pattern) do
                if strbyte(pattern, j) > 127 then
                    hasAccents = true
                    break
                end
            end
            
            if hasAccents then
                table.insert(accentedPatterns, {index = i, pattern = pattern, stat = entry[2]})
            end
        end
        count = count + 1
    end
    
    print("Total regex patterns: " .. count)
    print("Found " .. table.getn(accentedPatterns) .. " patterns with accents:")
    for _, info in ipairs(accentedPatterns) do
        print("#" .. info.index .. ": \"" .. info.pattern .. "\" -> " .. (info.stat or "unknown"))
    end
end

-- ========================================
-- 2. TABLE DE CORRECTION D'ENCODAGE
-- ========================================

PawnEncodingFixMap = {
    -- Caractères UTF-8 corrompus -> normaux (basés sur vos logs)
    ["Ã©"] = "é", ["Ã¨"] = "è", ["Ãª"] = "ê", ["Ã«"] = "ë",
    ["Ã¡"] = "á", ["Ã "] = "à", ["Ã¢"] = "â", ["Ã¤"] = "ä",
    ["Ã­"] = "í", ["Ã¬"] = "ì", ["Ã®"] = "î", ["Ã¯"] = "ï", 
    ["Ã³"] = "ó", ["Ã²"] = "ò", ["Ã´"] = "ô", ["Ã¶"] = "ö",
    ["Ãº"] = "ú", ["Ã¹"] = "ù", ["Ã»"] = "û", ["Ã¼"] = "ü",
    ["Ã§"] = "ç", ["Ã±"] = "ñ", ["Ã½"] = "ý", ["Ã¿"] = "ÿ",
    ["Ã¢"] = "â", ["Ã"] = "À", ["Ã"] = "É", ["Ã"] = "È",
    
    -- Séquences complètes spécifiques détectées dans vos logs
    ["AgilitÃ©"] = "Agilité",
    ["EnduranceÃ©"] = "Endurance",
    ["ÃquipÃ©"] = "Équipé", 
    ["dÃ©gÃ¢ts"] = "dégâts",
    ["dÃ©fense"] = "défense",
    ["hÃ¢te"] = "hâte",
    ["augmentÃ©"] = "augmenté",
    ["ramassÃ©"] = "ramassé",
    ["caractÃ©ristique"] = "caractéristique",
    ["Ã©levÃ©e"] = "élevée",
    ["amÃ©liorÃ©e"] = "améliorée",
    
    -- Espaces et caractères problématiques
    ["Â"] = "", -- Supprimer les Â parasites
}

-- ========================================
-- 3. FONCTION DE NETTOYAGE (WoW 3.3.5 compatible)
-- ========================================

function PawnCleanString(str)
    if not str or str == "" then return str end
    
    local originalStr = str
    
    -- Étape 1: Correction des espaces non-breaking (bytes 194,160)
    -- Créer la séquence byte par byte pour WoW 3.3.5
    local nonBreakingSpace = strchar(194) .. strchar(160)
    str = gsub(str, nonBreakingSpace, " ")
    
    -- Étape 2: Application des corrections de la table
    for corrupt, clean in pairs(PawnEncodingFixMap) do
        str = gsub(str, corrupt, clean)
    end
    
    -- Étape 3: Nettoyage final
    str = gsub(str, "Â+", "") -- Supprimer Â restants
    str = gsub(str, "%s+", " ") -- Normaliser espaces multiples
    str = strtrim(str)
    
    return str
end

-- ========================================
-- 4. HOOK DE LA FONCTION PRINCIPALE
-- ========================================

-- Sauvegarder la fonction originale
if not PawnLookForSingleStat_Original then
    PawnLookForSingleStat_Original = PawnLookForSingleStat
end

-- Version avec correction automatique
function PawnLookForSingleStat(RegexTable, Stats, ThisString, DebugMessages)
    local originalString = ThisString
    
    -- Nettoyer la string avant traitement
    if ThisString then
        ThisString = PawnCleanString(ThisString)
        
        -- Debug si correction appliquée
        if DebugMessages and ThisString ~= originalString then
            local debugMsg = "ENCODING FIXED: \"" .. originalString .. "\" -> \"" .. ThisString .. "\""
            if PawnDebugMessage then
                PawnDebugMessage(debugMsg)
            else
                print(debugMsg)
            end
        end
    end
    
    -- Appeler la fonction originale avec la string corrigée
    return PawnLookForSingleStat_Original(RegexTable, Stats, ThisString, DebugMessages)
end

-- ========================================
-- 5. FONCTIONS DE TEST (WoW 3.3.5 compatible)
-- ========================================

function PawnTestEncodingFix()
    print("=== TEST CORRECTION D'ENCODAGE ===")
    
    local testCases = {
        "AgilitÃ©",                                         -- -> "Agilité"
        "ÃquipÃ©Â : Score de dÃ©fense augmentÃ© de 14.",    -- -> "Équipé : Score de défense augmenté de 14."
        "ArmureÂ : 278",                                   -- -> "Armure : 278"
        "+2 aux dÃ©gÃ¢ts de l'arme",                       -- -> "+2 aux dégâts de l'arme"
        "LiÃ© quand ramassÃ©",                             -- -> "Lié quand ramassé"
    }
    
    for i, testCase in ipairs(testCases) do
        local cleaned = PawnCleanString(testCase)
        print("Test " .. i .. ":")
        print("  Input:  \"" .. testCase .. "\"")
        print("  Output: \"" .. cleaned .. "\"")
        print("  Fixed:  " .. (cleaned ~= testCase and "YES" or "NO"))
        print("")
    end
end

function PawnValidateSystem()
    print("=== VALIDATION SYSTÈME ===")
    
    -- Vérifier que les fonctions sont disponibles
    print("PawnCleanString: " .. (PawnCleanString and "OK" or "MISSING"))
    print("Original function saved: " .. (PawnLookForSingleStat_Original and "OK" or "MISSING"))
    
    -- Compter les entrées dans la table d'encodage
    local mapSize = 0
    for _ in pairs(PawnEncodingFixMap or {}) do mapSize = mapSize + 1 end
    print("Encoding map loaded: " .. (mapSize > 0 and "OK (" .. mapSize .. " entries)" or "MISSING"))
    
    -- Test rapide
    local testResult = PawnCleanString("AgilitÃ©")
    print("Quick test: 'AgilitÃ©' -> '" .. testResult .. "' " .. (testResult == "Agilité" and "OK" or "FAILED"))
    
    if testResult == "Agilité" then
        print("")
        print("SYSTÈME OPÉRATIONNEL!")
        print("Usage: /pawn debug on puis survolez des objets français")
    else
        print("")
        print("PROBLÈME DÉTECTÉ!")
        print("Vérifiez l'installation du fichier")
    end
end

-- Test simple pour vérifier la compatibilité
function PawnTestCompatibility()
    print("=== TEST COMPATIBILITÉ WoW 3.3.5 ===")
    
    -- Test des fonctions Lua utilisées
    local functions = {
        {name = "strchar", func = strchar, test = function() return strchar(65) == "A" end},
        {name = "strbyte", func = strbyte, test = function() return strbyte("A") == 65 end},
        {name = "strlen", func = strlen, test = function() return strlen("test") == 4 end},
        {name = "strfind", func = strfind, test = function() return strfind("test", "es") == 2 end},
        {name = "gsub", func = gsub, test = function() return gsub("test", "t", "x") == "xesx" end},
        {name = "strtrim", func = strtrim, test = function() return strtrim(" test ") == "test" end},
        {name = "table.getn", func = table.getn, test = function() return table.getn({1,2,3}) == 3 end},
    }
    
    local allOK = true
    for _, func in ipairs(functions) do
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
    
    print("")
    print("Compatibilité WoW 3.3.5: " .. (allOK and "OK" or "PROBLÈME"))
    return allOK
end

-- ========================================
-- 6. EXPORT DES FONCTIONS
-- ========================================

_G.PawnAnalyzeFileEncoding = PawnAnalyzeFileEncoding
_G.PawnShowCurrentRegexContent = PawnShowCurrentRegexContent
_G.PawnTestEncodingFix = PawnTestEncodingFix
_G.PawnValidateSystem = PawnValidateSystem
_G.PawnTestCompatibility = PawnTestCompatibility
_G.PawnCleanString = PawnCleanString

-- ========================================
-- 7. MESSAGE DE CHARGEMENT
-- ========================================

print("PawnEncodingFix loaded for WoW 3.3.5!")
print("Available commands:")
print("  /script PawnTestCompatibility()")
print("  /script PawnValidateSystem()")
print("  /script PawnAnalyzeFileEncoding()")
print("  /script PawnTestEncodingFix()")
print("Automatic string cleaning is now active!")