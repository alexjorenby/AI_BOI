require 'torch'
require 'nn'
require 'lfs'
require 'math'

choices = {}


choices[0] = 0
choices[1] = 0
choices[2] = 0
choices[3] = 0
choices[4] = 0
choices[5] = 0
choices[6] = 0


rand_chance = 60

local function init_nn()
  local net = nn.Sequential()
  net:add(nn.Linear(136, 300))
  net:add(nn.Tanh())
  net:add(nn.Linear(300, 500))
  net:add(nn.Tanh())
  net:add(nn.Linear(500, 900))
  net:add(nn.Tanh())
  net:add(nn.Linear(900, 200))
  net:add(nn.Tanh())
  net:add(nn.Linear(200, 1))
  
  local criterion = nn.MSECriterion()
  
  
  local net2 = nn.Sequential()
  net2:add(nn.Linear(136, 300))
  net2:add(nn.Tanh())
  net2:add(nn.Linear(300, 500))
  net2:add(nn.Tanh())
  net2:add(nn.Linear(500, 900))
  net2:add(nn.Tanh())
  net2:add(nn.Linear(900, 200))
  net2:add(nn.Tanh())
  net2:add(nn.Linear(200, 135))
  
  local criterion2 = nn.MSECriterion()
  
  return net, criterion, net2, criterion2
  
end


function random_chance(action, odds)      
  if (math.random(0,100) <= odds) then
    action = math.random(0,6)
  end
  return action
end


local function forward_prop(input, net)
  local action = 0
  local max_reward = math.huge * -1
  for i=0,6 do
    input_action = i*10000
    input[136] = input_action
    output = net:forward(input)
    
    print("Output for action " .. tostring(i) .. ": " .. output[1])
    if (output[1] > max_reward) then
      action = i
      max_reward = output[1]
    end    
  end
  
  print("Action Predicted: " .. tostring(action))
  choices[action] = choices[action] + 1
  
  
  action = random_chance(action, rand_chance)
  input[136] = action * 10000
  
  print("Action Taken: " .. tostring(action))
  
  
  local output = net:forward(input)
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
  for i=1,135 do
    temp = tonumber(io.read())
    if (temp == 16) then
      temp = temp * 1000
    end
    if (temp > 16) then
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


local function predict_next_state(input, action, net2)
  input[136] = action
  local output = net2:forward(input)
  return input, output
end


local function main()
  local net, criterion, net2, criterion2 = init_nn()
  local atrib = lfs.attributes("save1.dat")
  local file_modified = atrib.size
  local iteration = 0
  local new_score = 0
  local previous_score = 0
  local discount = 1/2
  local a = 1
  
  while a==1 do
    atrib = lfs.attributes("save1.dat")
    local new_file_size = atrib.size
    if (new_file_size > 5) then
      local input, new_score = process_features(score, 136)
            
      input, predicted_reward, action = forward_prop(input, net)
      
      
      if (iteration > 0) then
        local observed_output = torch.Tensor({new_score - previous_score})
        local observed_reward = observed_output + discount * predicted_reward
        print("Observed_reward: " .. tostring(observed_reward))
        print("Action From Input: " .. tostring(input_buf[136]))
        back_prop(input_buf, predicted_reward_buf, observed_reward, net, criterion, 0.001)
--        update_data("./datasets/dataset1.t7", input, observed_output)


        print("\nEND OF SET\n")
--        local actual_output2, new_score2 = process_features(score, 135)
        
--        back_prop(input2, predicted_output2, actual_output2, net2, criterion2, 0.01)
        
        
      end

      input_buf = input
      predicted_reward_buf = predicted_reward
      previous_score = new_score
      
      
--      input2, predicted_output2 = predict_next_state(input_buf, action, net2)
      
      
      update_cmd(action)
      

      
      
      atrib = lfs.attributes("save1.dat")
      new_file_size = atrib.size
      file_modified = new_file_size
            
      print("Iteration: " .. tostring(iteration))
      print("\n\n")
            
      iteration = iteration + 1
      
      
      if (iteration >= 10800) then
        a = 2
      end
      
    end
  end  
  
  print(choices[0])
  print(choices[1])
  print(choices[2])
  print(choices[3])
  print(choices[4])
  print(choices[5])
  print(choices[6])
  
end



main()
