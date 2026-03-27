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
  
  -- Create data directory if it doesn't exist
  if not M.progress_file:exists() then
    local data_dir = Path:new(data_path)
    if not data_dir:exists() then
      data_dir:mkdir({ parents = true })
    end
  end
  
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

M.get = function()
  if not M.progress then
    M.progress = M.load()
  end
  return M.progress
end

M.XP_VALUES = XP_VALUES

M.get_language_progress = function(lang)
  if not M.progress.languages[lang] then
    M.progress.languages[lang] = M.create_language_entry(lang)
  end
  return M.progress.languages[lang]
end

M.create_language_entry = function(lang)
  return {
    proficiency = "beginner",
    xp = 0,
    tasks_completed = 0,
    time_spent_minutes = 0,
    concepts_learned = {},
    errors_encountered = {},
    last_used = nil,
    achievements = {},
  }
end

M.add_language_xp = function(lang, amount, reason)
  local lang_progress = M.get_language_progress(lang)
  lang_progress.xp = lang_progress.xp + amount
  lang_progress.last_used = os.date("%Y-%m-%dT%H:%M:%SZ")
  
  M.update_proficiency(lang)
  M.save()
end

M.update_proficiency = function(lang)
  local lang_progress = M.get_language_progress(lang)
  local xp = lang_progress.xp
  
  if xp >= PROFICIENCY_THRESHOLDS.expert then
    lang_progress.proficiency = "expert"
  elseif xp >= PROFICIENCY_THRESHOLDS.advanced then
    lang_progress.proficiency = "advanced"
  elseif xp >= PROFICIENCY_THRESHOLDS.intermediate then
    lang_progress.proficiency = "intermediate"
  else
    lang_progress.proficiency = "beginner"
  end
end

M.allocate = function(points, activity_type)
  local multiplier = M.get_multiplier(activity_type)
  local total = math.floor(points * multiplier)
  
  M.progress.total_xp = M.progress.total_xp + total
  
  if total > 0 then
    M.update_level()
  end
  
  M.add_activity({
    type = "xp_earned",
    amount = total,
    source = activity_type,
    timestamp = os.time(),
  })
  
  return total
end

M.get_multiplier = function(activity_type)
  local config = require("vibelearn.config.defaults")
  local base = config.gamification and config.gamification.xp_multiplier or 1
  
  if activity_type == "task_easy" then
    return base * 1.0
  elseif activity_type == "task_medium" then
    return base * 1.5
  elseif activity_type == "task_hard" then
    return base * 2.0
  elseif activity_type == "streak_bonus" then
    return base * (1 + (M.progress.streak.current or 0) * 0.1)
  end
  
  return base
end

M.update_level = function()
  local old_level = M.progress.level
  
  for level, threshold in pairs(LEVEL_THRESHOLDS) do
    if M.progress.total_xp >= threshold then
      M.progress.level = math.max(M.progress.level or 1, level)
    end
  end
  
  if (M.progress.level or 1) > old_level then
    M.on_level_up(old_level, M.progress.level)
  end
end

M.on_level_up = function(old_level, new_level)
  local config = require("vibelearn.config.defaults")
  
  if config.gamification and config.gamification.show_notifications then
    vim.notify(
      string.format("🎉 Level Up! You are now level %d!", new_level),
      vim.log.levels.INFO
    )
  end
  
  M.add_activity({
    type = "level_up",
    old_level = old_level,
    new_level = new_level,
    timestamp = os.time(),
  })
  
  M.save()
end

M.add_activity = function(activity)
  table.insert(M.progress.recent_activities or {},1, activity)
  
  local config = require("vibelearn.config.defaults")
  local max_history = (config.storage and config.storage.max_history_days or 30) * 24
  
  if #M.progress.recent_activities > max_history then
    table.remove(M.progress.recent_activities)
  end
  
  M.save()
end

M.record_task_completion = function(lang, difficulty, time_spent_minutes, is_perfect)
  M.progress.statistics.tasks_completed = (M.progress.statistics.tasks_completed or 0) +1
  
  local xp_key = "task_" .. difficulty
  local base_xp = XP_VALUES[xp_key] or XP_VALUES.task_medium
  
  if is_perfect then
    base_xp = base_xp + (XP_VALUES.perfect_code or 0)
  end
  
  M.allocate(base_xp, xp_key)
  M.add_language_xp(lang, base_xp, "task_completion")
  
  local lang_progress = M.get_language_progress(lang)
  lang_progress.tasks_completed = (lang_progress.tasks_completed or 0) + 1
  lang_progress.time_spent_minutes = (lang_progress.time_spent_minutes or 0) + (time_spent_minutes or 0)
  
  M.add_activity({
    type = "task_completed",
    language = lang,
    difficulty = difficulty,
    time_spent = time_spent_minutes,
    xp_earned = base_xp,
    timestamp = os.time(),
  })
  
  M.save()
end

M.get_stats_summary = function()
  local progress = M.get()
  
  return {
    level = progress.level or 1,
    total_xp = progress.total_xp or 0,
    streak_days = progress.streak and progress.streak.current or 0,
    longest_streak = progress.streak and progress.streak.longest or 0,
    tasks_completed = progress.statistics and progress.statistics.tasks_completed or 0,
    languages_learned = progress.languages and vim.tbl_count(progress.languages) or 0,
    achievements_unlocked = progress.achievements and #progress.achievements or 0,
    total_time_hours = (progress.statistics and progress.statistics.time_spent_minutes or 0) / 60,
  }
end

return M