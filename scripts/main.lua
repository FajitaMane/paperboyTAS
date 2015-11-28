local env = "dev";

buttons = require "enum.buttons";

if (env == "movie" or env == "dev") then
	speedometer = require "ext.speedometer";
end

--speed through the game as fast as possible if collecting data
if (env == "prod" or env == "dev") then
	emu.speedmode("turbo")
end

local file = '../data/run1.fm2';

local gameisrunning = false;

menu_colors = {};
--add white to menu_colors
menu_colors[0] = {};
menu_colors[0].r = 252;
menu_colors[0].g = 252;
menu_colors[0].b = 252;
--add bright green to menu_colors
menu_colors[1] = {};
menu_colors[1].r = 0;
menu_colors[1].g = 168;
menu_colors[1].b = 0;
--add black to menu_colors
menu_colors[2] = {};
menu_colors[2].r = 0;
menu_colors[2].g = 0;
menu_colors[2].b = 0;

--returns current player score
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

-- returns the current lives of the paperboy in the emu at the current frame
-- int cur_lives
function lives()
	return 0 + memory.readbyte(0x00B2);
end

--returns current bonus score
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

--returns total score + bonus score
function total_score()
	return score() + bonus_score();
end

-- Typical call:  if hasbit(x, bit(3)) then ...
function hasbit(x, p)
  return x % (p + p) >= p       
end

-- Check if the game is currently in a menu
function is_in_menu()
	local vals = {};
	vals[0] = 0;
	vals[1] = 0;
	vals[2] = 0;
	for x_cur = 5, 200, 5 do
		for y_cur = 5, 100, 5 do
			r,g,b,a = emu.getscreenpixel(x_cur, y_cur, false);
			--this stores values for the menu_colors found on screen

			for k, v in pairs(menu_colors) do
				if (r == v.r and b == v.b and g == v.g) then
					vals[k] = vals[k] + 1;
				end
			end
		end
	end
	local max = 0;
	for k, v in pairs(menu_colors) do
		if (vals[k] > 150) then
			if (vals[k] > max) then
				max = vals[k];
			end
		end
	end
	return max > 600;
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

function bike_speed()
	return memory.readbyte(0x00BA);
end

function get_trailing_lives(lives)
	local FRAME_TRAIL = 30;
	if (lives < trailing_lives) then
		emu.print("found necessary move at " .. frame - FRAME_TRAIL);
	end
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
			return true;
		else
			return false;
		end
	else 
		gui.text(50, 50, "input_table not set");
		return false;
	end
end

function tablelength(T)
  local count = 0;
  for _ in pairs(T) do count = count + 1 end
  return count;
end

-- this variable stores the last AI paper toss
last_toss = 0;
last_toss_score = 0;
successful_toss_frames = {};
successful_toss_count = 0;
input_table = lines_from(file);

trailing_lives = 0;

--expirementing with delimiting score increases
score_delta_chunks = {}; -- linked list of score increases
score_increased_last_frame = false; -- bool, true if score was increaseing on the prior frame
score_chunk = 0; -- long, stores the value of a score increase

-- unsigned int. stores the current frame during the subroutine
frame = 1;
-- unsigned int. stores the first frame of the run nil if not frame has been found yet
starting_frame = nil;
last_frame_menu_text = "no";
local last_reset_frame = 0;

move_list = {};
move_list.moves = {};
--print all entries in the array for debugging
move_list.fprint = function()
	for i = 0, (tablelength(move_list.moves) - 1), 1  do
		emu.print("index: " .. i .. " with frame " .. move_list.moves[i].frame .. " press a");
	end
	emu.print("\n");
end
--returns true if the move_list contains a button state for the given frame
move_list.contains = function(argframe)
	for i = 0, (tablelength(move_list.moves) - 1), 1 do
		if (move_list.moves[i].frame == argframe) then
			return true;
		end
	end
	return false;
end
--insert sort by frame
move_list.fsort = function()
	for x = 1, (tablelength(move_list.moves) - 1), 1 do
		for i = 1, (tablelength(move_list.moves) - 1), 1 do
			--create local copy instead of pointer
			local itermove = move_list.moves[i - 1];
			for i2 = i - 1, 0, -1 do
				if (move_list.moves[i2].frame > move_list.moves[i].frame) then
					--emu.print("moving item " .. move_list.moves[i2].frame .. " after " .. move_list.moves[i].frame);
					move_list.moves[i2] = move_list.moves[i];
					move_list.moves[i] = itermove;
					move_list.fprint();
				end
			end
		end
	end
end
move_list.new = function(arg_frame, arg_button_state)
	move = {};
	move.frame = arg_frame;
	move.button_state = arg_button_state;
	move_list.moves[tablelength(move_list.moves)] = move;
end

--this variable stores the index of the next known move
move_list_cur = 0;

--initialize on the last score
last_frame_score = 0;

--sync frames by resetting the emulation
emu.softreset();

--this value stores whether or not this is the first run
virgin_run = true;
----------------------------------------------------------------------
-- 					Emulation Loop
----------------------------------------------------------------------
while (true) do
	--call RAM reading functions
	cur_lives = lives();
	cur_score = total_score();

	--reset the game if the game ends
	if (cur_lives < 1 and gameisrunning and not is_in_menu() and frame > 30) then
		cur_lives = 5;
		gameisrunning = false;
		last_reset_frame = frame;
		frame  = 0;
		move_list_cur = 0;
		virgin_run = false;
		move_list.fsort();
		emu.print('\n' .. tablelength(move_list.moves) .. " known frames for this run");
		move_list.fprint();
		emu.softreset();
	end

	gameisrunning = true;

	--game is running so check for trailing crashes
	get_trailing_lives(cur_lives);

	-- read the byte for the number of current papers
	papers = memory.readbyte(0x00B1);
	--gui.text(50, 10, papers);
	--gui.text(250, 15, total_score());
	if (is_in_menu()) then
		menu_text = "yes";
		gui.text(50, 200, "Skipping through menus");
	else 
		menu_text = "no";
	end

	--check if the game is in a menu and throttle button presses
	if (menu_text == "yes" and frame % 3 == 0) then
		--spam start and A until out of menus
		joypad.write(1, buttons.start_press);
	end

	--check if 
	if (menu_text == "no" and last_frame_menu_text == "yes") then
		--emu.print("deliveries started at " .. frame);
		if (tablelength(move_list.moves) > 0 and not virgin_run) then
			emu.print("move_list_cur = " .. move_list_cur);
			emu.print("waiting to toss at frame" .. move_list.moves[move_list_cur].frame);
		end
	end

	gui.text(5, 8, "Lives: " .. cur_lives);
	frame_toss_bool = frame_has_paper_toss(frame - 1);
	if frame_has_paper_toss_bool then
		gui.text(50, 40, "button press at frame " .. frame - 1);
		frame_has_paper_toss = false; 
	end

	--check if a known successful move is known for the current frame
	if (tablelength(move_list.moves) > 0 and frame == move_list.moves[move_list_cur].frame) then
		joypad.write(1, move_list.moves[move_list_cur].button_state);
		emu.print("tossing paper from move_list at " .. frame);
		move_list_cur = move_list_cur + 1;
	end

	--randomly toss papers
	if (frame % (math.random(200) + 50) == 0 and menu_text == "no") then
		joypad.write(1, buttons.a_press);
		last_toss = frame;
		last_toss_score = total_score();
	else
		--check for score increase
		score_delimit = 2000; --ms in between score increases
		-- check if this is a legal score increase block
		if (cur_score > last_frame_score and frame - last_toss < 1500 
			and menu_text == "no" and frame ~= 0) then
			score_increased_last_frame = true;
		end
		if (score_increased_last_frame and cur_score <= last_frame_score and last_toss ~= 0) then
			--check for dupes only if frame would otherwise be legal
			if (not move_list.contains(frame)) then move_list.new(last_toss, buttons.a_press) end;
			--emu.print("successful toss frame found at " .. last_toss .. ", " .. tablelength(move_list.moves) .. " moves known");
			score_increased_last_frame = false;
		end
	end
	--only draw the speedometer if the paperboy is delivering
	if (menu_text == "no") then
		speedometer.draw();
	end

	gui.text(100, 10, tablelength(move_list.moves) .. " successful AI tosses");
	--gui.text(100, 40, #successful_toss_frames .. " successful_toss_frames found");
	last_frame_menu_text = menu_text;
	last_frame_score = cur_score;
	frame = frame + 1;
	FCEU.frameadvance();
end

taseditor.registerauto(get_buttons);