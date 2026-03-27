local M = {}
local Path = require("plenary.path")
local log = require("vibelearn.utils.logger")

M.progress_file = nil
M.progress = nil

local LEVEL_THRESHOLDS = {
  [1] = 0,
  [2] = 100,
  [3] = 250,
  [4] = 500,
  [5] = 1000,
  [6] = 2000,
  [7] = 3500,
  [8] = 5500,
  [9] = 8000,
  [10] = 11000,
  [11] = 15000,
  [12] = 20000,
}

local PROFICIENCY_THRESHOLDS = {
  beginner = 0,
  intermediate = 500,
  advanced = 2000,
  expert = 5000,
}

local XP_VALUES = {
  task_easy = 15,
  task_medium = 30,
  task_hard = 50,
  task_expert = 100,
  streak_bonus = 10,
  achievement_bonus = 100,
  perfect_code = 25,
  hint_penalty = -5,
  skip_penalty = -20,
}

M.init = function(data_path)
  M.progress_file = Path:new(data_path, "progress.json")
  M.progress = M.load()
end

M.load = function()
  if not M.progress_file or not M.progress_file:exists() then
    return M.create_default()
  end
  
  local ok, data = pcall(function()
    local content = M.progress_file:read()
    return vim.json.decode(content)
  end)
  
  if not ok or not data then
    log.warn("Failed to load progress, creating new one")
    return M.create_default()
  end
  
  return data
end

M.create_default = function()
  return {
    version = 1,
    total_xp = 0,
    level = 1,
    streak = {
      current = 0,
      longest = 0,
      last_activity_date = nil,
    },
    languages = {},
    achievements = {},
    statistics = {
      tasks_completed = 0,
      tasks_skipped = 0,
      time_spent_minutes = 0,
      concepts_learned = {},
    },
    recent_activities = {},
  }
end

M.save = function(progress)
  if not progress then
    progress = M.progress
  end
  
  if not M.progress_file then
    log.error("Progress not initialized")
    return false
  end
  
  progress.updated_at = os.date("%Y-%m-%dT%H:%M:%SZ")
  
  local ok, encoded = pcall(vim.json.encode, progress)
  if not ok then
    log.error("Failed to encode progress")
    return false
  end
  
  M.progress_file:write(encoded, "w")
  return true
end

M.XP_VALUES = XP_VALUES

return M