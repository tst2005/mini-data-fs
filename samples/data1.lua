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

-- /x/y
local y1 = DATA["x"]["y"]
assert(y1[const.RAW]==data.x.y)

-- ../y
local y2 = y1[__]["y"]
assert(y2==y1)

-- /x/y/z/..
local y3 = DATA["x"]["y"]["z"][__]
assert(y3==y1)

-- /../../../x/y
local y4 = DATA[__][__][__]["x"]["y"]
assert(y4==y1)

-- cat /x/y/z
assert( DATA["x"]["y"]["z"][const.RAW] == "Z" )
