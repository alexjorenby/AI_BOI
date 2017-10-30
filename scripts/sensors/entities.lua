local E = {}



function find_entities()
  local enemy_locations = {}
	local fire = {}
	local room_items = {}
	i_counter = 0
  
  for ent, Entity in pairs(Isaac.GetRoomEntities()) do
		if (Entity:IsVulnerableEnemy()) then
      local enemy_idx = room:GetGridIndex(Entity.Position)
      enemy_locations[enemy_idx] = Entity.Type + 23
		end
		if (Entity ~= nil and Entity.Type == 33 and Entity.EntityCollisionClass ~= 0) then
      local fire_idx = room:GetGridIndex(Entity.Position)
			fire[fire_idx] = Entity.Type + 23
		end		
    if (Entity ~= nil and Entity.Type == 5) then
      local item_idx = room:GetGridIndex(Entity.Position)
      room_items[item_idx] = Entity.Type + 23
      i_counter = i_counter + 1
    end
	end
	if (not room:IsClear()) then
		item_time = 200 + i_counter * 75
	end
  
  return {enemy_locations, fire, room_items, i_counter}
  
end


function collect_tears(tears, target)
  for ent, Entity in pairs(Isaac.GetRoomEntities()) do
    if (Entity.Type == 2) then
      local idx = Entity.Index
      if (tears[idx] == nil and target ~= nil and target ~= -1) then
        
        tears[idx] = {index = idx, 
                      p_position = player.Position, 
                      p_velocity = player.Velocity, 
                      p_shot_speed = player.ShotSpeed, 
                      p_tear_fall_accel = player.TearFallingAcceleration, 
                      p_tear_fall_speed = player.TearFallingSpeed, 
                      p_tear_flags = player.TearFlags, 
                      p_tear_height = player.TearHeight, 
                      hit = false, 
                      t_index = target.Index, 
                      t_position = target.Position
                      }
      end
    end
  end
end



E.find_entities = find_entities
E.collect_tears = collect_tears

return E