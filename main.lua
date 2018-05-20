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
local queue = require("agent.queue")
local action_history_queue = queue.new()

for i=1, 5 do
  queue.pushright(action_history_queue, -1)
end


game = Game()
level = game:GetLevel()
seed = game:GetSeeds()
room = game:GetRoom()
tears = {}
tears2 = {}
blood_tears = {}
item_time = 600
frame_counter = 0

room_map = {}
enemy_map = {}
item_map = {}
projectile_map = {}

end_game = 1
command = -1
custom_score = 0
distance_check = 0
pickup_table = {}
target_flag = 0
seedName = "ZX8Q WFES"
seed:SetStartSeed(seedName)

local seconds_passed = 0
local target = -1
local check = 10
local stage = -1
local new_stage = -1

local DamagePenalty = 0
local ExplorationBonus = 0
local SchwagBonus = 0
local PickupBonus = 0
local TimePenalty = 0
local ItemPenalty = 0
local HitsTaken = 0
local SecondsPenalty = 0
local BaseStagePenalty = 0
local RoomBonuses = 0
local BossTrapRoomsCleared = 0
local AngelStatuesFought = 0
local RushBonus  = 0
local MegaSatanBonus = 0 
local LambBonus = 0
local XXXBonus = 0
local StageBonus = 0
local EnemiesInTheRoom = 0

local clear_bonus = 0
local kill_bonus = 0
local game_score = 0

local countdown = 2
local start_countdown = 0


-- Calls on room entry to update item retrieval timer. --
-- Lower time on already entered rooms so that we only --
-- pick up the "leftovers" from a first-traversal, and --
-- waste less time walking around.                     --
function testMod:new_room_update()
  game = Game()
  level = game:GetLevel()
  new_stage = level:GetStage()
	local room_desc = level:GetCurrentRoomDesc()
  room = game:GetRoom()
  
  pickup_table = {}

  tears = {}
  tears2 = {}
  blood_tears = {}
	if (room_desc.VisitedCount > 1) then
		item_time = 150
	else
		item_time = 300
	end
  local room_type = room:GetType()
  if (room_desc.VisitedCount <= 1) then
    if (room_type == 1) then
      clear_bonus = 40
    elseif (room_type == 9) then
      clear_bonus = 100
    end
    RoomBonuses = RoomBonuses + 10
  end
  
  start_countdown = start_countdown + 1
  
end

function update_stage()
  local penalty = 0
  local bonus = 0
  
  if (new_stage == 1) then
    penalty = 60
    bonus = 500
  end
  if (new_stage == 2) then
    penalty = 60
    bonus = 1000 + 500
  end
  if (new_stage == 3) then
    penalty = 120
    bonus = 1500 + 1000
  end
  if (new_stage == 4) then
    penalty = 180
    bonus = 1500 + 1500
  end
  if (new_stage == 5) then
    penalty = 180
    bonus = 2500 + 1500
  end
  if (new_stage == 6) then
    penalty = 300
    bonus = 2500 + 2500
  end
  if (new_stage == 7) then
    penalty = 300
    bonus = 3000 + 2500
  end
  if (new_stage == 8) then
    penalty = 360
    bonus = 3000 + 3000
  end
  if (new_stage == 9) then
    penalty = 360
    bonus = 3000
  end
  if (new_stage == 10) then
    penalty = 0
    bonus = 3000 + 3000
  end
  
  BaseStagePenalty = BaseStagePenalty + penalty
  StageBonus = StageBonus + bonus
end

xxx = 1


function testMod:update_agent()
  
  player = Isaac.GetPlayer(0)
  
  if (frame_counter % 60 == 0) then
    seconds_passed = seconds_passed + 1
  end
  
  if clear_bonus > 0 and room:IsClear() then
    RoomBonuses = RoomBonuses + clear_bonus
    clear_bonus = 0
  end
  
  EnemiesInTheRoom = room:GetAliveEnemiesCount()  
  
  
  ExplorationBonus = RoomBonuses + 100 * (BossTrapRoomsCleared + 3 * AngelStatuesFought) + kill_bonus
    
    
  SchwagBonus = player:GetGoldenHearts() + 10 * (player:GetMaxHearts() + player:GetHearts() + player:GetSoulHearts() + player:GetBlackHearts() + player:GetEternalHearts() + player:GetNumCoins()) + 20 * (player:GetNumKeys() + player:GetNumBombs()) + PickupBonus
  
  DamagePenalty = math.ceil((1.0 - math.exp(HitsTaken * math.log(0.8) / 12)) * (ExplorationBonus * 0.8))
  
  SecondsPenalty = math.exp(((seconds_passed) * -0.22) / BaseStagePenalty)
  TimePenalty = math.floor(math.ceil(((RushBonus + MegaSatanBonus + LambBonus + XXXBonus + StageBonus) * 0.8) * (1.0 - SecondsPenalty)))
  
  game_score = ExplorationBonus + SchwagBonus + RushBonus + MegaSatanBonus + LambBonus + XXXBonus + StageBonus - DamagePenalty - SecondsPenalty - TimePenalty
  
    
  if (xxx == 1) then
    Isaac.ExecuteCommand("seed ZX8Q WFES")
--    Isaac.ExecuteCommand("restart")
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
    
  blood_tears = {}
  collector.collect_tears(tears, blood_tears)
    
  if (frame_counter % 15 == 0) then
    target = update_strategy()
  end 
  
  Isaac.RenderText("game_score: " .. tostring(game_score), 300, 300, 255, 0, 255, 255)
--  Isaac.RenderText("DamagePenalty: " .. tostring(DamagePenalty), 100, 250, 255, 0, 255, 255)
  Isaac.RenderText("Score: " .. tostring(game_score + custom_score), 200, 275, 255, 0, 255, 255)

  
	cartographer.render_map(room_map, enemy_map, item_map, projectile_map)
  
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
  
  queue.popleft(action_history_queue)
  queue.pushright(action_history_queue, command)
  
  end_game = player:GetHearts() + player:GetSoulHearts() + player:GetBlackHearts() + player:GetEternalHearts() + player:GetGoldenHearts() + player:GetExtraLives()
  
  if start_countdown == 3 then
    countdown = countdown - 1
  end
  
  if countdown == 0 then
--    post_init_restart()
  end
  
  if check >= 0 then
    check = check - 1
  end
  
  if stage ~= new_stage then
    update_stage()
    stage = new_stage
  end
  
	D_map = {}  
  local collection = collector.find_entities()
  local door_table = sensor.find_door(player, room)
--  local door_table = {-1,-1,-1,-1,-1,-1,-1,-1}
  
  room_map = {}
  enemy_map = {}
  item_map = {}
  projectile_map = {}
  cartographer.make_new_map(room_map, door_table, collection[1], collection[3], collection[2], blood_tears, enemy_map, item_map, projectile_map)
  
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
  
--  local door_prox = (chosen_door.Position - player.Position):Length()
--  if (room:IsClear()) then
--    custom_score = custom_score + (5 - (door_prox)/1000)
--  end
  
  local str = Isaac.LoadModData(testMod)
  local iterator = 0
  local square_count = 0
  
  custom_score = custom_score + (item_time / 10000)
  
  local new_str = tostring(game_score + (custom_score * 0.5)) .. "\n"

  while (iterator < 450 and square_count < 135) do
    if (end_game <= 0) then
      new_str = new_str .. tostring(-1) .. "\n"
    end
    if (room_map[iterator] ~= nil) then
      new_str = new_str .. tostring(room_map[iterator]) .. "\n"
      square_count = square_count + 1
    end
    iterator = iterator + 1
  end  
  
  iterator = 0
  square_count = 0

  
  while (iterator < 450 and square_count < 135) do
    if (end_game <= 0 or item_time <= -10000 or (command > 45 and check < 1)) then
      new_str = new_str .. tostring(-1) .. "\n"
    end
    if (enemy_map[iterator] ~= nil) then
      new_str = new_str .. tostring(enemy_map[iterator]) .. "\n"
      square_count = square_count + 1
    end
    iterator = iterator + 1
  end  
  
  iterator = 0
  square_count = 0  
  
  while (iterator < 450 and square_count < 135) do
    if (end_game <= 0) then
      new_str = new_str .. tostring(-1) .. "\n"
    end
    if (room_map[iterator] ~= nil) then
      new_str = new_str .. tostring(item_map[iterator]) .. "\n"
      square_count = square_count + 1
    end
    iterator = iterator + 1
  end  
  
  iterator = 0
  square_count = 0
  
  while (iterator < 450 and square_count < 135) do
    if (end_game <= 0) then
      new_str = new_str .. tostring(-1) .. "\n"
    end
    if (room_map[iterator] ~= nil) then
      new_str = new_str .. tostring(projectile_map[iterator]) .. "\n"
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
  
  new_str = new_str .. tostring(ExplorationBonus) .. "\n"
  new_str = new_str .. tostring(RushBonus) .. "\n"
  new_str = new_str .. tostring(MegaSatanBonus) .. "\n"
  new_str = new_str .. tostring(LambBonus) .. "\n"
  new_str = new_str .. tostring(XXXBonus) .. "\n"
  new_str = new_str .. tostring(StageBonus) .. "\n"
  new_str = new_str .. tostring(DamagePenalty) .. "\n"
  new_str = new_str .. tostring(SecondsPenalty) .. "\n"
  new_str = new_str .. tostring(TimePenalty) .. "\n"
  new_str = new_str .. tostring(EnemiesInTheRoom) .. "\n"
  new_str = new_str .. tostring(RoomBonuses) .. "\n"
  new_str = new_str .. tostring(kill_bonus) .. "\n"
  new_str = new_str .. tostring(HitsTaken) .. "\n"
  new_str = new_str .. tostring(seconds_passed) .. "\n"
  new_str = new_str .. tostring(BaseStagePenalty) .. "\n"
  new_str = new_str .. tostring(SchwagBonus) .. "\n"
  new_str = new_str .. tostring(PickupBonus) .. "\n"
  
  for i=1,8 do
    new_str = new_str .. tostring(door_table[i]) .. "\n"
  end
      
  for i=action_history_queue.first, action_history_queue.last do
    new_str = new_str .. tostring(action_history_queue[i]) .. "\n"
  end
    
  if (new_str ~= "") then
    str = new_str .. str
    Isaac.SaveModData(testMod, str)
  end
  
  if (end_game <= 0 or item_time <= -5000 or (command > 45 and check < 1)) then
    if command > 45 then
      custom_score = 0
      check = 10
    end
--    custom_score = 0
    post_init_restart()
  end
  

  if (room:IsClear()) then
--    aim_direction = 0
  else
    return targets[1][1]
  end
        
end


function post_init_restart()
  seconds_passed = 0
  target = -1
  check = 10
  stage = -1
  new_stage = -1
  countdown = 2
  start_countdown = 0

  DamagePenalty = 0
  ExplorationBonus = 0
  SchwagBonus = 0
  PickupBonus = 0
  TimePenalty = 0
  ItemPenalty = 0
  HitsTaken = 0
  SecondsPenalty = 0
  BaseStagePenalty = 0
  RoomBonuses = 0
  BossTrapRoomsCleared = 0
  AngelStatuesFought = 0
  RushBonus  = 0
  MegaSatanBonus = 0 
  LambBonus = 0
  XXXBonus = 0
  StageBonus = 0
  EnemiesInTheRoom = 0

  clear_bonus = 0
  kill_bonus = 0
  game_score = 0
  custom_score = 0


  init_action = 0
  reset = 0
  seed:SetStartSeed(seedName)
  xxx = 1
--  Isaac.ExecuteCommand("restart")
  Isaac.ExecuteCommand("seed ZX8Q WFES")
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
    
    HitsTaken = HitsTaken + damageamount
    
  end
end


function testMod:entity_killed(entity)
  if (entity:isvulnerableEnemy()) then
    custom_score = custom_score + 30
    
    kill_bonus = kill_bonus + math.floor(math.ceil((EnemiesInTheRoom+1)^0.2 * 5))
    
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

function testMod:pickup_update(Pickup, Variant, Subtype)
  local bonus = 0
  if (Variant == 1) then
    if (Subtype == 1 or Subtype == 3 or Subtype == 7) then
      bonus = 1
    elseif (Subtype == 4) then
      bonus = 4
    else
      bonus = 2
    end
  elseif (Variant == 2) then
    if (Subtype == 0) then
      bonus = 1
    elseif (Subtype == 1) then
      bonus = 5
    elseif (Subtype == 2) then
      bonus = 10
    elseif (Subtype == 3 or Subtype == 4) then
      bonus = 2
    else 
      bonus = 0
    end
  elseif (Variant == 3) then
    if (Subtype == 0) then
      bonus = 2
    elseif (Subtype == 1) then
      bonus = 35
    elseif (Subtype == 2) then
      bonus = 4
    else 
      bonus = 2
    end
  elseif (Variant == 4) then
    if (Subtype == 0) then
      bonus = 2
    elseif (Subtype == 1) then
      bonus = 4
    elseif (Subtype == 3) then
      bonus = 35
    else
      bonus = 0
    end
  elseif (Variant == 12) then
    bonus = 2
  else
    bonus = 0
  end
  PickupBonus = PickupBonus + bonus
end


testMod:AddCallback(ModCallbacks.MC_POST_NEW_ROOM, testMod.new_room_update)

testMod:AddCallback(ModCallbacks.MC_POST_RENDER, testMod.update_agent)

testMod:AddCallback(ModCallbacks.MC_INPUT_ACTION, testMod.execute_movement, InputHook.GET_ACTION_VALUE)

testMod:AddCallback(ModCallbacks.MC_INPUT_ACTION, testMod.execute_shoot, InputHook.GET_MOUSE_POSITION)

testMod:AddCallback(ModCallbacks.MC_ENTITY_TAKE_DMG, testMod.damage_taken)

testMod:AddCallback(ModCallbacks.MC_POST_ENTITY_KILL, testMod.entity_killed)

testMod:AddCallback(ModCallbacks.MC_POST_GET_COLLECTIBLE, testMod.collectable_pickup)

testMod:AddCallback(ModCallbacks.MC_PRE_PICKUP_COLLISION, testMod.pickup_collision)

testMod:AddCallback(ModCallback.MC_POST_PICKUP_SELECTION, testMod.pickup_update)
