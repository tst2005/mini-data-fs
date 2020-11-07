
local __={}	-- ".."
local _={}	-- "."
local RAW={}	-- rawget
local PAIRS={}	--
local IPAIRS={}	--

local const={[".."]=__,["."]=_,["raw"]=RAW,["pairs"]=PAIRS,["ipairs"]=IPAIRS}

---- cache system ----
local cacheblackbox
do
	local function new()
		local cache=setmetatable({},{__mode="v"})
		return cache, function() return not next(cache) end
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
	local function blackbox()
		local cache,isempty = new()
		local function getset(k, v)
			if v==nil then
				return get(cache, k)
			end
			if type(v)=="function" then
				v=v()
			end
			return set(cache, k, v)
		end
		return getset, isempty
	end
	cacheblackbox = blackbox
end
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

local function inode(p_parent, name, o_current, cachegetset)
	assert(cachegetset)
	local p_current = cachegetset(current)
	if p_current then return p_current end
	p_current={}
	local mt ={}
	function mt.__index(self,k)
		if k==__ then
			return p_parent
		elseif k==_ then
			return p_current
		elseif k==RAW then
			--print("parent", parent, "current", current, "name", name,])
			if p_parent == nil then return o_current end
			return p_parent[RAW][name]
		elseif k==PAIRS then
			return __pairs
		elseif k==IPAIRS then
			return __ipairs
		end
		local o_sub = o_current[k]
		if o_sub == nil then return nil end
		--if type(o_sub)~="table" then return o_sub end

		local p_sub = cachegetset(o_sub)
		if p_sub then return p_sub end
		p_sub = inode(p_current, k, o_sub, cachegetset)
		return cachegetset(o_sub, p_sub)
--[[
		return cachegetset(o_sub, function() return inode(p_current, k, o_sub, cachegetset) end)
]]--
	end
--	function mt.__newindex(self,k_,v_)
--		-- v_ est ou n'est pas un proxy ?
--	end
	mt.__pairs = __pairs
	mt.__ipairs = __ipairs
	setmetatable(p_current,mt)
	return cachegetset(o_current, p_current)
end
local function pub_inode(parent, name, current, cache)
	if not cache then
		local cache, isempty = cacheblackbox()
		return inode(parent, name, current, cache), const, isempty
	end
	return inode(parent, name, current, cache)
end

return pub_inode
