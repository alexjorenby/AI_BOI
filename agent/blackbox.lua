require 'torch'
require 'nn'

local Settings = require("./communicate")
local NeuralNetwork = require("./neural_net")
local Queue = require("./queue")
local Trainer = require("./trainer")

local BlackBox = {}
BlackBox.__index = BlackBox

setmetatable(BlackBox, {
  __call = function (cls, ...)
  local self = setmetatable({}, cls)
  self:_init(...)
  return self
end
})

function BlackBox:_init(depth, height, width, numFeatures, numOutputs, rows, columns)
  self.net, self.criterion = NeuralNetwork.init_nn(numFeatures, numOutputs, rows, columns)
  self.num_features = numFeatures
  self.num_outputs = numOutputs
  self.store_iteration = 0
  
  self.iteration = 0
  self.max_iter = math.huge
  self.train = true
  self.discount = 0.9
  self.learning_rate = 0.00001
  self.store_data = true
  self.dataset_size = 500000000
  self.train_iter = 3
  self.train_learning_rate = 0.00001
  self.random_percentage = 75
  self.batch_size = 5
  self.foresight = 10
  self.load_model = true
  self.score = 0
  self.Done = false
  
  self.input_queue = Queue.new()
  self.skip = 0
  self.nth_best = 1
  
  self.rows = rows
  self.columns = columns

  self.test = false

  if self.load_model then
--    net = torch.load("../models/model03-04-18;02:42.th")
--      batch_size = 1
  else
--      batch_size = 0
  end
  
  if self.train then
    Trainer.train_from_datset(self.net, self.criterion, self.train_iter, self.train_learning_rate, self.dataset_size, self.num_features, self.num_outputs, self.batch_size)
  end 
  self.dataset_name = "./datasets/dataset" .. tostring(os.date("%m-%d-%y;%H:%M:%S")) .. ".t7"
    
end


function BlackBox:Run(passed_input, new_score, skip)
  
  self.skip = skip
  
  local nth_best = 1
  local check = 0
  local target_experience = nil
  local target_input = nil
  local target_predicted_output = nil
  local target_action = nil
  local string = ""

  if (self.iteration > 10000 and self.random_percentage > 0) then
    self.random_percentage = 25
  end
  
  if (self.iteration > 50000) then
--    self.test = true
    self.random_percentage = 5
  end
  
  local input, predicted_output, action = NeuralNetwork.forward_prop(passed_input, self.net, nth_best, self.random_percentage, -1, self.num_outputs)
  
    
  Queue.pushright(self.input_queue, {input, torch.Tensor(45):copy(predicted_output), action, new_score})
  
--  string = string .. "\n Predicted Output: \n" .. tostring(predicted_output) 
    
  if (self.iteration >= self.foresight and self.test == false) then
    
    target_experience = Queue.popleft(self.input_queue)
    target_input = target_experience[1]
    target_predicted_output = target_experience[2]
    target_action = target_experience[3] 
    
    local reward = self:CalculateReward(predicted_output, action, new_score, target_experience[4])

    observed_output = torch.Tensor(target_predicted_output:size()):copy(target_predicted_output)
--    if (self.iteration <= 50) then
--      observed_output = torch.zeros(target_predicted_output:size())
--    end
--        local observed_output = torch.zeros(target_predicted_output:size())
    
    observed_output[target_action] = reward
        
--    string = string .. "\n" .. "Target Observed output: \n" .. tostring(observed_output)
--    string = string .. "\n" .. "Target predicted output: \n"
    local str = ""
--    for p = 1, self.num_outputs do
--      str = str .. tostring(target_predicted_output[p]) .. ",\n"
--    end
    string = string .. "Predicted reward: " .. target_predicted_output[target_action] .. "\n"
    string = string .. "Reward: " .. tostring(reward) .. "\n"
    string = string .. str .. "\n" .. "Random Percentage: " .. tostring(self.random_percentage)
    
    local nan_error = 0

    for i=1, 45 do
      
      if ((target_predicted_output[i] ~= target_predicted_output[i]) or (observed_output[i] ~= observed_output[i])) then
        print("NOT A NUMBER ERROR")
        nan_error = 1
      end
    end

    if (nan_error == 0 and self.iteration > 10 and self.skip < 0) then

      NeuralNetwork.back_prop(target_input, target_predicted_output, observed_output, self.net, self.criterion, self.learning_rate, false)        
                  
      if self.store_data and (self.iteration >= 50) then
        Settings.update_data(self.dataset_name, target_input, target_action, observed_output)
        self.store_iteration = self.store_iteration + 1
        if (self.iteration % 150 == 0) then
          self.dataset_name = "./datasets/dataset" .. tostring(os.date("%m-%d-%y;%H:%M:%S")) .. ".t7"
        end
--        print("Memory saved")
      else
--        print("Memory NOT saved")
      end

    else
--      print("SKIPPED BACK PROPOGATION DUE TO NAN_ERROR. MEMORY NOT SAVED")
    end

  end

  self.skip = self.skip - 1
    
  self.previous_input = input
  self.previous_action = action
  self.previous_predicted_output = predicted_output
  self.score = new_score
    
    
  if (self.batch_size > 0 and self.skip <= 0) then
    Trainer.train_from_memory(self.net, self.criterion, 0, self.learning_rate, self.batch_size, self.dataset_name, self.num_features, self.num_outputs, input, predicted_output)
  end
  string = string .. "\nIteration: " .. tostring(self.iteration) .. "\n\n"
        
  self.iteration = self.iteration + 1
  
  string = string .. "\nEND OF SET\n"
  
  print(string)
        
  return action
  
end

function BlackBox:CalculateReward(predicted_output, action, new_score, last_score)
  local sum_reward = 0
  local inp = nil
  local pow = 1
  for i=self.input_queue.first, self.input_queue.last do
    if type(self.input_queue[i]) ~= "number" then
      inp = self.input_queue[i]
      sum_reward = sum_reward + ((inp[4]-last_score) * (self.discount ^ pow))
      pow = pow + 1
      last_score = inp[4]
    end
  end
  return (new_score - self.score) + sum_reward + (self.discount ^ pow * predicted_output[action])

end


return BlackBox

