local data = {
	foo = "FOO",
	bar = "BAR",
	x = { y = { z = "Z"}},
}

local inode = require "inode"
local DATA,const = inode(data)
local __ = const.__
local _ = const._

do
	local walk = require "mini-table-walk3"
	local split = require "split"

	local fs={inode=DATA, root=DATA}
	function fs:walk(path)
		local pwd = self.inode
		local t = split(path, "/", true) or {}
		if t[1]=="" then
			table.remove(t,1)
			pwd = self.root
		end
		return walk(pwd, t)
	end
	function fs:pwd()
		return self.inode
	end
	function fs:cd(path)
		local tmp = self:walk(path)
		self.inode=tmp
		return tmp
	end
	function fs:cat(path)
		local tmp = self:walk(path)
		return tmp and tmp[const.RAW]
	end

	fs:cd "x/y"
	assert( fs:cat("z") == "Z")
end
