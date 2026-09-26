local SRC = "src/init.luau"

local f = io.open(SRC, "r")
assert(f, "cannot open " .. SRC)
local code = f:read("*a")
f:close()

local version = code:match("KvantUI %- v([%d%.]+)")
assert(version, "version not found in header")

-- strip comments then collapse whitespace
code = code:gsub("%-%-%[%[.-%]%]", "")
code = code:gsub("%-%-[^\r\n]*", "")
code = code:gsub("[\r\n]+", "\n")
code = code:gsub("\n%s+", "\n")
code = code:gsub("%s+\n", "\n")
code = code:gsub("\n\n+", "\n")
code = code:gsub("^%s+", ""):gsub("%s+$", "")

local header = string.format("--!native\n--!optimize 2\n--Kvant v%s | MIT | github.com/napHiwka/Kvant\n", version)
os.execute("mkdir dist 2>nul")

local out = "dist/" .. version .. ".luau"
local o = io.open(out, "w")
assert(o, "cannot write " .. out)
o:write(header .. code)
o:close()
print("built " .. out .. " (" .. #code .. " bytes)")

-- changelog
local ignore = { chore = true, ops = true, build = true, docs = true }
local p = io.popen("git log --oneline")
if p then
	local cl = { "# Changelog\n" }
	local cur_section, cur_commits = nil, {}
	local function flush()
		if cur_section and #cur_commits > 0 then
			table.insert(cl, cur_section)
			for _, c in ipairs(cur_commits) do table.insert(cl, c) end
			table.insert(cl, "")
		end
		cur_commits = {}
	end

	for hash, msg in p:read("*a"):gmatch("(%x+)%s+([^\r\n]+)") do
		local ver = msg:match("^dist:%s*(.+)")
		if ver then
			flush()
			cur_section = "## " .. ver
		elseif not ignore[msg:match("^(%a+)")] then
			if not cur_section then cur_section = "## " .. version .. " (current)" end
			table.insert(cur_commits, "- " .. hash .. " " .. msg)
		end
	end
	flush()
	p:close()

	local cf = io.open("CHANGELOG.md", "w")
	if cf then
		cf:write(table.concat(cl, "\n"))
		cf:close()
		print("updated CHANGELOG.md")
	end
end