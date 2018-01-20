local E = {}



function find_entities()
  local enemy_locations = {}
	local fire = {}
	local room_items = {}
  local entity_offset = 24
	i_counter = 0
  
  for ent, Entity in pairs(Isaac.GetRoomEntities()) do
		if (Entity:IsVulnerableEnemy()) then
      local enemy_idx = room:GetGridIndex(Entity.Position)
      enemy_locations[enemy_idx] = Entity.Type + entity_offset
		end
		if (Entity ~= nil and Entity.Type == 33 and Entity.EntityCollisionClass ~= 0) then
      local fire_idx = room:GetGridIndex(Entity.Position)
			fire[fire_idx] = Entity.Type + entity_offset
		end		
    if (Entity ~= nil and Entity.Type == 5) then
      local item_idx = room:GetGridIndex(Entity.Position)
      room_items[item_idx] = Entity.Type + entity_offset
      i_counter = i_counter + 1
    end
	end
	if (not room:IsClear()) then
--		item_time = 200 + i_counter * 75
	end
  
  return {enemy_locations, fire, room_items, i_counter}
  
end


function collect_tears(tears)
  local tear_count = 0
  for ent, Entity in pairs(Isaac.GetRoomEntities()) do
    if (Entity.Type == 9 and tear_count < 10) then
      local idx = Entity.Index
      local proj = Entity:ToProjectile()
      if (tears[idx] == nil) then
        
        tears[idx] = {index = idx, 
--                      p_position = player.Position, 
--                      p_velocity = player.Velocity, 
--                      p_shot_speed = player.ShotSpeed, 
                      p_tear_fall_accel = proj.FallingAccel, 
                      p_tear_fall_speed = proj.FallingSpeed, 
                      p_tear_flags = proj.ProjectileFlags, 
                      p_tear_height = proj.Height, 
                      p_homing_strength = proj.HomingStrength,
                      p_acceleration = proj.Acceleration,
                      p_position = proj.Position,
                      p_velocity = proj.Velocity
--                      hit = false, 
--                      t_index = target.Index, 
--                      t_position = target.Position
                    }
        tear_count = tear_count + 1
      end
    end
  end
end



E.find_entities = find_entities
E.collect_tears = collect_tears

return E