-- Minimal stand-ins for the WoW 3.3.5a API (with !!!ClassicAPI), so Pawn 2.8.11's real files run under LuaJIT.
-- Loaded by tests/harness.lua; run everything from the addon root.

function GetLocale() return os.getenv("PAWN_TEST_LOCALE") or "frFR" end
function GetBuildInfo() return "3.3.5", "12340", "Jun 24 2010", 30300 end

-- Project constants as defined by !!!ClassicAPI (Util/Constants.lua).
WOW_PROJECT_MAINLINE, WOW_PROJECT_CLASSIC, WOW_PROJECT_BURNING_CRUSADE_CLASSIC, WOW_PROJECT_WRATH_CLASSIC = 1, 2, 5, 11
WOW_PROJECT_ID = WOW_PROJECT_WRATH_CLASSIC
LE_EXPANSION_CLASSIC, LE_EXPANSION_BURNING_CRUSADE, LE_EXPANSION_WRATH_OF_THE_LICH_KING = 0, 1, 2
LE_EXPANSION_LEVEL_CURRENT = 2

strfind, strsub, strlen, strlower, strupper = string.find, string.sub, string.len, string.lower, string.upper
strbyte, strchar, strrep, format = string.byte, string.char, string.rep, string.format
gsub, gmatch, tinsert, tremove = string.gsub, string.gmatch, table.insert, table.remove
floor, ceil, abs, min, max = math.floor, math.ceil, math.abs, math.min, math.max

function strtrim(Text, Chars)
	local Class = "[" .. gsub(Chars or " \t\r\n", "[%]%%%^%-]", "%%%0") .. "]"
	Text = gsub(Text, "^" .. Class .. "+", "")
	return (gsub(Text, Class .. "+$", ""))
end

function getglobal(Name) return _G[Name] end
function setglobal(Name, Value) _G[Name] = Value end
function hooksecurefunc() end

WowApiTime = 0
function GetTime() return WowApiTime end

-- VgerCore.Message writes here; tests look for "ERROR:" in it.
WowApiMessages = {}
DEFAULT_CHAT_FRAME = { AddMessage = function(self, Text) table.insert(WowApiMessages, tostring(Text)) end }

SlashCmdList = {}

-- Items known to the fake client: WowApiItems[ID] = { Name, EquipLoc }.  Unknown IDs behave like uncached items.
WowApiItems = {}
function GetItemInfo(ID)
	local Item = WowApiItems[ID]
	if not Item then return nil end
	return Item[1], "item:" .. ID, 3, 100, 80, "Armure", "Tissu", 1, Item[2]
end

-- Fake tooltip lines.
local FontString = {}
FontString.__index = FontString
function FontString:GetText() return self.Text end
function FontString:SetText(Text) self.Text = Text end
function FontString:GetTextColor() return 0, 1, 0 end -- green: a socket bonus counts as active
function FontString:SetTextColor() end

-- WowApiItemTooltips[Link] = Lines: what SetHyperlink shows for that link.  WowApiHyperlinks: every link shown.
WowApiItemTooltips = {}
WowApiHyperlinks = {}

-- Any method a test doesn't define is a no-op.
local function NoOp() end

local Tooltip = {}
Tooltip.__index = function(_, Key) return rawget(Tooltip, Key) or NoOp end
function Tooltip:NumLines() return self.Count end
function Tooltip:ClearLines() self.Count = 0 end
function Tooltip:GetItem() return nil, nil end
function Tooltip:SetHyperlink(Link)
	table.insert(WowApiHyperlinks, Link)
	WowApiSetTooltip(self.Name, WowApiItemTooltips[Link] or {})
end

-- Fills the fake tooltip called Name.  Each entry of Lines is a left-side string or { Left, Right }.
function WowApiSetTooltip(Name, Lines)
	local T = rawget(_G, Name)
	if not T then
		T = setmetatable({ Name = Name, Count = 0 }, Tooltip)
		_G[Name] = T
	end
	for i, Entry in ipairs(Lines) do
		local Left, Right = Entry, nil
		if type(Entry) == "table" then Left, Right = Entry[1], Entry[2] end
		_G[Name .. "TextLeft" .. i] = setmetatable({ Text = Left }, FontString)
		_G[Name .. "TextRight" .. i] = setmetatable({ Text = Right }, FontString)
	end
	T.Count = #Lines
	return T
end

local Frame = {}
Frame.__index = function(_, Key) return rawget(Frame, Key) or NoOp end
function Frame:SetScript(Name, Script) self.Scripts[Name] = Script end
function Frame:GetScript(Name) return self.Scripts[Name] end
function Frame:Show() self.Shown = true end
function Frame:Hide() self.Shown = false end
function Frame:IsShown() return self.Shown end
function CreateFrame(Type, Name)
	if Type == "GameTooltip" then return WowApiSetTooltip(Name or "WowApiAnonymousTooltip", {}) end
	local F = setmetatable({ Scripts = {}, Shown = true }, Frame)
	if Name then _G[Name] = F end
	return F
end
UIParent = CreateFrame("Frame", "UIParent")
WorldFrame = CreateFrame("Frame", "WorldFrame")
