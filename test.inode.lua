local data={
	list = {"a", "b", "c"},
	list2 = {"z", "a", "x"},
}

local inode = require "inode"

local f,const = inode(data)
local __,_,RAW,TYPE,RAWTYPE=const.__,const._,const.RAW,const.TYPE,const.RAWTYPE
assert(__ and _ and RAW and TYPE and RAWTYPE)

local passert=print

assert(f.list[RAW] == data.list)
assert(f.list[1][RAW] == data.list[1])
assert(f.list[2][RAW] == data.list[2])
assert(f.list[4]==nil)
assert(f.nonexistant==nil)
assert(f.list[__] == f)
assert(f.list[_] == f.list)
assert(f[_] == f)

--print(type(f.list[1]), f.list[1])
--print(type(f.list[1][RAW]), f.list[1][RAW])

assert(f[__] == f)
assert(f.list[__] == f)
assert(f.list[1][__] == f.list)
assert(f.list[2][RAW] == data.list[2])

-- orig is a table, proxy is a table
assert(type(f.list)=="table")
assert(f.list[RAWTYPE]=="table")
assert(type(f.list)==f.list[RAWTYPE])

assert(type(f.list[RAW])==f.list[TYPE])
assert(f.list[TYPE]=="table")

-- orig is a string, proxy is a table
assert(type(f.list[1])==f.list[1][RAWTYPE])
assert(f.list[1][RAWTYPE]=="table")
assert(type(f.list[1][RAW])=="string")
assert(f.list[1][TYPE]=="string")

-- usefull for lua 5.1 / luajit 2.0
local _pairs = f.list[const.PAIRS]
for k,v in _pairs(f.list) do
	print("_pairs", k, v[RAW])
end
-- pairs and ipairs is ok since lua 5.2
for k,v in pairs(f.list) do
	print("pairs", k, v[RAW])
end
local _ipairs = f.list[const.IPAIRS]
for k,v in _ipairs(f.list) do
	print("_ipairs", k, v[RAW])
end
-- pairs and ipairs is ok since lua 5.2
for k,v in ipairs(f.list) do
	print("ipairs", k, v[RAW])
end


assert(f.list[1]==f.list[1])
assert(f.list[2]==f.list[2])
assert(f.list[3]~=f.list2[3])

do
	local d1 = f.list[const.DEBUG]
	local d2 = f.list2[const.DEBUG]
	assert(d1.cachep~=d2.cachep)
	local function getcount(t)
		local c=0
		for k,v in pairs(t) do
			c=c+1
			--print(k,v,v[RAW])
		end
		return c
	end

	local x = {f.list[1], f.list[2], f.list[3], f.list2[3]}
	collectgarbage() collectgarbage()
	local countd1a=getcount(d1.cachep) -- 3
	local countd2a=getcount(d2.cachep) -- 1
	x[4]=nil -- remove f.list2[3]
	f.list2 = nil collectgarbage() collectgarbage()
	local countd1b=getcount(d1.cachep) -- 3
	local countd2b=getcount(d2.cachep) -- 0
	--print("countd1:", countd1a, countd1b)
	--print("countd2:", countd2a, countd2b)

	assert(countd1a==countd1b and countd1a>0) -- 3
	assert(countd2a>=countd2b and countd2b==0) -- 0
end

do
	local cacheisempty = f[const.DEBUG].cacheisempty
	assert(cacheisempty()==false)
	f=nil
	collectgarbage() collectgarbage()
	assert(cacheisempty()==true)
end

do
	local f,const = inode(data)
	f.toto = {"titi"}
	f.num = 123
	f.str = "abc"
	f.bool = true
	f.Not = false
	f.Nil = nil
	f.EmptyTable = {}
	f["foo"] = f.list
	assert(f.num[const.TYPE]=="number")
	assert(f.str[const.TYPE]=="string")
	assert(f.bool[const.TYPE]=="boolean")
	assert(f.Not[const.TYPE]=="boolean")
	assert(f.EmptyTable[const.TYPE]=="table")
--	print(require"tprint"(data,{inline=false, recursivefound=function(t) return require"tprint"(t) end}))
end

--session = { root=fs, dir=dir, pwd=[...], cache=... }
