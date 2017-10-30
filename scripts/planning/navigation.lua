local P = {}

local function calculate_path(start, D_map, goal)
  local grid_size = room:GetGridSize()
	local room_width = room:GetGridWidth()
	local room_height = room:GetGridHeight()
	local visited_grid = {}
	local v_count = 0
	local loc_path = ""
	local queue = List.new()
	local current = 0
	local split_string = ""
	List.push(queue, tostring(start))
	counter = 0
	
	local possible_paths = {}
	possible_paths[0] = {}
	local pp_counter = 0
  
  local goal_pos = room:GetGridPosition(goal)
  
	while (counter < grid_size and (queue.first <= queue.last) and pp_counter < 1) do
		loc_path = List.pop(queue) .. " "
		split_string = split(loc_path, "%S+")
		current = tonumber(split_string[# split_string])
    local current_pos = room:GetGridPosition(current)
    
				
		if (D_map[current] == 666) then
			possible_paths[pp_counter] = split(loc_path, "%S+")
			pp_counter = pp_counter + 1
--			path_test = split(loc_path, "%S+")
--			return split(loc_path, "%S+")
		

		elseif (not (contains(visited_grid, current))) then
			visited_grid[v_count] = current
			v_count = v_count + 1
      local pxy = Vector(current - math.floor(current/room_width)*room_width, math.floor(current / room_width))

			local cright = current + 1
			local cleft = current - 1
			local cdown = current + room_width
			local cup = current - room_width

			local cupright = current - room_width + 1 
			local cupleft = current - room_width - 1
			local cdownright = current + room_width + 1
			local cdownleft = current + room_width - 1
			
			local right_test = pxy.X < room_width
			local left_test = pxy.X > 0
			local down_test = pxy.Y < room_height
			local up_test = pxy.Y > 0
			
			-- Right
			if (right_test and D_map[cright] ~= 1 and D_map[cright] ~= 6) then
				List.push(queue, loc_path .. " " .. tostring(cright))
			end
			
			-- Left
			if (left_test and D_map[cleft] ~= 1 and D_map[cleft] ~= 6) then
				List.push(queue, loc_path .. " " .. tostring(cleft))
			end

			-- Down
			if (down_test and D_map[cdown] ~= 1 and D_map[cdown] ~= 6) then
				List.push(queue, loc_path .. " " .. tostring(cdown))
			end
			
			-- Up
			if (up_test and D_map[cup] ~= 1 and D_map[cup] ~= 6) then
				List.push(queue, loc_path .. " " .. tostring(cup))
			end
			
			-- Down Right
			if (right_test and down_test and D_map[cdownright] ~= 1 and D_map[cdownright] ~= 6
			and D_map[cdown] ~= 1 and D_map[cright] ~= 1) then
				List.push(queue, loc_path .. " " .. tostring(cdownright))
			end
						
			-- Down Left
			if (left_test and down_test and D_map[cdownleft] ~= 1 and D_map[cdownleft] ~= 6
			and D_map[cleft] ~= 1 and D_map[cdown] ~= 1) then
				List.push(queue, loc_path .. " " .. tostring(cdownleft))
			end
			
			
			-- Up Right
			if (right_test and up_test and D_map[cupright] ~= 1 and D_map[cupright] ~= 6
			and D_map[cright] ~= 1 and D_map[cup] ~= 1) then
				List.push(queue, loc_path .. " " .. tostring(cupright))
			end
			
			
			-- Up Left
			if (left_test and up_test and D_map[cupleft] ~= 1 and D_map[cupleft] ~= 6
			and D_map[cup] ~= 1 and D_map[cleft] ~= 1) then
				List.push(queue, loc_path .. " " .. tostring(cupleft))
			end
			
			counter = counter + 1
		end
	end
	return possible_paths
end


local function has_path(idx, D_map)
  local room_width = room:GetGridWidth()
	local a = ""
	local b = ""
	local c = ""
	local d = ""
	if (pcall(function() a = D_map[idx + room_width] end)) then
		if (a ~= 1) then
			return true
		end
	end
	if (pcall(function() b = D_map[idx - room_width] end)) then
		if (b ~= 1) then
			return true
		end
	end
	if (pcall(function() c = D_map[idx + 1] end)) then
		if (c ~= 1) then
			return true
		end
	end
	if (pcall(function() d = D_map[idx - 1] end)) then
		if (d ~= 1) then
			return true
		end
	end
	return false
end





function prioritize_search_direction(current_pos, goal_pos)
  
  
end

-- Lower-level List Helper Functions --
List = {}
function List.new ()
	return {first = 0, last = -1}
end

function List.push (list, value)
	local first = list.first - 1
	list.first = first
	list[first] = value
end

function List.pop (list)
	local last = list.last
	if list.first > last then error("list is empty") end
	local value = list[last]
	list[last] = nil 
	list.last = last - 1
	return value
end


P.has_path = has_path
P.calculate_path = calculate_path


return P