require "math"


local C = {}


-- Helper for Shoot_Tear() --
local function get_nearest_vulnerable_enemy()

	local nearest_enemy = nil
	local closest_distance = math.huge
	local entities = Isaac.GetRoomEntities()

	for _, entity in pairs(entities) do
		if entity:IsVulnerableEnemy() then
		 	local distance = entity.Position:Distance(player.Position)
		 	if distance < closest_distance then
		 		closest_distance = distance
		 		nearest_enemy = entity
	 		end
	 	end
	end

	return nearest_enemy
end	


local function Shoot_Tear()
	
	local target = get_nearest_vulnerable_enemy()
	if (target ~= nil) then
    aim(target)
	end
  return target
end


function aim(target)
  aim_direction = 0

  local Ax = player.Position.X - target.Position.X
  local Ay = player.Position.Y - target.Position.Y
  
  if (math.abs(Ax) >= math.abs(Ay)) then
    if (Ax >= 0) then
      -- left
      aim_direction = 1
    else
      -- right
      aim_direction = 2
    end
  else
    if (Ay >= 0) then
      -- up
      aim_direction = 3
    else
      -- down
      aim_direction = 4
    end
  end
  
end




C.Shoot_Tear = Shoot_Tear



return C
