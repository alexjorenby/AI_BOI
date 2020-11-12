StartDebug()

local testMod = RegisterMod("TestMod", 1)

require "math"
local RefreshRate = 15
frame_counter = 0
aim_direction = -1
move_direction = -1
temp = "false"
-- seedName = "ZX8Q WFES"
-- seed:SetStartSeed(seedName)


-- function post_init_restart()
--   seed:SetStartSeed(seedName)
--   xxx = 1
--  Isaac.ExecuteCommand("restart")
--   Isaac.ExecuteCommand("seed ZX8Q WFES")
-- end


function testMod:update_agent()
  player = Isaac.GetPlayer(0)
  frame_counter = frame_counter + 1
  Isaac.RenderText("Frame Counter: " .. tostring(frame_counter), 200, 25, 255, 0, 255, 255)
  if (frame_counter % RefreshRate == 0) then
    update_strategy()
  end 
end


function update_strategy()
  temp = Isaac.LoadModData(testMod)
  aim_direction = tonumber(string.sub(temp,1,2))
  move_direction = tonumber(string.sub(temp,3))

  up = false
  right = false
  down = false
  left = false
  stopped = false
  if (move_direction == 1) then
    up = true
  elseif (move_direction == 2) then
    right = true
  elseif (move_direction == 3) then
    down = true
  elseif (move_direction == 4) then
    left = true
  elseif (move_direction == 5) then
    up = true
	right = true
  elseif (move_direction == 6) then
    right = true
	down = true
  elseif (move_direction == 7) then
	down = true
	left = true
  elseif (move_direction == 8) then
    left = true
	up = true
  else
    stopped = true
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



testMod:AddCallback(ModCallbacks.MC_POST_RENDER, testMod.update_agent)

testMod:AddCallback(ModCallbacks.MC_INPUT_ACTION, testMod.execute_movement, InputHook.GET_ACTION_VALUE)

testMod:AddCallback(ModCallbacks.MC_INPUT_ACTION, testMod.execute_shoot, InputHook.GET_MOUSE_POSITION)
