require 'torch'
require 'nn'
require 'lfs'
require 'math'
require 'os'

local communicate = require("agent/communicate")
local NeuralNetwork = require("agent/neural_net")
local Queue = require("agent/queue")
local Trainer = require("agent/trainer")
local BlackBox = require("agent/blackbox")

local function main()
    
  blackBox = BlackBox(4, 9, 15, 9*15, 45, 9, 15)
  
  local action = 0
  
  local skip = 10
  
  while true do
    atrib = lfs.attributes("./save1.dat")
    new_file_size = atrib.size
    
    if (new_file_size > 10) then
      input, new_score = communicate.process_features(4, 15, 9)
      if input[1][1][1] == -1 then
        skip = 20
      end
      action = blackBox:Run(input, new_score, skip)
      communicate.update_cmd(action)
      atrib = lfs.attributes("./save1.dat")
      new_file_size = atrib.size
      skip = skip - 1
    end
  
  end

  return 1
  
end

main()


