local speedometer_module = {};


speedometer_module.test = "hello from speedometer";

--void. draws the white circle for the speedometer as well as the labels
function speedometer_module.draw()
	--these values are used to draw the speedometer
	local cx = 235;
	local cy = 210;
	local radius = 15;
	local speedometer_back = "white";
	local speedometer_needle = "black";
	local min_speed_angle = 100;
	local max_speed_angle = 60;
	local needle_radius_inner = 2;
	local needle_radius_outer = 17;
	local speedometer_unit_label = "mph";

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

	-- draw the mph or kmph label on the game
	gui.drawtext(cx + needle_radius_inner + 3, cy + radius, speedometer_unit_label, speedometer_back, speedometer_needle);
end

return speedometer_module;