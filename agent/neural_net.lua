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
  
  net:add(nn.SpatialConvolution(5,5,3,5,1,1,1,2))
  net:add(nn.ReLU(true))
  net:add(nn.SpatialConvolution(5,4,7,3,1,1,3,1))
  net:add(nn.ReLU(true))
  net:add(nn.SpatialConvolution(4,3,3,13,1,1,1,6))
  net:add(nn.ReLU(true))
  net:add(nn.View(405))
  net:add(nn.Linear(405, 45))

  
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
--    print("Average Error: " .. tostring(total_error2/examples2) .. " Error: " .. tostring(err))
  end
  
  return err
      
--  print("Predicted Output: " .. tostring(predicted_output))  
--  print("Actual Output: " .. tostring(actual_output))
--  print("Error: \n" .. tostring(err))
--  print("Rand Chance: " ..tostring(rand_test))

end

local function DivDown(numerator, denominator)
  return (numerator - (numerator % denominator)) / denominator
end

local function generate_cnn(maxDepth, maxKernelHeight, maxKernelWidth, maxSpatialConvolutions, maxLinearLayers, maxLayerNodes, startingDepth, startingHeight, startingWidth, outputNodes)
  
  local spatialConvolutions = math.random(maxSpatialConvolutions) - 1
  local linearLayers = math.random(maxLinearLayers) - 1
    
  local depth = startingDepth
  local nextDepth = math.random(maxDepth)
  local kernelWidth = math.random(maxKernelWidth)
  local kernelHeight = math.random(maxKernelHeight)
    
  j = 0
  
  while j < 1000 do
    local net = nn.Sequential()

    local s = 0
    local l = 0

    if spatialConvolutions > 0 then

      while s < spatialConvolutions do
        
        net:add(nn.SpatialConvolution(depth, nextDepth, kernelHeight, kernelWidth, 1, 1, DivDown(kernelHeight - 1, 2), DivDown(kernelWidth - 1, 2)))
--        net:add(nn.ReLU(true))
        if math.random(2) == 2 then
          net:add(nn.Sigmoid())
        end


        
        depth = nextDepth
        nextDepth = math.random(maxDepth)
        kernelWidth = math.random(maxKernelWidth)
        kernelHeight = math.random(maxKernelHeight)

  --      print(net)
        
        s = s + 1

      end
    end
    
    local sampleInput = torch.zeros(startingDepth,startingHeight,startingWidth)    
    
    if (pcall(function() net:forward(sampleInput) end)) then
      local sampleOutput = net:forward(sampleInput)
      local hiddenLayerNodes = sampleOutput:size()[1] * sampleOutput:size()[2] * sampleOutput:size()[3]
      net:add(nn.View(hiddenLayerNodes))
      
      if linearLayers > 0 then
        local nextLayerNodes = math.random(maxLayerNodes)
        
        while l < linearLayers do
          net:add(nn.Linear(hiddenLayerNodes, nextLayerNodes))
          
          if math.random(2) == 2 then
            net:add(nn.Sigmoid())
          end
          
--          net:add(nn.ReLU(true))
          
          hiddenLayerNodes = nextLayerNodes
          nextLayerNodes = math.random(maxLayerNodes)
          
    --      print(net)
          
          l = l + 1
          
        end
      end
      
      net:add(nn.Linear(hiddenLayerNodes, outputNodes))
      print(net)
      return net
    else
      print("Fail")
    end
    
    j = j + 1
    
    print(j)
    
  --  print(net)
  end
  
end



local function RandomOdd(max)
  return (2 * (math.random(DivDown(max,2)))) + 1
end



N.init_nn = init_nn
N.forward_prop = forward_prop
N.back_prop = back_prop
N.generate_cnn = generate_cnn

return N

