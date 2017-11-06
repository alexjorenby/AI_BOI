require "math"

local M = {}

local function move_left(player)
  left = true
end
	
local function move_right(player)
  right = true
end
	
local function move_up(player)
  up = true
end

local function move_down(player)
  down = true
end
		
local function move_up_right(player)	
  up = true
  right = true
end
	
local function move_up_left(player)	
  up = true
  left = true
end
	
local function move_down_right(player)	
  down = true
  right = true
end
	
local function move_down_left(player)	
  down = true
  left = true
end	

local function push_player(player, choice_direc)
  left = false
  right = false
  up = false
  down = false
	if (choice_direc == "upright") then
		move_up_right(player)
	elseif (choice_direc == "upleft") then
		move_up_left(player)
	elseif (choice_direc == "downright") then
		move_down_right(player)
	elseif (choice_direc == "downleft") then
		move_down_left(player)			
	elseif (choice_direc == "left") then
		move_left(player)
	elseif (choice_direc == "down") then
		move_down(player)
	elseif (choice_direc == "right") then
		move_right(player)
	elseif (choice_direc == "up") then
		move_up(player)
	else
		direction = "none"			
	end
end

function traverse_path(player, path)
  
  local player_pos = player.Position
	local result = ""
	local onX = false
	local onY = false
	local acc = 9

  if (command == 0) then
		result = "up"
  elseif (command == 1) then
		result = "down"
  elseif (command == 2) then
    result = "right"
  elseif (command == 3) then
    result = "left"
  elseif (command == 4) then
    result = "upright"
  elseif (command == 5) then
    result = "upleft"
  elseif (command == 5) then
    result = "downright"
  elseif (command == 6) then
    result = "downleft"
  end

  push_player(player, result)
  
end



M.traverse_path = traverse_path







return M