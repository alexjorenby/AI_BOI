require 'torch'
require 'nn'
require 'lfs'
require 'math'
require 'os'


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


local function forward_prop(input, net, random_percentage)
  
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
  action = random_chance(action, random_percentage)
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
    if (temp == 0 and i <=136) then
      temp = -100
    end
    input_buf[i] = temp
  end
  io.close(file)
  
  return input_buf, score
end


local function update_cmd(command)
  local cmd_file = io.open("save1.dat", "w+")
  cmd_file.write(cmd_file, tostring(command))
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


local function train_from_datset(net, criterion, iterations, learning_rate, dataset_size)
  local dataset = {}
  local dsn = 1
  local j = 0
  
  local data_offset = 0
  for file in lfs.dir("./datasets") do
    if (# file >= 24) then
      local ds = torch.load("./datasets/" .. file)
      for i = 0, #ds do
        local input = ds[i].data
        local output = ds[i].labels
        dataset[# dataset + 1] = { input, output }
      end
      data_offset = data_offset + # dataset
    end
  end
  if dataset_size > # dataset then
    dataset_size = # dataset
  end
  function dataset:size() return dataset_size end
    
  if (dataset:size() >= 1) then
    local trainer = nn.StochasticGradient(net, criterion)
    trainer.learningRate = learning_rate
    trainer.maxIteration = iterations
    trainer.shuffleIndices = true
    trainer:train(dataset)
  end
  
end


local function train_from_memory(net, criterion, iterations, learning_rate, batch_size)
  local chosen_dataset = ""
  local dir_size = 0
  for file in lfs.dir("./datasets") do
    dir_size = dir_size + 1
  end
  if dir_size >= 3 then
    while chosen_dataset == "" do
      local temp = ""
      local x, y = lfs.dir("./datasets")
      local stop = math.random(1, dir_size)
      for i=1, stop do
        temp = x(y)
      end
      if # temp > 5 then
        chosen_dataset = temp
      end
    end
    
    local dataset = {}
    local ds = torch.load("./datasets/" .. chosen_dataset)
    if batch_size > #ds then
      batch_size = #ds
    end
    while # dataset < batch_size do
      local idx = math.random(1, #ds-1)
      local input = ds[idx].data
      local output = ds[idx].labels
      dataset[# dataset + 1] = { input, output }
    end
    
    function dataset:size() return # dataset end
      
    if (dataset:size() >= 1) then
      local trainer = nn.StochasticGradient(net, criterion)
      trainer.learningRate = learning_rate
      trainer.maxIteration = iterations
      trainer.shuffleIndices = true
      trainer:train(dataset)
    end
  end  
end


local function prompt_user()
  local confirm = 'n'
  local dataset_size = -1
  local train_iter = -1
  local train_learning_rate = -1
  local max_iter = -1
  local discount_factor = -1
  local learning_rate = -1
  local random_percentage = 0
  local batch_size = 0
  local train = 'n'
  local store_data = 'n'
  local default_flag = 'n'
  
  print("Default setup? (y/n)")
  default_flag = io.read()
  if default_flag == 'y' then
    max_iter = math.huge
    train = 'y'
    discount_factor = 0.5
    learning_rate = 0.01
    store_data = 'y'
    dataset_size = math.huge
    train_iter = 10
    train_learning_rate = 0.001
    random_percentage = 10
    batch_size = 10
    confirm = 'y'
  end

  while confirm ~= 'y' do
    dataset_size = -1
    train_iter = -1
    train_learning_rate = -1
    
    print("Train from dataset? (y/n)")
    train = io.read()
    
    if (train == 'y') then
      print("Training iterations")
      train_iter = tonumber(io.read())
      if (train_iter == nil) then error("Invalid entry") end
      
      print("Learning rate for training")
      train_learning_rate = tonumber(io.read())
      if (train_learning_rate == nil) then error("Invalid entry") end
      
      print("Size of dataset")
      dataset_size = tonumber(io.read())
      if (dataset_size == nil) then error("Invalid entry") end
    end
    
    print("Store new data from this experience? (y/n)")
    store_data = io.read()
    
    print("Number of iterations")
    max_iter = tonumber(io.read())
    if (max_iter == nil) then error("Invalid entry") end
  
    print("Learning rate")
    learning_rate = tonumber(io.read())
    if (learning_rate == nil) then error("Invalid entry") end
    
    print("Random action percentage (integer)")
    random_percentage = tonumber(io.read())
    if (random_percentage == nil) then error("Invalid entry") end
    
    print("Discount percentage for future reward")
    discount_factor = tonumber(io.read())
    if (discount_factor == nil) then error("Invalid entry") end
    
    print("Memory batch size (integer)")
    batch_size = tonumber(io.read())
    if (batch_size == nil) then error("Invalid entry") end

    print("\nTrain: " .. tostring(train == 'y'))
    print("Training Iterations: " .. tostring(train_iter ~= -1 and train_iter or "None"))
    print("Training Learning Rate: " .. tostring(train_learning_rate ~= -1 and train_learning_rate or "None"))
    print("Dataset Size: " .. tostring(dataset_size ~= -1 and dataset_size or "None"))
    print("Store Data: " .. tostring(store_data == 'y'))
    print("Iterations: " .. tostring(max_iter))
    print("Learning Rate: " .. tostring(learning_rate))
    print("Random Chance: " .. tostring(random_percentage))
    print("Discount Factor: " .. tostring(discount_factor))
    print("Batch Size: " .. tostring(batch_size))
    print("\nConfirm? (y/n)")
    confirm = io.read()
  end
  return max_iter, train=='y', train_iter, train_learning_rate, dataset_size, store_data=='y', discount_factor, learning_rate, random_percentage, batch_size
end


local function main()
  local num_features = 145
  local net, criterion = init_nn(num_features, 8)
  local atrib = lfs.attributes("save1.dat")
  local file_modified = atrib.size
  local iteration = 0
  local new_score = 0
  local previous_score = 0
  local discount = 1/2  
  local random_percentage = 0
  
  max_iter, train, train_iter, train_learning_rate, dataset_size, store_data, discount, learning_rate, random_percentage, batch_size = prompt_user()
  local dataset_name = "./datasets/dataset" .. tostring(os.date("%m-%d-%y;%H:%M")) .. ".t7"
  
  if train then
    train_from_datset(net, criterion, train_iter, train_learning_rate, dataset_size)
  end
  
  while iteration <= max_iter do
    atrib = lfs.attributes("save1.dat")
    local new_file_size = atrib.size
    if (new_file_size > 5) then
      local input, new_score = process_features(score, num_features)
            
      input, predicted_output, action = forward_prop(input, net, random_percentage)
      
      if (iteration > 0) then
        local observed_output = torch.Tensor(previous_predicted_output:size()):copy(previous_predicted_output)
        observed_output[previous_action] = (new_score - previous_score) + discount * predicted_output[action]
        print("Predicted reward: \n" .. tostring(previous_predicted_output))
        print("Action From Input: " .. tostring(previous_action))
        back_prop(previous_input, previous_predicted_output, observed_output, net, criterion, learning_rate)
        if store_data then
          update_data(dataset_name, input, observed_output)
          if (iteration % 200 == 0) then
            dataset_name = "./datasets/dataset" .. tostring(os.date("%m-%d-%y;%H:%M")) .. ".t7"
          end
        end

        print("\nEND OF SET\n")
                
      end

      previous_input = input
      previous_action = action
      previous_predicted_output = predicted_output
      previous_score = new_score
      
      update_cmd(action)
      
      atrib = lfs.attributes("save1.dat")
      new_file_size = atrib.size
      file_modified = new_file_size
 
 
      train_from_memory(net, criterion, 1, learning_rate * (0.1), batch_size)
      
            
      print("Iteration: " .. tostring(iteration))
      print("\n\n")
            
      iteration = iteration + 1
            
    end
  end  
    
end



main()
