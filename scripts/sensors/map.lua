local M = {}


require "math"

require("enum.constants")
local pathfinder = require("scripts.planning.navigation")
local helper = require("scripts.help")

function make_new_map(map, enemy_locations, room_items, fire)
  
  local goal = -1
  local goal_override = false
  local goal_found = false
  
  
  local room_width = room:GetGridWidth()
  local room_height = room:GetGridHeight()
  local grid_size = room:GetGridSize()-1
  local isaac_pos = room:GetGridIndex(player.Position)
  
  
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
      map[grid_iterator] = grid_entity_type
    else
      map[grid_iterator] = 0
      
    end
    grid_iterator = grid_iterator + 1
    column = column + 1
	end
    
  for ent, x in pairs(room_items) do
    if (map[ent] ~= nil) then
      map[ent] = x
    end
  end
  for ent, x in pairs(enemy_locations) do
    if (map[ent] ~= nil) then
      map[ent] = x
    end
  end
  for ent, x in pairs(fire) do
    if (map[ent] ~= nil) then
      map[ent] = x
    end
  end

  local curr_node = room:GetGridIndex(player.Position)
  map[curr_node] = 24

  
end

function make_map(map, enemy_locations, room_items, fire)
  local goal = -1
  local goal_override = false
  local goal_found = false
  local room_width = room:GetGridWidth()
  
  
	for grid_iterator = 0, room:GetGridSize()-1 do
		grid_entity = room:GetGridEntity(grid_iterator)
            
    if (grid_entity ~= nil) then
      grid_entity_type = grid_entity.Desc.Type        
      if (helper.contains(avoid, grid_entity_type) and room:GetGridCollision(grid_iterator) ~= 0 or grid_entity_type == 8) then
        map[grid_iterator] = 1
      elseif (grid_entity_type == 20) then
        if (not goal_override and grid_entity.State == 0 and item_time > 0) then
          goal = grid_iterator
          map[grid_iterator] = 666
          goal_override = true
          goal_found = true
          
        else
          map[grid_iterator] = 2
        end
        
      else
        map[grid_iterator] = 0
        
      end
    else
      map[grid_iterator] = 0
      
    end
    
	end
  
  
  for ent, x in pairs(room_items) do
    map[ent] = 3
  end
  for ent, x in pairs(enemy_locations) do
    map[ent] = 6
  end
  for ent, x in pairs(fire) do
    map[ent] = 6
  end
  
  return goal
end




function render_map(arr)
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
      Isaac.RenderText(arr[iterator], 50 + (column * 20), 50 + (row * 20), 255, 0, 0, 255)      
      column = column + 1
      square_count = square_count + 1
    end
    iterator = iterator + 1
  end
end

M.make_map = make_map
M.render_map = render_map
M.make_new_map = make_new_map

return M
