local T = {}
local neural_net = require("./neural_net")

local DatasetDirectory = "./datasets"

function random_chance(action, action_table, odds, nb, outputs) 
  if (math.random(0,100) <= odds) then
    nb = math.random(1, outputs)
  end
  action = action_table[nb][1]
  return action
end


local function train_from_memory(net, criterion, iterations, learning_rate, batch_size, dataset_name, num_features, num_outputs, input, output)
  local chosen_dataset = ""
  local dir_size = 0
  
  for file in lfs.dir(DatasetDirectory) do
    dir_size = dir_size + 1
  end
  if dir_size >= 15 then
      
    local datasets = {}
    
    for file in lfs.dir(DatasetDirectory) do
      if file:len() > 4 then
        datasets[#datasets+1] = file
      end
    end
    
    table.sort(datasets, function(a,b) return a > b end)
    
    local Dataset = torch.load(DatasetDirectory .. "/" .. datasets[math.random(1,12)])
    
    local best_dataset = Dataset[math.random(0,#Dataset-1)]
    
    if (best_dataset ~= nil) then
          
      local datasetInputs = torch.DoubleTensor(batch_size, num_features)
      local datasetOutputs = torch.DoubleTensor(batch_size, num_outputs)
      
      local inputO = best_dataset.data
      local override_action = best_dataset.action
      local passed_output = torch.Tensor(output:size()):copy(output)
      passed_output[override_action] = best_dataset.labels[override_action]
      
      local input, predicted_output = neural_net.forward_prop(inputO, net, 1, 0, override_action, outputs)
      
      neural_net.back_prop(input, predicted_output, passed_output, net, criterion, learning_rate, true)

    else
--      print("Skipped training from memory, nil error")
    end

  end
end


local function train_from_datset(net, criterion, iterations, learning_rate, dataset_size, inputs, outputs, batch_size)
  local dataset = {}
  local dsn = 1
  local j = 0
    
  local dataset_count = 1
  
  for file in lfs.dir(DatasetDirectory) do
    if (# file >= 24) then
      local ds = torch.load(DatasetDirectory .. "/" .. file)
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
            
      local reward = output[override_action]
      local modified_output = torch.Tensor(predicted_output:size()):copy(predicted_output)
      modified_output[override_action] = reward
      
      neural_net.back_prop(input, predicted_output, modified_output, net, criterion, learning_rate, true)      
         
      print(i)
    end
  end
  
  print("Dataset size: " .. tostring(dataset_size))
  
  torch.save("./models/model" .. tostring(os.date("%m-%d-%y;%H:%M")) .. ".th", net)

end


T.train_from_memory = train_from_memory
T.train_from_datset = train_from_datset

return T
