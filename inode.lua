
local function mark() return {} end
local __=mark()	-- ".."
local _=mark()	-- "."
local RAW=mark()	-- rawget
local PAIRS=mark()	-- pairs
local IPAIRS=mark()	-- ipairs
local TYPE=mark()	-- get the original type (proxy for a string  will be "string")
local RAWTYPE=mark()	-- get the real     type (proxy for any value will be "table")

-- how to check if it is a proxy (internal use)
local ISPROXY=mark() -- non-proxy table can see this key request

local const={__=__,_=_,RAW=RAW,PAIRS=PAIRS,IPAIRS=IPAIRS,TYPE=TYPE,RAWTYPE=RAWTYPE}

local DEBUG=mark()	--
const.DEBUG=DEBUG	--
--const.ISPROXY = ISPROXY

local type = type -- the standard lua type function

-- simple version
local function isproxy(v)
	return type(v)=="table" and v[ISPROXY]
end

-- complexe version
local SECRET,ACK
local function isproxy(v)
	SECRET,ACK=mark(),mark()
	local ack
	return pcall(function()
		ack = v[ISPROXY](SECRET)
	end) and ACK==ack
end

local function sandbox_type(x)
	local a = type(x)
	if a~="table" or not isproxy(x) then
		return a
	else
		return x[TYPE]
	end
end

local function __rawtype(proxy)
	return proxy[TYPE]
end

local typevalue={
	[type(nil)]=true,
	[type(true)]=true,
	[type("")]=true,
	[type(0)]=true,
}
local function isvalue(x)
	return typevalue[type(x)] or false
end

local function __pairs(proxy)
	local function _next(proxy, k)
		local orig = proxy[RAW]
		local v
		k, v = next(orig, k)
		if nil~=v then
			return k, proxy[k] -- do not expose v without wrapper
		end
	end
	local orig = proxy[RAW]
	if type(orig)~="table" then
		return next, {orig}, nil
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

local function internal_inode(p_parent, name, o_current, gcache, parentcache)
	assert(gcache)
	local p_current
	if type(o_current)=="table" then
		p_current = gcache[o_current]
--if p_current then print("","gcache", gcache, "read ["..name.."]: "../ostring(p_current)) end
		if p_current then return p_current end
	elseif parentcache then
		-- o_current is a value like string/number/boolean
		assert(name)
		assert(type(p_parent)=="table")
		assert(type(name)=="string" or type(name)=="number", "WARNING: table key is a "..type(name))
		p_current = parentcache[name]
--if p_current then print("", "cachep", parentcache, "read ["..name.."]: "..tostring(p_current)) end
		if p_current then return p_current end
	else
		if type(o_current)~="table" then
			assert(parentcache)
		end
	end
	p_current = {}
	if p_parent==nil then p_parent=p_current end
	local new_cachep = setmetatable({},{__mode="v"}) -- indexed on the original key (usually string), will store p_current
	local mt = {}
	function mt.__index(_self,k)
		assert(_self==p_current,"cheat!")
		if k==nil then return nil end
		if k==__ then
			return p_parent
		elseif k==_ then
			return p_current
		elseif k==RAW then
			assert(p_parent~=nil)
			if p_parent == p_current then -- the root is reached
				return o_current
			end
			return p_parent[RAW][name]
		elseif k==TYPE then
			return type(p_current[RAW]) -- type(o_current) ?
		elseif k==RAWTYPE then
			return type(p_current)
		elseif k==PAIRS then
			return __pairs
		elseif k==IPAIRS then
			return __ipairs
		elseif k==ISPROXY then
			return function(secret) return SECRET==secret and ACK end
		elseif k==DEBUG then
			return {
				cache=gcache,
				cachep=new_cachep,
				cacheisempty=function()
					return not next(gcache)
				end,
			}
		end
		local o_sub = o_current[k]
		if o_sub == nil then
			-- the original data does not exists then
			-- destroy the cache if exists
			new_cachep[k]=nil
			return nil
		end
		--if type(o_sub)~="table" then return o_sub end -- no proxy for non-table object

		return internal_inode(p_current, k, o_sub, gcache, new_cachep)
	end
	function mt.__newindex(_self,k,v)
		assert(_self==p_current,"cheat!")
		-- v_ est ou n'est pas un proxy ?
		if type(v)=="table" then
			if isproxy(v) then
				v = v[RAW]
			end
		end
		o_current[k]=v
--		if v == nil then
--			remove from cache if exists
--		end
	end
	mt.__pairs = __pairs
	mt.__ipairs = __ipairs
	local rawtostringvalue = tostring(p_current):gsub("^table","proxy")
	mt.__tostring = function(proxy)
		local o = proxy[RAW] -- orig
		if isvalue(o) then
			return tostring(o)
		else
			return rawtostringvalue.."("..tostring(o)..")"
		end
	end
	setmetatable(p_current,mt)
	if type(o_current)=="table" then
		gcache[o_current] = p_current
--print("","gcache", gcache, "write ["..tostring(o_current).."]="..tostring(p_current))
	else
		parentcache[name] = p_current
--print("","cachep", parentcache, "write ["..name.."]="..tostring(p_current))
	end
	return p_current
end
local function pub_inode(o_current)
	assert(o_current)
	local gcache = setmetatable({},{__mode="v"}) -- indexed on the original table (o_current)
	return internal_inode(nil, "", o_current, gcache, nil), const, {type=sandbox_type}
end

do
	local f = pub_inode({t={},"v","v"})
	assert(f.t==f.t)
	assert(f[1]==f[1])
	assert(f[1]~=f[2])
	f=nil
end

return pub_inode
