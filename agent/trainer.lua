local T = {}
local neural_net = require("neural_net")


function random_chance(action, action_table, odds, nb, outputs) 
  local nth_best = nb
  if (math.random(0,100) <= odds) then
    nth_best = math.random(1, outputs)
  end
  print("Nth best from specific random chance: " .. tostring(nth_best))
  action = action_table[nth_best][1]
  return action
end


local function train_from_datset(net, criterion, iterations, learning_rate, dataset_size, inputs, outputs)
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
      print("predicted_output: \n" .. tostring(predicted_output))
      print("output: \n" .. tostring(output))
      print("action: " .. tostring(override_action))
      
      neural_net.back_prop(input, predicted_output, output, net, criterion, learning_rate)
      
    end
  end
  
  print("Dataset size: " .. tostring(dataset_size))

end


local function train_from_memory(net, criterion, iterations, learning_rate, batch_size, dataset_name, inputs, outputs)
  local chosen_dataset = ""
  local dir_size = 0
  for file in lfs.dir("../datasets") do
    dir_size = dir_size + 1
  end
  if dir_size >= 4 then
    size_check = 0
    while ((chosen_dataset == "") or (("../datasets/" .. chosen_dataset) == dataset_name)) and (batch_size > size_check) do
      local temp = ""
      local x, y = lfs.dir("../datasets")
      local stop = math.random(1, dir_size)
      for i=1, stop do
        temp = x(y)
      end
      if # temp > 5 then
        chosen_dataset = temp
        local tempds = torch.load("../datasets/" .. chosen_dataset)
        size_check = #tempds
      end
    end
    local dataset = {}
    local ds = torch.load("../datasets/" .. chosen_dataset)
    if batch_size > #ds then
      batch_size = #ds
    end
    
    local datasetInputs = torch.DoubleTensor(batch_size, inputs)
    local datasetOutputs = torch.DoubleTensor(batch_size, outputs)
    local dataset_count = 1
    
    while dataset_count <= batch_size do
      local idx = math.random(1, #ds-1)      
      local inputO = ds[idx].data
      local output = ds[idx].labels
      local override_action = ds[idx].action

      local input, predicted_output = neural_net.forward_prop(inputO, net, 1, 0, override_action, outputs)
      print("predicted_output: \n" .. tostring(predicted_output))
      print("output: \n" .. tostring(output))
      print("action: " .. tostring(override_action))
      
      neural_net.back_prop(input, predicted_output, output, net, criterion, learning_rate)

      dataset_count = dataset_count + 1
    end    
    print("Done")
    
  end  
end


T.train_from_memory = train_from_memory
T.train_from_datset = train_from_datset

return T
