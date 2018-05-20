local C = {}


local function update_cmd(command)
  local cmd_file = io.open("./save1.dat", "w+")
  cmd_file.write(cmd_file, tostring(command))
  cmd_file.close()
end


local function update_data(file_name, input, chosen_action, output)
  local f = io.open(file_name, "r")
  if (f == nil or f.read(f) == "") then
    f = io.open(file_name, "w")
    local dataset = {}
    dataset[0] = { data = input, labels = output, action = chosen_action }
    torch.save(file_name, dataset)
  else
    saved_dataset = torch.load(file_name)
    saved_dataset[#saved_dataset+1] = { data = input, labels = output , action = chosen_action }
    torch.save(file_name, saved_dataset)
  end
  f.close(f)
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
  local batch_size = 1
  local foresight = 1
  local train = 'n'
  local store_data = 'n'
  local load_model = 'n'
  local default_flag = 'n'
  
  print("Default setup? (y/n)")
  default_flag = io.read()
  if default_flag == 'y' then
    max_iter = math.huge
    train = 'n'
    discount_factor = 0.7
    learning_rate = 0.9
    store_data = 'y'
    dataset_size = 500000
    train_iter = 10
    train_learning_rate = 0.9
    random_percentage = 5
    batch_size = 0
    foresight = 5
    load_model = 'y'
    confirm = 'y'
  end

  while confirm ~= 'y' do
    dataset_size = -1
    train_iter = -1
    train_learning_rate = -1
    
    print("Load from model? (y/n)")
    load_model = io.read()
    
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
    
    print("Foresight (integer)")
    foresight = tonumber(io.read())
    if (foresight == nil) then error("Invalid entry") end

    print("\nLoad Model: " .. tostring(load_model == 'y'))
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
    print("Foresight: " .. tostring(foresight))
    print("\nConfirm? (y/n)")
    confirm = io.read()
  end
  return max_iter, train=='y', train_iter, train_learning_rate, dataset_size, store_data=='y', discount_factor, learning_rate, random_percentage, batch_size, foresight, load_model=='y'
end


local function process_features(depth, width, height)
  local file = io.open("./save1.dat", "r")
  io.input(file)

  local score = tonumber(io.read())  
  local input_buf = torch.Tensor(depth, height, width)
  local temp = 0
  
  for i=1,depth do
    for j=1,height do
      for k=1,width do
        temp = tonumber(io.read())
--        print(tostring(i) .. " " .. tostring(j) .. " " .. tostring(k))
        input_buf[i][j][k] = temp
      end
    end
  end

  io.close(file)
  
  return input_buf, score  
  
end



local function record_score(previous_score)
  local the_file = io.open("../loop.txt", "a+")
  local ps = tostring(previous_score) .. ",\n"
  the_file.write(the_file, ps)
  the_file.close()
end


C.update_cmd = update_cmd
C.update_data = update_data
C.prompt_user = prompt_user
C.process_features = process_features
C.record_score = record_score

return C

