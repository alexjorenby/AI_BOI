local T = {}
local neural_net = require("neural_net")


function random_chance(action, action_table, odds, nb, outputs) 
  local nth_best = nb
  if (math.random(0,100) <= odds) then
    nth_best = math.random(1, outputs)
  end
--  print("Nth best from specific random chance: " .. tostring(nth_best))
  action = action_table[nth_best][1]
  return action
end


local function train_from_memory(net, criterion, iterations, learning_rate, batch_size, dataset_name, inputs, outputs, input, output)
  local chosen_dataset = ""
  local dir_size = 0
  
  for file in lfs.dir("../datasets") do
    dir_size = dir_size + 1
  end
  if dir_size >= 14 then
  
    local best = math.huge
    local best_dataset = nil
    local temp = 0
    local idx = 0
    for file in lfs.dir("../datasets") do
      if file:len() > 4 then
        x = torch.load('../datasets/' .. file)
        idx = math.random(0, #x-1)
        temp = math.abs(torch.sum(input[{{1,135}}] - x[idx].data[{{1,135}}]))
        if temp < best then
          best = temp
          best_dataset = x
        end
      end
    end
    
    local sub_best = math.huge
    local sub_best_dataset = nil
    local sub_temp = 0
    local sub_idx = 0    
    for i=0, # best_dataset do
      sub_temp = math.abs(torch.sum(input[{{1,135}}] - best_dataset[i].data[{{1,135}}]))
      if sub_temp < sub_best then
        sub_best = temp
        sub_best_dataset = best_dataset[i]
      end
    end
    
    local datasetInputs = torch.DoubleTensor(batch_size, inputs)
    local datasetOutputs = torch.DoubleTensor(batch_size, outputs)
    
    local inputO = sub_best_dataset.data
--    local output = best_dataset.labels
    local override_action = sub_best_dataset.action
    local passed_output = torch.Tensor(output:size()):copy(output)
    passed_output[override_action] = sub_best_dataset.labels[override_action]
    
    local input, predicted_output = neural_net.forward_prop(inputO, net, 1, 0, override_action, outputs)
--      print("predicted_output: \n" .. tostring(predicted_output))
--      print("output: \n" .. tostring(output))
--      print("action: " .. tostring(override_action))
    
    neural_net.back_prop(input, predicted_output, passed_output, net, criterion, learning_rate * 0.1, true)

    print("Done")
  end
end


local function train_from_datset(net, criterion, iterations, learning_rate, dataset_size, inputs, outputs, batch_size)
  local dataset = {}
  local dsn = 1
  local j = 0
  
  local dataset_count = 1
  
  for file in lfs.dir("../datasets") do
    if (# file >= 24) then
      local ds = torch.load("../datasets/" .. file)
      for i = 0, #ds do
        local input = ds[i].data
        local output = ds[i].labels
        local action = ds[i].action
        dataset[# dataset + 1] = { input, output, action }
      end
    end
  end
  if dataset_size > # dataset then
    dataset_size = # dataset
  end
  
  function dataset:size() return dataset_size end
  
  print("Dataset size: " .. tostring(dataset_size))
  
  local datasetInputs = torch.DoubleTensor(dataset_size, inputs)
  local datasetOutputs = torch.DoubleTensor(dataset_size, outputs)
  
  for iter = 1, iterations do
    for i = 1, dataset_size do
      local idx = math.random(1, # dataset)
      local inputO = dataset[idx][1]
      local output = dataset[idx][2]
      local override_action = dataset[idx][3]
      
      local input, predicted_output = neural_net.forward_prop(inputO, net, 1, 0, override_action, outputs)
--      print("predicted_output: \n" .. tostring(predicted_output))
--      print("output: \n" .. tostring(output))
--      print("action: " .. tostring(override_action))
      neural_net.back_prop(input, predicted_output, output, net, criterion, learning_rate, true)      
      
--      train_from_memory(net, criterion, iterations, learning_rate, batch_size, dataset_name, inputs, outputs)
      
      
    end
  end
  
  print("Dataset size: " .. tostring(dataset_size))
  
  torch.save("../models/model" .. tostring(os.date("%m-%d-%y;%H:%M")) .. ".th", net)

end


T.train_from_memory = train_from_memory
T.train_from_datset = train_from_datset

return T
