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


reset = 0


command = -1

init_action = 0
init_push = 0


wait = 100


custom_score = 0



local target = -1

-- Calls on room entry to update item retrieval timer. --
-- Lower time on already entered rooms so that we only --
-- pick up the "leftovers" from a first-traversal, and --
-- waste less time walking around.                     --
function testMod:new_room_update()
  reset = reset + 1

  game = Game()
  local level = game:GetLevel()
	local room_desc = level:GetCurrentRoomDesc()
  room = game:GetRoom()


  
  store_map = {}
  store_map_count = 0
  
  tears = {}
  tears2 = {}
	if (room_desc.VisitedCount > 1) then
		item_time = 150
	else
		item_time = 300
	end
--	update_strategy()

  local tt = Vector(0, -11)
  player:AddVelocity(tt)

  
  
  if (reset >= 2) then
    custom_score = custom_score + 50
    post_init_restart()
  end
  
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
  Isaac.RenderText("Reset: " .. tostring(reset), 50, 25, 255, 0, 255, 255)
  Isaac.RenderText("Init_action: " .. tostring(init_action), 300, 25, 255, 0, 255, 255)
  
  if (item_time < 0) then
    init_action = 0
    post_init_restart()
  end
  
  if (init_action < 5) then
    target = update_strategy()
  end
  
  
--  collector.collect_tears(tears, target)
	cartographer.render_map(test_map)
  
	operator.traverse_path(player, path)
  
  
  temp = Isaac.LoadModData(testMod)
  if (# temp < 5) then
    command = tonumber(temp)
  else
    command = command
  end
  			
end

function update_strategy()
  
  end_game = player:GetHearts() + player:GetSoulHearts() + player:GetBlackHearts() + player:GetEternalHearts() + player:GetExtraLives()
  
  
  if (end_game <= 0) then
--    post_init_restart()
  end
  
	D_map = {}  
  local collection = collector.find_entities()
--  local goal = cartographer.make_map(D_map, collection[1], collection[3], collection[2])
  
  test_map = {}
  cartographer.make_new_map(test_map, collection[1], collection[3], collection[2])
  
  
	local curr_node = room:GetGridIndex(player.Position)
  
  
  custom_score = custom_score - 2
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

  if (new_str ~= "") then
    str = new_str .. str
    Isaac.SaveModData(testMod, str)
  end
  
  
  
  
  if (room:IsClear()) then
    aim_direction = 0
  else
    return fighter.Shoot_Tear()
  end
  
  
  init_action = 10
  
    
end


function post_init_restart()
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
  end
end


testMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, testMod.new_room_update)

testMod:AddCallback(ModCallbacks.MC_POST_RENDER, testMod.update_agent)

testMod:AddCallback(ModCallbacks.MC_INPUT_ACTION, testMod.execute_movement, InputHook.GET_ACTION_VALUE)

testMod:AddCallback(ModCallbacks.MC_INPUT_ACTION, testMod.execute_shoot, InputHook.GET_MOUSE_POSITION)

testMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, testMod.damage_taken)


