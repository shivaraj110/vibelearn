local M = {}
local Path = require("plenary.path")
local log = require("vibelearn.utils.logger")

M.tasks_dir = nil
M.active_task = nil
M.task_cache = {}

M.init = function(data_path)
  M.tasks_dir = Path:new(data_path, "tasks")
  
  if not M.tasks_dir:exists() then
    M.tasks_dir:mkdir({ parents = true })
  end
  
  M.load_cache()
end

M.load_cache = function()
  local files = M.tasks_dir:read()
  if not files then
    return
  end
  
  for _, file in ipairs(vim.split(files, "\n")) do
    if file:match("%.json$") then
      local task_file = M.tasks_dir:joinpath(file)
      local ok, content = pcall(task_file.read, task_file)
      
      if ok and content then
        local task_data = vim.json.decode(content)
        if task_data and task_data.id then
          M.task_cache[task_data.id] = task_data
        end
      end
    end
  end
end

M.save_task = function(task)
  if not task or not task.id then
    log.error("Cannot save task: missing ID")
    return false
  end
  
  local filename = task.id .. ".json"
  local task_file = M.tasks_dir:joinpath(filename)
  
  local ok, encoded = pcall(vim.json.encode, task)
  if not ok then
    log.error("Failed to encode task", task.id)
    return false
  end
  
  local ok2 = pcall(task_file.write, task_file, encoded)
  if not ok2 then
    log.error("Failed to write task file", task.id)
    return false
  end
  
  M.task_cache[task.id] = task
  log.debug("Task saved:", task.id)
  return true
end

M.get_task = function(task_id)
  if M.task_cache[task_id] then
    return M.task_cache[task_id]
  end
  
  local task_file = M.tasks_dir:joinpath(task_id .. ".json")
  if not task_file:exists() then
    return nil
  end
  
  local ok, content = pcall(task_file.read, task_file)
  if not ok or not content then
    return nil
  end
  
  local task_data = vim.json.decode(content)
  M.task_cache[task_id] = task_data
  return task_data
end

M.generate_id = function()
  local template = "xxxxxxxx-xxxx-4xxx-yxxx-xxxxxxxxxxxx"
  return string.gsub(template, "[xy]", function(c)
    local v = (c == "x") and math.random(0, 0xf) or math.random(8, 0xb)
    return string.format("%x", v)
  end)
end

return M