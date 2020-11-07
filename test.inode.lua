local data={
	list = {"a", "b", "c"},
	list2 = {"z", "a", "x"},
}

local inode = require "inode"

local f,const = inode(data)

local passert=print

assert(f.list[const.raw] == data.list)
assert(f.list[1][const.raw] == data.list[1])
assert(f.list[2][const.raw] == data.list[2])
assert(f.list[4]==nil)
assert(f.nonexistant==nil)
assert(f.list[const[".."]] == f)
assert(f.list[const["."]] == f.list)
assert(f[const["."]] == f)

assert(f[const[".."]] == nil)
assert(f.list[const[".."]] == f)
assert(f.list[1][const[".."]] == f.list)
assert(f.list[2][const.raw] == data.list[2])

-- usefull for lua 5.1 / luajit 2.0
local _pairs = f.list[const.pairs]
for k,v in _pairs(f.list) do
	print(".", k, v[const.raw])
end
-- pairs and ipairs is ok since lua 5.2
for k,v in pairs(f.list) do
	print(".", k, v[const.raw])
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
			--print(k,v,v[const.raw])
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

--session = { root=fs, dir=dir, pwd=[...], cache=... }
