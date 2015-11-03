local frame = 1;
local file = '../data/run1.fm2';

-- maps the button bit masks and allows for drawing them in the emu window
buttons = {
	A      = {x=30, y=5, w=3, h=3, bitmask=1},
	B      = {x=24, y=5, w=3, h=3, bitmask=2},
	select = {x=18, y=7, w=3, h=1, bitmask=4},
	start  = {x=12, y=7, w=3, h=1, bitmask=8},
	up     = {x=4, y=1, w=2, h=2, bitmask=16},
	down   = {x=4, y=7, w=2, h=2, bitmask=32},
	left   = {x=1, y=4, w=2, h=2, bitmask=64},
	right  = {x=7, y=4, w=2, h=2, bitmask=128}
}

a_press = {
	up = true,
	down = false,
	left = false,
	right = false,
	A = true,
	B = false,
	start = false,
	select = false
}

function score()
	hundredthou = memory.readbyte(0x00D4);
	tenthou = memory.readbyte(0x00D5);
	thou = memory.readbyte(0x00D6);
	hundred = memory.readbyte(0x00D7);
	ten = memory.readbyte(0x00D8);
	retval = (ten * 10);
	retval = retval + (hundred * 100);
	retval = retval + (thou * 1000);
	retval = retval + (tenthou * 10000);
	retval = retval + (hundredthou* 100000);
	return retval;
end

function bonus_score()
	hundredthou = memory.readbyte(0x076E);
	tenthou = memory.readbyte(0x076F);
	thou = memory.readbyte(0x0770 );
	hundred = memory.readbyte(0x0771);
	ten = memory.readbyte(0x0772);
	retval = (ten * 10);
	retval = retval + (hundred * 100);
	retval = retval + (thou * 1000);
	retval = retval + (tenthou * 10000);
	retval = retval + (hundredthou* 100000);
	return retval;
end

function total_score()
	return score() + bonus_score();
end

-- Typical call:  if hasbit(x, bit(3)) then ...
function hasbit(x, p)
  return x % (p + p) >= p       
end

-- get all lines from a file, returns an empty 
-- list/table if the file does not exist
function lines_from(file)
  lines = {}
  for line in io.lines(file) do 
    lines[#lines + 1] = line
  end
  gui.text(50, 60, #lines .. " lines in file");
  return lines
end

function get_buttons()
	if (taseditor.engaged()) then
		if hasbit(taseditor.getInput(frame - 5, 1), buttons.A.bitmask) then
			gui.text(50, 30, "Paper tossed last in frame " .. frame);
		end
	else
		gui.text(50, 30, "Tas Editor not engaged");
	end
end

function frame_has_paper_toss(frame_index)
	if (input_table) then
		if (input_table[frame_index]) then
			return true
		else
			return false
		end
	else 
		gui.text(50, 50, "input_table not set");
	end
end

function tablelength(T)
  local count = 0
  for _ in pairs(T) do count = count + 1 end
  return count
end

-- this variable stores the last AI paper toss
last_toss = 0;
last_toss_score = 0;
successful_toss_frames = {};
successful_toss_count = 0;
input_table = lines_from(file);

while (true) do
	lives = memory.readbyte(0x00B2);
	papers = memory.readbyte(0x00B1);
	gui.text(50, 10, papers);
	gui.text(250, 15, total_score());
	gui.text(50, 20, "frame " .. frame);
	if (frame_has_paper_toss(frame - 1)) then
		gui.text(50, 40, "button press at frame " .. frame - 1);
	else 
		gui.text(50, 40, "button press not detected");
	end
	if (frame % (math.random(300) + 50) == 0) then
		joypad.write(1, a_press);
		last_toss = frame;
		last_toss_score = total_score();
	else
		if (total_score() > last_toss_score and frame - last_toss > 150) then
			emu.print(last_toss);
			successful_toss_frames[tablelength(successful_toss_frames)] = last_toss;
			successful_toss_count = successful_toss_count + 1;
		end
	end
	gui.text(100, 10, tablelength(successful_toss_frames) .. " succesful AI tosses");
	--gui.text(100, 40, #successful_toss_frames .. " successful_toss_frames found");
	FCEU.frameadvance();
	frame = frame + 1;
end

taseditor.registerauto(get_buttons);