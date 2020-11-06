local data={
	list = {"a", "b", "c"}
}

local inode = require "inode"

local f,const,cache = inode(nil,nil,data)
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

local function isempty(cache)
	return not next(cache)
end
assert(isempty(cache)==false)
f=nil collectgarbage()
assert(isempty(cache)==true)

--session = { root=fs, dir=dir, pwd=[...], cache=... }
