-- Reads and writes the test corpus files (tests/corpus/*.txt).
-- Line format:  left[ || right] => expectation   (or  || right => expectation)
-- expectation: ignored | unhandled | todo | Stat=value[; Stat=value]
-- The LAST " => " on the line separates the text from the expectation.
-- A newline inside a tooltip text (meta gem requirements) is written as the two characters \n.
local Corpus = {}

-- Newline <-> the two characters "\\n" (real client texts contain no backslash).
function Corpus.Escape(Text) return (Text:gsub("\n", "\\n")) end
function Corpus.Unescape(Text) return (Text:gsub("\\n", "\n")) end

function Corpus.FormatStats(Stats)
	local Keys = {}
	for Key in pairs(Stats) do table.insert(Keys, Key) end
	table.sort(Keys)
	local Parts = {}
	for _, Key in ipairs(Keys) do table.insert(Parts, Key .. "=" .. string.format("%.10g", Stats[Key])) end
	return table.concat(Parts, "; ")
end

-- Returns a Case, or nil for blank and comment lines, or nil plus an error message.
function Corpus.ParseCase(Line)
	Line = Line:gsub("\r$", "")
	if Line:match("^%s*$") or Line:match("^#") then return nil end
	local Text, Expect = Line:match("^(.*) => (.-)%s*$")
	if not Text then return nil, "missing ' => '" end
	Text = Text:gsub("%s+$", "")
	local Left, Right
	if Text:sub(1, 3) == "|| " then
		Left, Right = "", Text:sub(4)
	else
		Left, Right = Text:match("^(.-)%s+|| (.*)$")
		if not Left then Left = Text end
	end
	-- Text stays as written in the file (escaped); Left and Right are the real tooltip texts.
	local Case = { Left = Corpus.Unescape(Left), Right = Right and Corpus.Unescape(Right), Text = Text }
	if Expect == "ignored" or Expect == "unhandled" or Expect == "todo" then
		Case.Kind = Expect
		return Case
	end
	Case.Kind, Case.Stats = "stats", {}
	for Part in Expect:gmatch("[^;]+") do
		local Stat, Value = Part:match("^%s*(%w+)=(%-?[%d%.]+)%s*$")
		if not Stat then return nil, "bad expectation '" .. Part .. "'" end
		Case.Stats[Stat] = tonumber(Value)
	end
	return Case
end

function Corpus.ReadFile(Path)
	local Cases, Errors, Number = {}, {}, 0
	for Line in io.lines(Path) do
		Number = Number + 1
		local Case, Err = Corpus.ParseCase(Line)
		if Case then
			Case.File, Case.Line = Path, Number
			table.insert(Cases, Case)
		elseif Err then
			table.insert(Errors, Path .. ":" .. Number .. ": " .. Err)
		end
	end
	return Cases, Errors
end

function Corpus.Files()
	local Files = {}
	local Pipe = io.popen("ls tests/corpus/*.txt 2>/dev/null")
	for Path in Pipe:lines() do table.insert(Files, Path) end
	Pipe:close()
	return Files
end

-- Appends "Text => Expect" lines to Path (Text escaped with Corpus.Escape), skipping texts already present in Path or in any corpus file.
-- Writes Header first when Path doesn't exist yet.  Returns the number of lines added.
function Corpus.Append(Path, Entries, Header)
	local Known = {}
	local Paths = Corpus.Files()
	local Existing = io.open(Path, "r")
	if Existing then Existing:close() table.insert(Paths, Path) end
	for _, File in ipairs(Paths) do
		for _, Case in ipairs((Corpus.ReadFile(File))) do Known[Case.Text] = true end
	end
	local Out = assert(io.open(Path, "a"))
	if not Existing and Header then Out:write(Header, "\n") end
	local Added = 0
	for _, Entry in ipairs(Entries) do
		local Text = Corpus.Escape(Entry.Text)
		if not Known[Text] then
			Out:write(Text, " => ", Entry.Expect, "\n")
			Known[Text] = true
			Added = Added + 1
		end
	end
	Out:close()
	return Added
end

return Corpus
