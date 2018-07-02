local M = {}


require "math"

require("enum.constants")
local pathfinder = require("scripts.planning.navigation")
local helper = require("scripts.helper")

function make_new_map(map, chosen_door, enemy_locations, room_items, fire, blood_tears, enemy_map, item_map, projectile_map, detail_map, hud_map, custom_score, item_time, end_game)  
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
  
  local detail = 0
    
  while grid_iterator <= vertical_bound do
    
    detail = 0
    
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
          
          adj_room_index = ge_door.TargetRoomIndex
          local next_room_desc = level:GetRoomByIdx(adj_room_index)
          local visited = next_room_desc.VisitedCount

          detail = visited
        end
      end
      map[grid_iterator] = grid_entity_type * 10
      enemy_map[grid_iterator] = grid_entity_type * 10
      item_map[grid_iterator] = grid_entity_type * 10
      projectile_map[grid_iterator] = grid_entity_type * 10
      
      if detail ~= 0 then
        detail_map[grid_iterator] = detail * 10
      else
        detail_map[grid_iterator] = grid_entity_type
      end
      
    else
      map[grid_iterator] = 0
      enemy_map[grid_iterator] = -1
      item_map[grid_iterator] = 1
      projectile_map[grid_iterator] = -1
      detail_map[grid_iterator] = 0
    end

    
    grid_iterator = grid_iterator + 1
    column = column + 1
	end
  
  hud_iterator = 0
    
  while hud_iterator < 135 do
    if hud_iterator < 15*3 then
      hud_map[hud_iterator] = custom_score
    elseif hud_iterator < 15*6 then
      hud_map[hud_iterator] = item_time
    elseif hud_iterator < 15*9 then
      hud_map[hud_iterator] = end_game
    else
      hud_map[hud_iterator] = 0
    end
    hud_iterator = hud_iterator + 1
  end
  
  set_submap(item_map, detail_map, room_items, 50, 10)
  
  set_submap(enemy_map, detail_map, enemy_locations, -50, 10)

  set_submap(projectile_map, detail_map, blood_tears, -50, 10)
  
  set_submap(enemy_map, detail_map, fire, -50, 10)

  local curr_node = room:GetGridIndex(player.Position)
  map[curr_node] = 666

  
end

function set_submap(map, detail_map, arr, value, multiplier)
  for ent, x in pairs(arr) do
    if (map[ent] ~= nil) then
      map[ent] = value
      detail_map[ent] = x * multiplier
    end
  end
end


function render_map(arr, enemy_map, item_map, projectile_map, detail_map, hud_map)
  
  render_map_helper(arr, 150, 50)
  
  render_map_helper(enemy_map, 150, 205)
  
  render_map_helper(hud_map, 405, 205)
    
  render_map_helper(item_map, 405, 50)
  
end

function render_map_helper(map, xOffset, yOffset)
  local iterator = 0
  local row = 0
  local column = 0
  local square_count = 0

  
  while (iterator < 800 and square_count < 135) do
    if (column == 15) then
      row = row + 1
      column = 0
    end
    if (map[iterator] ~= nil) then
      Isaac.RenderText(map[iterator], xOffset + (column * 15), yOffset + (row * 15), 255, 0, 0, 255)    
      column = column + 1
      square_count = square_count + 1
    end
    iterator = iterator + 1
  end
end

M.render_map = render_map
M.make_new_map = make_new_map

return M
