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