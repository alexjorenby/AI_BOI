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
    aim(targets[1][1])
	end
  return targets
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
