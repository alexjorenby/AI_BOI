StartDebug()

local testMod = RegisterMod("TestMod", 1)

require "math"


require("enum.constants")

--local pathfinder = require("scripts.planning.navigation")
local operator = require("scripts.actions.movement")
local fighter = require("scripts.actions.combat")
local cartographer = require("scripts.sensors.map")
--local helper = require("scripts.help")
--local sensor = require("scripts.planning.goal")
local collector = require("scripts.sensors.entities")

game = Game()
room = game:GetRoom()
tears = {}
tears2 = {}
item_time = 600
frame_counter = 0
test_map = {}
end_game = 1

command = -1

custom_score = 0



other_type = 0



local target = -1

-- Calls on room entry to update item retrieval timer. --
-- Lower time on already entered rooms so that we only --
-- pick up the "leftovers" from a first-traversal, and --
-- waste less time walking around.                     --
function testMod:new_room_update()
--  reset = reset + 1

  game = Game()
  local level = game:GetLevel()
	local room_desc = level:GetCurrentRoomDesc()
  room = game:GetRoom()

  tears = {}
  tears2 = {}
	if (room_desc.VisitedCount > 1) then
		item_time = 150
	else
		item_time = 300
	end

  custom_score = custom_score + 30
  
  
end


function testMod:update_agent()
	player = Isaac.GetPlayer(0)
  
	item_time = item_time - 1
	frame_counter = frame_counter + 1

--  local total_tears = 0
--  local tears_hit = 0
--  for ent, x in pairs(tears) do
--    total_tears = total_tears + 1
--    if (x["hit"]) then
--      tears_hit = tears_hit + 1
--    end
--  end

	Isaac.RenderText("ITEM TIME: " .. tostring(item_time), 200, 25, 255, 0, 255, 255)
--  Isaac.RenderText("PMV: " .. tostring(player_velocity.X) .. " - " .. tostring(player_velocity.Y), 50, 25, 255, 0, 255, 255)
  Isaac.RenderText("Command: " .. tostring(command), 300, 25, 255, 0, 255, 255)
  
  
  if (frame_counter % 20 == 0) then
    target = update_strategy()
  end
  
--  collector.collect_tears(tears, target)
	cartographer.render_map(test_map)
  
	operator.traverse_path(player, path)
  
  
  temp = Isaac.LoadModData(testMod)
  if (# temp < 8) then
    command = tonumber(temp)
  else
    command = command
  end
  			
end

curr_node = 0
last_node = 0

function update_strategy()
  
  end_game = player:GetHearts() + player:GetSoulHearts() + player:GetBlackHearts() + player:GetEternalHearts() + player:GetExtraLives()
  
  
  if (end_game <= 0 or item_time <= -5000) then
--    custom_score = 0
    post_init_restart()
  end
  
	D_map = {}  
  local collection = collector.find_entities()
  
  test_map = {}
  cartographer.make_new_map(test_map, collection[1], collection[3], collection[2])
  
	curr_node = room:GetGridIndex(player.Position)
  
  if (curr_node == last_node) then
    custom_score = custom_score - 10
  end
    
  last_node = curr_node
  
  local str = Isaac.LoadModData(testMod)
  local iterator = 0
  local square_count = 0
  local new_str = tostring(custom_score) .. "\n"

  while (iterator < 450 and square_count < 135) do
    if (test_map[iterator] ~= nil) then
      new_str = new_str .. tostring(test_map[iterator]) .. "\n"
      square_count = square_count + 1
    end
    iterator = iterator + 1
  end
  
  
  local player_velocity = player.Velocity
  new_str = new_str .. tostring(player_velocity.X) .. "\n"
  new_str = new_str .. tostring(player_velocity.Y) .. "\n"
  

  if (new_str ~= "") then
    str = new_str .. str
    Isaac.SaveModData(testMod, str)
  end

  if (room:IsClear()) then
--    custom_score = custom_score - 2
    aim_direction = 0
  else
--    custom_score = custom_score - 1
    return fighter.Shoot_Tear()
  end
  
  
    
end


function post_init_restart()
  custom_score = custom_score - 30
  init_action = 0
  reset = 0
  Isaac.ExecuteCommand("restart")
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
    custom_score = custom_score + 9
  end
  if (entity.Type == 1) then
    custom_score = custom_score - 15
  end
end


function testMod:entity_killed(entity)
  if (entity:isvulnerableEnemy()) then
    custom_score = custom_score + 15
  end
end



testMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, testMod.new_room_update)

testMod:AddCallback(ModCallbacks.MC_POST_RENDER, testMod.update_agent)

testMod:AddCallback(ModCallbacks.MC_INPUT_ACTION, testMod.execute_movement, InputHook.GET_ACTION_VALUE)

testMod:AddCallback(ModCallbacks.MC_INPUT_ACTION, testMod.execute_shoot, InputHook.GET_MOUSE_POSITION)

testMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, testMod.damage_taken)

testMod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, testMod.entity_killed)

