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

function tablelength(T)
	local count = 0;
	for _ in pairs(T) do count = count + 1 end
	return count;
end

move_list = {};

move_list.moves = {};
--print all entries in the array for debugging
move_list.fprint = function()
	for i = 0, (tablelength(move_list.moves) - 1), 1  do
		emu.print(move_list.moves[i].frame .. " press a");
	end
	emu.print("\n");
end
--insert sort by frame
move_list.fsort = function()
	for x = 1, (tablelength(move_list.moves) - 1), 1 do
		for i = 1, (tablelength(move_list.moves) - 1), 1 do
			emu.print("beginning iteration " .. i);
			--create local copy instead of pointer
			local itermove = move_list.moves[i - 1];
			for i2 = i - 1, 0, -1 do
				if (move_list.moves[i2].frame > move_list.moves[i].frame) then
					emu.print("moving item " .. move_list.moves[i2].frame .. " after " .. move_list.moves[i].frame);
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

-- enumerate a test array of moves with edge cases
move_list.new(10000, a_press);
move_list.new(2456, a_press);
move_list.new(1205, a_press);
move_list.new(84, a_press);
move_list.new(5910, a_press);
move_list.new(0, a_press);

emu.print("before sorting:");
move_list.fprint();
move_list.fsort();
emu.print("after sorting:");
move_list.fprint();