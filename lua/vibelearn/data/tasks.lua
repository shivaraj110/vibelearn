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
  if not M.tasks_dir:exists() then
    return
  end
  
  local dir_path = tostring(M.tasks_dir)
  local files = vim.fn.readdir(dir_path)
  if not files or #files == 0 then
    return
  end
  
  for _, file in ipairs(files) do
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

M.create_task = function(task_data)
  local task = vim.tbl_deep_extend("force", {
    id = M.generate_id(),
    created_at = os.time(),
    status = "pending",
    attempts = 0,
    hints_used = 0,
    time_spent = 0,
  }, task_data or {})
  
  M.save_task(task)
  return task
end

M.start_task = function(task_id)
  local task = M.get_task(task_id)
  if not task then
    log.error("Task not found:", task_id)
    return false
  end
  
  task.status = "in_progress"
  task.started_at = os.time()
  task.attempts = (task.attempts or 0) + 1
  
  M.save_task(task)
  M.active_task = task
  
  log.info("Task started:", task.title or task_id)
  return true
end

M.get_active_task = function()
  return M.active_task
end

M.set_active_task = function(task_id)
  local task = M.get_task(task_id)
  if task then
    M.active_task = task
    log.info("Active task set:", task.title or task_id)
    return true
  end
  return false
end

M.mark_completed = function(task_id, solution, is_perfect)
  local task = M.get_task(task_id)
  if not task then
    return false
  end
  
  task.status = "completed"
  task.completed_at = os.time()
  task.solution = solution
  task.is_perfect = is_perfect or false
  
  M.save_task(task)
  
  local progress = require("vibelearn.data.progress")
  progress.record_task_completion(
    task.language,
    M.difficulty_to_name(task.difficulty),
    task.time_spent,
    is_perfect
  )
  
  if M.active_task and M.active_task.id == task_id then
    M.active_task = nil
  end
  
  log.info("Task completed:", task.title or task_id)
  return true
end

M.mark_skipped = function(task_id, reason)
  local task = M.get_task(task_id)
  if not task then
    return false
  end
  
  task.status = "skipped"
  task.skipped_at = os.time()
  task.skip_reason = reason
  
  M.save_task(task)
  
  if M.active_task and M.active_task.id == task_id then
    M.active_task = nil
  end
  
  log.info("Task skipped:", task.title or task_id)
  return true
end

M.difficulty_to_name = function(difficulty)
  local names = {
    [1] = "easy",
    [2] = "easy",
    [3] = "medium",
    [4] = "hard",
    [5] = "hard",
  }
  return names[difficulty] or "medium"
end

M.use_hint = function(task_id)
  local task = M.get_task(task_id)
  if not task or not task.hints then
    return nil
  end
  
  local hint_number = (task.hints_used or 0) + 1
  if hint_number > #task.hints then
    return nil
  end
  
  task.hints_used = hint_number
  M.save_task(task)
  
  return task.hints[hint_number]
end

M.clear_active_task = function()
  M.active_task = nil
end

M.get_statistics = function(lang)
  local stats = {
    total = 0,
    completed = 0,
    skipped = 0,
    in_progress = 0,
    pending = 0,
    average_difficulty = 0,
    average_time = 0,
    completion_rate = 0,
  }
  
  local total_difficulty = 0
  local total_time = 0
  
  for _, task in pairs(M.task_cache) do
    if not lang or task.language == lang then
      stats.total = stats.total + 1
      total_difficulty = total_difficulty + (task.difficulty or 0)
      total_time = total_time + (task.time_spent or 0)
      
      if task.status == "completed" then
        stats.completed = stats.completed + 1
      elseif task.status == "skipped" then
        stats.skipped = stats.skipped + 1
      elseif task.status == "in_progress" then
        stats.in_progress = stats.in_progress + 1
      else
        stats.pending = stats.pending + 1
      end
    end
  end
  
  if stats.total > 0 then
    stats.average_difficulty = total_difficulty / stats.total
    stats.average_time = total_time / stats.total
    stats.completion_rate = (stats.completed / stats.total) *100
  end
  
  return stats
end

return M