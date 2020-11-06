
local __={}	-- ".."
local _={}	-- "."
local RAW={}	-- rawget
local KEYS={}	--
local INDEX={}	--

local const={[".."]=__,["."]=_,["raw"]=RAW,["keys"]=KEYS,["index"]=INDEX}

---- cache system ----
local function new()
	local cache=setmetatable({},{__mode="v"})
	return cache
end
local function get(cache, o)
	local v = cache[o]
	if v then
		return v
	end
end
local function set(cache, v, o)
	if type(v)=="table" then
		cache[v] = o
	end
	return o
end
---- /cache system ----

local function inode(parent, name, current, cache)
	assert(cache)
	local c = get(cache, current)
	if c then return c end
	local t={}
	local mt ={}
	function mt.__index(self,k)
		if k==__ then
			return parent
		elseif k==_ then
			return t
		elseif k==RAW then
			--print("parent", parent, "current", current, "name", name,])
			if parent == nil then return current end
			return parent[RAW][name]
		elseif k==KEYS then
			-- TODO
		elseif k==INDEX then
			-- TODO
		end
		local v = current[k]
		if v == nil then return nil end
		--if type(v)~="table" then return v end
		local c2 = get(cache, v)
		if c2 then
			return c2
		end
		c2 = inode(t, k, v, cache)
		return set(cache, v, c2)
	end
	setmetatable(t,mt)
	return set(cache, current, t)
end
local function pub_inode(parent, name, current, cache)
	if not cache then
		cache = new()
		return inode(parent, name, current, cache), const, cache
	end
	return inode(parent, name, current, cache)
end

return pub_inode
