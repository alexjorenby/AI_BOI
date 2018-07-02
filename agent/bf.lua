require 'torch'
require 'nn'
require 'lfs'
require 'math'
require 'os'
require 'optim'

local neural_net = require("neural_net")
local trainer = require("trainer")


local maxDepth = 10
local maxKernelHeight = 9
local maxKernelWidth = 15
local maxSpatialConvolutions = 15
local maxLinearLayers = 7
local maxLayerNodes = 500
local startingDepth = 5
local startingHeight = 9
local startingWidth = 15
local outputNodes = 45

local criterion = nn.MSECriterion()
local train_iter = 5
local train_learning_rate = 0.000001
local dataset_size = math.huge
local num_features = 135 -- 9 * 15
local num_outputs = 45


local f = 0

--local masterNet = nn.Sequential()
  
--net:add(nn.Normalize(1))
--net:add(nn.Linear(5, 1149, true))
--net:add(nn.Linear(1149, 419, true))
--net:add(nn.Linear(419, 1479, true))
--net:add(nn.Linear(1479, 5, true))

while true do
  local net = neural_net.generate_cnn(maxDepth, maxKernelHeight, maxKernelWidth, maxSpatialConvolutions, maxLinearLayers, maxLayerNodes, startingDepth, startingHeight, startingWidth, outputNodes)
  
  local str = tostring(net) .. "\n"
  str = str .. tostring(os.date("%m-%d-%y;%H:%M")) .."\n"
  local the_file = io.open("../result.txt", "a+")
  the_file.write(the_file, str .. "first\n")
  the_file.close()
  
  if f > 0 then
    trainer.train_from_datset(net, criterion, train_iter, train_learning_rate, dataset_size, num_features, num_outputs, 0)
    
    str = tostring(total_error2/examples2) .. "\n"
    str = str .. tostring(os.date("%m-%d-%y;%H:%M")) .."\n\n\n\n"
    
    the_file = io.open("../result.txt", "a+")
    the_file.write(the_file, str)
    the_file.close()
  end
  
  f = f + 1
  
end









function old()

  local num_features = 577
  local num_outputs = 9
  local dataset_size = 50000000000
  local train_iter = 10
  local train_learning_rate = 0.01


  while true do

    local net = nn.Sequential()
    net:add(nn.Normalize(1))

    local r = math.random(9, 2500)

    net:add(nn.Linear(num_features, r, true))

    local hidden_layers = math.random(0,15)
    local temp = 0

    local str = tostring(hidden_layers+1) .. ", " .. tostring(r) .. ", "
    print(tostring(hidden_layers))
    print(tostring(r))

    for i=1, hidden_layers do
      temp = math.random(9, 2000)
      str = str .. ", " .. tostring(temp)
      print(temp)
      net:add(nn.Linear(r, temp, true))
      r = temp
    end

    net:add(nn.Sigmoid())
    net:add(nn.Linear(r, num_outputs, true))

    local criterion = nn.MSECriterion()

    trainer.train_from_datset(net, criterion, train_iter, train_learning_rate, dataset_size, num_features, num_outputs, 0)

    str = str .. ", " .. tostring(aver) .. " Time: " .. tostring(os.date("%m-%d-%y;%H:%M")) .."\n\n"
    local the_file = io.open("../result.txt", "a+")
    the_file.write(the_file, str)
    the_file.close()
      
  end
end



