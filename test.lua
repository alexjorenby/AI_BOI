require 'torch'
require 'nn'
require 'lfs'
require 'math'
require 'os'


rand_chance = 10

local function init_nn(inputs, outputs)
  local net = nn.Sequential()
  net:add(nn.Linear(inputs, 300))
  net:add(nn.Tanh())
  net:add(nn.Linear(300, 500))
  net:add(nn.Tanh())
  net:add(nn.Linear(500, 900))
  net:add(nn.Tanh())
  net:add(nn.Linear(900, 200))
  net:add(nn.Tanh())
  net:add(nn.Linear(200, outputs))
  
  local criterion = nn.MSECriterion()
  return net, criterion
end


function random_chance(action, odds)      
  if (math.random(0,100) <= odds) then
    action = math.random(1,8)
  end
  return action
end


local function forward_prop(input, net)
  
  output = net:forward(input)
  local max_reward = math.huge * -1
  local action = 0
  for i=1,8 do
    if (output[i] > max_reward) then
      action = i
      max_reward = output[i]
    end
  end
  
  print("Action Predicted: " .. tostring(action))
  action = random_chance(action, rand_chance)
  print("Action Taken: " .. tostring(action))
    
  return input, output, action
end


local function back_prop(input, predicted_output, actual_output, net, criterion, learning_rate)
  
  local err = criterion:forward(net:forward(input), actual_output)
  local gradOutput = criterion:backward(predicted_output, actual_output)
  net:zeroGradParameters()
  net:backward(input, gradOutput)
  net:updateParameters(learning_rate)
    
--  print("Predicted Output: " .. tostring(predicted_output))  
--  print("Actual Output: " .. tostring(actual_output))
  print("Error: \n" .. tostring(err))
--  print("Rand Chance: " ..tostring(rand_test))

end


local function process_features(previous_score, num_features)
  local file = io.open("save1.dat", "r")
  io.input(file)

  local score = tonumber(io.read())  
  local input_buf = torch.Tensor(num_features)
  local temp = 0
  for i=1,num_features do
    temp = tonumber(io.read())
    if (temp == 16) then
      temp = temp * 1000
    end
    if (temp > 16 or i >= 136) then
      temp = temp * 10
    end
    input_buf[i] = temp
  end
  io.close(file)
  
  return input_buf, score
end


local function update_cmd(direction)
  local cmd_file = io.open("save1.dat", "w+")
  cmd_file.write(cmd_file, tostring(direction))
  cmd_file.close()
end


local function update_data(file_name, input, output)
  local f = io.open(file_name, "r")
  if (f == nil or f.read(f) == "") then
    f = io.open(file_name, "w")
    local dataset = {}
    dataset[0] = { data = input, labels = output }
    torch.save(file_name, dataset)
  else
    saved_dataset = torch.load(file_name)
    saved_dataset[#saved_dataset+1] = { data = input, labels = output }
    torch.save(file_name, saved_dataset)
  end
  f.close(f)
end


local function train_from_datset(net, criterion, iterations, learning_rate)
  local dataset = {}
  local dsn = 1
  local j = 0
  
  local dataset_size = 0
  for file in lfs.dir("./datasets") do
    if (# file >= 24) then
      local ds = torch.load("./datasets/" .. file)
      for i=0, #ds do
        local input = ds[i].data
        local output = ds[i].labels
        dataset[i+dataset_size] = { input, output }
      end
      dataset_size = # dataset
    end
    
  end
  function dataset:size() return # dataset end

  print("Datset size: " .. dataset:size())
  if (dataset:size() >= 1) then
    local trainer = nn.StochasticGradient(net, criterion)
    trainer.learningRate = learning_rate
    trainer.maxIteration = iterations
    trainer:train(dataset)
  end
  
end


local function main()
  local num_features = 137
  local net, criterion = init_nn(num_features, 8)
  local atrib = lfs.attributes("save1.dat")
  local file_modified = atrib.size
  local iteration = 0
  local new_score = 0
  local previous_score = 0
  local discount = 1/2
  local a = 1
  local dataset_name = "./datasets/dataset" .. tostring(os.date("%m-%d-%y;%H:%M")) .. ".t7"
  
  train_from_datset(net, criterion, 10, 0.001)
  
  while a==1 do
    atrib = lfs.attributes("save1.dat")
    local new_file_size = atrib.size
    if (new_file_size > 5) then
      local input, new_score = process_features(score, num_features)
            
      input, predicted_output, action = forward_prop(input, net)
      
      if (iteration > 0) then
        local observed_output = torch.Tensor(previous_predicted_output:size()):copy(previous_predicted_output)
        observed_output[previous_action] = (new_score - previous_score) + discount * predicted_output[previous_action]
        print("Observed_reward: " .. tostring(observed_output))
        print("Action From Input: " .. tostring(previous_action))
        back_prop(previous_input, previous_predicted_output, observed_output, net, criterion, 0.01)
        update_data(dataset_name, input, observed_output)

        print("\nEND OF SET\n")
        
        if (iteration % 200 == 0) then
          dataset_name = "./datasets/dataset" .. tostring(os.date("%m-%d-%y;%H:%M")) .. ".t7"
        end
        
      end

      previous_input = input
      previous_action = action
      previous_predicted_output = predicted_output
      previous_score = new_score
      
      update_cmd(action)
      
      atrib = lfs.attributes("save1.dat")
      new_file_size = atrib.size
      file_modified = new_file_size
            
      print("Iteration: " .. tostring(iteration))
      print("\n\n")
            
      iteration = iteration + 1
      
--      if (iteration >= 10800*3) then
--        a = 2
--      end
      
    end
  end  
    
end



main()
