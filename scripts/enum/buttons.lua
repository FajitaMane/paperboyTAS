--module is contained in this table
local button_module = {};

-- maps the button bit masks and allows for drawing them in the emu window
button_module.buttonlist = {
	A      = {x=30, y=5, w=3, h=3, bitmask=1},
	B      = {x=24, y=5, w=3, h=3, bitmask=2},
	select = {x=18, y=7, w=3, h=1, bitmask=4},
	start  = {x=12, y=7, w=3, h=1, bitmask=8},
	up     = {x=4, y=1, w=2, h=2, bitmask=16},
	down   = {x=4, y=7, w=2, h=2, bitmask=32},
	left   = {x=1, y=4, w=2, h=2, bitmask=64},
	right  = {x=7, y=4, w=2, h=2, bitmask=128}
}

button_module.a_press = {
	up = true,
	down = false,
	left = false,
	right = false,
	A = true,
	B = false,
	start = false,
	select = false
}

button_module.start_press = {
	up = false,
	down = false,
	left = false,
	right = false,
	A = true,
	B = false,
	start = true,
	select = false
}

return button_module;