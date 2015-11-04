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

--this code is used to draw the speedometer
cx = 235;
cy = 210;
radius = 15;
local speedometer_back = "white";
local speedometer_needle = "black";
local min_speed_angle = 100;
local max_speed_angle = 75;
local needle_radius_inner = 2;
local needle_radius_outer = 17;

--void. draws the white circle for the speedometer as well as the labels
function drawspeedometer()
	--draw the speedometer background
	for foo = 0, 360, 1 do
		x = cx + radius * math.cos(foo);
		y = cy + radius * math.sin(foo);
		gui.setpixel(x, y, speedometer_back);
		-- if this is the first pass, fill in the rows
		if (foo < 180) then
			left_bound = cx - (x - cx);
			local cur = 0;
			while (left_bound + cur < x) do
				gui.setpixel(left_bound + cur, y, speedometer_back);
				cur = cur + 1;
			end
		end
	end

	--calculate points for the needle based on current speed
	--the first point is the one that points to the speed
	speedf = (bike_speed() / 255);
	if (speedf <= 0.30) then
		speedf = 0;
	else 
		-- states speed as a float between 0 and 1
		speedf = speedf - 0.30;
		speedf = speedf * (1 / 0.7);
	end
	gui.text(10, 30, "Speed " .. speedf);
	needle_angle = min_speed_angle + math.floor(speedf * ((360 - min_speed_angle) + max_speed_angle));
	x1 = cx + needle_radius_outer * math.cos(math.rad(needle_angle));
	y1 = cy + needle_radius_outer * math.sin(math.rad(needle_angle));
	x2 = cx + needle_radius_inner * math.cos(math.rad((360 - min_speed_angle) + max_speed_angle));
	y2 = cy + needle_radius_inner * math.sin(math.rad((360 - min_speed_angle) + max_speed_angle));

	gui.line(x1, y1, x2, y2, speedometer_needle);

	-- draw the numbers around the speedometer
	local labels_inc = 2;
	local labels_min = 2;
	local labels_max = 12;
	local inc_angle_degrees = math.floor(((340 - min_speed_angle) + max_speed_angle) 
			/ ((labels_max - labels_min) / labels_inc));
	for fiveinc = labels_min, labels_max, labels_inc do
		local margin_right = 5;
		local margin_bottom = 3;
		local label_x = (cx - margin_right) + radius
			* math.cos(math.rad((min_speed_angle + (((fiveinc / labels_inc) - 1) * inc_angle_degrees)) % 360));
		local label_y = (cy - margin_bottom) + radius 
			* math.sin(math.rad((min_speed_angle + (((fiveinc / labels_inc) - 1) * inc_angle_degrees)) % 360));
		gui.drawtext(label_x, label_y, "" .. fiveinc, speedometer_back, speedometer_needle);
	end
end

-- this variable stores the last AI paper toss
last_toss = 0;
last_toss_score = 0;
successful_toss_frames = {};
successful_toss_count = 0;
input_table = lines_from(file);

--expirementing with delimiting score increases
score_delta_chunks = {}; -- linked list of score increases
score_increased_last_frame = false; -- bool, true if score was increaseing on the prior frame
score_chunk = 0; -- long, stores the value of a score increase

-- unsigned int. stores the current frame during the subroutine
frame = 1;

while (true) do
	cur_lives = lives();
	papers = memory.readbyte(0x00B1);
	gui.text(50, 10, papers);
	gui.text(250, 15, total_score());
	gui.text(50, 20, "frame " .. frame);
	gui.text(5, 8, "Lives: " .. cur_lives);
	frame_toss_bool = frame_has_paper_toss(frame - 1);
	if frame_has_paper_toss_bool then
		gui.text(50, 40, "button press at frame " .. frame - 1);
		frame_has_paper_toss = false;
	else 
		-- gui.text(50, 40, "button press not detected");
	end
	if (frame % (math.random(300) + 50) == 0) then
		joypad.write(1, a_press);
		last_toss = frame;
		last_toss_score = total_score();
	else
		if (total_score() > last_toss_score) then
			if (score_increased_last_frame) then
				local cur_score = total_score();
				score_chunk = score_chunk + (cur_score - last_toss_score);
				score_delta_chunks[tablelength(score_delta_chunks)] = score_chunk;
				score_increased_last_frame = true;
			else 
				successful_toss_frames[tablelength(successful_toss_frames)] = last_toss;
				successful_toss_count = successful_toss_count + 1;
			end
		end
	end
	drawspeedometer();

	gui.text(100, 10, tablelength(successful_toss_frames) .. " succesful AI tosses");
	--gui.text(100, 40, #successful_toss_frames .. " successful_toss_frames found");
	FCEU.frameadvance();
	frame = frame + 1;
end

taseditor.registerauto(get_buttons);