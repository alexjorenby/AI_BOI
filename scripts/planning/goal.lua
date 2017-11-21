local G = {}

local pathfinder = require("scripts.planning.navigation")

local function find_trapdoor(room, grid_size)

	-- Look through the entire grid 
	-- TOOD: Integrate with existing pathfinding
	for r = 0, grid_size-1 do
		grid_entity = room:GetGridEntity(r)
		if (grid_entity ~= nil) then
			if (grid_entity.Desc.Type == 17) then
				return room:GetGridIndex(grid_entity.Position)
			end
		end
	end
  return nil
end

local function find_door(player, room)
  local level = game:GetLevel()
	local visited_door = nil
	local found_doors = {}
	local target_index = 0
	local visited_min = math.huge
	for i=0,8 do
		if (pcall(function () door = room:GetDoor(doors[i]) end)) then
			if (pcall(function () door_exists = door.TargetRoomIndex end)) then

				adj_room_index = door.TargetRoomIndex
				local next_room_desc = level:GetRoomByIdx(adj_room_index)
				local visited = next_room_desc.VisitedCount

				if (visited < 1) then
					-- Rooms we are currently avoiding:  
					-- Secret and SuperSecret (7,8) (Can't reliably search for these at the moment without cheating)
					-- Curse (10) (Too likely to damage with current algorithm)
					-- Challenge (11) (Conditions are unknown, presently dealing with challenge OOS)
					-- and key rooms (while keys are less than 3) (Accounting for the general case of double key rooms) 
					-- TODO De-jank this if statement by enumerating elsewhere
					if(door:IsKeyFamiliarTarget() )then --and player:GetNumKeys() > 3) then
						door.SetLocked(false)
					end

					if((door:IsKeyFamiliarTarget() and player:GetNumKeys() > 1 and door.TargetRoomType == 4) or 
						 not(door.TargetRoomType == 7 or door.TargetRoomType == 8 or
						  door.TargetRoomType == 10 or door.TargetRoomType == 11 or
						  door.TargetRoomType == 12 or door.TargetRoomType == 2)) then	
						found_doors[target_index] = door
						target_index = target_index + 1		
					end
				end

				-- Return to the last room you visited.
				-- At present this is INCREDIBLY clunky and gets caught in all sorts of terrible loops
				-- It's basically a hill-climber in the form of a pathfinding algorithm.
				-- The issue is we don't have the entire map available to us at all times, and so 
				-- We can't pathfind effectively given a limited map. Heuristic analysis
				-- Proves to be pretty difficult.
				if (visited >= 1) then
					if (visited < visited_min) then
						visited_door = door
						visited_min = visited
					end
				end
			end
		end
	end

	-- If you haven't found a new room to move to, move to the previous one and continue the same search.
	if (target_index == 0) then
		return visited_door
	end

	-- This was causing problems earlier, however; currently the door sweep is handling this.
	-- Leaving in for documentation. 
	--if (found_doors[0]:IsKeyFamiliarTarget() and player:GetNumKeys() > 0) then
	--	return found_doors[0]
	--end
	return found_doors[0]
	
end

function find_goal(enemy_locations, room_items, i_counter, D_map)
  local goal = -1
  local room_width = room:GetGridWidth()
  local grid_size = room:GetGridSize()
	if (room:IsClear()) then	
    if (i_counter > 0 and item_time > 0) then
			local pickup_goal = false
			local i = 0
			while (i < i_counter and pickup_goal == false) do
--				if (pathfinder.has_path(room_items[i], D_map)) then
        for ent, x in pairs(room_items) do
          goal = ent
          pickup_goal = true
        end
				i = i + 1
			end
    else
      if(room:GetType() == 5) then
        goal = find_trapdoor(room, grid_size)
      else
        local door = find_door(player, room)
        -- Should never select a door when you cannot unlock it
        -- TODO FIX THIS IT IS HORRIBLY BROKEN
        if (door.TargetRoomType == 4 and door:IsLocked()) then
          door:TryUnlock(false)
        end
        local door_pos = door.Position
        goal = room:GetGridIndex(door.Position)
      end
    end
	else
    for ent2, x2 in pairs(enemy_locations) do
      pcall (function() combat_dest = enemy_locations[ent2] + math.random(-5, 5) + (math.random(-5, 5) * room_width) end)
      if (is_valid(combat_dest, D_map)) then
        break
      end
    end
    goal = combat_dest
	end
  D_map[goal] = 666
  return goal
end

function is_valid(goal, D_map)
  local occupant = D_map[goal]
  if (occupant == nil) then return false end
  if (occupant == 1) then return false end
  if (occupant == 6) then return false end
  if (not pathfinder.has_path(goal, D_map)) then return false end  
  return true
end


G.find_door = find_door
G.find_goal = find_goal

return G