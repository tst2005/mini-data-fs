
local __={}	-- ".."
local _={}	-- "."
local RAW={}	-- rawget
local PAIRS={}	--
local IPAIRS={}	--

local const={[".."]=__,["."]=_,["raw"]=RAW,["pairs"]=PAIRS,["ipairs"]=IPAIRS}

---- cache system ----
local function new()
	local cache=setmetatable({},{__mode="v"})
	return cache
end
local function get(cache, k)
	local v = cache[k]
	if v then
		return v
	end
end
local function set(cache, k, v)
	if type(v)=="table" then
		cache[k] = v
	end
	return v
end
--local function cacheblackbox()
--	local cache = new()
--	return function(k, f)
--		if f==nil then
--			return get(cache, k)
--		end
--		return set(cache, k, f())
--	end
--end
---- /cache system ----

local function __pairs(proxy)
	local function _next(proxy, k)
		local orig = proxy[RAW]
		local v
		k, v = next(orig, k)
		if nil~=v then
			return k, proxy[k] -- do not expose v without wrapper
		end
	end
	return _next, proxy, nil
end

local function __ipairs(proxy)
	local function _next(proxy, i)
		i = i + 1
		local v = proxy[i]
		if nil~=v then return i, v end
	end
	return _next, proxy, 0
end

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
		elseif k==PAIRS then
			return __pairs
		elseif k==IPAIRS then
			return __ipairs
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
--	function mt.__newindex(self,k_,v_)
--		-- v_ est ou n'est pas un proxy ?
--	end
	mt.__pairs = __pairs
	mt.__ipairs = __ipairs
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
