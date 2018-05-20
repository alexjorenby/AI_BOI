require 'torch'
require 'nn'

local N = {}


local function init_nn(depth, height, width)
  local net = nn.Sequential()
  
--  net:add(nn.Normalize(1))
--  net:add(nn.Linear(inputs, 1149, true))
--  net:add(nn.Sigmoid())
--  net:add(nn.Linear(1149, 419, true))
--  net:add(nn.Sigmoid())
--  net:add(nn.Linear(419, 1479, true))
-- net:add(nn.SoftMax())
--  net:add(nn.Linear(1479, outputs, true))
  
  net:add(nn.SpatialConvolution(4,5,3,3))
  net:add(nn.ReLU())
--  net:add(nn.SpatialMaxPooling(2,2,2,2))
  net:add(nn.SpatialConvolution(5,5,2,2))
  net:add(nn.ReLU())
  net:add(nn.SpatialConvolution(5,4,5,2))
  net:add(nn.ReLU())
  net:add(nn.SpatialConvolution(4,4,2,4))
--  net:add(nn.ReLU())
  net:add(nn.View(56))
  net:add(nn.Linear(56, 45))
--  net:add(nn.Linear(5,3))
  
  local criterion = nn.MSECriterion()
  return net, criterion
end


local function forward_prop(input, net, nth_best, random_percentage, override_action, outputs)
  local action = 0
  local action_table = {}
  if (override_action > 0) then
    local output = net:forward(input)
    return input, output, override_action
  else
    local output = net:forward(input)
    local max_reward = math.huge * -1
    for i=1,outputs do
      action_table[i] = {i, output[i]}
    end
    
    table.sort(action_table, function(a,b) return a[2] > b[2] end)
    
--    print("Picking the Nth best choice: " .. tostring(nth_best))      
    action = action_table[nth_best][1]
--    print("Action Predicted: " .. tostring(action))
    action = random_chance(action, action_table, random_percentage, nth_best, outputs)
--    print("Action Taken: " .. tostring(action))
    return input, output, action
  end
end


total_error = 0
examples = 0
total_error2 = 0
examples2 = 0


local function back_prop(input, predicted_output, actual_output, net, criterion, learning_rate, training)
  
  local err = criterion:forward(predicted_output, actual_output)
  net:zeroGradParameters()
  local gradOutput = criterion:backward(predicted_output, actual_output)
  net:backward(input, gradOutput)
  net:updateParameters(learning_rate)
    
  if (training == false) then
    total_error = total_error + err
    examples = examples + 1
--    print("Average Error: " .. tostring(total_error/examples) .. " Error: " .. tostring(err) )
  else
    total_error2 = total_error2 + err
    examples2 = examples2 + 1
    print("Average Error: " .. tostring(total_error2/examples2) .. " Error: " .. tostring(err))
  end
      
--  print("Predicted Output: " .. tostring(predicted_output))  
--  print("Actual Output: " .. tostring(actual_output))
--  print("Error: \n" .. tostring(err))
--  print("Rand Chance: " ..tostring(rand_test))

end


N.init_nn = init_nn
N.forward_prop = forward_prop
N.back_prop = back_prop

return N

