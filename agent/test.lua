require 'torch'
require 'nn'
require 'lfs'
require 'math'
require 'os'
require 'optim'

local communicate = require("communicate")
local neural_net = require("neural_net")
local queue = require("queue")
local trainer = require("trainer")


local function main()
  local num_features = 197
  local num_outputs = 9
  local net, criterion = neural_net.init_nn(num_features, num_outputs)
  local atrib = lfs.attributes("../save1.dat")
  local file_modified = atrib.size
  local iteration = 0
  local new_score = 0
  local previous_score = 0
  local discount = 1/2  
  local random_percentage = 0
  local foresight = 1
  
  max_iter, train, train_iter, train_learning_rate, dataset_size, store_data, discount, learning_rate, random_percentage, batch_size, foresight, load_model = communicate.prompt_user()
  local dataset_name = "../datasets/dataset" .. tostring(os.date("%m-%d-%y;%H:%M")) .. ".t7"
  
  if load_model then
    net = torch.load("../models/model01-20-18;13:39.th")
  end
  
  if train then
    trainer.train_from_datset(net, criterion, train_iter, train_learning_rate, dataset_size, num_features, num_outputs, batch_size)
  end  
  
  local input_queue = queue.new()
  
  local nth_best = 1
  while iteration <= max_iter do
    atrib = lfs.attributes("../save1.dat")
    local new_file_size = atrib.size
    if (new_file_size > 5) then
      
      if (batch_size > 0) then
        trainer.train_from_memory(net, criterion, 0, learning_rate, batch_size, dataset_name, num_features, num_outputs)
      end

      if (iteration % foresight == 0) then
        if (math.random(0,100) <= random_percentage) then
          nth_best = math.random(2,4)
        else
          nth_best = 1
        end
      end
      local input, new_score = communicate.process_features(score, num_features)
    
      input, predicted_output, action = neural_net.forward_prop(input, net, nth_best, random_percentage, -1, num_outputs)
      communicate.update_cmd(action)
      
      queue.pushright(input_queue, {input, predicted_output, action, new_score})
      
      if (iteration >= foresight) then
        
        local target_experience = queue.popleft(input_queue)
        local target_input = target_experience[1]
        local target_predicted_output = target_experience[2]
        local target_action = target_experience[3]        
        local target_score = target_experience[4]
        local last_score = target_score
        local sum_reward = 0
        local pow = 1

        for i=input_queue.first, input_queue.last do
          if type(input_queue[i]) ~= "number" then
            local inp = input_queue[i]
            sum_reward = sum_reward + ((inp[4]-last_score) * (discount ^ pow))
            pow = pow + 1
            last_score = inp[4]
          end
        end
        local observed_output = torch.Tensor(target_predicted_output:size()):copy(target_predicted_output)
--        local observed_output = torch.zeros(target_predicted_output:size())
        local reward = (new_score - last_score) + sum_reward + (discount ^ pow * predicted_output[action])
        observed_output[target_action] = reward
        
        print("Target action: " .. tostring(target_action))
        print("Score difference: " .. tostring(new_score - target_score))
        print("Sum reward: " .. tostring(sum_reward))
        
        print("Target Observed output: \n" .. tostring(observed_output))
        print("Target predicted output: \n" .. tostring(target_predicted_output))
        
--        print("Predicted output: \n" .. tostring(predicted_output))
--        print("Observed reward: \n" .. tostring(observed_output))
--        print("Action From Input: " .. tostring(target_input[2]))

        local nan_error = 0

        for i=1, num_features do
          if target_input[i] ~= target_input[i] then
            print("NOT A NUMBER ERROR")
            nan_error = 1
          end
        end
        for j=1, 9 do
          if ((target_predicted_output[j] ~= target_predicted_output[j]) or (observed_output[j] ~= observed_output[j])) then
            print("NOT A NUMBER ERROR")
            nan_error = 1
          end
        end

        if nan_error == 0 and iteration > 10 then

          neural_net.back_prop(target_input, target_predicted_output, observed_output, net, criterion, learning_rate, false)        
          
          if store_data and math.abs(reward) >= 2.2 then
            communicate.update_data(dataset_name, target_input, target_action, observed_output)
            if (iteration % 100 == 0) then
              dataset_name = "../datasets/dataset" .. tostring(os.date("%m-%d-%y;%H:%M")) .. ".t7"
            end
            print("Memory saved")
          else
            print("Memory NOT saved")
          end
        else
          print("SKIPPED BACK PROPOGATION DUE TO NAN_ERROR. MEMORY NOT SAVED")
        end

        print("\nEND OF SET\n")
                
      end

      previous_input = input
      previous_action = action
      previous_predicted_output = predicted_output
      previous_score = new_score
      
      atrib = lfs.attributes("../save1.dat")
      new_file_size = atrib.size
      file_modified = new_file_size
             
      print("Iteration: " .. tostring(iteration))
      print("\n\n")
            
      iteration = iteration + 1
            
    end
  end  
  print("End Score: " .. tostring(previous_score))
end



main()



-- 2500 iterations: 16.8698