local M = {}


require "math"

require("enum.constants")
local pathfinder = require("scripts.planning.navigation")
local helper = require("scripts.helper")

function make_new_map(map, chosen_door, enemy_locations, room_items, fire, blood_tears, enemy_map, item_map, projectile_map)  
  local room_width = room:GetGridWidth()
  local room_height = room:GetGridHeight()
  local grid_size = room:GetGridSize()-1
  local isaac_pos = room:GetGridIndex(player.Position)

--  local door_index = room:GetGridIndex(chosen_door.Position)
    
  local start = 0
  
  if (room_width > 15 or room_height > 9) then      
    start = isaac_pos - 7 - 4 * room_width
    if ((isaac_pos % 28) > 7) then
      while (((start + 14) % room_width) < (start % room_width)) do
        start = start - 1
      end
    else
      while (((start + 14) % room_width) < (start % room_width)) do
        start = start + 1
      end
    end
    while (start < 0) do
      start = start + room_width
    end
    while ((start + (8*room_width)) > grid_size) do
      start = start - room_width
    end
    
  end
  
  local vertical_bound = start + 14 + 8*room_width
  grid_iterator = start
  column = 0
  
  
  
  
  while grid_iterator <= vertical_bound do
    
    if (column == 15) then
      grid_iterator = grid_iterator + room_width - 15
      column = 0
    end
    
		grid_entity = room:GetGridEntity(grid_iterator)
            
    if (grid_entity ~= nil) then
      grid_entity_type = grid_entity.Desc.Type
      if grid_entity_type == 2 then
        local r = grid_entity:ToRock()
        if r.State == 2 then
          grid_entity_type = 0
        end
      end
      if grid_entity_type == 14 then
        local p = grid_entity:ToPoop()
        if p.State == 4 then
          grid_entity_type = 0
        end
      end
      if grid_entity_type == 16 then
        local ge_door = grid_entity:ToDoor()
        if ge_door:GetVariant() == 7 then
          grid_entity_type = 15
        else
          grid_entity_type = ge_door:GetVariant() + (ge_door.TargetRoomType * 100)
        end
      end
      map[grid_iterator] = grid_entity_type
    else
      map[grid_iterator] = 0
      
    end
    
    enemy_map[grid_iterator] = 0
    item_map[grid_iterator] = 0
    projectile_map[grid_iterator] = 0
    

    grid_iterator = grid_iterator + 1
    column = column + 1
	end
    
  for ent, x in pairs(room_items) do
    if (item_map[ent] ~= nil) then
      item_map[ent] = x
    end
  end
  for ent, x in pairs(enemy_locations) do
    if (enemy_map[ent] ~= nil) then
      enemy_map[ent] = x
    end
  end
  for ent, x in pairs(blood_tears) do
    if (projectile_map[ent] ~= nil) then
      projectile_map[ent] = x
    end
  end
  for ent, x in pairs(fire) do
    if (enemy_map[ent] ~= nil) then
      enemy_map[ent] = x
    end
  end

  local curr_node = room:GetGridIndex(player.Position)
  map[curr_node] = 666

  
end


function render_map(arr, enemy_map, item_map, projectile_map)
  local iterator = 0
  local row = 0
  local column = 0
  local square_count = 0
    
  while (iterator < 800 and square_count < 135) do
    if (column == 15) then
      row = row + 1
      column = 0
    end
    if (arr[iterator] ~= nil) then
      Isaac.RenderText(arr[iterator], 150 + (column * 15), 50 + (row * 15), 255, 0, 0, 255)      
      column = column + 1
      square_count = square_count + 1
    end
    iterator = iterator + 1
  end
  
  iterator = 0
  row = 0
  column = 0
  square_count = 0

  
  while (iterator < 800 and square_count < 135) do
    if (column == 15) then
      row = row + 1
      column = 0
    end
    if (enemy_map[iterator] ~= nil) then
      Isaac.RenderText(enemy_map[iterator], 150 + (column * 15), 205 + (row * 15), 255, 0, 0, 255)    
      column = column + 1
      square_count = square_count + 1
    end
    iterator = iterator + 1
  end
  
  iterator = 0
  row = 0
  column = 0
  square_count = 0

  
  while (iterator < 800 and square_count < 135) do
    if (column == 15) then
      row = row + 1
      column = 0
    end
    if (item_map[iterator] ~= nil) then
      Isaac.RenderText(item_map[iterator], 405 + (column * 15), 205 + (row * 15), 255, 0, 0, 255)    
      column = column + 1
      square_count = square_count + 1
    end
    iterator = iterator + 1
  end
  
  iterator = 0
  row = 0
  column = 0
  square_count = 0

  
  while (iterator < 800 and square_count < 135) do
    if (column == 15) then
      row = row + 1
      column = 0
    end
    if (projectile_map[iterator] ~= nil) then
      Isaac.RenderText(projectile_map[iterator], 405 + (column * 15), 50 + (row * 15), 255, 0, 0, 255)    
      column = column + 1
      square_count = square_count + 1
    end
    iterator = iterator + 1
  end
  
end

M.render_map = render_map
M.make_new_map = make_new_map

return M
