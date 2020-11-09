local data = {
	foo = "FOO",
	bar = "BAR",
	x = { y = { z = "Z"}},
}

local inode = require "inode"
local DATA,const = inode(data)
local __ = const.__
local _ = const._

assert( tostring(DATA.foo) == "FOO" )
assert( DATA.foo[const.RAW] == "FOO" )

local y1 = DATA["x"]["y"]		-- /x/y
local y2 = y1[__]["y"]			-- ../y
local y3 = DATA["x"]["y"]["z"][__]	-- /x/y/z/..
local y3 = DATA[__][__][__]["x"]["y"]	-- /../../../x/y


