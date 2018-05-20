require "math"


local C = {}


-- Helper for Shoot_Tear() --
local function get_nearest_vulnerable_enemy(buffer_size)

	local nearest_enemy = {}
	local entities = Isaac.GetRoomEntities()
  for i=1, buffer_size do
    nearest_enemy[i] = {nil, math.huge} 
  end

	for _, entity in pairs(entities) do
		if entity:IsVulnerableEnemy() then
		 	local distance = entity.Position:Distance(player.Position)
      nearest_enemy[# nearest_enemy + 1] = { entity, distance }
	 	end
	end
  
  table.sort(nearest_enemy, function(a,b) return a[2] < b[2] end)
  
  local current_buf_size = # nearest_enemy
  for j=buffer_size+1, current_buf_size do
    nearest_enemy[j] = nil
  end

	return nearest_enemy
end	


local function Shoot_Tear(buf_size)
	local targets = get_nearest_vulnerable_enemy(buf_size)
	if (targets[1] ~= nil and targets[1][1] ~= nil) then
    aim(1)
	end
  aim(1)
  return targets
end


function aim(target)
  aim_direction = 0
    
  if (command == 10 or command == 14 or command == 18 or command == 22 or command == 26 or command == 30 or command == 34 or command == 38 or command == 42) then
    aim_direction = 1
  elseif (command == 11 or command == 15 or command == 19 or command == 23 or command == 27 or command == 31 or command == 35 or command == 39 or command == 43) then
    aim_direction = 2
  elseif (command == 12 or command == 16 or command == 20 or command == 24 or command == 28 or command == 32 or command == 36 or command == 40 or command == 44) then
    aim_direction = 3
  elseif (command == 13 or command == 17 or command == 21 or command == 25 or command == 29 or command == 33 or command == 37 or command == 41 or command == 45) then
    aim_direction = 4
  else
    aim_direction = 0
  end
  
end




C.Shoot_Tear = Shoot_Tear



return C
