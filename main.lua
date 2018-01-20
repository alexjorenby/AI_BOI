StartDebug()

local testMod = RegisterMod("TestMod", 1)

require "math"
require("enum.constants")
--local pathfinder = require("scripts.planning.navigation")
local operator = require("scripts.actions.movement")
local fighter = require("scripts.actions.combat")
local cartographer = require("scripts.sensors.map")
--local helper = require("scripts.helper")
local sensor = require("scripts.planning.goal")
local collector = require("scripts.sensors.entities")

game = Game()
seed = game:GetSeeds()
room = game:GetRoom()
tears = {}
tears2 = {}
item_time = 600
frame_counter = 0
room_map = {}
end_game = 1
command = -1
custom_score = 0
distance_check = 0
pickup_table = {}
target_flag = 0
seedName = "XT1S Y1ZM"
seed:SetStartSeed(seedName)
local target = -1

-- Calls on room entry to update item retrieval timer. --
-- Lower time on already entered rooms so that we only --
-- pick up the "leftovers" from a first-traversal, and --
-- waste less time walking around.                     --
function testMod:new_room_update()
  game = Game()
  local level = game:GetLevel()
	local room_desc = level:GetCurrentRoomDesc()
  room = game:GetRoom()
  
  pickup_table = {}

  tears = {}
  tears2 = {}
	if (room_desc.VisitedCount > 1) then
		item_time = 150
	else
		item_time = 300
	end
  custom_score = (custom_score + ((100)/room_desc.VisitedCount))
  
end

xxx = 1

function testMod:update_agent()
	player = Isaac.GetPlayer(0)
  
  if (xxx == 1) then
    Isaac.ExecuteCommand("seed ZX8Q WFES")
    xxx = 0
  end
  
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
  Isaac.RenderText("Custom Score: " .. tostring(custom_score), 50, 25, 255, 0, 255, 255)
    
  if (frame_counter % 15 == 0) then
    target = update_strategy()
  end 
  collector.collect_tears(tears)
  
--  Isaac.RenderText("Tears: " .. tostring(tears[1]), 300, 25, 255, 0, 255, 255)
  
	cartographer.render_map(room_map)
  
	operator.traverse_path(player, path)  
  
  temp = Isaac.LoadModData(testMod)
  if (# temp < 8 and tonumber(temp) ~= nil) then
    command = tonumber(temp)
  else
    command = command
  end
  			
end

curr_node = 0
last_node = 0
stationary_counter = 1
function update_strategy()
  
  end_game = player:GetHearts() + player:GetSoulHearts() + player:GetBlackHearts() + player:GetEternalHearts() + player:GetExtraLives()
    
  if (end_game <= 0 or item_time <= -10000) then
--    custom_score = 0
    post_init_restart()
  end
  
	D_map = {}  
  local collection = collector.find_entities()
  local chosen_door = sensor.find_door(player, room)
  
  room_map = {}
  cartographer.make_new_map(room_map, chosen_door, collection[1], collection[3], collection[2])
  
  local targets = fighter.Shoot_Tear(5)
  local sum_distance = 0
  local sum_count = 0
  for idx, ent in pairs(targets) do
    if ent == nil or ent[1] == nil then
      local f = 0
    else
      sum_distance = sum_distance + tonumber(ent[2])
      sum_count = sum_count + 1
    end
  end
  
  if (sum_count > 0) then
    distance_check = (3 - ((sum_distance/100) - 1.5*(1+(sum_count/5)))^2)
--    custom_score = custom_score + (3 - ((sum_distance/100) - 4*(1+(sum_count/5)))^2)
  end

	curr_node = room:GetGridIndex(player.Position)
  
  if (curr_node == last_node) then
    stationary_counter = stationary_counter + 1
    if (stationary_counter > 1) then
      if (room:IsClear()) then
        custom_score = custom_score - 1
      else
        custom_score = custom_score - 0.5
      end
    end
  else
    stationary_counter = 0
  end
    
  last_node = curr_node
  
  local door_prox = (chosen_door.Position - player.Position):Length()
  if (room:IsClear()) then
--    custom_score = custom_score + (5 - (door_prox)/1000)
  end
  
  local str = Isaac.LoadModData(testMod)
  local iterator = 0
  local square_count = 0
  
  custom_score = custom_score + (item_time / 10000)
  
  local new_str = tostring(custom_score) .. "\n"

  while (iterator < 450 and square_count < 135) do
    if (room_map[iterator] ~= nil) then
      new_str = new_str .. tostring(room_map[iterator]) .. "\n"
      square_count = square_count + 1
    end
    iterator = iterator + 1
  end  
  
  local player_velocity = player.Velocity
  new_str = new_str .. tostring(player_velocity.X) .. "\n"
  new_str = new_str .. tostring(player_velocity.Y) .. "\n"
  new_str = new_str .. tostring(player.Position.X) .. "\n"
  new_str = new_str .. tostring(player.Position.Y) .. "\n"
--  new_str = new_str .. tostring(door_prox) .. "\n"
--  new_str = new_str .. tostring(room:GetType()) .. "\n"
--  new_str = new_str .. tostring(room:GetRoomShape()) .. "\n"
  new_str = new_str .. tostring(item_time) .. "\n"
  new_str = new_str .. tostring(curr_node) .. "\n"
  new_str = new_str .. tostring(last_node) .. "\n"
  
  local target_count = 0
  for idx, ent in pairs(targets) do
    target_flag = ent[1]
    if ent == nil or ent[1] == nil then
      new_str = new_str .. tostring(-1) .. "\n"
    else
      new_str = new_str .. tostring(ent[2]) .. "\n"
    end
    target_count = target_count + 1
  end
  
  while target_count < 5 do
    new_str = new_str .. tostring(-1)
  end
  
  local proj_count = 0
  for ent, x in pairs(tears) do
    local check = true
    for a, b in pairs(x) do
      if b == nil then
        check = false
      end
    end
    if proj_count <= 5 and check then      
      new_str = new_str .. tostring(x["p_tear_fall_accel"]) .. "\n" .. tostring(x["p_tear_fall_speed"]) .. "\n" .. tostring(x["p_tear_flags"]) .. "\n" .. tostring(x["p_tear_height"]) .. "\n" .. tostring(x["p_homing_strength"]) .. "\n" .. tostring(x["p_acceleration"]) .. "\n" .. tostring(x["p_position"].X) .. "\n" .. tostring(x["p_position"].Y) .. "\n" .. tostring(x["p_velocity"].X) .. "\n" .. tostring(x["p_velocity"].Y) .. "\n"

      proj_count = proj_count + 1
    end
  end
  
  while proj_count <= 5 do
    new_str = new_str .. "0\n0\n0\n0\n0\n0\n0\n0\n0\n0\n"
    proj_count = proj_count + 1
  end
  
  if (new_str ~= "") then
    str = new_str .. str
    Isaac.SaveModData(testMod, str)
  end

  if (room:IsClear()) then
    aim_direction = 0
  else
    return targets[1][1]
  end
    
end


function post_init_restart()
  custom_score = custom_score - 200
  init_action = 0
  reset = 0
  seed:SetStartSeed(seedName)
  xxx = 1
--  Isaac.ExecuteCommand("restart")
  Isaac.ExecuteCommand("seed XT1S Y1ZM")
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
--    tears2[damagesource.Entity.Index] = damagesource.Entity.Index
--    if (tears[t.Index] ~= nil) then
--      tears[t.Index]["hit"] = true
--    end
    custom_score = custom_score + 36
  end
  if (entity.Type == 1) then
    custom_score = custom_score - 30
  end
end


function testMod:entity_killed(entity)
  if (entity:isvulnerableEnemy()) then
    custom_score = custom_score + 30
  end
end

function testMod:collectable_pickup(SelectedCollectible, PoolType, Decrease, Seed)
  custom_score = custom_score + 200
end

function testMod:pickup_collision(Pickup, Collider, Low)
  if pickup_table[Pickup.Index] == nil then
    custom_score = custom_score + 20
  end
  pickup_table[Pickup.Index] = Pickup.Index
end



testMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, testMod.new_room_update)

testMod:AddCallback(ModCallbacks.MC_POST_RENDER, testMod.update_agent)

testMod:AddCallback(ModCallbacks.MC_INPUT_ACTION, testMod.execute_movement, InputHook.GET_ACTION_VALUE)

testMod:AddCallback(ModCallbacks.MC_INPUT_ACTION, testMod.execute_shoot, InputHook.GET_MOUSE_POSITION)

testMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, testMod.damage_taken)

testMod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, testMod.entity_killed)

testMod:AddCallback(ModCallbacks.MC_POST_GET_COLLECTIBLE, testMod.collectable_pickup)

testMod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, testMod.pickup_collision)

