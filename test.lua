require 'torch'
require 'nn'
require 'lfs'
require 'math'


local function init_nn()
  net = nn.Sequential()
  net:add(nn.Linear(136, 300))
  net:add(nn.Tanh())
  net:add(nn.Linear(300, 500))
  net:add(nn.Tanh())
  net:add(nn.Linear(500, 900))
  net:add(nn.Tanh())
  net:add(nn.Linear(900, 200))
  net:add(nn.Tanh())
  net:add(nn.Linear(200, 1))
  
  criterion = nn.MSECriterion()
end


function random_chance(action, odds)      
  if (math.random(0,100) <= odds) then
    action = math.random(0,6)
  end
  return action
end


local function forward_prop(input)
  local action = 0
  local max_reward = math.huge * -1
  for i=0,6 do
    input[136] = i
    output = net:forward(input)
    
    print("Output for action " .. tostring(i) .. ": " .. output[1])
    if (output[1] > max_reward) then
      action = i
      max_reward = output[1]
    end    
  end
  
  action = random_chance(action, 40)
  input[136] = action
  
  
  local output = net:forward(input)
  return input, output, action
end


local function back_prop(input, predicted_output, actual_output)
  
  local err = criterion:forward(net:forward(input), actual_output)
  local gradOutput = criterion:backward(predicted_output, actual_output)
  net:zeroGradParameters()
  net:backward(input, gradOutput)
  net:updateParameters(0.001)
    
  print("Predicted Output: " .. tostring(predicted_output))  
  print("Actual Output: " .. tostring(actual_output[1]))
  print("Error: " .. tostring(err))
  print("Rand Chance: " ..tostring(rand_test))

end


local function process_features(previous_score)
  local file = io.open("save1.dat", "r")
  io.input(file)

  local score = tonumber(io.read())  
  local input_buf = torch.Tensor(136)
  local temp = 0
  for i=1,135 do
    temp = tonumber(io.read())
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
  if (f == nil) then
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


local function main()
  init_nn()
  local atrib = lfs.attributes("save1.dat")
  local file_modified = atrib.size
  local iteration = 0
  
  while 1==1 do
    atrib = lfs.attributes("save1.dat")
    local new_file_size = atrib.size
    if (new_file_size > 5) then
      local input_buf, new_score = process_features(score)
      
      if (iteration > 0) then
        local actual_output = torch.Tensor({new_score - previous_score})
        back_prop(input, predicted_output, actual_output)
        update_data("./datasets/dataset1.t7", input, actual_output)
      end
      previous_score = new_score
            
      input, predicted_output, action = forward_prop(input_buf)
      
      update_cmd(action)
      
      atrib = lfs.attributes("save1.dat")
      new_file_size = atrib.size
      file_modified = new_file_size
            
      print("Iteration: " .. tostring(iteration))
      print("\n\n")
            
      iteration = iteration + 1
      
    end
  end  
end



main()
