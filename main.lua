StartDebug()

local testMod = RegisterMod("TestMod", 1)

require "math"
require("enum.constants")

local pathfinder = require("scripts.planning.navigation")
local operator = require("scripts.actions.movement")
local fighter = require("scripts.actions.combat")
local cartographer = require("scripts.sensors.map")
local helper = require("scripts.help")
local sensor = require("scripts.planning.goal")
local collector = require("scripts.sensors.entities")

game = Game()
room = game:GetRoom()
tears = {}
tears2 = {}
item_time = 600
frame_counter = 0
test_map = {}
possible_paths = {}
store_map = {}
store_map_count = 0
end_game = 666

local target = -1

-- Calls on room entry to update item retrieval timer. --
-- Lower time on already entered rooms so that we only --
-- pick up the "leftovers" from a first-traversal, and --
-- waste less time walking around.                     --
function testMod:new_room_update()
  local level = game:GetLevel()
	local room_desc = level:GetCurrentRoomDesc()
  room = game:GetRoom()
  local str = Isaac.LoadModData(testMod)
--  for ent, x in pairs(tears) do
--    str = str .. tostring(x["index"]) .. 
--        "; " .. tostring(x["p_position"].X) .. 
--        ", " .. tostring(x["p_position"].Y) .. 
--        "; " .. tostring(x["p_velocity"].X) .. 
--        ", " .. tostring(x["p_velocity"].Y) .. 
--        "; " .. tostring(x["p_shot_speed"]) .. 
--        "; " .. tostring(x["p_tear_fall_accel"]) .. 
--        "; " .. tostring(x["p_tear_fall_speed"]) .. 
--        "; " .. tostring(x["p_tear_flags"]) .. 
--        "; " .. tostring(x["p_tear_height"]) .. 
--        "; " .. tostring(x["hit"]) .. 
--        "; " .. tostring(x["t_position"].X) .. 
--        ", " .. tostring(x["t_position"].Y) .. 
--        "\n\n"
--  end

  for ent, x in pairs(store_map) do
    local new_data = ""
    local row = 0
    local iterator = 0
    local square_count = 0
    while (iterator < 450 and square_count < 135) do
      if (row  == 15) then
        new_data = new_data .. "\n"
        row = 0
      end
      if (x[iterator] ~= nil) then
        new_data = new_data .. tostring(x[iterator]) .. ","
        square_count = square_count + 1
        row = row + 1
      end
      iterator = iterator + 1
    end
    str = str .. new_data .. ";\n\n"
  end

  if (str ~= "") then
    Isaac.SaveModData(testMod, str)
  end
  
  store_map = {}
  store_map_count = 0
  
  tears = {}
  tears2 = {}
	if (room_desc.VisitedCount > 1) then
		item_time = 150
	else
		item_time = 300
	end
	update_strategy()
end

function testMod:update_agent()

	player = Isaac.GetPlayer(0)
	item_time = item_time - 1
	frame_counter = frame_counter + 1
	
  local total_tears = 0
  local tears_hit = 0
  for ent, x in pairs(tears) do
    total_tears = total_tears + 1
    if (x["hit"]) then
      tears_hit = tears_hit + 1
    end
  end

	Isaac.RenderText("ITEM TIME: " .. tostring(item_time), 200, 25, 255, 0, 255, 255)
  Isaac.RenderText("End Game: " .. tostring(end_game), 50, 25, 255, 0, 255, 255)
  Isaac.RenderText("Hit Rate: " .. tostring((tears_hit) / (total_tears) * 100) .. "%", 300, 25, 255, 0, 255, 255)
	if (frame_counter % 10 == 0) then
		target = update_strategy()
	end
  collector.collect_tears(tears, target)
	cartographer.render_map(test_map)
  
	operator.traverse_path(player, path)
  			
end

function update_strategy()
  
  end_game = player:GetHearts() + player:GetSoulHearts() + player:GetBlackHearts() + player:GetEternalHearts() + player:GetExtraLives()
  
  if (end_game <= 0 or item_time < -5000) then
    Isaac.ExecuteCommand("restart")
  end
  
	D_map = {}  
  local collection = collector.find_entities()
  local goal = cartographer.make_map(D_map, collection[1], collection[3], collection[2])
  
  test_map = {}
  cartographer.make_new_map(test_map, collection[1], collection[3], collection[2])
  
  while (goal < 0) do
    goal = sensor.find_goal(collection[1], collection[3], collection[4], D_map)
  end
  
	local curr_node = room:GetGridIndex(player.Position)
	possible_paths = pathfinder.calculate_path(curr_node, D_map, goal)
	path = possible_paths[helper.find_min(possible_paths)]
  
  store_map[store_map_count] = test_map
  store_map_count = store_map_count + 1
  
  if (room:IsClear()) then
    aim_direction = 0
  else
    return fighter.Shoot_Tear()
  end
    
end



function testMod:execute_movement(player, hook, but)
  -- Movement
  if (but == ButtonAction.ACTION_LEFT and left) then
    return 1.0
  elseif (but == ButtonAction.ACTION_RIGHT and right) then
    return 1.0
  end
  if (but == ButtonAction.ACTION_UP and up) then
    return 1.0
  elseif (but == ButtonAction.ACTION_DOWN and down) then
    return 1.0
  end
  
end 

function testMod:execute_shoot(player, hook, but)
  -- Combat
  if (but == ButtonAction.ACTION_SHOOTLEFT and aim_direction == 1) then
    -- left
    return 1.0
  elseif (but == ButtonAction.ACTION_SHOOTRIGHT and aim_direction == 2) then
    -- right
    return 1.0
  elseif (but == ButtonAction.ACTION_SHOOTUP and aim_direction == 3) then
    -- up
    return 1.0
  elseif (but == ButtonAction.ACTION_SHOOTDOWN and aim_direction == 4) then
    -- down
    return 1.0
  end
  
end

function testMod:damage_taken(entity, damageamount, damageflag, damagesource)
  if (damagesource.Type == 2) then
    local t = damagesource.Entity
    tears2[damagesource.Entity.Index] = damagesource.Entity.Index
    if (tears[t.Index] ~= nil) then
      tears[t.Index]["hit"] = true
    end
  end
end


testMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, testMod.new_room_update)

testMod:AddCallback(ModCallbacks.MC_POST_RENDER, testMod.update_agent)

--testMod:AddCallback(ModCallbacks.MC_INPUT_ACTION, testMod.execute_movement, InputHook.GET_ACTION_VALUE)

testMod:AddCallback(ModCallbacks.MC_INPUT_ACTION, testMod.execute_shoot, InputHook.GET_MOUSE_POSITION)

testMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, testMod.damage_taken)


