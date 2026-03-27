local M = {}
local log = require("vibelearn.utils.logger")
local tracker = require("vibelearn.core.tracker")
local analyzer = require("vibelearn.core.analyzer")
local progress = require("vibelearn.data.progress")
local ai_client = require("vibelearn.ai.client")
local tasks = require("vibelearn.data.tasks")
local dashboard = require("vibelearn.ui.dashboard")

M.config = nil
M.scheduled_task = nil
M.last_suggestion_time = nil
M.suggestion_count = 0

M.init = function(cfg)
  M.config = cfg
  M.setup_autocmds()
  log.info("Task scheduler initialized")
end

M.setup_autocmds = function()
  vim.api.nvim_create_autocmd("BufEnter", {
    group = vim.api.nvim_create_augroup("VibeLearnScheduler", { clear = true }),
    callback = M.on_buf_enter,
    desc = "VibeLearn: Check for task suggestions on buffer enter",
  })
  
  vim.api.nvim_create_autocmd("CursorHold", {
    group = vim.api.nvim_create_augroup("VibeLearnSchedulerIdle", { clear = true }),
    callback = M.on_idle,
    desc = "VibeLearn: Check for idle-time task suggestions",
  })
  
  log.debug("Scheduler autocmds setup complete")
end

M.should_suggest_task = function()
  if not M.config.schedule.on_filetype_switch then
    return false
  end
  
  local now = os.time()
  local min_interval = M.config.schedule.reminder_interval_hours * 3600
  
  if M.last_suggestion_time and (now - M.last_suggestion_time) < min_interval then
    return false
  end
  
  if M.suggestion_count >= M.config.schedule.max_suggestions_per_day then
    return false
  end
  
  local hour = tonumber(os.date("%H"))
  local quiet_start = M.config.schedule.quiet_hours.start
  local quiet_stop = M.config.schedule.quiet_hours.stop
  
  if hour >= quiet_start or hour < quiet_stop then
    return false
  end
  
  return true
end

M.on_buf_enter = function(args)
  if not M.should_suggest_task() then
    return
  end
  
  local buf = args.buf
  local ft = vim.bo[buf].filetype
  
  if not ft or ft == "" then
    return
  end
  
  local progress_data = progress.get()
  local profile = require("vibelearn.data.profiles").get()
  
  if vim.tbl_contains(profile.user.target_languages, ft) then
    local lang_progress = progress.get_language_progress(ft)
    
    if lang_progress.tasks_completed < 5 then
      M.queue_suggestion(ft)
    end
  end
end

M.on_idle = function()
  if not M.should_suggest_task() then
    return
  end
  
  local idle_time = M.get_idle_time()
  local min_idle = M.config.schedule.idle_time_minutes * 60
  
  if idle_time >= min_idle then
    local current_ft = tracker.get_current_state().filetype
    if current_ft then
      M.queue_suggestion(current_ft)
    end
  end
end

M.get_idle_time = function()
  local last_activity = tracker.get_current_state().last_activity
  if not last_activity then
    return 0
  end
  
  return os.time() - last_activity
end

M.queue_suggestion = function(lang)
  M.scheduled_task = {
    language = lang,
    queued_at = os.time(),
    status = "pending",
  }
  
  log.debug("Task suggestion queued for:", lang)
end

M.suggest_task = function(lang)
  lang = lang or M.get_current_target_language()
  
  if not lang then
    log.warn("No target language detected")
    vim.notify("Please set a target language in your VibeLearn config", vim.log.levels.WARN)
    return nil
  end
  
  local assessment = analyzer.assess_language(lang)
  local difficulty = M.determine_difficulty(assessment)
  local concepts = analyzer.get_recommended_concepts(lang, assessment.level)
  
  dashboard.show_generating(lang)
  
  ai_client.generate_task(
    M.get_source_language(),
    lang,
    difficulty,
    concepts,
    function(task, err)
      dashboard.close_generating()
      
      if err then
        log.error("Failed to generate task:", err)
        vim.notify("Failed to generate task. Please check your OpenCode setup.", vim.log.levels.ERROR)
        return
      end
      
      if not task then
        log.error("No task received from AI")
        vim.notify("Could not generate a task. Please try again.", vim.log.levels.WARN)
        return
      end
      
      task.language = lang
      tasks.save_task(task)
      
      M.display_task(task)
      
      M.last_suggestion_time = os.time()
      M.suggestion_count = M.suggestion_count + 1
    end
  )
  
  return true
end

M.display_task = function(task)
  local dashboard = require("vibelearn.ui.dashboard")
  dashboard.open_task(task)
end

M.get_source_language = function()
  local profile = require("vibelearn.data.profiles").get()
  return profile.user.primary_language or "python"
end

M.get_current_target_language = function()
  local profile = require("vibelearn.data.profiles").get()
  local targets = profile.user.target_languages
  
  if #targets == 0 then
    return nil
  end
  
  local current_ft = tracker.get_current_state().filetype
  
  if current_ft and vim.tbl_contains(targets, current_ft) then
    return current_ft
  end
  
  local lang_progress = {}
  for _, lang in ipairs(targets) do
    local progress_data = progress.get_language_progress(lang)
    lang_progress[lang] = progress_data.tasks_completed or 0
  end
  
  table.sort(targets, function(a, b)
    return lang_progress[a] < lang_progress[b]
  end)
  
  return targets[1]
end

M.determine_difficulty = function(assessment)
  local level_map = {
    beginner = 1,
    intermediate = 2,
    advanced = 4,
    expert = 5,
  }
  
  local base_difficulty = level_map[assessment.level] or 1
  
  if assessment.confidence < 0.5 then
    return math.max(1, base_difficulty - 1)
  end
  
  if assessment.confidence > 0.8 then
    return math.min(5, base_difficulty + 1)
  end
  
  return base_difficulty
end

M.start_task = function(task_id)
  local task = tasks.get_task(task_id)
  if not task then
    log.error("Task not found:", task_id)
    return false
  end
  
  tasks.start_task(task_id)
  tasks.set_active_task(task_id)
  
  log.info("Task started:", task.title)
  vim.notify("Task started: " .. task.title, vim.log.levels.INFO)
  
  return true
end

M.complete_task = function(task_id, solution, is_perfect)
  task_id = task_id or (tasks.get_active_task() and tasks.get_active_task().id)
  
  if not task_id then
    log.error("No active task to complete")
    return false
  end
  
  local success = tasks.mark_completed(task_id, solution, is_perfect)
  
  if success then
    M.scheduled_task = nil
    M.suggestion_count = M.suggestion_count - 1
    
    local task = tasks.get_task(task_id)
    local xp_gained = progress.XP_VALUES["task_" .. tasks.difficulty_to_name(task.difficulty)]
    
    vim.notify(
      string.format("🎉 Task completed! +%d XP", xp_gained),
      vim.log.levels.INFO
    )
  end
  
  return success
end

M.skip_task = function(task_id, reason)
  task_id = task_id or (tasks.get_active_task() and tasks.get_active_task().id)
  
  if not task_id then
    log.error("No active task to skip")
    return false
  end
  
  local success = tasks.mark_skipped(task_id, reason)
  
  if success then
    M.scheduled_task = nil
    
    progress.allocate(progress.XP_VALUES.skip_penalty, "task_skipped")
    vim.notify("Task skipped. -20 XP", vim.log.levels.INFO)
  end
  
  return success
end

M.get_hint = function(task_id)
  task_id = task_id or (tasks.get_active_task() and tasks.get_active_task().id)
  
  if not task_id then
    log.error("No active task")
    return nil
  end
  
  local hint = tasks.use_hint(task_id)
  
  if hint then
    vim.notify("💡 Hint: " .. hint, vim.log.levels.INFO)
  else
    vim.notify("No more hints available", vim.log.levels.WARN)
  end
  
  return hint
end

M.get_daily_progress = function()
  local daily_goal = M.config.schedule.daily_goal_tasks or 3
  local today = os.date("%Y-%m-%d")
  local completed_today = 0
  
  local progress_data = progress.get()
  for _, lang_data in pairs(progress_data.languages) do
    completed_today = completed_today + (lang_data.tasks_completed_today or 0)
  end
  
  return {
    completed = completed_today,
    goal = daily_goal,
    percentage = math.min(100, (completed_today / daily_goal) * 100),
  }
end

M.reset_daily_count = function()
  local last_reset = M.config.schedule.last_daily_reset or os.time() - 86400
  local now = os.time()
  
  if os.difftime(now, last_reset) >= 86400 then
    M.suggestion_count =0
    M.config.schedule.last_daily_reset = now
    log.debug("Daily suggestion count reset")
  end
end

return M