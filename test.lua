require 'torch'
require 'nn'
require 'lfs'
require 'math'

rand_cap = -25

local function init_nn()
  net = nn.Sequential()
  net:add(nn.Linear(137, 900))
  net:add(nn.Tanh())
  net:add(nn.Linear(900, 800))
  net:add(nn.Tanh())
  net:add(nn.Linear(800, 1000))
  net:add(nn.Tanh())
  net:add(nn.Linear(1000, 500))
  net:add(nn.Tanh())
  net:add(nn.Linear(500, 1))
  
  criterion = nn.MSECriterion()
end


local function forward_prop(input)
  local action = 0
  local max_reward = math.huge * -1
  for i=0,3 do
    input[136] = i
    output = net:forward(input)
    
      if (i == 0) then
        a = "u"
      elseif (i == 1) then
        a = "d"
      elseif (i == 2) then
        a = "r"
      elseif (i == 3) then
        a = "l"
      else
        a = "f"
      end
    
    
    
    print("Output for action " .. tostring(a) .. ": " .. output[1])
    if (output[1] > max_reward) then
      action = i
      max_reward = output[1]
    end    
  end
  local output = net:forward(input)
  return action, output
end


local function back_prop(input, predicted_output, actual_output)
  
  criterion:forward(net:forward(input), actual_output)
  net:zeroGradParameters()
  net:backward(input, criterion:backward(net.output, actual_output))
  net:updateParameters(0.0001)
  
  
  print("actual output: " .. tostring(actual_output[1]))
  print("\n\n")

end


local function update_cmd(direction)
  local cmd_file = io.open("save1.dat", "w+")
  cmd_file.write(cmd_file, tostring(direction))
  cmd_file.close()
end


local function main()
  init_nn()
  local atrib = lfs.attributes("save1.dat")
  local file_modified = atrib.size
  local iteration = 0
  local current_score = 0
  local previous_score = 0
  local predicted_reward = 0
  local input_buf = torch.Tensor(136)
  local action = 0
  local actual_output = torch.Tensor(1)
  local sum = 0
  
  while 1==1 do
    atrib = lfs.attributes("save1.dat")
    local new_file_size = atrib.size
    if (new_file_size > 5) then
      random = false

      local file = io.open("save1.dat", "r")
      io.input(file)
      
      current_score = tonumber(io.read())
      actual_output[1] = current_score
      if (iteration > 0) then
        back_prop(input_buf, predicted_output, actual_output)
      end
      sum = 0
      
      input_buf = torch.Tensor(137)
      local temp = 0
      for i=1,135 do
        temp = tonumber(io.read())
        sum = sum + temp
        input_buf[i] = temp
      end
      io.close(file)
      
      
      input_buf[137] = current_score
      
      action, predicted_output = forward_prop(input_buf)
      
      
      rand_cap = rand_cap + 1
      if (rand_cap >= 40) then
        rand_cap = 40
      end
      if (iteration >= 500) then
        rand_cap = 0
      end
      
      if (math.random(0,100) >= rand_cap) then
--        action = math.random(0,3)
--        random = true
      end

      
      
      input_buf[136] = action


      print("Action: " .. action .. " Random: " .. tostring(random))
      print("Predicted Output: " .. tostring(predicted_output))
      print("Random Action: " .. tostring(100-rand_cap) .. "%")
      
      iteration = iteration + 1
      print("Iteration: " .. iteration)
      
      



      update_cmd(action)
      
      atrib = lfs.attributes("save1.dat")
      new_file_size = atrib.size
      file_modified = new_file_size
    end
  end  
end



main()
